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
    static func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    static func requestPermissions() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        return try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    static func sendTestNotification(delaySeconds: TimeInterval = 2.0) async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        let isAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
        if !isAuthorized {
            let requested = try await requestPermissions()
            guard requested else { return false }
        }

        let content = UNMutableNotificationContent()
        content.title = "LaterBox Notification Test"
        content.body = "Notifications are active and working! You'll receive alerts when saved items return to your inbox."
        content.sound = .default
        content.userInfo = ["isTest": true]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1.0, delaySeconds), repeats: false)
        let request = UNNotificationRequest(identifier: "laterbox-test-notification-\(UUID().uuidString)", content: content, trigger: trigger)
        try await center.add(request)
        return true
    }

    static func update(id: String, title: String, date: Date?) async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id])
        guard let date, date > Date() else { return true }
        let settings = await center.notificationSettings()
        let isAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
        if !isAuthorized {
            let allowed = try await requestPermissions()
            guard allowed else { return false }
        }
        let content = UNMutableNotificationContent()
        content.title = "Back in your Inbox"
        content.body = title.isEmpty ? "A scheduled item is ready for review." : title
        content.sound = .default
        content.userInfo = ["itemID": id]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, date.timeIntervalSinceNow), repeats: false)
        try await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        return true
    }

    static func notifyReturned(id: String, title: String) async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        let isAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
        if !isAuthorized {
            let requested = try await requestPermissions()
            guard requested else { return false }
        }
        let content = UNMutableNotificationContent()
        content.title = "Back in your Inbox"
        content.body = title.isEmpty ? "A scheduled item has returned to your inbox." : title
        content.sound = .default
        content.userInfo = ["itemID": id]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
        let request = UNNotificationRequest(identifier: "returned-\(id)", content: content, trigger: trigger)
        try await center.add(request)
        return true
    }
}

// MARK: - Relative Return Date & Time Expression Parser
public struct ParsedRelativeDate: Equatable {
    public let date: Date
    public let intervalDescription: String
    public let isRelative: Bool

    public init(date: Date, intervalDescription: String, isRelative: Bool) {
        self.date = date
        self.intervalDescription = intervalDescription
        self.isRelative = isRelative
    }
}

public enum RelativeDateParser {
    public static func parse(_ text: String, now: Date = Date()) -> ParsedRelativeDate? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let lower = trimmed.lowercased()

        // 1. Minutes pattern: e.g. "in 10 minutes", "10m", "10 min", "10 mins", "10 minutes", "back in 10 minutes"
        if let match = firstMatch(for: #"(?:in|after|back in|remind me in|see (?:it|this) in)?\s*(\d+)\s*(?:m|min|mins|minute|minutes)\b"#, in: lower),
           let count = Int(match), count > 0 {
            let date = now.addingTimeInterval(Double(count) * 60)
            let desc = count == 1 ? "1 minute" : "\(count) minutes"
            return ParsedRelativeDate(date: date, intervalDescription: desc, isRelative: true)
        }

        // 2. Hours pattern: e.g. "in 2 hours", "1 hour", "1h", "2 hrs"
        if let match = firstMatch(for: #"(?:in|after|back in|remind me in|see (?:it|this) in)?\s*(\d+)\s*(?:h|hr|hrs|hour|hours)\b"#, in: lower),
           let count = Int(match), count > 0 {
            let date = now.addingTimeInterval(Double(count) * 3600)
            let desc = count == 1 ? "1 hour" : "\(count) hours"
            return ParsedRelativeDate(date: date, intervalDescription: desc, isRelative: true)
        }

        // 3. Seconds pattern: e.g. "in 30 seconds", "45s"
        if let match = firstMatch(for: #"(?:in|after|back in|remind me in)?\s*(\d+)\s*(?:s|sec|secs|second|seconds)\b"#, in: lower),
           let count = Int(match), count > 0 {
            let date = now.addingTimeInterval(Double(count))
            let desc = count == 1 ? "1 second" : "\(count) seconds"
            return ParsedRelativeDate(date: date, intervalDescription: desc, isRelative: true)
        }

        // 4. Days pattern: e.g. "in 3 days", "3 days", "in 1 day"
        if let match = firstMatch(for: #"(?:in|after|back in|remind me in)?\s*(\d+)\s*(?:d|day|days)\b"#, in: lower),
           let count = Int(match), count > 0 {
            let date = Calendar.current.date(byAdding: .day, value: count, to: now) ?? now.addingTimeInterval(Double(count) * 86400)
            let desc = count == 1 ? "1 day" : "\(count) days"
            return ParsedRelativeDate(date: date, intervalDescription: desc, isRelative: true)
        }

        // 5. Weeks pattern: e.g. "in 2 weeks", "1 week"
        if let match = firstMatch(for: #"(?:in|after|back in|remind me in)?\s*(\d+)\s*(?:w|wk|wks|week|weeks)\b"#, in: lower),
           let count = Int(match), count > 0 {
            let date = Calendar.current.date(byAdding: .day, value: count * 7, to: now) ?? now.addingTimeInterval(Double(count) * 7 * 86400)
            let desc = count == 1 ? "1 week" : "\(count) weeks"
            return ParsedRelativeDate(date: date, intervalDescription: desc, isRelative: true)
        }

        // 6. Natural keywords
        let calendar = Calendar.current
        if lower.contains("tomorrow morning") {
            var comp = calendar.dateComponents([.year, .month, .day], from: now)
            comp.hour = 9; comp.minute = 0; comp.second = 0
            if let target = calendar.date(from: comp)?.addingTimeInterval(86400) {
                return ParsedRelativeDate(date: target, intervalDescription: "tomorrow morning", isRelative: false)
            }
        }
        if lower.contains("tomorrow evening") || lower.contains("tomorrow night") {
            var comp = calendar.dateComponents([.year, .month, .day], from: now)
            comp.hour = 20; comp.minute = 0; comp.second = 0
            if let target = calendar.date(from: comp)?.addingTimeInterval(86400) {
                return ParsedRelativeDate(date: target, intervalDescription: "tomorrow evening", isRelative: false)
            }
        }
        if lower.contains("tomorrow") {
            let target = calendar.date(byAdding: .day, value: 1, to: now) ?? now.addingTimeInterval(86400)
            return ParsedRelativeDate(date: target, intervalDescription: "tomorrow", isRelative: false)
        }
        if lower.contains("tonight") {
            var comp = calendar.dateComponents([.year, .month, .day, .hour], from: now)
            let currentHour = comp.hour ?? 12
            comp.hour = max(currentHour + 2, 20); comp.minute = 0; comp.second = 0
            if let target = calendar.date(from: comp) {
                return ParsedRelativeDate(date: target, intervalDescription: "tonight", isRelative: false)
            }
        }
        if lower.contains("this weekend") || lower.contains("weekend") {
            if let saturday = calendar.nextDate(after: now, matching: DateComponents(hour: 9, weekday: 7), matchingPolicy: .nextTime) {
                return ParsedRelativeDate(date: saturday, intervalDescription: "this weekend", isRelative: false)
            }
        }
        if lower.contains("next week") {
            let target = calendar.date(byAdding: .day, value: 7, to: now) ?? now.addingTimeInterval(7 * 86400)
            return ParsedRelativeDate(date: target, intervalDescription: "next week", isRelative: false)
        }

        // 7. Fallback to NSDataDetector for absolute dates like "Oct 15 at 3pm"
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue),
           let match = detector.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
           let matchDate = match.date, matchDate > now {
            return ParsedRelativeDate(date: matchDate, intervalDescription: matchDate.formatted(date: .abbreviated, time: .shortened), isRelative: false)
        }

        return nil
    }

    private static func firstMatch(for pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        guard let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) else { return nil }
        if match.numberOfRanges > 1 {
            let range = match.range(at: 1)
            if let strRange = Range(range, in: text) {
                return String(text[strRange])
            }
        }
        return nil
    }
}

