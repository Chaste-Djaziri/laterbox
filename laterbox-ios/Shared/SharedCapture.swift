import Foundation
import UserNotifications

struct SharedAttachment: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var name: String
    var relativePath: String
    var typeIdentifier: String
}
struct SharedCapture: Codable, Identifiable {
    var id = UUID().uuidString
    var content = ""
    var title = ""
    var tags: [String] = []
    var category = ""
    var returnAt: Date?
    var attachments: [SharedAttachment] = []
}
enum SharedCaptureStore {
    static let group = "group.pro.micorp.laterbox"
    static func root() throws -> URL {
        guard let root = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) else {
            throw CocoaError(.fileNoSuchFile)
        }
        return root
    }
    static func save(_ capture: SharedCapture) throws {
        let folder = try root().appendingPathComponent("Captures", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try JSONEncoder().encode(capture).write(to: folder.appendingPathComponent(capture.id + ".json"), options: .atomic)
    }
    static func pending() throws -> [(URL, SharedCapture)] {
        let folder = try root().appendingPathComponent("Captures", isDirectory: true)
        guard FileManager.default.fileExists(atPath: folder.path) else { return [] }
        return try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }.map { ($0, try JSONDecoder().decode(SharedCapture.self, from: Data(contentsOf: $0))) }
    }
    static func copyFile(_ source: URL, type: String) throws -> SharedAttachment {
        let id = UUID().uuidString
        let path = "Attachments/\(id)/\(source.lastPathComponent)"
        let destination = try root().appendingPathComponent(path)
        try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: source, to: destination)
        return SharedAttachment(id: id, name: source.lastPathComponent, relativePath: path, typeIdentifier: type)
    }
    static func fileURL(_ attachment: SharedAttachment) throws -> URL {
        let root = try root()
        let file = root.appendingPathComponent(attachment.relativePath).standardizedFileURL
        guard file.path.hasPrefix(root.standardizedFileURL.path + "/Attachments/") else { throw CocoaError(.fileReadInvalidFileName) }
        return file
    }
}
enum ReturnNotification {
    static func update(id: String, title: String, date: Date?) async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id])
        guard let date, date > Date() else { return true }
        let allowed = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        guard allowed else { return false }
        let content = UNMutableNotificationContent()
        content.title = "Back in your Inbox"
        content.body = title
        content.sound = .default
        content.userInfo = ["itemID": id]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, date.timeIntervalSinceNow), repeats: false)
        try await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        return true
    }
}
