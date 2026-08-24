import Foundation

struct PendingShareCapture: Codable {
    let id: String
    let value: String?
    let kind: String
    let source: String
    let createdAt: String
    let filePaths: [String]

    init(
        id: String,
        value: String?,
        kind: String,
        source: String,
        createdAt: String,
        filePaths: [String] = []
    ) {
        self.id = id
        self.value = value
        self.kind = kind
        self.source = source
        self.createdAt = createdAt
        self.filePaths = filePaths
    }

    private enum CodingKeys: String, CodingKey {
        case id, value, kind, source, createdAt, filePaths
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        value = try container.decodeIfPresent(String.self, forKey: .value)
        kind = try container.decode(String.self, forKey: .kind)
        source = try container.decode(String.self, forKey: .source)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        filePaths = try container.decodeIfPresent([String].self, forKey: .filePaths) ?? []
    }

    var toDictionary: [String: Any] {
        var dictionary: [String: Any] = [
            "id": id,
            "filePaths": filePaths,
            "createdAt": createdAt,
        ]
        if let value { dictionary["text"] = value }
        return dictionary
    }
}

final class ShareCaptureQueue {
    private let appGroupId: String
    private let groupDefaults: UserDefaults?
    private let standardDefaults: UserDefaults
    private let groupContainerURL: URL?
    private let fallbackContainerURL: URL
    private let key = "laterbox.pendingShareCaptures"

    init(appGroupId: String = "group.pro.micorp.laterbox") {
        self.appGroupId = appGroupId
        self.groupDefaults = UserDefaults(suiteName: appGroupId)
        self.standardDefaults = UserDefaults.standard

        let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupId
        )
        self.groupContainerURL = container

        // Robust fallback directories accessible in app sandbox
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
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
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

    @discardableResult
    func enqueue(_ capture: PendingShareCapture) -> Bool {
        var captures = readAll()
        let isDuplicate = captures.contains { existing in
            existing.id == capture.id ||
                (capture.value != nil && !capture.value!.isEmpty && existing.value?.trimmingCharacters(in: .whitespacesAndNewlines) == capture.value?.trimmingCharacters(in: .whitespacesAndNewlines)) ||
                (!capture.filePaths.isEmpty && existing.filePaths == capture.filePaths)
        }
        if isDuplicate { return true }
        captures.append(capture)

        guard let data = try? JSONEncoder().encode(captures) else { return false }
        
        var writeSucceeded = false

        // 1. Write to all available file queue locations
        for fileURL in queueFileURLs {
            let parentDir = fileURL.deletingLastPathComponent()
            ensureDirectoryExists(at: parentDir)
            do {
                try data.write(to: fileURL, options: .atomic)
                writeSucceeded = true
            } catch {
                do {
                    try data.write(to: fileURL)
                    writeSucceeded = true
                } catch {
                    // Continue to fallback channels
                }
            }
        }

        // 2. Write to App Group UserDefaults suite
        if let groupDefaults {
            groupDefaults.set(data, forKey: key)
            groupDefaults.synchronize()
            if groupDefaults.data(forKey: key) != nil {
                writeSucceeded = true
            }
        }

        // 3. Write to standard UserDefaults
        standardDefaults.set(data, forKey: key)
        standardDefaults.synchronize()
        if standardDefaults.data(forKey: key) != nil {
            writeSucceeded = true
        }

        return writeSucceeded
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

        // 1. Read from queue files
        for fileURL in queueFileURLs {
            if let fileData = try? Data(contentsOf: fileURL),
               let decoded = try? JSONDecoder().decode([PendingShareCapture].self, from: fileData) {
                appendUnique(decoded)
            }
        }

        // 2. Read from App Group UserDefaults
        if let groupDefaults,
           let groupData = groupDefaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([PendingShareCapture].self, from: groupData) {
            appendUnique(decoded)
        }

        // 3. Read from standard UserDefaults
        if let stdData = standardDefaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([PendingShareCapture].self, from: stdData) {
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
        standardDefaults.removeObject(forKey: key)
        standardDefaults.synchronize()
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
            try? data.write(to: fileURL, options: .atomic)
        }

        groupDefaults?.set(data, forKey: key)
        groupDefaults?.synchronize()
        standardDefaults.set(data, forKey: key)
        standardDefaults.synchronize()
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
