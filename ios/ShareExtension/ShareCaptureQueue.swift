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

    init?(appGroupId: String) {
        guard
            let defaults = UserDefaults(suiteName: appGroupId),
            let containerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: appGroupId
            )
        else { return nil }
        self.defaults = defaults
        self.containerURL = containerURL
        queueURL = containerURL.appendingPathComponent("pending-share-captures.json")
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
        do {
            try data.write(to: queueURL, options: .atomic)
            defaults.removeObject(forKey: key)
            return true
        } catch {
            return false
        }
    }

    func readAll() -> [PendingShareCapture] {
        let storedData = (try? Data(contentsOf: queueURL)) ?? defaults.data(forKey: key)
        guard
            let data = storedData,
            let captures = try? JSONDecoder().decode(
                [PendingShareCapture].self,
                from: data
            )
        else {
            return []
        }
        return captures
    }

    func clear() {
        readAll().forEach { deleteStagingDirectory(id: $0.id) }
        try? FileManager.default.removeItem(at: queueURL)
        defaults.removeObject(forKey: key)
    }

    @discardableResult
    func acknowledge(ids: Set<String>) -> Bool {
        guard !ids.isEmpty else { return true }
        let remaining = readAll().filter { !ids.contains($0.id) }
        guard let data = try? JSONEncoder().encode(remaining) else { return false }
        do {
            try data.write(to: queueURL, options: .atomic)
            defaults.removeObject(forKey: key)
            ids.forEach { deleteStagingDirectory(id: $0) }
            return true
        } catch {
            return false
        }
    }

    private func deleteStagingDirectory(id: String) {
        guard !id.contains("/"), !id.contains("..") else { return }
        let directory = containerURL
            .appendingPathComponent("PendingAttachments", isDirectory: true)
            .appendingPathComponent(id, isDirectory: true)
        try? FileManager.default.removeItem(at: directory)
    }
}
