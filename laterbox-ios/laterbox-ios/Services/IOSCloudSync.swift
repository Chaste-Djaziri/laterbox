import Foundation
import SwiftData

struct CloudItemSnapshot: Codable {
    var id: String
    var user_id: String?
    var url: String?
    var title: String?
    var text_content: String?
    var type: String?
    var favorite: Bool?
    var status: String?
    var return_at: String?
    var created_at: String?
    var updated_at: String?
    var deleted_at: String?
    var item_metadata: CloudMetadata?
    var item_notes: CloudNote?
    var collection_items: [CloudMembership]?
}
struct CloudMembership: Codable { var collection_id: String; var collections: CloudCollection? }
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
            let data = try await cloudRequest("items?user_id=eq.\(userID)&select=*,item_metadata(*),item_notes(*),collection_items(collection_id,collections(id,name))&order=id.asc&limit=100&offset=\(offset)", token: token)
            do {
                let page = try JSONDecoder().decode([CloudItemSnapshot].self, from: data)
                result += page
                if page.count < 100 { break }
                offset += page.count
            } catch {
                throw CloudSyncError.decodingError(error.localizedDescription)
            }
        }
        return result
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
            _ = try await cloudRequest("collection_items?on_conflict=collection_id,item_id", token: token, method: "POST", body: ["collection_id": collection["id"]!, "item_id": body["id"]!, "created_at": body["created_at"]!])
        }
    }
}

@MainActor
extension SyncCoordinator {
    func performCloudSync(context: ModelContext, transport: (any IOSCloudTransport)? = nil) async throws {
        guard isProUser else { return }
        guard isAuthenticated, let uid = currentUserId, let token = authToken else {
            throw CloudSyncError.unauthenticated
        }
        let api: any IOSCloudTransport = transport ?? LaterBoxAPIService.shared
        for id in cloudDeletionQueue {
            guard currentUserId == uid, authToken == token else { return }
            _ = try await api.cloudRequest("items?id=eq.\(id)&user_id=eq.\(uid)", token: token, method: "DELETE", body: nil)
            cloudDeletionQueue.removeAll { $0 == id }
        }
        let remote = try await api.downloadSnapshots(userID: uid, token: token)
        guard currentUserId == uid, authToken == token else { return }
        let local = try context.fetch(FetchDescriptor<LBItem>())
        let byID = Dictionary(uniqueKeysWithValues: local.map { ($0.id, $0) })
        for snapshot in remote {
            let date = snapshot.updated_at.flatMap(Self.cloudDate) ?? .distantPast
            let item: LBItem
            if let existing = byID[snapshot.id] {
                if existing.updatedAt > date { continue }
                if existing.updatedAt == date {
                    // Tie-breaker matching Web's resolveActionConflict:
                    // If local is deleted and remote is not deleted, local wins (keep local deleted, upload)
                    if existing.status == "deleted" && snapshot.deleted_at == nil {
                        continue
                    }
                    // If both are active or both are deleted with identical timestamps, already in sync
                    if (existing.status == "deleted") == (snapshot.deleted_at != nil) {
                        continue
                    }
                    // Remote is deleted while local is active: remote delete wins
                }
                item = existing
            } else {
                item = LBItem(id: snapshot.id, title: snapshot.title ?? snapshot.url ?? "Untitled")
                context.insert(item)
            }
            item.userId = uid; item.title = snapshot.title ?? snapshot.url ?? "Untitled"; item.url = snapshot.url
            item.textContent = snapshot.text_content; item.type = snapshot.type ?? "link"; item.favorite = snapshot.favorite ?? false
            item.status = snapshot.deleted_at == nil ? (snapshot.status ?? "inbox") : "deleted"
            item.returnAt = snapshot.return_at.flatMap(Self.cloudDate)
            item.createdAt = snapshot.created_at.flatMap(Self.cloudDate) ?? date; item.updatedAt = date
            if let metadata = snapshot.item_metadata {
                item.domain = metadata.domain; item.siteName = metadata.site_name; item.metadataDescription = metadata.description
                item.faviconUrl = metadata.favicon_url; item.previewImageUrl = metadata.preview_image_url; item.enrichmentStatus = metadata.status
                item.tags = metadata.structured_data?.tags ?? []; item.category = metadata.structured_data?.category ?? ""
                item.summary = metadata.structured_data?.summary ?? ""; item.formattedContent = metadata.structured_data?.formattedContent ?? ""
                if let seenVal = metadata.structured_data?.seen { item.seen = seenVal }
            }
            item.noteContent = snapshot.item_notes?.deleted_at == nil ? snapshot.item_notes?.content : nil
            item.collectionId = snapshot.collection_items?.first?.collection_id
            item.collectionName = snapshot.collection_items?.first?.collections?.name
            item.isSyncPending = false
        }
        try context.save()
        for item in try context.fetch(FetchDescriptor<LBItem>()) where item.isSyncPending && (item.userId == nil || item.userId == uid) {
            guard currentUserId == uid, authToken == token else { return }
            let revision = item.updatedAt
            let stamp = revision.ISO8601Format()
            let null = NSNull()
            let body: [String: Any] = ["id": item.id, "user_id": uid, "title": item.title, "url": item.url as Any? ?? null,
                "text_content": item.textContent as Any? ?? null, "type": item.type, "favorite": item.favorite,
                "status": item.status, "return_at": item.returnAt?.ISO8601Format() as Any? ?? null,
                "created_at": item.createdAt.ISO8601Format(), "updated_at": stamp, "deleted_at": item.status == "deleted" ? stamp as Any : null]
            let metadata: [String: Any] = ["item_id": item.id, "user_id": uid, "domain": item.domain as Any? ?? null,
                "site_name": item.siteName as Any? ?? null, "description": item.metadataDescription as Any? ?? null,
                "favicon_url": item.faviconUrl as Any? ?? null, "preview_image_url": item.previewImageUrl as Any? ?? null,
                "status": item.enrichmentStatus, "content_type": item.type, "updated_at": stamp,
                "structured_data": ["tags": item.tags, "category": item.category, "summary": item.summary, "formattedContent": item.formattedContent, "seen": item.seen]]
            let note: [String: Any] = ["item_id": item.id, "user_id": uid, "content": item.noteContent ?? "", "updated_at": stamp, "deleted_at": item.noteContent == nil ? stamp as Any : null]
            var collection: [String: Any]?
            if let name = item.collectionName, !name.isEmpty {
                if item.collectionId == nil { item.collectionId = UUID().uuidString }
                collection = ["id": item.collectionId!, "user_id": uid, "name": name, "created_at": item.createdAt.ISO8601Format(), "updated_at": stamp]
            }
            try await api.uploadSnapshot(body, metadata: metadata, note: note, collection: collection, token: token)
            guard currentUserId == uid, authToken == token else { return }
            item.userId = uid
            if item.updatedAt == revision { item.isSyncPending = false }
            try context.save()
        }
    }

    /// Resolves local unassigned items on login (merge or discard), downloads cross-platform items from cloud,
    /// refreshes collections and catalog, and updates return notifications.
    func resolveLoginData(
        merge: Bool,
        email: String,
        userId: String,
        token: String,
        context: ModelContext,
        transport: (any IOSCloudTransport)? = nil
    ) async throws {
        self.setSession(email: email, userId: userId, token: token)
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
            let byID = Dictionary(uniqueKeysWithValues: updatedLocal.map { ($0.id, $0) })

            for snapshot in remote {
                let date = snapshot.updated_at.flatMap(Self.cloudDate) ?? .distantPast
                let item: LBItem
                if let existing = byID[snapshot.id] {
                    if existing.updatedAt > date { continue }
                    if existing.updatedAt == date {
                        if existing.status == "deleted" && snapshot.deleted_at == nil { continue }
                        if (existing.status == "deleted") == (snapshot.deleted_at != nil) { continue }
                    }
                    item = existing
                } else {
                    item = LBItem(id: snapshot.id, title: snapshot.title ?? snapshot.url ?? "Untitled")
                    context.insert(item)
                }
                item.userId = userId
                item.title = snapshot.title ?? snapshot.url ?? "Untitled"
                item.url = snapshot.url
                item.textContent = snapshot.text_content
                item.type = snapshot.type ?? "link"
                item.favorite = snapshot.favorite ?? false
                item.status = snapshot.deleted_at == nil ? (snapshot.status ?? "inbox") : "deleted"
                item.returnAt = snapshot.return_at.flatMap(Self.cloudDate)
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
                let rawCollName = snapshot.collection_items?.first?.collections?.name ?? (item.category.isEmpty ? nil : item.category)
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
