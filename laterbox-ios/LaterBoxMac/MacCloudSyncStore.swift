// laterbox-ios/LaterBoxMac/MacCloudSyncStore.swift
import Foundation
import SwiftUI
import Security
import CryptoKit
import UniformTypeIdentifiers

struct MacCloudItem: Decodable, Identifiable {
    let id: String
    let title: String?
    let url: String?
    let text_content: String?
    let type: String?
    let status: String?
    let favorite: Bool?
    let return_at: String?
    let created_at: String?
    let inbox_entered_at: String?
    let deleted_at: String?
}

struct MacChecklistEntry: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var done: Bool
}

private struct MacInboxMetadata: Decodable {
    let item_id: String
    let description: String?
    let preview_image_url: String?
    let content_type: String?
    let structured_data: String?
}

struct MacCollection: Decodable, Identifiable, Hashable {
    let id: String
    var name: String
    var created_at: String?
}

struct MacCollectionMembership: Decodable {
    let collection_id: String
    let item_id: String
}

struct MacCloudAttachment: Decodable, Identifiable {
    let id: String
    let original_file_name: String
    let mime_type: String
    let byte_size: Int64
}

struct MacCloudDraft {
    let id: String
    let kind: String
    let title: String
    let content: String
    let tags: [String]
    let returnDate: Date?
    let isSomeday: Bool
    let checklist: [String]
    let collectionIDs: [String]
    let newCollections: [String]
    let preview: MacLinkPreview?
    let linkDescription: String
    let files: [URL]
}

enum MacCloudError: LocalizedError {
    case notSignedIn
    case unauthorized
    case server(Int, String)
    case unsupportedFiles

    var errorDescription: String? {
        switch self {
        case .notSignedIn: "Please sign in to save and sync."
        case .unauthorized: "Your session has expired. Sign in again to continue."
        case let .server(status, message): "Sync failed (\(status)): \(message)"
        case .unsupportedFiles: "File uploads aren't connected on Mac yet. Text, links and tasks can be saved now."
        }
    }
}

@MainActor
final class MacCloudSyncStore: ObservableObject {
    @Published private(set) var items: [MacInboxEntry] = []
    @Published private(set) var activeItems: [MacInboxEntry] = []
    @Published private(set) var allItems: [MacInboxEntry] = []
    @Published private(set) var deletedItems: [MacInboxEntry] = []
    @Published private(set) var collections: [MacCollection] = []
    @Published private(set) var collectionMemberships: [MacCollectionMembership] = []
    @Published private(set) var loading = false
    @Published private(set) var saving = false
    @Published private(set) var lastError: String?
    @Published private(set) var lastSynced: Date?
    @Published private(set) var lastPushed: Date?
    @Published private(set) var isConnected = false
    private var refreshInFlight = false
    private var authRenewal: Task<Void, Error>?
    private var attachmentIDs: [String: String] = [:]
    private var attemptedPreviewURLs = Set<String>()
    private var recoveredPreviewURLs: [String: URL] = [:]

    private let endpoint = URL(string: "https://ltjisrgldssqskcylcbj.supabase.co/rest/v1/")!
    private let authEndpoint = URL(string: "https://ltjisrgldssqskcylcbj.supabase.co/auth/v1/token?grant_type=refresh_token")!
    private let apiKey = "sb_publishable_Rc4e_ik2LE4SR0UrfX-OEQ_5Mu_lw9p"

    private struct AuthTokens {
        let access: String
        let refresh: String
        let userID: String
    }

    private var keychainQuery: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrAccount as String: "laterbox-macos-session"]
    }

    private func jwtUserID(_ token: String) -> String? {
        let pieces = token.split(separator: ".")
        guard pieces.count == 3 else { return nil }
        var payload = String(pieces[1]).replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        payload += String(repeating: "=", count: (4 - payload.count % 4) % 4)
        guard let data = Data(base64Encoded: payload),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return json["sub"] as? String
    }

    private func readAuth() throws -> AuthTokens {
        var query = keychainQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let fields = try? JSONDecoder().decode([String: String].self, from: data),
              let access = fields["access_token"], !access.isEmpty,
              let id = jwtUserID(access) else { throw MacCloudError.notSignedIn }
        return AuthTokens(access: access, refresh: fields["refresh_token"] ?? "", userID: id)
    }

    private func renewAuth() async throws {
        if let renewal = authRenewal {
            try await renewal.value
            return
        }
        let renewal = Task { try await performAuthRenewal() }
        authRenewal = renewal
        defer { authRenewal = nil }
        try await renewal.value
    }

    private func performAuthRenewal() async throws {
        let old = try readAuth()
        guard !old.refresh.isEmpty else { throw MacCloudError.unauthorized }
        var request = URLRequest(url: authEndpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["refresh_token": old.refresh])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
              let values = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let access = values["access_token"] as? String,
              let refresh = values["refresh_token"] as? String else {
            throw MacCloudError.unauthorized
        }
        // A concurrently refreshed session must never be overwritten with
        // refresh tokens from an older request.
        let current = try readAuth()
        guard current.refresh == old.refresh else { return }
        let encoded = try JSONEncoder().encode(["access_token": access, "refresh_token": refresh])
        let status = SecItemUpdate(keychainQuery as CFDictionary, [kSecValueData as String: encoded] as CFDictionary)
        guard status == errSecSuccess else { throw MacCloudError.notSignedIn }
    }

    private func request(_ tableAndQuery: String, method: String = "GET",
                         body: Any? = nil, preferRepresentation: Bool = false) async throws -> Data {
        for attempt in 0...1 {
            let credentials = try readAuth()
            guard let suffix = tableAndQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: suffix, relativeTo: endpoint) else { throw URLError(.badURL) }
            var req = URLRequest(url: url)
            req.httpMethod = method
            req.timeoutInterval = 20
            req.setValue(apiKey, forHTTPHeaderField: "apikey")
            req.setValue("Bearer \(credentials.access)", forHTTPHeaderField: "Authorization")
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if method != "GET" {
                let resolution = method == "POST" ? "resolution=merge-duplicates," : ""
                req.setValue(resolution + (preferRepresentation ? "return=representation" : "return=minimal"), forHTTPHeaderField: "Prefer")
            }
            if let body { req.httpBody = try JSONSerialization.data(withJSONObject: body) }
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
            if http.statusCode == 401 && attempt == 0 {
                if (try? readAuth().access) == credentials.access {
                    try await renewAuth()
                }
                continue
            }
            guard (200..<300).contains(http.statusCode) else {
                let raw = String(data: data, encoding: .utf8) ?? "Unexpected server response"
                throw MacCloudError.server(http.statusCode, String(raw.prefix(220)))
            }
            return data
        }
        throw MacCloudError.unauthorized
    }

    /// Earn must use the same authenticated server endpoints as Web. All
    /// money, referral status and payout eligibility are computed server-side.
    func earnAPI(_ path: String = "", method: String = "GET", body: [String: Any]? = nil) async throws -> Data {
        guard ["", "/code"].contains(path) else { throw URLError(.badURL) }
        for attempt in 0...1 {
            let credentials = try readAuth()
            guard let url = URL(string: "https://laterbox.dev/api/earn" + path) else { throw URLError(.badURL) }
            var request = URLRequest(url: url)
            request.httpMethod = method
            request.timeoutInterval = 25
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.setValue("Bearer \(credentials.access)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
            if let body { request.httpBody = try JSONSerialization.data(withJSONObject: body) }
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
            if http.statusCode == 401 && attempt == 0 {
                if (try? readAuth().access) == credentials.access { try await renewAuth() }
                continue
            }
            guard (200..<300).contains(http.statusCode) else {
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                let message = json?["error"] as? String ?? "Earn is temporarily unavailable."
                throw MacCloudError.server(http.statusCode, message)
            }
            return data
        }
        throw MacCloudError.unauthorized
    }

    /// Same support route used by Web. The authenticated session binds tickets
    /// to the current account and server-side rate limits remain authoritative.
    func supportAPI(method: String = "GET", body: [String: Any]? = nil) async throws -> Data {
        guard method == "GET" || method == "POST" else { throw URLError(.unsupportedURL) }
        for attempt in 0...1 {
            let credentials = try readAuth()
            var request = URLRequest(url: URL(string: "https://laterbox.dev/api/support")!)
            request.httpMethod = method
            request.timeoutInterval = 25
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.setValue("Bearer \(credentials.access)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
            if let body { request.httpBody = try JSONSerialization.data(withJSONObject: body) }
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
            if http.statusCode == 401 && attempt == 0 {
                if (try? readAuth().access) == credentials.access { try await renewAuth() }
                continue
            }
            guard (200..<300).contains(http.statusCode) else {
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                throw MacCloudError.server(http.statusCode,
                    json?["error"] as? String ?? "Support is temporarily unavailable.")
            }
            return data
        }
        throw MacCloudError.unauthorized
    }

    /// Billing data and management URLs are server-authorized; no client-side
    /// payment credentials or plan prices are trusted.
    func billingAPI(_ path: String, method: String = "GET", body: [String: Any]? = nil) async throws -> Data {
        guard ["/entitlement", "/portal"].contains(path),
              (path == "/entitlement" ? method == "GET" : method == "POST") else {
            throw URLError(.unsupportedURL)
        }
        for attempt in 0...1 {
            let credentials = try readAuth()
            var request = URLRequest(url: URL(string: "https://laterbox.dev/api/billing" + path)!)
            request.httpMethod = method
            request.timeoutInterval = 25
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.setValue("Bearer \(credentials.access)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
            if let body { request.httpBody = try JSONSerialization.data(withJSONObject: body) }
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
            if http.statusCode == 401 && attempt == 0 {
                if (try? readAuth().access) == credentials.access { try await renewAuth() }
                continue
            }
            guard (200..<300).contains(http.statusCode) else {
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                throw MacCloudError.server(http.statusCode,
                    json?["error"] as? String ?? "Billing is temporarily unavailable.")
            }
            return data
        }
        throw MacCloudError.unauthorized
    }

    func setStarred(_ id: String, starred: Bool) async throws {
        _ = try await request("items?id=eq.\(id)", method: "PATCH",
                              body: ["favorite": starred, "updated_at": ISO8601DateFormatter().string(from: Date())])
        lastPushed = Date()
        await refresh()
    }

    func archive(_ id: String) async throws {
        _ = try await request("items?id=eq.\(id)", method: "PATCH",
                              body: ["status": "archived", "updated_at": ISO8601DateFormatter().string(from: Date())])
        lastPushed = Date()
        await refresh()
    }

    func delete(_ id: String) async throws {
        let now = ISO8601DateFormatter().string(from: Date())
        _ = try await request("items?id=eq.\(id)", method: "PATCH",
                              body: ["deleted_at": now, "updated_at": now])
        lastPushed = Date()
        await refresh()
    }

    func restoreToInbox(_ id: String) async throws {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        _ = try await request("items?id=eq.\(id)", method: "PATCH",
                              body: ["status": "inbox", "return_at": NSNull(), "deleted_at": NSNull(),
                                     "inbox_entered_at": timestamp, "seen": false,
                                     "updated_at": timestamp])
        // Match Web's Inbox transition: restore a task group's unchecked state.
        if let existing = (allItems + deletedItems).first(where: { $0.id == id }),
           existing.itemType == "task", !existing.checklist.isEmpty {
            let data = try await request("item_metadata?select=structured_data&item_id=eq.\(id)&limit=1")
            let records = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] ?? []
            let raw = records.first?["structured_data"] as? String
            var structured = raw?.data(using: .utf8)
                .flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] } ?? [:]
            structured["taskChecklist"] = existing.checklist.map {
                ["id": $0.id, "title": $0.title, "done": false] as [String: Any]
            }
            structured["seen"] = false
            let encoded = String(data: try JSONSerialization.data(withJSONObject: structured), encoding: .utf8) ?? "{}"
            _ = try await request("item_metadata?item_id=eq.\(id)", method: "PATCH",
                                  body: ["structured_data": encoded, "updated_at": timestamp])
        }
        lastPushed = Date()
        await refresh()
    }

    /// Uses the same cloud cleanup endpoint as Web hard deletion. Never remove
    /// a deleted row locally unless the server confirms the irreversible action.
    func permanentlyDelete(_ id: String) async throws {
        guard deletedItems.contains(where: { $0.id == id }) else {
            throw MacCloudError.server(409, "This item is not in Recently Deleted.")
        }
        let result = try await attachmentAction(["action": "delete-item", "itemId": id])
        guard result["deleted"] as? Bool == true else {
            throw MacCloudError.server(502, "Cloud cleanup was not confirmed. Please retry.")
        }
        lastPushed = Date()
        deletedItems.removeAll { $0.id == id }
        await refresh()
    }

    func emptyTrash() async throws {
        for id in deletedItems.map(\.id) {
            try await permanentlyDelete(id)
        }
    }

    func keep(_ id: String) async throws {
        _ = try await request("items?id=eq.\(id)", method: "PATCH",
                              body: ["status": "saved", "updated_at": ISO8601DateFormatter().string(from: Date())])
        lastPushed = Date()
        await refresh()
    }

    func reschedule(_ id: String, date: Date?) async throws {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        _ = try await request("items?id=eq.\(id)", method: "PATCH",
                              body: ["return_at": date.map { ISO8601DateFormatter().string(from: $0) } as Any? ?? NSNull(),
                                     "status": "deferred", "updated_at": timestamp])
        lastPushed = Date()
        await refresh()
    }

    func updateChecklist(_ id: String, entries: [MacChecklistEntry]) async throws {
        let data = try await request("item_metadata?select=structured_data&item_id=eq.\(id)&limit=1")
        let rows = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] ?? []
        let old = rows.first?["structured_data"] as? String
        var structured = old?.data(using: .utf8)
            .flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] } ?? [:]
        structured["taskChecklist"] = entries.map {
            ["id": $0.id, "title": $0.title, "done": $0.done] as [String: Any]
        }
        let encoded = String(data: try JSONSerialization.data(withJSONObject: structured), encoding: .utf8) ?? "{}"
        _ = try await request("item_metadata?item_id=eq.\(id)", method: "PATCH",
                              body: ["structured_data": encoded,
                                     "updated_at": ISO8601DateFormatter().string(from: Date())])
        lastPushed = Date()
        await refresh()
    }

    private func isoDate(_ value: String?) -> Date? {
        guard let value else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: value) ?? ISO8601DateFormatter().date(from: value)
    }

    func refresh() async {
        guard !refreshInFlight else { return }
        refreshInFlight = true
        loading = true
        defer { refreshInFlight = false; loading = false }
        do {
            let credentials = try readAuth()
            // RLS is still enforced. User ID filters scope the request and
            // avoid accidental cross-account UI display.
            let data = try await request("items?select=id,title,url,text_content,type,status,favorite,return_at,created_at,inbox_entered_at,deleted_at&user_id=eq.\(credentials.userID)&order=created_at.desc&limit=500")
            let rows = try JSONDecoder().decode([MacCloudItem].self, from: data)
            var metadataByItem: [String: MacInboxMetadata] = [:]
            if let data = try? await request("item_metadata?select=item_id,description,preview_image_url,content_type,structured_data&user_id=eq.\(credentials.userID)&limit=500"),
               let metadata = try? JSONDecoder().decode([MacInboxMetadata].self, from: data) {
                metadataByItem = Dictionary(metadata.map { ($0.item_id, $0) }, uniquingKeysWith: { first, _ in first })
            }
            // Fetch collection names and membership separately: this also
            // exposes empty collections, which an item-only join would miss.
            let collectionData = try await request("collections?select=id,name,created_at&user_id=eq.\(credentials.userID)&deleted_at=is.null&order=created_at.asc&limit=500")
            let membershipData = try await request("collection_items?select=collection_id,item_id&user_id=eq.\(credentials.userID)&deleted_at=is.null&limit=5000")
            let incomingCollections = try JSONDecoder().decode([MacCollection].self, from: collectionData)
            let incomingMemberships = try JSONDecoder().decode([MacCollectionMembership].self, from: membershipData)
            // Defensive client reconciliation for older synced accounts. The
            // database also enforces active-name uniqueness after migration.
            var uniqueCollections: [MacCollection] = []
            var firstIDByName: [String: String] = [:]
            var canonicalIDByID: [String: String] = [:]
            for collection in incomingCollections {
                let key = collection.name.trimmingCharacters(in: .whitespacesAndNewlines)
                    .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                if let existing = firstIDByName[key] {
                    canonicalIDByID[collection.id] = existing
                } else {
                    firstIDByName[key] = collection.id
                    canonicalIDByID[collection.id] = collection.id
                    uniqueCollections.append(collection)
                }
            }
            var uniqueMemberships: [MacCollectionMembership] = []
            var seenMemberships = Set<String>()
            for membership in incomingMemberships {
                guard let canonical = canonicalIDByID[membership.collection_id] else { continue }
                let key = "\(canonical):\(membership.item_id)"
                if seenMemberships.insert(key).inserted {
                    uniqueMemberships.append(MacCollectionMembership(collection_id: canonical, item_id: membership.item_id))
                }
            }
            collections = uniqueCollections
            collectionMemberships = uniqueMemberships
            let names = Dictionary(uniqueKeysWithValues: uniqueCollections.map { ($0.id, $0.name) })
            var collectionsByItem: [String: [String]] = [:]
            for membership in uniqueMemberships {
                if let name = names[membership.collection_id] {
                    collectionsByItem[membership.item_id, default: []].append(name)
                }
            }
            let now = Date()
            allItems = rows.compactMap { row in
                let schedule = isoDate(row.return_at)
                let status = row.status ?? ""
                guard row.deleted_at != nil || ["inbox", "deferred", "saved", "archived"].contains(status) else { return nil }
                let url = row.url.flatMap { URL(string: $0) }
                let metadata = metadataByItem[row.id]
                let type = (metadata?.content_type ?? row.type)?.lowercased() ?? ""
                let category: MacInboxEntry.Category
                if type == "video" || url?.host?.contains("youtube") == true || url?.host?.contains("spotify") == true {
                    category = .media
                } else if type == "note" || type == "task" || type == "text" || url == nil {
                    category = .update
                } else {
                    category = .article
                }
                let title = row.title?.isEmpty == false ? row.title! : (url?.host ?? "Untitled item")
                let youtubeID: String? = {
                    guard let url, let host = url.host?.lowercased() else { return nil }
                    if host == "youtu.be" { return url.pathComponents.dropFirst().first }
                    if host == "youtube.com" || host.hasSuffix(".youtube.com") {
                        if url.path == "/watch" {
                            return URLComponents(url: url, resolvingAgainstBaseURL: false)?
                                .queryItems?.first(where: { $0.name == "v" })?.value
                        }
                        if url.path.hasPrefix("/shorts/") {
                            return url.pathComponents.dropFirst(2).first
                        }
                    }
                    return nil
                }()
                let videoImage = youtubeID.flatMap { id -> URL? in
                    guard id.range(of: "^[A-Za-z0-9_-]{11}$", options: .regularExpression) != nil else { return nil }
                    return URL(string: "https://i.ytimg.com/vi/\(id)/hqdefault.jpg")
                }
                let storedImage = metadata?.preview_image_url.flatMap { raw -> URL? in
                    guard let image = URL(string: raw, relativeTo: url)?.absoluteURL,
                          ["http", "https"].contains(image.scheme?.lowercased() ?? "") else { return nil }
                    return image
                }
                let image = storedImage ?? videoImage ?? url.flatMap { recoveredPreviewURLs[$0.absoluteString] }
                let structured = metadata?.structured_data.flatMap { $0.data(using: .utf8) }
                    .flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
                let tags = structured?["tags"] as? [String] ?? []
                let entries: [MacChecklistEntry] = (structured?["taskChecklist"] as? [[String: Any]] ?? []).compactMap { row in
                    guard let title = row["title"] as? String else { return nil }
                    return MacChecklistEntry(id: row["id"] as? String ?? UUID().uuidString, title: title, done: row["done"] as? Bool ?? false)
                }
                return MacInboxEntry(
                    id: row.id, source: url?.host?.replacingOccurrences(of: "www.", with: "") ?? (type == "task" ? "Task" : type == "file" ? "File" : "Note"),
                    title: title, snippet: metadata?.description?.isEmpty == false ? metadata!.description! : (row.text_content ?? row.url ?? ""), url: url,
                    previewImageURL: image,
                    date: isoDate(row.created_at) ?? now, category: category,
                    isStarred: row.favorite ?? false, isUnread: status == "inbox",
                    itemType: row.type ?? "link", returnDate: schedule, tags: tags,
                    checklist: entries, collectionNames: collectionsByItem[row.id] ?? [],
                    inboxArrival: status == "inbox" ? isoDate(row.inbox_entered_at) ?? isoDate(row.created_at) : schedule,
                    lifecycleStatus: row.deleted_at != nil ? "deleted" : status
                )
            }
            deletedItems = allItems.filter { $0.lifecycleStatus == "deleted" }
            allItems.removeAll { $0.lifecycleStatus == "deleted" }
            activeItems = allItems.filter { entry in
                entry.lifecycleStatus == "inbox" || entry.lifecycleStatus == "deferred"
            }
            items = activeItems.filter { entry in
                entry.isUnread || entry.returnDate.map { $0 <= now } == true
            }
            isConnected = true
            lastError = nil
            lastSynced = Date()
            schedulePreviewRecovery()
        } catch {
            // Keep last known rows during temporary outages.
            lastError = error.localizedDescription
        }
    }

    /// Fills missing previews in the background without delaying cloud sync.
    /// Each source URL is fetched only once during an app session.
    private func schedulePreviewRecovery() {
        let sources = allItems.compactMap { item -> URL? in
            guard item.previewImageURL == nil, let url = item.url,
                  ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
                  !attemptedPreviewURLs.contains(url.absoluteString) else { return nil }
            return url
        }
        let unique = Dictionary(sources.map { ($0.absoluteString, $0) }, uniquingKeysWith: { a, _ in a })
        guard !unique.isEmpty else { return }
        for source in unique.keys { attemptedPreviewURLs.insert(source) }

        let urls = Array(unique.values)
        Task { [weak self] in
            await withTaskGroup(of: (String, URL?).self) { group in
                var remaining = urls.makeIterator()
                for _ in 0..<min(4, urls.count) {
                    if let url = remaining.next() {
                        group.addTask {
                            (url.absoluteString, await MacCaptureSuggestions.recoverImage(for: url))
                        }
                    }
                }
                while let (source, image) = await group.next() {
                    guard let self, !Task.isCancelled else {
                        group.cancelAll()
                        break
                    }
                    if let image {
                        self.recoveredPreviewURLs[source] = image
                        self.applyRecoveredImage(image, source: source)
                    }
                    if let next = remaining.next() {
                        group.addTask {
                            (next.absoluteString, await MacCaptureSuggestions.recoverImage(for: next))
                        }
                    }
                }
            }
        }
    }

    private func applyRecoveredImage(_ image: URL, source: String) {
        func update(_ entries: inout [MacInboxEntry]) {
            for index in entries.indices {
                if entries[index].url?.absoluteString == source,
                   entries[index].previewImageURL == nil {
                    entries[index].previewImageURL = image
                }
            }
        }
        update(&allItems)
        update(&activeItems)
        update(&items)
    }

    func collectionItems(_ collectionID: String) -> [MacInboxEntry] {
        let ids = Set(collectionMemberships.filter { $0.collection_id == collectionID }.map(\.item_id))
        return allItems.filter { ids.contains($0.id) }.sorted { $0.date > $1.date }
    }

    func collectionCount(_ collectionID: String) -> Int {
        collectionItems(collectionID).count
    }

    func createCollection(_ name: String) async throws {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw MacCloudError.server(400, "Enter a collection name.") }
        guard !collections.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) else {
            throw MacCloudError.server(409, "A collection with that name already exists.")
        }
        let owner = try readAuth().userID
        let now = ISO8601DateFormatter().string(from: Date())
        _ = try await request("collections", method: "POST", body: [
            "id": UUID().uuidString, "user_id": owner, "name": name,
            "created_at": now, "updated_at": now
        ])
        lastPushed = Date()
        await refresh()
    }

    func renameCollection(_ id: String, name: String) async throws {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw MacCloudError.server(400, "Enter a collection name.") }
        guard !collections.contains(where: { $0.id != id && $0.name.caseInsensitiveCompare(name) == .orderedSame }) else {
            throw MacCloudError.server(409, "A collection with that name already exists.")
        }
        _ = try await request("collections?id=eq.\(id)", method: "PATCH", body: [
            "name": name, "updated_at": ISO8601DateFormatter().string(from: Date())
        ])
        lastPushed = Date()
        await refresh()
    }

    func deleteCollection(_ id: String) async throws {
        // Memberships are explicitly removed first; saved items remain intact.
        _ = try await request("collection_items?collection_id=eq.\(id)", method: "DELETE")
        _ = try await request("collections?id=eq.\(id)", method: "DELETE")
        lastPushed = Date()
        await refresh()
    }

    func setCollectionMembership(_ collectionID: String, itemID: String, included: Bool) async throws {
        if included {
            let owner = try readAuth().userID
            _ = try await request("collection_items?on_conflict=collection_id,item_id",
                method: "POST", body: [
                    "collection_id": collectionID, "item_id": itemID,
                    "user_id": owner,
                    "created_at": ISO8601DateFormatter().string(from: Date())
                ])
        } else {
            _ = try await request("collection_items?collection_id=eq.\(collectionID)&item_id=eq.\(itemID)",
                                  method: "DELETE")
        }
        lastPushed = Date()
        await refresh()
    }

    func attachments(for itemID: String) async throws -> [MacCloudAttachment] {
        let data = try await request("attachments?select=id,original_file_name,mime_type,byte_size&item_id=eq.\(itemID)&order=created_at.asc")
        return try JSONDecoder().decode([MacCloudAttachment].self, from: data)
    }

    func attachmentDownloadURL(_ id: String) async throws -> URL {
        let result = try await attachmentAction(["action": "prepare-download", "attachmentId": id])
        guard let raw = result["downloadUrl"] as? String,
              let url = URL(string: raw), url.scheme?.lowercased() == "https" else {
            throw MacCloudError.server(502, "Unable to open this attachment.")
        }
        return url
    }

    private func attachmentAction(_ body: [String: Any]) async throws -> [String: Any] {
        for attempt in 0...1 {
            let auth = try readAuth()
            let url = URL(string: "https://ltjisrgldssqskcylcbj.supabase.co/functions/v1/attachment-storage")!
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.timeoutInterval = 30
            req.setValue(apiKey, forHTTPHeaderField: "apikey")
            req.setValue("Bearer \(auth.access)", forHTTPHeaderField: "Authorization")
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
            if http.statusCode == 401 && attempt == 0 {
                if (try? readAuth().access) == auth.access {
                    try await renewAuth()
                }
                continue
            }
            guard (200..<300).contains(http.statusCode),
                  let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw MacCloudError.server(http.statusCode, String((String(data: data, encoding: .utf8) ?? "Attachment upload failed").prefix(200)))
            }
            return result
        }
        throw MacCloudError.unauthorized
    }

    private func uploadAttachment(_ file: URL, itemID: String, userID: String, timestamp: String) async throws {
        // The file is accessed only after the user explicitly chooses it from
        // NSOpenPanel. Keep the security scope open for the entire upload.
        let scoped = file.startAccessingSecurityScopedResource()
        defer { if scoped { file.stopAccessingSecurityScopedResource() } }
        let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
        guard let byteSize = (attributes[.size] as? NSNumber)?.int64Value,
              byteSize > 0, byteSize <= 100 * 1024 * 1024 else {
            throw MacCloudError.server(413, "Files must be between 1 byte and 100 MB.")
        }
        let ext = file.pathExtension.lowercased().isEmpty ? "bin" : file.pathExtension.lowercased()
        let mime = UTType(filenameExtension: ext)?.preferredMIMEType?.lowercased() ?? "application/octet-stream"

        // Stream the file when hashing: do not copy up to 100 MB into memory.
        let handle = try FileHandle(forReadingFrom: file)
        defer { try? handle.close() }
        var sha = SHA256()
        while let bytes = try handle.read(upToCount: 256 * 1024), !bytes.isEmpty {
            sha.update(data: bytes)
        }
        let checksum = sha.finalize().map { String(format: "%02x", $0) }.joined()
        let key = itemID + ":" + file.path
        let attachmentID = attachmentIDs[key] ?? UUID().uuidString
        attachmentIDs[key] = attachmentID

        let common: [String: Any] = [
            "attachmentId": attachmentID, "itemId": itemID,
            "originalFileName": file.lastPathComponent, "extension": ext,
            "mimeType": mime, "byteSize": byteSize, "sha256": checksum
        ]
        var prepare = common
        prepare["action"] = "prepare-upload"
        let prepared = try await attachmentAction(prepare)
        guard let signedString = prepared["uploadUrl"] as? String,
              let signedURL = URL(string: signedString) else {
            throw MacCloudError.server(502, "Unable to get a secure file upload URL.")
        }

        var upload = URLRequest(url: signedURL)
        upload.httpMethod = "PUT"
        upload.timeoutInterval = 180
        upload.setValue(mime, forHTTPHeaderField: "Content-Type")
        upload.setValue(checksum, forHTTPHeaderField: "x-amz-meta-sha256")
        upload.setValue(attachmentID, forHTTPHeaderField: "x-amz-meta-attachment-id")
        upload.setValue(userID, forHTTPHeaderField: "x-amz-meta-user-id")
        let (resultData, uploadResponse) = try await URLSession.shared.upload(for: upload, fromFile: file)
        guard let uploadHTTP = uploadResponse as? HTTPURLResponse,
              (200..<300).contains(uploadHTTP.statusCode) else {
            let message = String(data: resultData, encoding: .utf8) ?? "File upload failed"
            throw MacCloudError.server((uploadResponse as? HTTPURLResponse)?.statusCode ?? 502, String(message.prefix(180)))
        }

        var complete = common
        complete["action"] = "complete-upload"
        let completed = try await attachmentAction(complete)
        guard let objectKey = completed["objectKey"] as? String, !objectKey.isEmpty else {
            throw MacCloudError.server(502, "Cloud upload verification failed.")
        }
        let row: [String: Any] = [
            "id": attachmentID, "item_id": itemID, "user_id": userID,
            "original_file_name": file.lastPathComponent, "file_extension": ext,
            "mime_type": mime, "byte_size": byteSize, "sha256": checksum,
            "r2_object_key": objectKey,
            "created_at": timestamp, "updated_at": timestamp
        ]
        _ = try await request("attachments?on_conflict=id", method: "POST", body: [row])
    }

    func save(_ draft: MacCloudDraft) async throws {
        guard !saving else { return }
        saving = true
        defer { saving = false }
        let credentials = try readAuth()
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let url: String? = draft.kind == "Link" ? draft.content.trimmingCharacters(in: .whitespacesAndNewlines) : nil
        let text: String? = draft.kind == "Link" ? nil : draft.content
        let itemType = draft.kind.lowercased()
        let itemRow: [String: Any] = [
            "id": draft.id,
            "user_id": credentials.userID,
            "title": draft.title,
            "url": url as Any? ?? NSNull(),
            "text_content": text as Any? ?? NSNull(),
            "type": itemType,
            "favorite": false,
            "status": "deferred",
            "return_at": draft.returnDate.map { ISO8601DateFormatter().string(from: $0) } as Any? ?? NSNull(),
            "created_at": timestamp,
            "updated_at": timestamp
        ]
        // Stable UUID makes retries idempotent; an interrupted response cannot
        // create duplicate items.
        _ = try await request("items?on_conflict=id", method: "POST", body: [itemRow])
        for file in draft.files {
            try await uploadAttachment(file, itemID: draft.id, userID: credentials.userID, timestamp: timestamp)
        }
        var structured: [String: Any] = ["source": "macOS", "os": "macOS"]
        if !draft.tags.isEmpty { structured["tags"] = draft.tags }
        if let preview = draft.preview {
            structured["siteName"] = preview.siteName
            if let author = preview.author { structured["author"] = author }
        }
        if !draft.checklist.isEmpty {
            structured["taskChecklist"] = draft.checklist.map {
                ["id": UUID().uuidString, "title": $0, "done": false] as [String: Any]
            }
        }
        let metadata: [String: Any] = [
            "item_id": draft.id,
            "user_id": credentials.userID,
            "title": draft.title,
            "domain": url.flatMap { URL(string: $0)?.host } as Any? ?? NSNull(),
            "site_name": url.flatMap { URL(string: $0)?.host } as Any? ?? NSNull(),
            "description": draft.linkDescription.isEmpty ? (draft.preview?.description as Any? ?? NSNull()) : draft.linkDescription,
            "content_type": url == nil ? (itemType == "task" ? "note" : itemType) : (draft.preview?.contentType ?? "link"),
            "preview_image_url": draft.preview?.imageURL?.absoluteString as Any? ?? NSNull(),
            "favicon_url": url.flatMap { URL(string: $0)?.host }.map { "https://www.google.com/s2/favicons?domain=\($0)&sz=128" } as Any? ?? NSNull(),
            "classification_source": "macOS",
            "structured_data": String(data: try JSONSerialization.data(withJSONObject: structured), encoding: .utf8) ?? "{}",
            "status": draft.preview == nil ? "pending" : "enriched",
            "attempt_count": 0,
            "created_at": timestamp,
            "updated_at": timestamp
        ]
        _ = try await request("item_metadata?on_conflict=item_id", method: "POST", body: [metadata], preferRepresentation: false)

        var collections = draft.collectionIDs
        if !draft.newCollections.isEmpty {
            let existing = try await MacCollectionLookup.fetch()
            for name in draft.newCollections {
                if let found = existing.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
                    collections.append(found.id)
                } else {
                    let id = UUID().uuidString
                    let col: [String: Any] = ["id": id, "user_id": credentials.userID, "name": name,
                                              "created_at": timestamp, "updated_at": timestamp]
                    _ = try await request("collections", method: "POST", body: [col])
                    collections.append(id)
                }
            }
        }
        for collectionID in Set(collections) {
            let membership: [String: Any] = ["collection_id": collectionID, "item_id": draft.id,
                                             "user_id": credentials.userID,
                                             "created_at": timestamp, "updated_at": timestamp]
            _ = try await request("collection_items?on_conflict=collection_id,item_id", method: "POST", body: [membership])
        }
        lastPushed = Date()
        await refresh()
    }
}
