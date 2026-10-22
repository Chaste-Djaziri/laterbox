import Foundation
import CryptoKit
import UniformTypeIdentifiers
import SwiftData

struct CloudItemSnapshot: Codable {
    var id: String
    var user_id: String?
    var url: String?
    var title: String?
    var text_content: String?
    var text_selector: String? = nil
    var type: String?
    var favorite: Bool?
    var status: String?
    var return_at: String?
    var inbox_entered_at: String? = nil
    var created_at: String?
    var updated_at: String?
    var deleted_at: String?
    var item_metadata: CloudMetadata?
    var item_notes: CloudNote?
    var collection_items: [CloudMembership]?
    var attachments: [CloudAttachmentSnapshot]?
    var permanently_deleted: Bool?
}
struct CloudDeletionReceipt: Codable { var item_id: String; var deleted_at: String }
struct CloudAttachmentSnapshot: Codable {
    var id: String
    var item_id: String
    var original_file_name: String
    var file_extension: String
    var mime_type: String
    var byte_size: Int64
    var sha256: String
    var r2_object_key: String?
    var deleted_at: String?
}
struct CloudMembership: Codable {
    var collection_id: String
    var deleted_at: String?
    var collections: CloudCollection?

    init(collection_id: String, deleted_at: String? = nil, collections: CloudCollection? = nil) {
        self.collection_id = collection_id
        self.deleted_at = deleted_at
        self.collections = collections
    }
}
struct CloudCollection: Codable { var id: String; var name: String }
struct CloudNote: Codable { var content: String; var deleted_at: String? }
struct CloudMetadata: Codable {
    var domain: String?; var site_name: String?; var description: String?
    var favicon_url: String?; var preview_image_url: String?; var status: String
    var structured_data: CloudClassification?
}
struct CloudClassification: Codable {
    var tags: [String]?; var category: String?; var summary: String?; var formattedContent: String?; var seen: Bool?
}

// Older clients can send classification as a JSON string as well as an object.
extension CloudClassification {
    enum CodingKeys: String, CodingKey { case tags, category, summary, formattedContent, seen }
    init(from decoder: Decoder) throws {
        if let string = try? decoder.singleValueContainer().decode(String.self) {
            self = (try? JSONDecoder().decode(Self.self, from: Data(string.utf8))) ?? Self()
            return
        }
        guard let values = try? decoder.container(keyedBy: CodingKeys.self) else { self = Self(); return }
        tags = try? values.decodeIfPresent([String].self, forKey: .tags)
        category = try? values.decodeIfPresent(String.self, forKey: .category)
        summary = try? values.decodeIfPresent(String.self, forKey: .summary)
        formattedContent = try? values.decodeIfPresent(String.self, forKey: .formattedContent)
        seen = try? values.decodeIfPresent(Bool.self, forKey: .seen)
    }
}

public enum CloudSyncError: LocalizedError, CustomStringConvertible, Sendable, Equatable {
    case unauthenticated
    case unauthorized(message: String)
    case serverError(statusCode: Int, message: String)
    case networkUnavailable(String)
    case decodingError(String)
    case other(String)

    public var errorDescription: String? {
        description
    }

    public var description: String {
        switch self {
        case .unauthenticated:
            return "Session expired or missing authentication. Please sign in again."
        case .unauthorized(let message):
            let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
            let lower = trimmed.lowercased()
            if lower.contains("jwt expired") || lower.contains("token expired") {
                return "Session expired (JWT expired). Please sign in again to continue syncing."
            }
            return trimmed.isEmpty ? "Authentication required or access denied (401/403)." : "Authentication error: \(trimmed)"
        case .serverError(let code, let message):
            let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "Server error (HTTP \(code)). Please try again later." : "Server error (HTTP \(code)): \(trimmed)"
        case .networkUnavailable(let message):
            let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "Network offline. Changes will sync when reconnected." : "Network error: \(trimmed)"
        case .decodingError(let message):
            return "Failed to parse cloud response: \(message)"
        case .other(let message):
            return message
        }
    }
}

protocol IOSCloudTransport: Sendable {
    func downloadSnapshots(userID: String, token: String) async throws -> [CloudItemSnapshot]
    func cloudRequest(_ path: String, token: String, method: String, body: Any?) async throws -> Data
    func uploadSnapshot(_ body: [String: Any], metadata: [String: Any], note: [String: Any], collection: [String: Any]?, token: String) async throws
}

extension LaterBoxAPIService: IOSCloudTransport {
    func cloudRequest(_ path: String, token: String, method: String = "GET", body: Any? = nil) async throws -> Data {
        guard let url = URL(string: "\(supabaseUrl)/rest/v1/\(path)") else { throw CloudSyncError.other("Invalid server URL") }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("resolution=merge-duplicates,return=minimal", forHTTPHeaderField: "Prefer")
        if let body { request.httpBody = try JSONSerialization.data(withJSONObject: body) }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let urlErr as URLError {
            switch urlErr.code {
            case .cancelled:
                // SwiftUI refresh tasks and disappearing views can cancel an
                // in-flight request. Preserve cancellation so the coordinator
                // can ignore it instead of showing a false network failure.
                throw CancellationError()
            case .notConnectedToInternet, .networkConnectionLost, .dnsLookupFailed:
                throw CloudSyncError.networkUnavailable("No internet connection")
            case .timedOut:
                throw CloudSyncError.networkUnavailable("Request timed out connecting to cloud server")
            default:
                throw CloudSyncError.networkUnavailable(urlErr.localizedDescription)
            }
        } catch {
            throw CloudSyncError.other(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else { throw CloudSyncError.other("Invalid response from cloud server") }
        guard (200..<300).contains(http.statusCode) else {
            var serverMsg = ""
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                serverMsg = (json["message"] as? String) ?? (json["msg"] as? String) ?? (json["error_description"] as? String) ?? (json["error"] as? String) ?? ""
            } else if let rawString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !rawString.isEmpty {
                serverMsg = rawString
            }
            if http.statusCode == 401 || http.statusCode == 403 {
                throw CloudSyncError.unauthorized(message: serverMsg.isEmpty ? "Authentication token expired or unauthorized access" : serverMsg)
            } else {
                throw CloudSyncError.serverError(statusCode: http.statusCode, message: serverMsg)
            }
        }
        return data
    }
    func downloadSnapshots(userID: String, token: String) async throws -> [CloudItemSnapshot] {
        var result: [CloudItemSnapshot] = []
        var offset = 0
        while true {
            let data = try await cloudRequest("items?user_id=eq.\(userID)&select=*,item_metadata(*),item_notes(*),collection_items(collection_id,deleted_at,collections(id,name)),attachments(id,item_id,original_file_name,file_extension,mime_type,byte_size,sha256,r2_object_key,deleted_at)&order=id.asc&limit=100&offset=\(offset)", token: token)
            do {
                let page = try JSONDecoder().decode([CloudItemSnapshot].self, from: data)
                result += page
                if page.count < 100 { break }
                offset += page.count
            } catch {
                throw CloudSyncError.decodingError(error.localizedDescription)
            }
        }
        let receipts = try await downloadDeletionReceipts(userID: userID, token: token)
        let removedIDs = Set(receipts.map { $0.item_id.lowercased() })
        result.removeAll { removedIDs.contains($0.id.lowercased()) }
        result += receipts.map { CloudItemSnapshot(id: $0.item_id, user_id: userID, updated_at: $0.deleted_at,
            deleted_at: $0.deleted_at, permanently_deleted: true) }
        return result
    }
    func downloadDeletionReceipts(userID: String, token: String) async throws -> [CloudDeletionReceipt] {
        var receipts: [CloudDeletionReceipt] = []
        var offset = 0
        while true {
            let data = try await cloudRequest("item_deletion_receipts?user_id=eq.\(userID)&select=item_id,deleted_at&order=item_id&limit=1000&offset=\(offset)", token: token)
            let page = try JSONDecoder().decode([CloudDeletionReceipt].self, from: data)
            receipts += page
            if page.count < 1000 { return receipts }
            offset += page.count
        }
    }
    func uploadSnapshot(_ body: [String: Any], metadata: [String: Any], note: [String: Any], collection: [String: Any]?, token: String) async throws {
        _ = try await cloudRequest("items?on_conflict=id", token: token, method: "POST", body: body)
        var mergedMetadata = metadata
        if let itemID = body["id"] as? String {
            let oldData = try await cloudRequest("item_metadata?item_id=eq.\(itemID)&select=structured_data", token: token)
            if let rows = try JSONSerialization.jsonObject(with: oldData) as? [[String: Any]],
               var structured = rows.first?["structured_data"] as? [String: Any],
               let current = metadata["structured_data"] as? [String: Any] {
                structured.merge(current) { _, new in new }
                mergedMetadata["structured_data"] = structured
            }
        }
        _ = try await cloudRequest("item_metadata?on_conflict=item_id", token: token, method: "POST", body: mergedMetadata)
        _ = try await cloudRequest("item_notes?on_conflict=item_id", token: token, method: "POST", body: note)
        if let collection {
            _ = try await cloudRequest("collections?on_conflict=id", token: token, method: "POST", body: collection)
            let userId = (collection["user_id"] as? String) ?? (body["user_id"] as? String) ?? ""
            let stamp = (collection["updated_at"] as? String) ?? (body["updated_at"] as? String) ?? ISO8601DateFormatter().string(from: Date())
            let createdAt = (collection["created_at"] as? String) ?? (body["created_at"] as? String) ?? stamp
            let membershipBody: [String: Any] = [
                "collection_id": collection["id"]!,
                "item_id": body["id"]!,
                "user_id": userId,
                "created_at": createdAt,
                "updated_at": stamp,
                "deleted_at": NSNull()
            ]
            _ = try await cloudRequest("collection_items?on_conflict=collection_id,item_id", token: token, method: "POST", body: membershipBody)
            if let itemID = body["id"] as? String, let collId = collection["id"] as? String, !userId.isEmpty {
                _ = try? await cloudRequest("collection_items?item_id=eq.\(itemID)&user_id=eq.\(userId)&collection_id=neq.\(collId)&deleted_at=is.null", token: token, method: "PATCH", body: ["deleted_at": stamp, "updated_at": stamp])
            }
        } else if let itemID = body["id"] as? String, let userId = body["user_id"] as? String {
            let stamp = (body["updated_at"] as? String) ?? ISO8601DateFormatter().string(from: Date())
            _ = try? await cloudRequest("collection_items?item_id=eq.\(itemID)&user_id=eq.\(userId)&deleted_at=is.null", token: token, method: "PATCH", body: ["deleted_at": stamp, "updated_at": stamp])
        }
        if let itemID = body["id"] as? String, let userId = body["user_id"] as? String,
           body["deleted_at"] != nil, !(body["deleted_at"] is NSNull) {
            let stamp = (body["deleted_at"] as? String) ?? (body["updated_at"] as? String) ?? ISO8601DateFormatter().string(from: Date())
            _ = try? await cloudRequest("collection_items?item_id=eq.\(itemID)&user_id=eq.\(userId)&deleted_at=is.null", token: token, method: "PATCH", body: ["deleted_at": stamp, "updated_at": stamp])
        }
    }
}

extension LaterBoxAPIService {
    func permanentlyDeleteCloudItem(itemID: String, token: String) async throws {
        let result = try await attachmentFunction(["action": "delete-item", "itemId": itemID], token: token)
        guard result["deleted"] as? Bool == true else {
            throw CloudSyncError.other("Permanent deletion could not finish. It will be retried.")
        }
    }

    func uploadAttachments(_ attachments: [SharedAttachment], itemID: String, userID: String, token: String) async throws -> [SharedAttachment] {
        var uploaded = attachments
        for index in uploaded.indices {
            let attachment = uploaded[index]
            guard attachment.remoteObjectKey == nil else { continue }
            let source = try SharedCaptureStore.fileURL(attachment)
            let data = try Data(contentsOf: source)
            let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
            let ext = source.pathExtension.lowercased().isEmpty ? "bin" : source.pathExtension.lowercased()
            let mime = attachment.mimeType ?? UTType(filenameExtension: ext)?.preferredMIMEType ?? "application/octet-stream"
            let payload: [String: Any] = ["action": "prepare-upload", "attachmentId": attachment.id, "itemId": itemID,
                "originalFileName": attachment.name, "extension": ext, "mimeType": mime, "byteSize": data.count, "sha256": digest]
            let prepared = try await attachmentFunction(payload, token: token)
            guard let uploadURL = prepared["uploadUrl"] as? String, let url = URL(string: uploadURL) else { throw CloudSyncError.other("Attachment upload URL was unavailable") }
            var request = URLRequest(url: url); request.httpMethod = "PUT"; request.httpBody = data
            request.setValue(mime, forHTTPHeaderField: "Content-Type")
            request.setValue(digest, forHTTPHeaderField: "x-amz-meta-sha256")
            // The signing function normalizes UUIDs to lowercase. Signed metadata
            // must match byte-for-byte (Swift UUID().uuidString is uppercase).
            request.setValue(attachment.id.lowercased(), forHTTPHeaderField: "x-amz-meta-attachment-id")
            request.setValue(userID, forHTTPHeaderField: "x-amz-meta-user-id")
            let (responseData, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard (200..<300).contains(status) else {
                let xml = String(data: responseData, encoding: .utf8) ?? ""
                let code = xml.range(of: "<Code>").flatMap { start in
                    xml.range(of: "</Code>", range: start.upperBound..<xml.endIndex).map {
                        String(xml[start.upperBound..<$0.lowerBound])
                    }
                } ?? "Storage request rejected"
                throw CloudSyncError.other("Attachment upload failed (HTTP \(status): \(code))")
            }
            let complete: [String: Any] = ["action": "complete-upload", "attachmentId": attachment.id, "itemId": itemID,
                "originalFileName": attachment.name, "extension": ext, "mimeType": mime, "byteSize": data.count, "sha256": digest]
            let verified = try await attachmentFunction(complete, token: token)
            guard let objectKey = verified["objectKey"] as? String else { throw CloudSyncError.other("Attachment verification failed") }
            uploaded[index].remoteObjectKey = objectKey; uploaded[index].byteSize = Int64(data.count); uploaded[index].sha256 = digest; uploaded[index].mimeType = mime
        }
        return uploaded
    }

    func publishItemWithAttachments(_ body: [String: Any], attachments: [SharedAttachment], userID: String, token: String) async throws {
        let stamp = ISO8601DateFormatter().string(from: Date())
        let rows: [[String: Any]] = try attachments.map { attachment in
            guard let key = attachment.remoteObjectKey, !key.isEmpty,
                  let size = attachment.byteSize, let digest = attachment.sha256,
                  let mime = attachment.mimeType else {
                throw CloudSyncError.other("An attachment has not finished uploading")
            }
            let ext = URL(fileURLWithPath: attachment.name).pathExtension.lowercased()
            return ["id": attachment.id, "item_id": body["id"]!, "user_id": userID,
                "original_file_name": attachment.name, "file_extension": ext.isEmpty ? "bin" : ext,
                "mime_type": mime, "byte_size": size, "sha256": digest, "r2_object_key": key,
                "created_at": stamp, "updated_at": stamp]
        }
        _ = try await cloudRequest("rpc/publish_item_attachments", token: token, method: "POST", body: ["item": body, "assets": rows])
    }

    func downloadAttachment(_ attachment: CloudAttachmentSnapshot, token: String) async throws -> SharedAttachment {
        let response = try await attachmentFunction(["action": "prepare-download", "attachmentId": attachment.id], token: token)
        guard let rawURL = response["downloadUrl"] as? String, let url = URL(string: rawURL) else { throw CloudSyncError.other("Attachment download URL was unavailable") }
        let (data, httpResponse) = try await URLSession.shared.data(from: url)
        guard let http = httpResponse as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw CloudSyncError.other("Attachment download failed. Please try pulling again.")
        }
        let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        guard Int64(data.count) == attachment.byte_size, digest == attachment.sha256.lowercased() else {
            throw CloudSyncError.other("Attachment download was incomplete. Please try pulling again.")
        }
        let safeName = attachment.original_file_name.isEmpty ? "attachment" : URL(fileURLWithPath: attachment.original_file_name).lastPathComponent
        let directory = try SharedCaptureStore.attachmentDirectory(id: attachment.id, root: SharedCaptureStore.root())
        let relative = "Attachments/\(directory.lastPathComponent)/\(safeName)"
        let destination = directory.appendingPathComponent(safeName)
        try data.write(to: destination, options: .atomic)
        return SharedAttachment(id: attachment.id, name: safeName, relativePath: relative, typeIdentifier: UTType(mimeType: attachment.mime_type)?.identifier ?? attachment.mime_type,
            remoteObjectKey: attachment.r2_object_key, byteSize: attachment.byte_size, sha256: attachment.sha256, mimeType: attachment.mime_type)
    }

    func remoteAttachments(itemID: String, userID: String, token: String) async throws -> [CloudAttachmentSnapshot] {
        let data = try await cloudRequest("attachments?item_id=eq.\(itemID)&user_id=eq.\(userID)&deleted_at=is.null&select=id,item_id,original_file_name,file_extension,mime_type,byte_size,sha256,r2_object_key,deleted_at", token: token)
        return try JSONDecoder().decode([CloudAttachmentSnapshot].self, from: data)
    }

    private func attachmentFunction(_ body: [String: Any], token: String) async throws -> [String: Any] {
        guard let url = URL(string: "\(supabaseUrl)/functions/v1/attachment-storage") else { throw CloudSyncError.other("Invalid attachment service URL") }
        var request = URLRequest(url: url); request.httpMethod = "POST"; request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.setValue(anonKey, forHTTPHeaderField: "apikey"); request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization"); request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { throw CloudSyncError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: String(data: data, encoding: .utf8) ?? "Attachment service failed") }
        return (try JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    }
}

@MainActor
extension SyncCoordinator {
    @discardableResult
    func performCloudPull(context: ModelContext, transport: (any IOSCloudTransport)? = nil) async throws -> Int {
        guard hasCloudPro else { return 0 }
        guard isAuthenticated, let uid = currentUserId, var token = authToken else {
            throw CloudSyncError.unauthenticated
        }
        let api: any IOSCloudTransport = transport ?? LaterBoxAPIService.shared
        let remote: [CloudItemSnapshot]
        do {
            remote = try await api.downloadSnapshots(userID: uid, token: token)
        } catch let err as CloudSyncError {
            if case .unauthorized = err, await refreshAuthSession(), let refreshedToken = authToken {
                token = refreshedToken
                remote = try await api.downloadSnapshots(userID: uid, token: token)
            } else {
                throw err
            }
        }
        guard currentUserId == uid, authToken == token else { return 0 }
        let local = try context.fetch(FetchDescriptor<LBItem>())
        var byID: [String: LBItem] = [:]
        var byURL: [String: LBItem] = [:]
        for loc in local {
            byID[loc.id.lowercased()] = loc
            if let norm = LBItem.normalizeURL(loc.url) {
                if let existing = byURL[norm] {
                    if !loc.isSyncPending && existing.isSyncPending {
                        byURL[norm] = loc
                    }
                } else {
                    byURL[norm] = loc
                }
            }
        }
        var appliedCount = 0

        for snapshot in remote {
            if snapshot.permanently_deleted == true {
                for item in local where item.id.caseInsensitiveCompare(snapshot.id) == .orderedSame {
                    context.delete(item)
                    appliedCount += 1
                }
                byID.removeValue(forKey: snapshot.id.lowercased())
                cloudDeletionQueue.removeAll { $0.caseInsensitiveCompare(snapshot.id) == .orderedSame }
                continue
            }
            let remoteDate = snapshot.updated_at.flatMap(Self.cloudDate) ?? .distantPast
            let item: LBItem
            let normSnapUrl = LBItem.normalizeURL(snapshot.url)
            let existingMatch = byID[snapshot.id.lowercased()] ?? (normSnapUrl.flatMap { byURL[$0] })

            if let existing = existingMatch {
                // Restore files independently of item timestamps or pending edits.
                // Updating a title must not prevent an already-uploaded image from downloading.
                if let attachmentAPI = api as? LaterBoxAPIService,
                   let remoteAssets = snapshot.attachments?.filter({ $0.deleted_at == nil }), !remoteAssets.isEmpty {
                    var assets = existing.attachmentsData.flatMap { try? JSONDecoder().decode([SharedAttachment].self, from: $0) } ?? []
                    for remote in remoteAssets {
                        let index = assets.firstIndex { $0.id.caseInsensitiveCompare(remote.id) == .orderedSame }
                        if let index, (try? SharedCaptureStore.fileURL(assets[index])).map({ FileManager.default.fileExists(atPath: $0.path) }) == true {
                            assets[index].remoteObjectKey = remote.r2_object_key
                            assets[index].byteSize = remote.byte_size
                            assets[index].sha256 = remote.sha256
                            assets[index].mimeType = remote.mime_type
                        } else {
                            let restored = try await attachmentAPI.downloadAttachment(remote, token: token)
                            if let index { assets[index] = restored } else { assets.append(restored) }
                        }
                    }
                    existing.attachmentsData = try JSONEncoder().encode(assets)
                    try context.save()
                }
                // A snapshot can arrive after the item upload but before its assets.
                // It must never acknowledge or replace an unfinished local capture.
                if existing.isSyncPending, let data = existing.attachmentsData,
                   let attachments = try? JSONDecoder().decode([SharedAttachment].self, from: data),
                   !attachments.isEmpty { continue }
                let isIdChange = existing.id.caseInsensitiveCompare(snapshot.id) != .orderedSame

                // Conflict resolution taking the recent action based on timestamps:
                if existing.updatedAt > remoteDate {
                    // Local edit/delete is newer than remote snapshot: local action takes precedence
                    continue
                }
                if existing.updatedAt == remoteDate {
                    // Tie-breaker matching Web's resolveActionConflict:
                    // If local is deleted and remote is not deleted, local delete wins
                    if existing.status == "deleted" && snapshot.deleted_at == nil {
                        continue
                    }
                    // If both are active or both are deleted with identical timestamps, already in sync
                    if (existing.status == "deleted") == (snapshot.deleted_at != nil) {
                        let localAssets = existing.attachmentsData.flatMap { try? JSONDecoder().decode([SharedAttachment].self, from: $0) } ?? []
                        let allAssetsAvailable = (snapshot.attachments ?? []).filter { $0.deleted_at == nil }.allSatisfy { remote in
                            localAssets.contains { local in
                                local.id.caseInsensitiveCompare(remote.id) == .orderedSame && (try? SharedCaptureStore.fileURL(local)).map {
                                    FileManager.default.fileExists(atPath: $0.path)
                                } == true
                            }
                        }
                        if allAssetsAvailable {
                            existing.isSyncPending = false
                            continue
                        }
                    }
                    // Remote is deleted while local is active: remote delete wins
                }

                if isIdChange {
                    let noteToKeep = existing.noteContent
                    let tagsToKeep = existing.tags
                    let collIdToKeep = existing.collectionId
                    let collNameToKeep = existing.collectionName
                    let attachmentsToKeep = existing.attachmentsData
                    context.delete(existing)
                    if let direct = byID[snapshot.id.lowercased()] {
                        context.delete(direct)
                    }
                    item = LBItem(id: snapshot.id, title: snapshot.title ?? snapshot.url ?? "Untitled")
                    item.noteContent = noteToKeep
                    item.attachmentsData = attachmentsToKeep
                    item.tags = tagsToKeep
                    item.collectionId = collIdToKeep
                    item.collectionName = collNameToKeep
                    context.insert(item)
                } else {
                    item = existing
                }
                byID[snapshot.id.lowercased()] = item
                if let norm = normSnapUrl { byURL[norm] = item }
            } else {
                if snapshot.deleted_at != nil || cloudDeletionQueue.contains(where: { $0.caseInsensitiveCompare(snapshot.id) == .orderedSame }) {
                    continue
                }
                // When no local version exists, take the cloud version and save locally for offline viewing
                item = LBItem(id: snapshot.id, title: snapshot.title ?? snapshot.url ?? "Untitled")
                context.insert(item)
                byID[snapshot.id.lowercased()] = item
                if let norm = normSnapUrl { byURL[norm] = item }
            }
            item.userId = uid; item.title = snapshot.title ?? snapshot.url ?? "Untitled"; item.url = snapshot.url
            item.textContent = snapshot.text_content; item.textSelector = snapshot.text_selector
            item.type = snapshot.type ?? "link"; item.favorite = snapshot.favorite ?? false
            let priorInboxEntry = existingMatch?.status == "inbox" ? existingMatch?.inboxEnteredAt : nil
            item.status = snapshot.deleted_at == nil ? (snapshot.status ?? "inbox") : "deleted"
            item.returnAt = snapshot.return_at.flatMap(Self.cloudDate)
            item.inboxEnteredAt = snapshot.inbox_entered_at.flatMap(Self.cloudDate)
                ?? (item.status == "inbox" ? priorInboxEntry : nil)
            item.createdAt = snapshot.created_at.flatMap(Self.cloudDate) ?? remoteDate; item.updatedAt = remoteDate
            if let metadata = snapshot.item_metadata {
                item.domain = metadata.domain; item.siteName = metadata.site_name; item.metadataDescription = metadata.description
                item.faviconUrl = metadata.favicon_url; item.previewImageUrl = metadata.preview_image_url; item.enrichmentStatus = metadata.status
                item.tags = metadata.structured_data?.tags ?? []; item.category = metadata.structured_data?.category ?? ""
                item.summary = metadata.structured_data?.summary ?? ""; item.formattedContent = metadata.structured_data?.formattedContent ?? ""
                if let seenVal = metadata.structured_data?.seen { item.seen = seenVal }
            }
            item.noteContent = snapshot.item_notes?.deleted_at == nil ? snapshot.item_notes?.content : nil
            let activeMembership = snapshot.collection_items?.first { $0.deleted_at == nil }
            item.collectionId = activeMembership?.collection_id
            item.collectionName = activeMembership?.collections?.name
            if let remoteAttachments = snapshot.attachments?.filter({ $0.deleted_at == nil }),
               let attachmentAPI = api as? LaterBoxAPIService {
                var localAttachments: [SharedAttachment] = []
                for attachment in remoteAttachments {
                    if var existing = try? JSONDecoder().decode([SharedAttachment].self, from: item.attachmentsData ?? Data()).first(where: { $0.id.caseInsensitiveCompare(attachment.id) == .orderedSame }),
                       (try? SharedCaptureStore.fileURL(existing)).map({ FileManager.default.fileExists(atPath: $0.path) }) == true {
                        existing.remoteObjectKey = attachment.r2_object_key
                        existing.byteSize = attachment.byte_size
                        existing.sha256 = attachment.sha256
                        existing.mimeType = attachment.mime_type
                        localAttachments.append(existing)
                    } else {
                        localAttachments.append(try await attachmentAPI.downloadAttachment(attachment, token: token))
                    }
                }
                if !localAttachments.isEmpty { item.attachmentsData = try? JSONEncoder().encode(localAttachments) }
            }
            if let collName = item.collectionName, !collName.isEmpty {
                _ = ensureCollectionExists(named: collName, context: context)
            }
            item.isSyncPending = false
            appliedCount += 1
        }
        LBItem.cleanupDuplicatesInStore(context: context)
        try context.save()
        return appliedCount
    }

    @discardableResult
    func performCloudPush(context: ModelContext, transport: (any IOSCloudTransport)? = nil, deletionsOnly: Bool = false) async throws -> Int {
        guard hasCloudPro || !cloudDeletionQueue.isEmpty else { return 0 }
        guard isAuthenticated, let uid = currentUserId, var token = authToken else {
            throw CloudSyncError.unauthenticated
        }
        let api: any IOSCloudTransport = transport ?? LaterBoxAPIService.shared
        var pushedCount = 0

        func executeWithRetry<T>(_ block: (String) async throws -> T) async throws -> T {
            do {
                return try await block(token)
            } catch let err as CloudSyncError {
                if case .unauthorized = err, await refreshAuthSession(), let refreshedToken = authToken {
                    token = refreshedToken
                    return try await block(refreshedToken)
                }
                throw err
            }
        }

        for id in cloudDeletionQueue {
            guard currentUserId == uid, authToken == token else { return pushedCount }
            _ = try await executeWithRetry { curToken in
                if let attachmentAPI = api as? LaterBoxAPIService {
                    try await attachmentAPI.permanentlyDeleteCloudItem(itemID: id, token: curToken)
                    return Data()
                }
                return try await api.cloudRequest("items?id=eq.\(id)&user_id=eq.\(uid)", token: curToken, method: "DELETE", body: nil)
            }
            cloudDeletionQueue.removeAll { $0 == id }
            pushedCount += 1
        }

        guard hasCloudPro && !deletionsOnly else { return pushedCount }

        let pending = try context.fetch(FetchDescriptor<LBItem>())
            .filter { $0.isSyncPending && ($0.userId == nil || $0.userId == uid) }

        for item in pending {
            guard currentUserId == uid, authToken == token else { return pushedCount }
            var knownAssets = try item.attachmentsData.map { try JSONDecoder().decode([SharedAttachment].self, from: $0) } ?? []
            let isFileCapture = ["image", "file", "document"].contains(item.type) && item.url == nil
            if item.status != "deleted", let attachmentAPI = api as? LaterBoxAPIService,
               (isFileCapture && knownAssets.isEmpty) || knownAssets.contains(where: { $0.remoteObjectKey == nil || $0.sha256 == nil || $0.mimeType == nil }) {
                let remoteAssets = try await executeWithRetry { curToken in
                    try await attachmentAPI.remoteAttachments(itemID: item.id, userID: uid, token: curToken)
                }
                for remote in remoteAssets where remote.r2_object_key != nil {
                    if let index = knownAssets.firstIndex(where: { $0.id.caseInsensitiveCompare(remote.id) == .orderedSame }) {
                        knownAssets[index].remoteObjectKey = remote.r2_object_key
                        knownAssets[index].byteSize = remote.byte_size
                        knownAssets[index].sha256 = remote.sha256
                        knownAssets[index].mimeType = remote.mime_type
                    } else {
                        let name = URL(fileURLWithPath: remote.original_file_name).lastPathComponent
                        knownAssets.append(SharedAttachment(id: remote.id, name: name,
                            relativePath: "Attachments/\(remote.id)/\(name)",
                            typeIdentifier: UTType(mimeType: remote.mime_type)?.identifier ?? remote.mime_type,
                            remoteObjectKey: remote.r2_object_key, byteSize: remote.byte_size,
                            sha256: remote.sha256, mimeType: remote.mime_type))
                    }
                }
                if !knownAssets.isEmpty {
                    item.attachmentsData = try JSONEncoder().encode(knownAssets)
                    try context.save()
                }
            }
            if ["image", "file", "document"].contains(item.type), item.url == nil, item.status != "deleted" {
                let assets = try item.attachmentsData.map { try JSONDecoder().decode([SharedAttachment].self, from: $0) } ?? []
                guard !assets.isEmpty else {
                    throw CloudSyncError.other("The file for ‘\(item.title)’ is missing. Share it again to upload the attachment. This item has not been synced.")
                }
            }
            let revision = item.updatedAt
            let stamp = revision.ISO8601Format()
            let null = NSNull()
            let body: [String: Any] = ["id": item.id, "user_id": uid, "title": item.title, "url": item.url as Any? ?? null,
                "text_content": item.textContent as Any? ?? null, "text_selector": item.textSelector as Any? ?? null,
                "type": item.type, "favorite": item.favorite,
                "status": item.status, "return_at": item.returnAt?.ISO8601Format() as Any? ?? null,
                "inbox_entered_at": item.inboxEnteredAt?.ISO8601Format() as Any? ?? null,
                "created_at": item.createdAt.ISO8601Format(), "updated_at": stamp, "deleted_at": item.status == "deleted" ? stamp as Any : null]
            let metadata: [String: Any] = ["item_id": item.id, "user_id": uid, "domain": item.domain as Any? ?? null,
                "site_name": item.siteName as Any? ?? null, "description": item.metadataDescription as Any? ?? null,
                "favicon_url": item.faviconUrl as Any? ?? null, "preview_image_url": item.previewImageUrl as Any? ?? null,
                "status": item.enrichmentStatus, "content_type": item.type, "updated_at": stamp,
                "structured_data": ["tags": item.tags, "category": item.category, "summary": item.summary, "formattedContent": item.formattedContent, "seen": item.seen]]
            let note: [String: Any] = ["item_id": item.id, "user_id": uid, "content": item.noteContent ?? "", "updated_at": stamp, "deleted_at": item.noteContent == nil ? stamp as Any : null]
            var collection: [String: Any]?
            if let name = item.collectionName, !name.isEmpty {
                if item.collectionId == nil {
                    let existingColls = (try? context.fetch(FetchDescriptor<LBCollection>())) ?? []
                    if let found = existingColls.first(where: { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }) {
                        item.collectionId = found.id
                    } else {
                        item.collectionId = UUID().uuidString
                    }
                }
                collection = ["id": item.collectionId!, "user_id": uid, "name": name, "created_at": item.createdAt.ISO8601Format(), "updated_at": stamp]
            }
            if let attachmentData = item.attachmentsData {
                let attachments = try JSONDecoder().decode([SharedAttachment].self, from: attachmentData)
                if !attachments.isEmpty {
                guard let attachmentAPI = api as? LaterBoxAPIService else {
                    throw CloudSyncError.other("This sync connection cannot upload attachments")
                }
                let uploaded = try await executeWithRetry { curToken in
                    try await attachmentAPI.uploadAttachments(attachments, itemID: item.id, userID: uid, token: curToken)
                }
                try await executeWithRetry { curToken in
                    try await attachmentAPI.publishItemWithAttachments(body, attachments: uploaded, userID: uid, token: curToken)
                }
                item.attachmentsData = try JSONEncoder().encode(uploaded)
                try context.save()
                }
            }
            try await executeWithRetry { curToken in
                try await api.uploadSnapshot(body, metadata: metadata, note: note, collection: collection, token: curToken)
            }
            guard currentUserId == uid, authToken == token else { return pushedCount }
            item.userId = uid
            if item.updatedAt == revision { item.isSyncPending = false }
            pushedCount += 1
            try context.save()
        }
        return pushedCount
    }

    func performCloudSync(context: ModelContext, transport: (any IOSCloudTransport)? = nil) async throws {
        if !cloudDeletionQueue.isEmpty {
            _ = try await performCloudPush(context: context, transport: transport, deletionsOnly: true)
        }
        _ = try await performCloudPull(context: context, transport: transport)
        _ = try await performCloudPush(context: context, transport: transport)
    }

    /// Resolves local unassigned items on login (merge or discard), downloads cross-platform items from cloud,
    /// refreshes collections and catalog, and updates return notifications.
    func resolveLoginData(
        merge: Bool,
        email: String,
        userId: String,
        token: String,
        refreshToken: String? = nil,
        context: ModelContext,
        transport: (any IOSCloudTransport)? = nil
    ) async throws {
        self.setSession(email: email, userId: userId, token: token, refreshToken: refreshToken)
        self.syncState = .syncing

        // 1. Resolve local items
        let localItems = (try? context.fetch(FetchDescriptor<LBItem>())) ?? []
        let localCollections = (try? context.fetch(FetchDescriptor<LBCollection>())) ?? []

        if merge {
            // Associate guest/unassigned items with the user account and mark for cloud upload
            for item in localItems where item.userId == nil || item.userId != userId {
                item.userId = userId
                item.isSyncPending = true
            }
            for coll in localCollections where coll.userId == nil || coll.userId != userId {
                coll.userId = userId
            }
        } else {
            // Discard local items that were created as guest/unassigned
            for item in localItems where item.userId == nil || item.userId != userId {
                context.delete(item)
            }
            for coll in localCollections where coll.userId == nil || coll.userId != userId {
                context.delete(coll)
            }
        }
        try? context.save()

        // 2. Fetch cross-platform remote items
        let api: any IOSCloudTransport = transport ?? LaterBoxAPIService.shared
        do {
            let remote = try await api.downloadSnapshots(userID: userId, token: token)
            let updatedLocal = (try? context.fetch(FetchDescriptor<LBItem>())) ?? []
            var byID: [String: LBItem] = [:]
            var byURL: [String: LBItem] = [:]
            for loc in updatedLocal {
                byID[loc.id] = loc
                if let norm = LBItem.normalizeURL(loc.url) {
                    if let existing = byURL[norm] {
                        if !loc.isSyncPending && existing.isSyncPending {
                            byURL[norm] = loc
                        }
                    } else {
                        byURL[norm] = loc
                    }
                }
            }

            for snapshot in remote {
                if snapshot.permanently_deleted == true {
                    for item in updatedLocal where item.id.caseInsensitiveCompare(snapshot.id) == .orderedSame {
                        context.delete(item)
                    }
                    continue
                }
                let date = snapshot.updated_at.flatMap(Self.cloudDate) ?? .distantPast
                let item: LBItem
                let normSnapUrl = LBItem.normalizeURL(snapshot.url)
                let existingMatch = byID[snapshot.id] ?? (normSnapUrl.flatMap { byURL[$0] })

                if let existing = existingMatch {
                    let isIdChange = (existing.id != snapshot.id)

                    if existing.updatedAt > date { continue }
                    if existing.updatedAt == date {
                        if existing.status == "deleted" && snapshot.deleted_at == nil { continue }
                        if (existing.status == "deleted") == (snapshot.deleted_at != nil) {
                            existing.isSyncPending = false
                            continue
                        }
                    }

                    if isIdChange {
                        let noteToKeep = existing.noteContent
                        let tagsToKeep = existing.tags
                        let collIdToKeep = existing.collectionId
                        let collNameToKeep = existing.collectionName
                        context.delete(existing)
                        if let direct = byID[snapshot.id] {
                            context.delete(direct)
                        }
                        item = LBItem(id: snapshot.id, title: snapshot.title ?? snapshot.url ?? "Untitled")
                        item.noteContent = noteToKeep
                        item.tags = tagsToKeep
                        item.collectionId = collIdToKeep
                        item.collectionName = collNameToKeep
                        context.insert(item)
                    } else {
                        item = existing
                    }
                    byID[snapshot.id] = item
                    if let norm = normSnapUrl { byURL[norm] = item }
                } else {
                    if snapshot.deleted_at != nil || cloudDeletionQueue.contains(where: { $0.caseInsensitiveCompare(snapshot.id) == .orderedSame }) {
                        continue
                    }
                    item = LBItem(id: snapshot.id, title: snapshot.title ?? snapshot.url ?? "Untitled")
                    context.insert(item)
                    byID[snapshot.id] = item
                    if let norm = normSnapUrl { byURL[norm] = item }
                }
                item.userId = userId
                item.title = snapshot.title ?? snapshot.url ?? "Untitled"
                item.url = snapshot.url
                item.textContent = snapshot.text_content
                item.textSelector = snapshot.text_selector
                item.type = snapshot.type ?? "link"
                item.favorite = snapshot.favorite ?? false
                let priorInboxEntry = existingMatch?.status == "inbox" ? existingMatch?.inboxEnteredAt : nil
                item.status = snapshot.deleted_at == nil ? (snapshot.status ?? "inbox") : "deleted"
                item.returnAt = snapshot.return_at.flatMap(Self.cloudDate)
                item.inboxEnteredAt = snapshot.inbox_entered_at.flatMap(Self.cloudDate)
                    ?? (item.status == "inbox" ? priorInboxEntry : nil)
                item.createdAt = snapshot.created_at.flatMap(Self.cloudDate) ?? date
                item.updatedAt = date

                if let metadata = snapshot.item_metadata {
                    item.domain = metadata.domain
                    item.siteName = metadata.site_name
                    item.metadataDescription = metadata.description
                    item.faviconUrl = metadata.favicon_url
                    item.previewImageUrl = metadata.preview_image_url
                    item.enrichmentStatus = metadata.status
                    item.tags = metadata.structured_data?.tags ?? []
                    item.category = metadata.structured_data?.category ?? ""
                    item.summary = metadata.structured_data?.summary ?? ""
                    item.formattedContent = metadata.structured_data?.formattedContent ?? ""
                    if let seenVal = metadata.structured_data?.seen { item.seen = seenVal }
                }
                item.noteContent = snapshot.item_notes?.deleted_at == nil ? snapshot.item_notes?.content : nil

                // Auto-create and refresh collection catalog
                let activeMembership = snapshot.collection_items?.first { $0.deleted_at == nil }
                let rawCollName = activeMembership?.collections?.name ?? (item.category.isEmpty ? nil : item.category)
                if let name = rawCollName, !name.isEmpty {
                    if let coll = ensureCollectionExists(named: name, context: context) {
                        item.collectionId = coll.id
                        item.collectionName = coll.name
                        if item.category.isEmpty { item.category = coll.name }
                    }
                }
                item.isSyncPending = false

                // Re-register return notification if scheduled in the future
                if let returnDate = item.returnAt, returnDate > Date() {
                    _ = try? await ReturnNotification.update(id: item.id, title: item.title, description: item.notificationDescription, date: returnDate)
                }
            }
            LBItem.cleanupDuplicatesInStore(context: context)
            try context.save()
        } catch {
            // Remote fetch might fail if offline; local resolution remains saved
        }

        // 3. Upload pending items if user chose to merge local data
        await refreshEntitlement()
        if merge {
            try? await performCloudSync(context: context, transport: transport)
        }

        self.lastSyncedAt = Date()
        self.syncState = .synced
        self.catalogUpdateTrigger = UUID()
    }

    static func cloudDate(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: value) ?? ISO8601DateFormatter().date(from: value)
    }
}
