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
    private let defaults: UserDefaults
    private let containerURL: URL
    private let queueURL: URL
    private let key = "laterbox.pendingShareCaptures"

    init(appGroupId: String = "group.pro.micorp.laterbox") {
        let groupDefaults = UserDefaults(suiteName: appGroupId)
        let groupContainer = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupId
        )
        self.defaults = groupDefaults ?? UserDefaults.standard

        let fallbackURL: URL
        if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            fallbackURL = docs.appendingPathComponent("LaterBoxShare", isDirectory: true)
        } else {
            fallbackURL = FileManager.default.temporaryDirectory.appendingPathComponent("LaterBoxShare", isDirectory: true)
        }

        self.containerURL = groupContainer ?? fallbackURL
        self.queueURL = self.containerURL.appendingPathComponent("pending-share-captures.json")
        try? FileManager.default.createDirectory(at: self.containerURL, withIntermediateDirectories: true)
    }

    func stagingDirectory(for captureId: String) -> URL {
        let directory = containerURL
            .appendingPathComponent("PendingAttachments", isDirectory: true)
            .appendingPathComponent(captureId, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
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
        
        var fileSuccess = false
        do {
            try data.write(to: queueURL, options: .atomic)
            fileSuccess = true
        } catch {
            fileSuccess = false
        }

        // Dual storage: also persist to UserDefaults for cross-sandbox reliability
        defaults.set(data, forKey: key)
        defaults.synchronize()

        return fileSuccess || defaults.data(forKey: key) != nil
    }

    func readAll() -> [PendingShareCapture] {
        var captures: [PendingShareCapture] = []
        var seenIds = Set<String>()

        // 1. Read from queue file
        if let fileData = try? Data(contentsOf: queueURL),
           let decoded = try? JSONDecoder().decode([PendingShareCapture].self, from: fileData) {
            for item in decoded {
                if seenIds.insert(item.id).inserted {
                    captures.append(item)
                }
            }
        }

        // 2. Read from defaults fallback
        if let defaultsData = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([PendingShareCapture].self, from: defaultsData) {
            for item in decoded {
                if seenIds.insert(item.id).inserted {
                    captures.append(item)
                }
            }
        }

        return captures
    }

    func clear() {
        readAll().forEach { deleteStagingDirectory(id: $0.id) }
        try? FileManager.default.removeItem(at: queueURL)
        defaults.removeObject(forKey: key)
        defaults.synchronize()
    }

    @discardableResult
    func acknowledge(ids: Set<String>) -> Bool {
        guard !ids.isEmpty else { return true }
        let remaining = readAll().filter { !ids.contains($0.id) }
        
        ids.forEach { deleteStagingDirectory(id: $0) }

        if remaining.isEmpty {
            try? FileManager.default.removeItem(at: queueURL)
            defaults.removeObject(forKey: key)
            defaults.synchronize()
            return true
        }

        guard let data = try? JSONEncoder().encode(remaining) else { return false }
        try? data.write(to: queueURL, options: .atomic)
        defaults.set(data, forKey: key)
        defaults.synchronize()
        return true
    }

    func deleteStagingDirectory(id: String) {
        guard !id.contains("/"), !id.contains("..") else { return }
        let directory = containerURL
            .appendingPathComponent("PendingAttachments", isDirectory: true)
            .appendingPathComponent(id, isDirectory: true)
        try? FileManager.default.removeItem(at: directory)
    }
}
