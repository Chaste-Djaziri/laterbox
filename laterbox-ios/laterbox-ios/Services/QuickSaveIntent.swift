import Foundation
import AppIntents

public enum LaterBoxReturnPreset: String, AppEnum {
    case in10Minutes = "in10m"
    case in1Hour = "in1h"
    case tomorrow = "tomorrow"
    case thisWeekend = "weekend"
    case nextWeek = "nextWeek"
    case none = "none"

    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Return Time"

    public static var caseDisplayRepresentations: [LaterBoxReturnPreset: DisplayRepresentation] = [
        .in10Minutes: "In 10 Minutes",
        .in1Hour: "In 1 Hour",
        .tomorrow: "Tomorrow (9 AM)",
        .thisWeekend: "This Weekend",
        .nextWeek: "Next Week",
        .none: "No Reminder (Inbox)"
    ]

    public var targetDate: Date? {
        let now = Date()
        switch self {
        case .in10Minutes:
            return now.addingTimeInterval(600)
        case .in1Hour:
            return now.addingTimeInterval(3600)
        case .tomorrow:
            return Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: now.addingTimeInterval(86400)) ?? now.addingTimeInterval(86400)
        case .thisWeekend:
            return Calendar.current.nextDate(after: now, matching: DateComponents(hour: 9, weekday: 7), matchingPolicy: .nextTime) ?? now.addingTimeInterval(86400 * 2)
        case .nextWeek:
            return Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now.addingTimeInterval(86400 * 7)
        case .none:
            return nil
        }
    }
}

public struct QuickSaveIntent: AppIntent {
    public static var title: LocalizedStringResource = "Quick Save to LaterBox"
    public static var description = IntentDescription("Save a note, idea, or link to LaterBox directly without opening the app.")

    public static var openAppWhenRun: Bool = true

    @Parameter(title: "Note or URL", description: "What you would like to save to LaterBox")
    public var content: String?

    @Parameter(title: "Title", description: "Optional title for the item")
    public var title: String?

    @Parameter(title: "When to Return", description: "When to see this item back in your inbox")
    public var returnPreset: LaterBoxReturnPreset?

    public init() {}

    public init(content: String, title: String? = nil, returnPreset: LaterBoxReturnPreset? = nil) {
        self.content = content
        self.title = title
        self.returnPreset = returnPreset
    }

    public static var parameterSummary: some ParameterSummary {
        Summary("Save \(\.$content) to LaterBox") {
            \.$title
            \.$returnPreset
        }
    }

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let trimmed = content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmed.isEmpty {
            UserDefaults(suiteName: "group.pro.micorp.laterbox")?.set(true, forKey: "pendingOpenQuickSaveModal")
            NotificationCenter.default.post(name: NSNotification.Name("OpenQuickSaveModal"), object: nil)
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(150))
                NotificationCenter.default.post(name: NSNotification.Name("OpenQuickSaveModal"), object: nil)
            }
            return .result(dialog: "Opening Quick Save in LaterBox...")
        }

        var capture = SharedCapture()
        capture.content = trimmed

        // Extract URL if present
        var detectedUrl: String?
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue),
           let match = detector.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
           let matchUrl = match.url {
            detectedUrl = matchUrl.absoluteString
        }

        // Title resolution
        let customTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let customTitle, !customTitle.isEmpty {
            capture.title = customTitle
        } else if let firstLine = trimmed.components(separatedBy: .newlines).first, !firstLine.isEmpty {
            capture.title = String(firstLine.prefix(80))
        } else {
            capture.title = "Quick Note"
        }

        // Return schedule
        if let returnPreset {
            capture.returnAt = returnPreset.targetDate
        }

        // Category & tags
        if detectedUrl != nil {
            capture.category = "Reading"
            capture.tags = ["link", "quick-save"]
        } else {
            capture.category = "Inbox"
            capture.tags = ["note", "quick-save"]
        }

        do {
            try SharedCaptureStore.save(capture)
            if let returnAt = capture.returnAt {
                _ = try? await ReturnNotification.update(
                    id: capture.id,
                    title: capture.title,
                    description: capture.content,
                    date: returnAt
                )
            }

            let reminderText: String
            if let returnAt = capture.returnAt {
                reminderText = " (scheduled for \(returnAt.formatted(date: .abbreviated, time: .shortened)))"
            } else {
                reminderText = " to your Inbox"
            }

            return .result(dialog: "Saved ‘\(capture.title)’\(reminderText).")
        } catch {
            return .result(dialog: "Failed to save: \(error.localizedDescription)")
        }
    }
}

@available(iOS 18.0, *)
public struct QuickSaveControlIntent: AppIntent {
    public static var title: LocalizedStringResource = "Quick Save to LaterBox"
    public static var description = IntentDescription("Open the quick save input in LaterBox.")
    public static var openAppWhenRun: Bool = true

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & OpensIntent {
        UserDefaults(suiteName: "group.pro.micorp.laterbox")?.set(true, forKey: "pendingOpenQuickSaveModal")
        NotificationCenter.default.post(name: NSNotification.Name("OpenQuickSaveModal"), object: nil)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            NotificationCenter.default.post(name: NSNotification.Name("OpenQuickSaveModal"), object: nil)
        }
        let deepLink = URL(string: "laterbox://quick-save")!
        return .result(opensIntent: OpenURLIntent(deepLink))
    }
}
