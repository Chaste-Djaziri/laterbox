import Foundation

struct PendingShareCapture: Codable {
    let id: String
    let value: String?
    let kind: String
    let source: String
    let createdAt: String
    let filePaths: [String]
    let returnAt: String?

    init(
        id: String,
        value: String?,
        kind: String,
        source: String,
        createdAt: String,
        filePaths: [String] = [],
        returnAt: String? = nil
    ) {
        self.id = id
        self.value = value
        self.kind = kind
        self.source = source
        self.createdAt = createdAt
        self.filePaths = filePaths
        self.returnAt = returnAt
    }

    private enum CodingKeys: String, CodingKey {
        case id, value, kind, source, createdAt, filePaths, returnAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        value = try container.decodeIfPresent(String.self, forKey: .value)
        kind = try container.decode(String.self, forKey: .kind)
        source = try container.decode(String.self, forKey: .source)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        filePaths = try container.decodeIfPresent([String].self, forKey: .filePaths) ?? []
        returnAt = try container.decodeIfPresent(String.self, forKey: .returnAt)
    }

    var toDictionary: [String: Any] {
        var dictionary: [String: Any] = [
            "id": id,
            "filePaths": filePaths,
            "createdAt": createdAt,
        ]
        if let value { dictionary["text"] = value }
        if let returnAt { dictionary["returnAt"] = returnAt }
        return dictionary
    }
}

enum ShareQueueError: LocalizedError {
    case appGroupUnavailable
    case encodeFailed
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .appGroupUnavailable:
            return "App Group container (group.pro.micorp.laterbox) is not available on this device. Please check App Group entitlements."
        case .encodeFailed:
            return "Failed to encode share item."
        case .writeFailed(let reason):
            return "Could not write to App Group storage: \(reason)"
        }
    }
}

final class ShareCaptureQueue {
    static let shareReceivedNotification = "pro.micorp.laterbox.share_received"

    private let appGroupId: String
    private let groupDefaults: UserDefaults?
    private let groupContainerURL: URL?
    private let fallbackContainerURL: URL
    private let key = "laterbox.pendingShareCaptures"

    var isAppGroupAvailable: Bool {
        return groupContainerURL != nil
    }

    init(appGroupId: String = "group.pro.micorp.laterbox") {
        self.appGroupId = appGroupId
        self.groupDefaults = UserDefaults(suiteName: appGroupId)

        let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupId
        )
        self.groupContainerURL = container

        if container == nil {
            NSLog("[LaterBox WARNING] App Group container for '\(appGroupId)' is nil. Verify entitlements and provisioning.")
        }

        // Fallback directory accessible in app sandbox
        if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            self.fallbackContainerURL = docs.appendingPathComponent("LaterBoxShare", isDirectory: true)
        } else if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            self.fallbackContainerURL = appSupport.appendingPathComponent("LaterBoxShare", isDirectory: true)
        } else if let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            self.fallbackContainerURL = caches.appendingPathComponent("LaterBoxShare", isDirectory: true)
        } else {
            self.fallbackContainerURL = FileManager.default.temporaryDirectory.appendingPathComponent("LaterBoxShare", isDirectory: true)
        }

        ensureDirectoryExists(at: fallbackContainerURL)
        if let groupContainerURL {
            ensureDirectoryExists(at: groupContainerURL)
        }
    }

    private func ensureDirectoryExists(at url: URL) {
        let attributes: [FileAttributeKey: Any] = [
            .protectionKey: FileProtectionType.completeUntilFirstUserAuthentication
        ]
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: attributes)
    }

    private var activeContainerURL: URL {
        return groupContainerURL ?? fallbackContainerURL
    }

    private var queueFileURLs: [URL] {
        var urls: [URL] = []
        if let group = groupContainerURL {
            urls.append(group.appendingPathComponent("pending-share-captures.json"))
        }
        urls.append(fallbackContainerURL.appendingPathComponent("pending-share-captures.json"))
        return urls
    }

    func stagingDirectory(for captureId: String) -> URL {
        let directory = activeContainerURL
            .appendingPathComponent("PendingAttachments", isDirectory: true)
            .appendingPathComponent(captureId, isDirectory: true)
        ensureDirectoryExists(at: directory)
        return directory
    }

    private func notifyShareReceived() {
        let notificationName = CFNotificationName(Self.shareReceivedNotification as CFString)
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            notificationName,
            nil,
            nil,
            true
        )
    }

    func enqueueResult(_ capture: PendingShareCapture) -> Result<Void, ShareQueueError> {
        var captures = readAll()
        if captures.contains(where: { $0.id == capture.id }) {
            return .success(())
        }
        captures.append(capture)

        guard let data = try? JSONEncoder().encode(captures) else {
            return .failure(.encodeFailed)
        }

        var sharedWriteSucceeded = false
        var fallbackWriteSucceeded = false
        var lastError: Error?

        // 1. Write to App Group file container (accessible cross-process)
        if let group = groupContainerURL {
            let fileURL = group.appendingPathComponent("pending-share-captures.json")
            let parentDir = fileURL.deletingLastPathComponent()
            ensureDirectoryExists(at: parentDir)
            do {
                try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
                sharedWriteSucceeded = true
            } catch {
                do {
                    try data.write(to: fileURL)
                    try? FileManager.default.setAttributes(
                        [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                        ofItemAtPath: fileURL.path
                    )
                    sharedWriteSucceeded = true
                } catch {
                    lastError = error
                    NSLog("[LaterBox] Could not write to group queue file: \(error)")
                }
            }
        }

        // 2. Write to App Group UserDefaults suite (accessible cross-process only if App Group container is valid)
        if let groupDefaults, groupContainerURL != nil {
            groupDefaults.set(data, forKey: key)
            groupDefaults.synchronize()
            if groupDefaults.data(forKey: key) != nil {
                sharedWriteSucceeded = true
            }
        }

        // 3. Write to fallback sandbox container (used in unit tests / standalone previews)
        let fallbackURL = fallbackContainerURL.appendingPathComponent("pending-share-captures.json")
        let fallbackParent = fallbackURL.deletingLastPathComponent()
        ensureDirectoryExists(at: fallbackParent)
        do {
            try data.write(to: fallbackURL, options: .atomic)
            fallbackWriteSucceeded = true
        } catch {
            do {
                try data.write(to: fallbackURL)
                fallbackWriteSucceeded = true
            } catch {
                if lastError == nil { lastError = error }
                NSLog("[LaterBox] Could not write to fallback queue file: \(error)")
            }
        }

        if isAppGroupAvailable {
            if sharedWriteSucceeded {
                notifyShareReceived()
                return .success(())
            } else {
                let message = lastError?.localizedDescription ?? "Failed to write data into App Group file or defaults."
                return .failure(.writeFailed(message))
            }
        } else {
            if fallbackWriteSucceeded {
                notifyShareReceived()
                return .success(())
            } else {
                return .failure(.appGroupUnavailable)
            }
        }
    }

    @discardableResult
    func enqueue(_ capture: PendingShareCapture) -> Bool {
        switch enqueueResult(capture) {
        case .success:
            return true
        case .failure:
            return false
        }
    }

    func readAll() -> [PendingShareCapture] {
        var captures: [PendingShareCapture] = []
        var seenIds = Set<String>()

        func appendUnique(_ items: [PendingShareCapture]) {
            for item in items {
                if seenIds.insert(item.id).inserted {
                    captures.append(item)
                }
            }
        }

        // 1. Read from shared App Group queue file
        if let group = groupContainerURL {
            let fileURL = group.appendingPathComponent("pending-share-captures.json")
            if let fileData = try? Data(contentsOf: fileURL),
               let decoded = try? JSONDecoder().decode([PendingShareCapture].self, from: fileData) {
                appendUnique(decoded)
            }
        }

        // 2. Read from App Group UserDefaults suite
        if let groupDefaults {
            groupDefaults.synchronize()
            if let groupData = groupDefaults.data(forKey: key),
               let decoded = try? JSONDecoder().decode([PendingShareCapture].self, from: groupData) {
                appendUnique(decoded)
            }
        }

        // 3. Read from fallback container (for unit tests or local legacy files)
        let fallbackURL = fallbackContainerURL.appendingPathComponent("pending-share-captures.json")
        if let fileData = try? Data(contentsOf: fallbackURL),
           let decoded = try? JSONDecoder().decode([PendingShareCapture].self, from: fileData) {
            appendUnique(decoded)
        }

        return captures
    }

    func clear() {
        readAll().forEach { deleteStagingDirectory(id: $0.id) }
        for fileURL in queueFileURLs {
            try? FileManager.default.removeItem(at: fileURL)
        }
        groupDefaults?.removeObject(forKey: key)
        groupDefaults?.synchronize()
    }

    @discardableResult
    func acknowledge(ids: Set<String>) -> Bool {
        guard !ids.isEmpty else { return true }
        let remaining = readAll().filter { !ids.contains($0.id) }
        
        ids.forEach { deleteStagingDirectory(id: $0) }

        if remaining.isEmpty {
            clear()
            return true
        }

        guard let data = try? JSONEncoder().encode(remaining) else { return false }
        
        for fileURL in queueFileURLs {
            let parentDir = fileURL.deletingLastPathComponent()
            ensureDirectoryExists(at: parentDir)
            do {
                try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            } catch {
                try? data.write(to: fileURL)
            }
        }

        groupDefaults?.set(data, forKey: key)
        groupDefaults?.synchronize()
        return true
    }

    func deleteStagingDirectory(id: String) {
        guard !id.contains("/"), !id.contains("..") else { return }
        for container in [groupContainerURL, fallbackContainerURL].compactMap({ $0 }) {
            let directory = container
                .appendingPathComponent("PendingAttachments", isDirectory: true)
                .appendingPathComponent(id, isDirectory: true)
            try? FileManager.default.removeItem(at: directory)
        }
    }
}
