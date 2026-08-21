import Foundation

struct PendingShareCapture: Codable {
    let id: String
    let value: String?
    let kind: String
    let source: String
    let createdAt: String
    let filePaths: [String]

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
    private let containerURL: URL?
    private let key = "laterbox.pendingShareCaptures"

    init?(appGroupId: String) {
        guard let defaults = UserDefaults(suiteName: appGroupId) else { return nil }
        self.defaults = defaults
        containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupId
        )
    }

    @discardableResult
    func enqueue(_ capture: PendingShareCapture) -> Bool {
        var captures = readAll()
        if !captures.contains(where: { $0.id == capture.id }) {
            captures.append(capture)
        }
        guard let data = try? JSONEncoder().encode(captures) else { return false }
        defaults.set(data, forKey: key)
        return defaults.synchronize()
    }

    func readAll() -> [PendingShareCapture] {
        guard
            let data = defaults.data(forKey: key),
            let captures = try? JSONDecoder().decode([PendingShareCapture].self, from: data)
        else { return [] }
        return captures
    }

    func clear() {
        readAll().forEach { deleteStagingDirectory(id: $0.id) }
        defaults.removeObject(forKey: key)
    }

    @discardableResult
    func acknowledge(ids: Set<String>) -> Bool {
        guard !ids.isEmpty else { return true }
        let remaining = readAll().filter { !ids.contains($0.id) }
        guard let data = try? JSONEncoder().encode(remaining) else { return false }
        defaults.set(data, forKey: key)
        let saved = defaults.synchronize()
        if saved { ids.forEach { deleteStagingDirectory(id: $0) } }
        return saved
    }

    private func deleteStagingDirectory(id: String) {
        guard !id.contains("/"), !id.contains(".."), let containerURL else { return }
        let directory = containerURL
            .appendingPathComponent("PendingAttachments", isDirectory: true)
            .appendingPathComponent(id, isDirectory: true)
        try? FileManager.default.removeItem(at: directory)
    }
}
