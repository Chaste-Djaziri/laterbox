import Foundation
import AppIntents
import UserNotifications
import NaturalLanguage
#if canImport(Darwin)
import Darwin
#endif

nonisolated struct SharedAttachment: Codable, Identifiable, Equatable, Sendable {
    var id: String = UUID().uuidString
    var name: String
    var relativePath: String
    var typeIdentifier: String
    // Cloud metadata is populated after a Pro attachment upload or download.
    var remoteObjectKey: String?
    var byteSize: Int64?
    var sha256: String?
    var mimeType: String?
}
nonisolated struct SharedCapture: Codable, Identifiable, Sendable {
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
nonisolated enum SharedCaptureStore: Sendable {
    nonisolated static let group = "group.pro.micorp.laterbox"

    nonisolated static func root() throws -> URL {
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

    nonisolated static func save(_ capture: SharedCapture) throws {
        let folder = try root().appendingPathComponent("Captures", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try JSONEncoder().encode(capture).write(to: folder.appendingPathComponent(capture.id + ".json"), options: .atomic)
    }

    nonisolated static func pending() throws -> [(URL, SharedCapture)] {
        let folder = try root().appendingPathComponent("Captures", isDirectory: true)
        guard FileManager.default.fileExists(atPath: folder.path) else { return [] }
        return try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }.compactMap { url in
                guard let data = try? Data(contentsOf: url),
                      let item = try? JSONDecoder().decode(SharedCapture.self, from: data) else { return nil }
                return (url, item)
            }
    }

    nonisolated static func copyFile(_ source: URL, type: String) throws -> SharedAttachment {
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

    nonisolated static func fileURL(_ attachment: SharedAttachment) throws -> URL {
        let root = try root()
        let file = root.appendingPathComponent(attachment.relativePath).standardizedFileURL
        guard file.path.hasPrefix(root.standardizedFileURL.path) else { throw CocoaError(.fileReadInvalidFileName) }
        return file
    }

    /// Cloud UUIDs are lowercase; Swift UUIDs are uppercase. Reuse the actual
    /// directory spelling rather than trying to recreate it on a case-insensitive volume.
    nonisolated static func attachmentDirectory(id: String, root: URL) throws -> URL {
        guard UUID(uuidString: id) != nil else { throw CocoaError(.fileReadInvalidFileName) }
        let base = root.appendingPathComponent("Attachments", isDirectory: true)
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        if let existing = try FileManager.default.contentsOfDirectory(at: base, includingPropertiesForKeys: [.isDirectoryKey])
            .first(where: { $0.lastPathComponent.caseInsensitiveCompare(id) == .orderedSame &&
                (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }) {
            return existing
        }
        let directory = base.appendingPathComponent(id.lowercased(), isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    // MARK: - Shared AI Settings Persistence
    nonisolated static func saveAISettings(_ settings: SharedAISettings) {
        if let defaults = UserDefaults(suiteName: group) {
            defaults.set(settings.selectedProvider, forKey: "laterbox_selected_ai_provider")
            defaults.set(settings.isOnDeviceModelEnabled, forKey: "laterbox_enable_on_device_model")
            defaults.set(settings.bazaarlinkApiKey, forKey: "laterbox_bazaarlink_api_key")
            defaults.set(settings.geminiApiKey, forKey: "laterbox_gemini_api_key")
            defaults.set(settings.openaiApiKey, forKey: "laterbox_openai_api_key")
            defaults.set(settings.claudeApiKey, forKey: "laterbox_claude_api_key")
            defaults.set(settings.bazaarlinkModel, forKey: "laterbox_bazaarlink_model")
            defaults.set(settings.geminiModel, forKey: "laterbox_gemini_model")
            defaults.set(settings.openaiModel, forKey: "laterbox_openai_model")
            defaults.set(settings.claudeModel, forKey: "laterbox_claude_model")
        }
        if let root = try? root() {
            let file = root.appendingPathComponent("ai_settings.json")
            if let data = try? JSONEncoder().encode(settings) {
                try? data.write(to: file, options: .atomic)
            }
        }
    }

    nonisolated static func loadAISettings() -> SharedAISettings {
        let groupDefaults = UserDefaults(suiteName: group)
        var settings = SharedAISettings()

        if let root = try? root() {
            let file = root.appendingPathComponent("ai_settings.json")
            if let data = try? Data(contentsOf: file),
               let decoded = try? JSONDecoder().decode(SharedAISettings.self, from: data) {
                settings = decoded
            }
        }

        if let prov = groupDefaults?.string(forKey: "laterbox_selected_ai_provider") ?? UserDefaults.standard.string(forKey: "laterbox_selected_ai_provider"), !prov.isEmpty {
            settings.selectedProvider = prov
        }
        if let onDeviceObj = groupDefaults?.object(forKey: "laterbox_enable_on_device_model") as? Bool ?? UserDefaults.standard.object(forKey: "laterbox_enable_on_device_model") as? Bool {
            settings.isOnDeviceModelEnabled = onDeviceObj
        }
        if let bzKey = groupDefaults?.string(forKey: "laterbox_bazaarlink_api_key") ?? UserDefaults.standard.string(forKey: "laterbox_bazaarlink_api_key"), !bzKey.isEmpty {
            settings.bazaarlinkApiKey = bzKey
        }
        if let gemKey = groupDefaults?.string(forKey: "laterbox_gemini_api_key") ?? UserDefaults.standard.string(forKey: "laterbox_gemini_api_key"), !gemKey.isEmpty {
            settings.geminiApiKey = gemKey
        }
        if let oaiKey = groupDefaults?.string(forKey: "laterbox_openai_api_key") ?? UserDefaults.standard.string(forKey: "laterbox_openai_api_key"), !oaiKey.isEmpty {
            settings.openaiApiKey = oaiKey
        }
        if let cldKey = groupDefaults?.string(forKey: "laterbox_claude_api_key") ?? UserDefaults.standard.string(forKey: "laterbox_claude_api_key"), !cldKey.isEmpty {
            settings.claudeApiKey = cldKey
        }
        if let bzModel = groupDefaults?.string(forKey: "laterbox_bazaarlink_model") ?? UserDefaults.standard.string(forKey: "laterbox_bazaarlink_model"), !bzModel.isEmpty {
            settings.bazaarlinkModel = bzModel
        }
        if let gemModel = groupDefaults?.string(forKey: "laterbox_gemini_model") ?? UserDefaults.standard.string(forKey: "laterbox_gemini_model"), !gemModel.isEmpty {
            settings.geminiModel = gemModel
        }
        if let oaiModel = groupDefaults?.string(forKey: "laterbox_openai_model") ?? UserDefaults.standard.string(forKey: "laterbox_openai_model"), !oaiModel.isEmpty {
            settings.openaiModel = oaiModel
        }
        if let cldModel = groupDefaults?.string(forKey: "laterbox_claude_model") ?? UserDefaults.standard.string(forKey: "laterbox_claude_model"), !cldModel.isEmpty {
            settings.claudeModel = cldModel
        }

        return settings
    }

    // MARK: - Available Collections Cache
    nonisolated static func saveAvailableCollections(_ collections: [String]) {
        if let root = try? root() {
            let file = root.appendingPathComponent("cached_collections.json")
            if let data = try? JSONEncoder().encode(collections) {
                try? data.write(to: file, options: .atomic)
            }
        }
    }

    nonisolated static func loadAvailableCollections() -> [String] {
        if let root = try? root() {
            let file = root.appendingPathComponent("cached_collections.json")
            if let data = try? Data(contentsOf: file),
               let decoded = try? JSONDecoder().decode([String].self, from: data), !decoded.isEmpty {
                return decoded
            }
        }
        return ["Inbox", "Reading", "Watch Later", "Listen Later", "To-Do", "Shopping", "Documents", "Ideas"]
    }
}
enum ReturnNotification {
    private static var isTestingOrExtension: Bool {
        Bundle.main.bundlePath.hasSuffix(".appex") ||
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
        ProcessInfo.processInfo.environment["XCInjectBundleInto"] != nil ||
        NSClassFromString("XCTestCase") != nil
    }

    static func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    static func requestPermissions() async throws -> Bool {
        if isTestingOrExtension {
            return false
        }
        let center = UNUserNotificationCenter.current()
        return try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    static func sendTestNotification(delaySeconds: TimeInterval = 2.0) async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        let isAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
        if !isAuthorized {
            if isTestingOrExtension {
                return false
            }
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

    static func update(id: String, title: String, description: String? = nil, date: Date?) async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id])
        guard let date, date > Date() else { return true }
        let settings = await center.notificationSettings()
        let isAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
        if !isAuthorized {
            if isTestingOrExtension {
                return false
            }
            let allowed = try await requestPermissions()
            guard allowed else { return false }
        }
        let content = UNMutableNotificationContent()
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        content.title = cleanTitle.isEmpty ? "Back in your Inbox" : cleanTitle
        if !cleanTitle.isEmpty {
            content.subtitle = "Back in your Inbox"
        }
        let cleanDesc = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let cleanDesc, !cleanDesc.isEmpty {
            content.body = cleanDesc
        } else {
            content.body = "A scheduled item is ready for review in your inbox."
        }
        content.sound = .default
        content.userInfo = ["itemID": id]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, date.timeIntervalSinceNow), repeats: false)
        try await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        return true
    }

    static func update(id: String, title: String, date: Date?) async throws -> Bool {
        try await update(id: id, title: title, description: nil, date: date)
    }

    static func notifyReturned(id: String, title: String, description: String? = nil) async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        let isAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
        if !isAuthorized {
            if isTestingOrExtension {
                return false
            }
            let requested = try await requestPermissions()
            guard requested else { return false }
        }
        let content = UNMutableNotificationContent()
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        content.title = cleanTitle.isEmpty ? "Back in your Inbox" : cleanTitle
        if !cleanTitle.isEmpty {
            content.subtitle = "Back in your Inbox"
        }
        let cleanDesc = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let cleanDesc, !cleanDesc.isEmpty {
            content.body = cleanDesc
        } else {
            content.body = "A scheduled item has returned to your inbox."
        }
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

// MARK: - Shared AI Settings Model
nonisolated struct SharedAISettings: Codable, Sendable {
    var selectedProvider: String = "local"
    var isOnDeviceModelEnabled: Bool = true
    var bazaarlinkApiKey: String = ""
    var geminiApiKey: String = ""
    var openaiApiKey: String = ""
    var claudeApiKey: String = ""
    var bazaarlinkModel: String = "qwen/qwen3.7-flash"
    var geminiModel: String = "gemini-2.5-flash"
    var openaiModel: String = "gpt-4o-mini"
    var claudeModel: String = "claude-3-5-haiku-20241022"

    init(
        selectedProvider: String = "local",
        isOnDeviceModelEnabled: Bool = true,
        bazaarlinkApiKey: String = "",
        geminiApiKey: String = "",
        openaiApiKey: String = "",
        claudeApiKey: String = "",
        bazaarlinkModel: String = "qwen/qwen3.7-flash",
        geminiModel: String = "gemini-2.5-flash",
        openaiModel: String = "gpt-4o-mini",
        claudeModel: String = "claude-3-5-haiku-20241022"
    ) {
        self.selectedProvider = selectedProvider
        self.isOnDeviceModelEnabled = isOnDeviceModelEnabled
        self.bazaarlinkApiKey = bazaarlinkApiKey
        self.geminiApiKey = geminiApiKey
        self.openaiApiKey = openaiApiKey
        self.claudeApiKey = claudeApiKey
        self.bazaarlinkModel = bazaarlinkModel
        self.geminiModel = geminiModel
        self.openaiModel = openaiModel
        self.claudeModel = claudeModel
    }

    var isCustomKeyProvider: Bool {
        selectedProvider != "local" && selectedProvider != "onDevice"
    }

    var hasApiKey: Bool {
        switch selectedProvider {
        case "local", "onDevice":
            return true
        case "bazaarlink":
            return !bazaarlinkApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case "gemini":
            return !geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case "openai":
            return !openaiApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case "claude":
            return !claudeApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default:
            return true
        }
    }

    var providerDisplayName: String {
        switch selectedProvider {
        case "local": return "Local responses"
        case "onDevice": return "On-Device Neural Engine"
        case "bazaarlink": return "BazaarLink (\(bazaarlinkModel))"
        case "gemini": return "Google Gemini (\(geminiModel))"
        case "openai": return "OpenAI (\(openaiModel))"
        case "claude": return "Claude (\(claudeModel))"
        default: return "Later AI"
        }
    }

    var providerShortName: String {
        switch selectedProvider {
        case "local": return "Local AI"
        case "onDevice": return "On-Device AI"
        case "bazaarlink": return "BazaarLink"
        case "gemini": return "Gemini"
        case "openai": return "OpenAI"
        case "claude": return "Claude"
        default: return "Later AI"
        }
    }
}

// MARK: - On-Device & Remote Capture Analysis DTO
nonisolated struct OnDeviceCaptureAnalysis: Sendable {
    var title: String?
    var summary: String?
    var contentType: String?
    var tags: [String]
    var collectionName: String?
    var returnAt: Date?
    var detectedUrl: String?
    var previewImageUrl: String?
    var siteName: String?
    var faviconUrl: String?
    var isLinkEnriched: Bool
    var sourceDescription: String
    var formattedTaskContent: String?

    init(
        title: String? = nil,
        summary: String? = nil,
        contentType: String? = nil,
        tags: [String] = [],
        collectionName: String? = nil,
        returnAt: Date? = nil,
        detectedUrl: String? = nil,
        previewImageUrl: String? = nil,
        siteName: String? = nil,
        faviconUrl: String? = nil,
        isLinkEnriched: Bool = false,
        sourceDescription: String = "On-Device AI",
        formattedTaskContent: String? = nil
    ) {
        self.title = title
        self.summary = summary
        self.contentType = contentType
        self.tags = tags
        self.collectionName = collectionName
        self.returnAt = returnAt
        self.detectedUrl = detectedUrl
        self.previewImageUrl = previewImageUrl
        self.siteName = siteName
        self.faviconUrl = faviconUrl
        self.isLinkEnriched = isLinkEnriched
        self.sourceDescription = sourceDescription
        self.formattedTaskContent = formattedTaskContent
    }
}

// MARK: - LaterAI Shared Unified Analyzer
enum LaterAISharedAnalyzer {
    static func detectURL(_ text: String) -> String? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return nil }
        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        for match in matches {
            if let url = match.url {
                return url.absoluteString
            }
        }
        return nil
    }

    static func isGenericTitle(_ title: String?) -> Bool {
        guard let raw = title?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return true }
        let stripped = raw.trimmingCharacters(in: CharacterSet(charactersIn: "-–—|: •\t\n\r"))
        let lower = stripped.lowercased()
        return lower.isEmpty ||
               lower == "youtube" ||
               lower == "- youtube" ||
               (lower.hasSuffix("youtube") && lower.count <= 14) ||
               lower == "video playlist" ||
               lower.contains("video playlist") ||
               lower == "untitled" ||
               lower.hasPrefix("http://") ||
               lower.hasPrefix("https://") ||
               lower == "watch" ||
               lower == "watch video" ||
               lower == "before you continue to youtube" ||
               lower == "vimeo" ||
               lower == "spotify" ||
               lower == "soundcloud"
    }

    public static func cleanTitle(_ title: String?) -> String? {
        guard let raw = title?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return nil }
        if isGenericTitle(raw) { return nil }
        var cleaned = raw
        for suffix in [" - YouTube", " | YouTube", " – YouTube", " — YouTube", " - Vimeo", " | Vimeo", " on Spotify"] {
            if cleaned.hasSuffix(suffix) {
                cleaned = String(cleaned.dropLast(suffix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return isGenericTitle(cleaned) ? nil : cleaned
    }

    public static func isGenericDescription(_ desc: String?) -> Bool {
        guard let raw = desc?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return true }
        return raw.contains("enjoy the videos and music you love") ||
               raw.contains("upload original content") ||
               raw.contains("share it all with friends, family")
    }

    public static func enrichLink(_ rawUrlString: String) async -> (
        title: String?,
        siteName: String?,
        description: String?,
        previewImageUrl: String?,
        keywords: [String],
        contentType: String?
    ) {
        guard let url = URL(string: rawUrlString.trimmingCharacters(in: .whitespacesAndNewlines)),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme) else {
            return (nil, nil, nil, nil, [], nil)
        }

        var oembedTitle: String?
        var oembedAuthor: String?
        var oembedThumb: String?
        var oembedSite: String?
        var detectedType: String?

        let host = url.host?.lowercased() ?? ""
        if host.contains("youtube.com") || host == "youtu.be" || host.contains("vimeo.com") {
            oembedSite = host.contains("vimeo") ? "Vimeo" : "YouTube"
            detectedType = "video"
            var oembedUrlString: String?
            if let encoded = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                if host.contains("vimeo") {
                    oembedUrlString = "https://vimeo.com/api/oembed.json?url=\(encoded)"
                } else {
                    oembedUrlString = "https://www.youtube.com/oembed?url=\(encoded)&format=json"
                }
            }
            if let oembedUrlString, let oembedUrl = URL(string: oembedUrlString) {
                var ytReq = URLRequest(url: oembedUrl)
                ytReq.timeoutInterval = 4
                if let (ytData, ytResp) = try? await URLSession.shared.data(for: ytReq),
                   (ytResp as? HTTPURLResponse)?.statusCode == 200,
                   let ytJson = try? JSONSerialization.jsonObject(with: ytData) as? [String: Any] {
                    if let rawTitle = (ytJson["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !rawTitle.isEmpty {
                        oembedTitle = cleanTitle(rawTitle) ?? rawTitle
                    }
                    if let author = (ytJson["author_name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !author.isEmpty {
                        oembedAuthor = author
                    }
                    if let thumb = (ytJson["thumbnail_url"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !thumb.isEmpty {
                        oembedThumb = thumb.replacingOccurrences(of: "/hqdefault.jpg", with: "/mqdefault.jpg")
                                           .replacingOccurrences(of: "/sddefault.jpg", with: "/mqdefault.jpg")
                    }
                }
            }
        }

        var finalTitle = oembedTitle
        var finalSite = oembedSite
        var finalDesc = oembedAuthor != nil ? "Video by \(oembedAuthor!) on \(oembedSite ?? "Web")" : nil
        var finalImg = oembedThumb
        var finalKeywords: [String] = []

        if let oembedAuthor {
            finalKeywords.append(oembedAuthor.lowercased())
            finalKeywords.append("video")
        }

        var req = URLRequest(url: URL(string: "https://laterbox.dev/api/enrich")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 5
        let body = ["url": url.absoluteString]
        if let bodyData = try? JSONSerialization.data(withJSONObject: body) {
            req.httpBody = bodyData
            if let (data, resp) = try? await URLSession.shared.data(for: req),
               let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let rawTitle = (json["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                let site = ((json["siteName"] ?? json["site_name"]) as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                let desc = (json["description"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                let img = ((json["previewImageUrl"] ?? json["preview_image_url"]) as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                let keywords = (json["keywords"] as? [String]) ?? []

                if finalTitle == nil || isGenericTitle(finalTitle) {
                    if let cleaned = cleanTitle(rawTitle) {
                        finalTitle = cleaned
                    }
                }
                if let site, !site.isEmpty { finalSite = site }
                if let desc, !desc.isEmpty && !isGenericDescription(desc) { finalDesc = desc }
                if finalImg == nil, let img, !img.isEmpty { finalImg = img }
                finalKeywords.append(contentsOf: keywords)
            }
        }

        return (finalTitle, finalSite, finalDesc, finalImg, finalKeywords, detectedType)
    }

    static func analyze(
        content: String,
        detectedUrl: String? = nil,
        attachments: [SharedAttachment] = [],
        availableCollections: [String] = [],
        settings: SharedAISettings? = nil
    ) async -> OnDeviceCaptureAnalysis {
        let aiSettings = settings ?? SharedCaptureStore.loadAISettings()
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedUrl = detectedUrl ?? detectURL(trimmedContent)

        var enrichedTitle: String? = nil
        var enrichedSummary: String? = nil
        var enrichedSite: String? = nil
        var enrichedImage: String? = nil
        var enrichedContentType: String? = nil
        var enrichedTags: [String] = []
        var isLinkEnriched = false

        if let resolvedUrl {
            let metadata = await enrichLink(resolvedUrl)
            if let title = metadata.title, !isGenericTitle(title) {
                enrichedTitle = title
                isLinkEnriched = true
            }
            if let desc = metadata.description { enrichedSummary = desc }
            if let site = metadata.siteName { enrichedSite = site }
            if let img = metadata.previewImageUrl { enrichedImage = img }
            if let ct = metadata.contentType { enrichedContentType = ct }
            enrichedTags = metadata.keywords
        }

        // 1. If remote AI provider with custom key is chosen, query remote API first
        if aiSettings.isCustomKeyProvider && aiSettings.hasApiKey {
            if let remoteAnalysis = await queryRemoteCaptureAnalysis(
                content: trimmedContent,
                detectedUrl: resolvedUrl,
                attachments: attachments,
                availableCollections: availableCollections,
                enrichedTitle: enrichedTitle,
                enrichedSummary: enrichedSummary,
                enrichedContentType: enrichedContentType,
                settings: aiSettings
            ) {
                var finalAnalysis = remoteAnalysis
                if finalAnalysis.previewImageUrl == nil { finalAnalysis.previewImageUrl = enrichedImage }
                if finalAnalysis.siteName == nil { finalAnalysis.siteName = enrichedSite }
                finalAnalysis.isLinkEnriched = isLinkEnriched
                return finalAnalysis
            }
        }

        // 2. High-Accuracy Generalized On-Device Semantic Intent Engine
        let deduction = deduceCaptureIntent(
            content: trimmedContent,
            detectedUrl: resolvedUrl,
            attachments: attachments,
            enrichedTitle: enrichedTitle,
            enrichedSummary: enrichedSummary,
            enrichedContentType: enrichedContentType
        )

        var allTags = Set<String>()
        let hashtags = trimmedContent.split(whereSeparator: \.isWhitespace)
            .filter { $0.hasPrefix("#") && $0.count > 1 }
            .map { String($0.dropFirst()).trimmingCharacters(in: CharacterSet.alphanumerics.inverted).lowercased() }
            .filter { !$0.isEmpty }
        allTags.formUnion(hashtags)

        for kw in enrichedTags {
            let clean = kw.lowercased().trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            if clean.count >= 2 && clean.count <= 25 { allTags.insert(clean) }
        }

        if let resolvedUrl, let host = URL(string: resolvedUrl)?.host {
            let domain = host.replacingOccurrences(of: "www.", with: "")
            if let primary = domain.split(separator: ".").first, primary.count >= 3 {
                allTags.insert(String(primary).lowercased())
            }
        }

        for actionTag in deduction.actionTags {
            allTags.insert(actionTag)
        }

        let textToTag = "\(deduction.suggestedTitle ?? "") \(trimmedContent) \(deduction.suggestedNotes ?? "")"
        if !textToTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let tagger = NLTagger(tagSchemes: [.nameType])
            tagger.string = textToTag
            let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
            let tagsToExtract: Set<NLTag> = [.organizationName, .placeName, .personalName]
            tagger.enumerateTags(in: textToTag.startIndex..<textToTag.endIndex, unit: .word, scheme: .nameType, options: options) { tag, tokenRange in
                if let tag, tagsToExtract.contains(tag) {
                    let entity = String(textToTag[tokenRange]).lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    if entity.count >= 3 && entity.count <= 20 {
                        allTags.insert(entity.replacingOccurrences(of: " ", with: "-"))
                    }
                }
                return true
            }
        }

        let lowerCorpus = textToTag.lowercased()
        let topicMap: [(keyword: String, tag: String)] = [
            ("design", "design"), ("figma", "design"), ("ui", "ui"), ("ux", "ux"),
            ("swift", "swift"), ("ios", "ios"), ("apple", "apple"), ("python", "python"),
            ("react", "react"), ("javascript", "javascript"), ("rust", "rust"),
            ("recipe", "recipe"), ("cook", "cooking"), ("dinner", "food"),
            ("book", "reading"), ("paper", "research"), ("article", "reading"),
            ("workout", "fitness"), ("gym", "fitness"), ("health", "health"),
            ("crypto", "crypto"), ("bitcoin", "crypto"), ("finance", "finance"), ("budget", "finance"),
            ("travel", "travel"), ("flight", "travel"), ("hotel", "travel"),
            ("meeting", "work"), ("client", "work"), ("project", "work"), ("deadline", "work"),
            ("idea", "ideas"), ("startup", "startup"), ("ai", "ai"), ("llm", "ai")
        ]
        for item in topicMap {
            if lowerCorpus.contains(item.keyword) { allTags.insert(item.tag) }
        }

        var suggestedCollection: String? = nil
        let candidateTags = Array(allTags)
        for collName in availableCollections {
            let lowerColl = collName.lowercased()
            if candidateTags.contains(where: { $0.localizedCaseInsensitiveCompare(lowerColl) == .orderedSame }) ||
               lowerCorpus.contains(lowerColl) {
                suggestedCollection = collName
                break
            }
        }
        if suggestedCollection == nil {
            if deduction.dominantType == "task" {
                if allTags.contains("shopping") {
                    suggestedCollection = availableCollections.first { $0.localizedCaseInsensitiveCompare("Shopping") == .orderedSame } ?? "Shopping"
                } else {
                    suggestedCollection = availableCollections.first { $0.localizedCaseInsensitiveCompare("To-Do") == .orderedSame || $0.localizedCaseInsensitiveCompare("Tasks") == .orderedSame } ?? "To-Do"
                }
            } else if deduction.dominantType == "video" {
                suggestedCollection = availableCollections.first { $0.localizedCaseInsensitiveCompare("Videos") == .orderedSame || $0.localizedCaseInsensitiveCompare("Watch Later") == .orderedSame } ?? "Watch Later"
            } else if deduction.dominantType == "article" {
                suggestedCollection = availableCollections.first { $0.localizedCaseInsensitiveCompare("Reading") == .orderedSame || $0.localizedCaseInsensitiveCompare("Articles") == .orderedSame } ?? "Reading"
            } else if deduction.dominantType == "music" {
                suggestedCollection = availableCollections.first { $0.localizedCaseInsensitiveCompare("Listen Later") == .orderedSame } ?? "Listen Later"
            } else {
                suggestedCollection = "Inbox"
            }
        }

        let sourceDesc = isLinkEnriched ? "Auto-filled from link" : (aiSettings.selectedProvider == "onDevice" ? "Auto-filled by On-Device AI" : "Auto-filled by Local AI")

        return OnDeviceCaptureAnalysis(
            title: deduction.suggestedTitle,
            summary: deduction.suggestedNotes,
            contentType: deduction.dominantType,
            tags: Array(allTags).sorted(),
            collectionName: suggestedCollection,
            returnAt: deduction.bestReturnDate,
            detectedUrl: resolvedUrl,
            previewImageUrl: enrichedImage,
            siteName: enrichedSite,
            isLinkEnriched: isLinkEnriched,
            sourceDescription: sourceDesc,
            formattedTaskContent: deduction.formattedTask
        )
    }

    private static func queryRemoteCaptureAnalysis(
        content: String,
        detectedUrl: String?,
        attachments: [SharedAttachment],
        availableCollections: [String],
        enrichedTitle: String?,
        enrichedSummary: String?,
        enrichedContentType: String?,
        settings: SharedAISettings
    ) async -> OnDeviceCaptureAnalysis? {
        let collectionsPrompt = availableCollections.isEmpty ? "none" : availableCollections.joined(separator: ", ")
        let userPrompt = """
        User capture: "\(content)"
        Detected URL: \(detectedUrl ?? "none")
        Enriched title: \(enrichedTitle ?? "none")
        Enriched description: \(enrichedSummary ?? "none")
        Enriched type: \(enrichedContentType ?? "none")
        Attachment names: \(attachments.map(\.name).joined(separator: ", "))
        Available collections: \(collectionsPrompt)

        Analyze user phrasing and mixed content (tasks with links/videos/images). Deduce what the user wants most out of it:
        - If action phrasing implies doing, buying, reviewing, watching, or reading later, classify as "task", generate an action title, format task items as "- [ ] item" in formattedTaskContent, and provide best returnDateISO.
        - Otherwise classify as video, article, link, document, image, or note.
        Respond in JSON:
        {
          "title": "...",
          "contentType": "task"|"video"|"article"|"link"|"document"|"image"|"note",
          "summary": "...",
          "formattedTaskContent": "...",
          "tags": ["..."],
          "collectionName": "...",
          "returnDateISO": "..."
        }
        """

        if settings.selectedProvider == "bazaarlink" {
            let key = settings.bazaarlinkApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty, let url = URL(string: "https://api.bazaarlink.ai/v1/chat/completions") else { return nil }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
            req.timeoutInterval = 12

            let payload: [String: Any] = [
                "model": settings.bazaarlinkModel,
                "messages": [
                    ["role": "system", "content": "You are Later AI. Always output valid JSON."],
                    ["role": "user", "content": userPrompt]
                ],
                "response_format": ["type": "json_object"],
                "temperature": 0.2
            ]
            guard let bodyData = try? JSONSerialization.data(withJSONObject: payload) else { return nil }
            req.httpBody = bodyData

            guard let (data, resp) = try? await URLSession.shared.data(for: req),
                  let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let msg = choices.first?["message"] as? [String: Any],
                  let contentStr = msg["content"] as? String,
                  let parsed = try? JSONSerialization.jsonObject(with: contentStr.data(using: .utf8) ?? Data()) as? [String: Any]
            else { return nil }

            return parseRemoteJSONToAnalysis(parsed: parsed, detectedUrl: detectedUrl, source: "Auto-filled by BazaarLink (\(settings.bazaarlinkModel))")
        } else if settings.selectedProvider == "gemini" {
            let key = settings.geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty, let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(settings.geminiModel):generateContent?key=\(key)") else { return nil }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.timeoutInterval = 12

            let payload: [String: Any] = [
                "contents": [["parts": [["text": userPrompt]]]],
                "generationConfig": ["responseMimeType": "application/json", "maxOutputTokens": 1024]
            ]
            guard let bodyData = try? JSONSerialization.data(withJSONObject: payload) else { return nil }
            req.httpBody = bodyData

            guard let (data, resp) = try? await URLSession.shared.data(for: req),
                  let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let contentObj = candidates.first?["content"] as? [String: Any],
                  let parts = contentObj["parts"] as? [[String: Any]],
                  let text = parts.first?["text"] as? String,
                  let parsed = try? JSONSerialization.jsonObject(with: text.data(using: .utf8) ?? Data()) as? [String: Any]
            else { return nil }

            return parseRemoteJSONToAnalysis(parsed: parsed, detectedUrl: detectedUrl, source: "Auto-filled by Gemini (\(settings.geminiModel))")
        } else if settings.selectedProvider == "openai" {
            let key = settings.openaiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty, let url = URL(string: "https://api.openai.com/v1/chat/completions") else { return nil }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
            req.timeoutInterval = 12

            let payload: [String: Any] = [
                "model": settings.openaiModel,
                "messages": [
                    ["role": "system", "content": "You are Later AI. Always output valid JSON."],
                    ["role": "user", "content": userPrompt]
                ],
                "response_format": ["type": "json_object"],
                "temperature": 0.2
            ]
            guard let bodyData = try? JSONSerialization.data(withJSONObject: payload) else { return nil }
            req.httpBody = bodyData

            guard let (data, resp) = try? await URLSession.shared.data(for: req),
                  let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let msg = choices.first?["message"] as? [String: Any],
                  let contentStr = msg["content"] as? String,
                  let parsed = try? JSONSerialization.jsonObject(with: contentStr.data(using: .utf8) ?? Data()) as? [String: Any]
            else { return nil }

            return parseRemoteJSONToAnalysis(parsed: parsed, detectedUrl: detectedUrl, source: "Auto-filled by OpenAI (\(settings.openaiModel))")
        } else if settings.selectedProvider == "claude" {
            let key = settings.claudeApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty, let url = URL(string: "https://api.anthropic.com/v1/messages") else { return nil }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue(key, forHTTPHeaderField: "x-api-key")
            req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            req.timeoutInterval = 12

            let payload: [String: Any] = [
                "model": settings.claudeModel,
                "max_tokens": 1024,
                "system": "You are Later AI. Respond ONLY with a valid JSON object matching the requested schema without any markdown formatting or commentary.",
                "messages": [
                    ["role": "user", "content": userPrompt]
                ]
            ]
            guard let bodyData = try? JSONSerialization.data(withJSONObject: payload) else { return nil }
            req.httpBody = bodyData

            guard let (data, resp) = try? await URLSession.shared.data(for: req),
                  let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let contentArray = json["content"] as? [[String: Any]],
                  let firstText = contentArray.first?["text"] as? String
            else { return nil }

            var cleanedText = firstText.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleanedText.hasPrefix("```json") {
                cleanedText = String(cleanedText.dropFirst(7))
            } else if cleanedText.hasPrefix("```") {
                cleanedText = String(cleanedText.dropFirst(3))
            }
            if cleanedText.hasSuffix("```") {
                cleanedText = String(cleanedText.dropLast(3))
            }
            cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)

            guard let parsed = try? JSONSerialization.jsonObject(with: cleanedText.data(using: .utf8) ?? Data()) as? [String: Any] else { return nil }

            return parseRemoteJSONToAnalysis(parsed: parsed, detectedUrl: detectedUrl, source: "Auto-filled by Claude (\(settings.claudeModel))")
        }
        return nil
    }

    private static func parseRemoteJSONToAnalysis(parsed: [String: Any], detectedUrl: String?, source: String) -> OnDeviceCaptureAnalysis {
        let title = (parsed["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let ct = (parsed["contentType"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let summary = (parsed["summary"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let formattedTask = (parsed["formattedTaskContent"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let tags = (parsed["tags"] as? [String]) ?? []
        let coll = (parsed["collectionName"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

        var retDate: Date? = nil
        if let iso = parsed["returnDateISO"] as? String, !iso.isEmpty {
            retDate = ISO8601DateFormatter().date(from: iso)
        }
        if retDate == nil, let dateStr = parsed["returnDate"] as? String, !dateStr.isEmpty {
            retDate = deduceBestReturnDate(from: dateStr, contentType: ct ?? "")
        }

        return OnDeviceCaptureAnalysis(
            title: title?.isEmpty == false ? title : nil,
            summary: summary?.isEmpty == false ? summary : nil,
            contentType: ct?.isEmpty == false ? ct : nil,
            tags: tags,
            collectionName: coll?.isEmpty == false ? coll : nil,
            returnAt: retDate,
            detectedUrl: detectedUrl,
            sourceDescription: source,
            formattedTaskContent: formattedTask?.isEmpty == false ? formattedTask : nil
        )
    }

    static func classifyTaskOrNotes(content: String) -> (isTask: Bool, title: String?, taskLines: [String]) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return (false, nil, []) }
        let lines = trimmed.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }

        var taskLines: [String] = []
        var headerTitle: String? = nil
        let taskBulletRegex = try? NSRegularExpression(pattern: #"^(?:[-*•]|\d+[.)]|\[[ xX]?\])\s+(.+)$"#)

        for (index, line) in lines.enumerated() {
            let nsLine = line as NSString
            if let match = taskBulletRegex?.firstMatch(in: line, range: NSRange(location: 0, length: nsLine.length)), match.numberOfRanges > 1 {
                let text = nsLine.substring(with: match.range(at: 1))
                taskLines.append(text)
            } else if index == 0 && lines.count > 1 && (line.hasSuffix(":") || line.lowercased().contains("to-do") || line.lowercased().contains("todo") || line.lowercased().contains("buy") || line.lowercased().contains("shopping")) {
                headerTitle = line.trimmingCharacters(in: CharacterSet(charactersIn: ": \t"))
            }
        }

        if taskLines.count >= 2 || (taskLines.count >= 1 && headerTitle != nil) {
            let defaultTitle = headerTitle ?? (taskLines.first.map { "To-Do: \($0)" }) ?? "Tasks"
            return (true, defaultTitle, taskLines)
        }

        let actionVerbs = [
            "buy", "purchase", "order", "pick up", "get", "need", "call", "email", "text", "message",
            "schedule", "book", "reserve", "fix", "clean", "organize", "pack", "send", "submit", "pay",
            "finish", "complete", "prepare", "review", "read", "watch", "study", "todo", "to-do", "task"
        ]

        if lines.count == 1 {
            let lower = trimmed.lowercased()
            let startsWithAction = actionVerbs.contains { verb in
                lower.hasPrefix(verb + " ") || lower == verb
            }
            let hasFutureTime = lower.contains("tomorrow") || lower.contains("tonight") || lower.contains("next week") || lower.contains("by friday") || lower.contains("by monday") || lower.contains("in ") || lower.contains("at ") || lower.contains("on ")

            if startsWithAction || (hasFutureTime && actionVerbs.contains { lower.contains($0) }) {
                return (true, trimmed, [trimmed])
            }
        }

        return (false, nil, [])
    }

    static func deduceCaptureIntent(
        content: String,
        detectedUrl: String?,
        attachments: [SharedAttachment],
        enrichedTitle: String?,
        enrichedSummary: String?,
        enrichedContentType: String?
    ) -> (
        dominantType: String,
        suggestedTitle: String?,
        suggestedNotes: String?,
        formattedTask: String?,
        actionTags: [String],
        bestReturnDate: Date?
    ) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        var userTextWithoutUrl = trimmed
        if let detectedUrl {
            userTextWithoutUrl = userTextWithoutUrl.replacingOccurrences(of: detectedUrl, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let lower = trimmed.lowercased()
        let lowerUrl = (detectedUrl ?? "").lowercased()

        let hasVideo = lowerUrl.contains("youtube.com") || lowerUrl.contains("youtu.be") || lowerUrl.contains("vimeo.com") || lowerUrl.contains("tiktok.com") || lowerUrl.contains("twitch.tv") ||
            attachments.contains { $0.name.lowercased().hasSuffix(".mp4") || $0.name.lowercased().hasSuffix(".mov") } ||
            enrichedContentType == "video"

        let hasArticle = lowerUrl.contains("medium.com") || lowerUrl.contains("substack.com") || lowerUrl.contains("blog") || lowerUrl.contains("article") || lowerUrl.contains(".pdf") ||
            attachments.contains { $0.name.lowercased().hasSuffix(".pdf") || $0.name.lowercased().hasSuffix(".doc") } ||
            enrichedContentType == "article"

        let hasMusic = lowerUrl.contains("spotify.com") || lowerUrl.contains("music.apple.com") || lowerUrl.contains("soundcloud.com") ||
            attachments.contains { $0.name.lowercased().hasSuffix(".mp3") || $0.name.lowercased().hasSuffix(".m4a") } ||
            enrichedContentType == "music"

        let taskAnalysis = classifyTaskOrNotes(content: trimmed)

        let watchPhrases = ["watch", "watch later", "see video", "check out video", "tutorial", "stream"]
        let readPhrases = ["read", "read later", "check article", "finish reading", "study", "skim"]
        let buyPhrases = ["buy", "order", "groceries", "grocery", "shopping", "pick up", "purchase", "store list", "supermarket"]
        let reviewPhrases = ["review", "feedback", "inspect", "prepare", "sign", "fill out", "check", "fix", "update", "finish", "test", "submit"]

        let hasWatchPhrasing = watchPhrases.contains { lower.contains($0) }
        let hasReadPhrasing = readPhrases.contains { lower.contains($0) }
        let hasBuyPhrasing = buyPhrases.contains { lower.contains($0) }
        let hasReviewPhrasing = reviewPhrases.contains { lower.contains($0) }

        var dominantType = "note"
        var title: String? = nil
        var notes: String? = nil
        var formattedTask: String? = nil
        var actionTags: [String] = []

        if taskAnalysis.isTask && !taskAnalysis.taskLines.isEmpty {
            dominantType = "task"
            actionTags.append("task")
            actionTags.append("todo")
            if hasBuyPhrasing { actionTags.append("shopping") }

            var lines = taskAnalysis.taskLines.map { line -> String in
                if line.hasPrefix("- [ ]") || line.hasPrefix("- [x]") { return line }
                return "- [ ] \(line)"
            }
            if let detectedUrl {
                lines.append("Source: \(detectedUrl)")
            }
            formattedTask = lines.joined(separator: "\n")
            notes = formattedTask

            if let taskTitle = taskAnalysis.title, !taskTitle.isEmpty {
                title = taskTitle
            } else if let enriched = enrichedTitle, !isGenericTitle(enriched) {
                title = enriched
            }
        } else if hasVideo && (hasWatchPhrasing || taskAnalysis.isTask || !userTextWithoutUrl.isEmpty) {
            dominantType = "task"
            actionTags.append(contentsOf: ["task", "video", "watch-later"])

            let cleanTitle = enrichedTitle ?? "Video"
            if !userTextWithoutUrl.isEmpty && !userTextWithoutUrl.localizedCaseInsensitiveContains(cleanTitle) {
                let firstLine = userTextWithoutUrl.components(separatedBy: .newlines).first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                title = firstLine.prefix(60).isEmpty ? "Watch: \(cleanTitle)" : String(firstLine.prefix(60))
            } else {
                title = "Watch: \(cleanTitle)"
            }

            var taskItems: [String] = ["- [ ] Watch \(cleanTitle)"]
            if let url = detectedUrl { taskItems.append("Video: \(url)") }
            if !userTextWithoutUrl.isEmpty { taskItems.append("\nNote: \(userTextWithoutUrl)") }
            formattedTask = taskItems.joined(separator: "\n")
            notes = formattedTask
        } else if (hasArticle || detectedUrl != nil) && (hasReadPhrasing || hasReviewPhrasing) {
            dominantType = "task"
            actionTags.append(contentsOf: ["task", "reading", "read-later"])

            let cleanTitle = enrichedTitle ?? "Article"
            title = "Read: \(cleanTitle)"

            var taskItems: [String] = ["- [ ] Read \(cleanTitle)"]
            if let url = detectedUrl { taskItems.append("Link: \(url)") }
            if !userTextWithoutUrl.isEmpty { taskItems.append("\nNote: \(userTextWithoutUrl)") }
            formattedTask = taskItems.joined(separator: "\n")
            notes = formattedTask
        } else if hasBuyPhrasing {
            dominantType = "task"
            actionTags.append(contentsOf: ["task", "shopping", "todo"])

            let cleanTitle = enrichedTitle ?? (userTextWithoutUrl.isEmpty ? "Shopping List" : userTextWithoutUrl)
            title = enrichedTitle != nil ? "Buy items for \(cleanTitle)" : (userTextWithoutUrl.isEmpty ? "Shopping List" : String(userTextWithoutUrl.prefix(60)))

            var taskItems: [String] = []
            if !userTextWithoutUrl.isEmpty {
                let lines = userTextWithoutUrl.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                for l in lines { taskItems.append("- [ ] \(l)") }
            } else {
                taskItems.append("- [ ] Purchase \(cleanTitle)")
            }
            if let url = detectedUrl { taskItems.append("Ref: \(url)") }
            formattedTask = taskItems.joined(separator: "\n")
            notes = formattedTask
        } else if !attachments.isEmpty && (hasReviewPhrasing || taskAnalysis.isTask) {
            dominantType = "task"
            actionTags.append(contentsOf: ["task", "review", "work"])

            let attName = attachments.first?.name ?? "Attachment"
            title = !userTextWithoutUrl.isEmpty ? String(userTextWithoutUrl.prefix(60)) : "Review \(attName)"
            formattedTask = "- [ ] Review \(attName)\nAttached file: \(attName)"
            notes = formattedTask
        } else if taskAnalysis.isTask {
            dominantType = "task"
            actionTags.append(contentsOf: ["task", "todo"])

            let taskText = taskAnalysis.title ?? userTextWithoutUrl
            title = taskText
            formattedTask = "- [ ] \(taskText)"
            notes = formattedTask
        } else {
            if hasVideo {
                dominantType = "video"
                actionTags.append("video")
            } else if hasMusic {
                dominantType = "music"
                actionTags.append("music")
            } else if hasArticle {
                dominantType = "article"
                actionTags.append("reading")
            } else if !attachments.isEmpty {
                let name = attachments.first!.name.lowercased()
                dominantType = (name.hasSuffix(".jpg") || name.hasSuffix(".png") || name.hasSuffix(".heic")) ? "image" : "document"
            } else if detectedUrl != nil {
                dominantType = enrichedContentType ?? "link"
            } else {
                dominantType = "note"
            }

            title = enrichedTitle ?? (userTextWithoutUrl.isEmpty ? (attachments.first?.name ?? "Saved Item") : String(userTextWithoutUrl.prefix(70)))
            notes = enrichedSummary ?? (!userTextWithoutUrl.isEmpty ? userTextWithoutUrl : nil)
        }

        let bestDate = deduceBestReturnDate(
            from: trimmed,
            contentType: dominantType,
            hasVideo: hasVideo,
            hasArticle: hasArticle
        )

        return (
            dominantType: dominantType,
            suggestedTitle: title,
            suggestedNotes: notes,
            formattedTask: formattedTask,
            actionTags: actionTags,
            bestReturnDate: bestDate
        )
    }

    static func deduceBestReturnDate(
        from text: String,
        contentType: String,
        hasVideo: Bool = false,
        hasArticle: Bool = false
    ) -> Date? {
        let lower = text.lowercased()
        let calendar = Calendar.current
        let now = Date()

        if let match = try? NSRegularExpression(pattern: #"(?i)\bin\s+(\d+)\s*(hours?|hrs?|h)\b"#).firstMatch(in: lower, range: NSRange(location: 0, length: (lower as NSString).length)), match.numberOfRanges >= 2 {
            let numStr = (lower as NSString).substring(with: match.range(at: 1))
            if let h = Double(numStr) { return now.addingTimeInterval(h * 3600) }
        }
        if let match = try? NSRegularExpression(pattern: #"(?i)\bin\s+(\d+)\s*(minutes?|mins?|m)\b"#).firstMatch(in: lower, range: NSRange(location: 0, length: (lower as NSString).length)), match.numberOfRanges >= 2 {
            let numStr = (lower as NSString).substring(with: match.range(at: 1))
            if let m = Double(numStr) { return now.addingTimeInterval(m * 60) }
        }
        if let match = try? NSRegularExpression(pattern: #"(?i)\bin\s+(\d+)\s*(days?|d)\b"#).firstMatch(in: lower, range: NSRange(location: 0, length: (lower as NSString).length)), match.numberOfRanges >= 2 {
            let numStr = (lower as NSString).substring(with: match.range(at: 1))
            if let d = Int(numStr) {
                let target = calendar.date(byAdding: .day, value: d, to: now) ?? now
                return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: target) ?? target
            }
        }
        if let match = try? NSRegularExpression(pattern: #"(?i)\bin\s+(\d+)\s*(weeks?|w)\b"#).firstMatch(in: lower, range: NSRange(location: 0, length: (lower as NSString).length)), match.numberOfRanges >= 2 {
            let numStr = (lower as NSString).substring(with: match.range(at: 1))
            if let w = Int(numStr) {
                let target = calendar.date(byAdding: .day, value: w * 7, to: now) ?? now
                return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: target) ?? target
            }
        }

        if lower.contains("tonight") || lower.contains("this evening") {
            let hour = calendar.component(.hour, from: now)
            if hour < 20 {
                return calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now)
            } else {
                return now.addingTimeInterval(7200)
            }
        } else if lower.contains("tomorrow morning") || lower.contains("tomorrow am") {
            return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now.addingTimeInterval(86400))
        } else if lower.contains("tomorrow afternoon") || lower.contains("tomorrow pm") {
            return calendar.date(bySettingHour: 14, minute: 0, second: 0, of: now.addingTimeInterval(86400))
        } else if lower.contains("tomorrow night") || lower.contains("tomorrow evening") {
            return calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now.addingTimeInterval(86400))
        } else if lower.contains("tomorrow") {
            return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now.addingTimeInterval(86400))
        } else if lower.contains("this weekend") || lower.contains("over the weekend") || lower.contains("saturday") {
            return calendar.nextDate(after: now, matching: DateComponents(hour: 10, weekday: 7), matchingPolicy: .nextTime)
        } else if lower.contains("sunday") {
            return calendar.nextDate(after: now, matching: DateComponents(hour: 10, weekday: 1), matchingPolicy: .nextTime)
        } else if lower.contains("next week") {
            return calendar.date(byAdding: .day, value: 7, to: now)
        }

        let daysOfWeek = [
            ("monday", 2), ("tuesday", 3), ("wednesday", 4),
            ("thursday", 5), ("friday", 6)
        ]
        for (dayName, weekdayNum) in daysOfWeek {
            if lower.contains("by \(dayName)") || lower.contains("on \(dayName)") || lower.contains("before \(dayName)") || lower.contains("this \(dayName)") {
                if let nextDay = calendar.nextDate(after: now, matching: DateComponents(hour: 9, weekday: weekdayNum), matchingPolicy: .nextTime) {
                    return nextDay
                }
            }
        }

        if let parsedRel = RelativeDateParser.parse(text, now: now) {
            return parsedRel.date
        }

        if contentType == "task" {
            return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now.addingTimeInterval(86400))
        }
        if hasVideo {
            let hour = calendar.component(.hour, from: now)
            if hour < 20 {
                return calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now)
            } else {
                return calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now.addingTimeInterval(86400))
            }
        }
        if hasArticle {
            return calendar.nextDate(after: now, matching: DateComponents(hour: 10, weekday: 7), matchingPolicy: .nextTime)
        }

        return nil
    }
}


@available(iOS 18.0, *)
enum QuickSaveControlDestination: String, AppEnum {
    case quickSave

    static var typeDisplayRepresentation = TypeDisplayRepresentation("LaterBox Screen")
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .quickSave: "Quick Save"
    ]
}

@available(iOS 18.0, *)
struct OpenQuickSaveControlIntent: OpenIntent {
    static var title: LocalizedStringResource = "Open LaterBox Quick Save"

    @Parameter(title: "Destination")
    var target: QuickSaveControlDestination

    init() {
        target = .quickSave
    }

    func perform() async throws -> some IntentResult {
        UserDefaults(suiteName: "group.pro.micorp.laterbox")?
            .set(true, forKey: "openQuickSaveFromControl")
        return .result()
    }
}
