import Foundation

struct PendingShareCapture: Codable {
    let id: String
    let value: String
    let kind: String
    let source: String
    let createdAt: String

    var toDictionary: [String: Any] {
        guard
            let data = try? JSONEncoder().encode(self),
            let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return [:]
        }
        return dict
    }
}

final class ShareCaptureQueue {
    private let defaults: UserDefaults
    private let key = "laterbox.pendingShareCaptures"

    init?(appGroupId: String) {
        guard let defaults = UserDefaults(suiteName: appGroupId) else { return nil }
        self.defaults = defaults
    }

    func enqueue(_ capture: PendingShareCapture) {
        var captures = readAll()
        captures.append(capture)
        guard let data = try? JSONEncoder().encode(captures) else { return }
        defaults.set(data, forKey: key)
    }

    func readAll() -> [PendingShareCapture] {
        guard
            let data = defaults.data(forKey: key),
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
        defaults.removeObject(forKey: key)
    }
}