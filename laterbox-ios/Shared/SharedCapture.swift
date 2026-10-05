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
    var previewImageUrl: String?
    var siteName: String?
    var metadataDescription: String?
}
enum SharedCaptureStore {
    static let group = "group.pro.micorp.laterbox"

    static func root() throws -> URL {
        if let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) {
            try? FileManager.default.createDirectory(at: container, withIntermediateDirectories: true)
            return container
        }

        #if targetEnvironment(simulator)
        // In the iOS Simulator, if the runtime does not resolve the App Group container
        // automatically due to local/ad-hoc build signing, locate the group container
        // directory created by CoreSimulator or fallback to a shared simulator directory.
        let home = NSHomeDirectory()
        let appGroupParent = URL(fileURLWithPath: home).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Shared/AppGroup")
        if let contents = try? FileManager.default.contentsOfDirectory(at: appGroupParent, includingPropertiesForKeys: nil) {
            for folder in contents {
                let meta = folder.appendingPathComponent(".com.apple.mobile_container_manager.metadata.plist")
                if let data = try? Data(contentsOf: meta),
                   let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
                   let id = plist["MCMMetadataIdentifier"] as? String, id == group {
                    try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                    return folder
                }
            }
        }
        let simFallback = URL(fileURLWithPath: "/tmp/\(group)")
        try? FileManager.default.createDirectory(at: simFallback, withIntermediateDirectories: true)
        return simFallback
        #else
        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let fallback = appSupport.appendingPathComponent("LaterBoxGroup", isDirectory: true)
            try? FileManager.default.createDirectory(at: fallback, withIntermediateDirectories: true)
            return fallback
        }
        let docFallback = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("LaterBoxGroup", isDirectory: true)
        try? FileManager.default.createDirectory(at: docFallback, withIntermediateDirectories: true)
        return docFallback
        #endif
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
            .filter { $0.pathExtension == "json" }.compactMap { url in
                guard let data = try? Data(contentsOf: url),
                      let item = try? JSONDecoder().decode(SharedCapture.self, from: data) else { return nil }
                return (url, item)
            }
    }

    static func copyFile(_ source: URL, type: String) throws -> SharedAttachment {
        let id = UUID().uuidString
        let filename = source.lastPathComponent.isEmpty ? "attachment-\(id)" : source.lastPathComponent
        let path = "Attachments/\(id)/\(filename)"
        let destination = try root().appendingPathComponent(path)
        try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: destination.path) {
            try? FileManager.default.removeItem(at: destination)
        }
        let didAccess = source.startAccessingSecurityScopedResource()
        defer { if didAccess { source.stopAccessingSecurityScopedResource() } }
        try FileManager.default.copyItem(at: source, to: destination)
        return SharedAttachment(id: id, name: filename, relativePath: path, typeIdentifier: type)
    }

    static func fileURL(_ attachment: SharedAttachment) throws -> URL {
        let root = try root()
        let file = root.appendingPathComponent(attachment.relativePath).standardizedFileURL
        guard file.path.hasPrefix(root.standardizedFileURL.path) else { throw CocoaError(.fileReadInvalidFileName) }
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
