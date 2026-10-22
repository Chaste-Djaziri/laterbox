import Foundation
import UniformTypeIdentifiers

struct AIAction: Codable {
    var intent: String
    var reply: String
    var content: String
    var title: String
    var category: String
    var contentType: String
    var tags: [String]
    var summary: String
    var formattedContent: String
    var query: String
    var returnDate: String

    init(intent: String = "chat", reply: String = "", content: String = "", title: String = "", category: String = "", contentType: String = "", tags: [String] = [], summary: String = "", formattedContent: String = "", query: String = "", returnDate: String = "") {
        self.intent = intent; self.reply = reply; self.content = content; self.title = title; self.category = category
        self.contentType = contentType; self.tags = tags; self.summary = summary; self.formattedContent = formattedContent
        self.query = query; self.returnDate = returnDate
    }
}

struct CaptureDraft: Codable, Equatable {
    var id = UUID().uuidString
    var content = ""
    var title = ""
    var category = ""
    var collectionName: String?
    var contentType = ""
    var tags: [String] = []
    var summary = ""
    var formattedContent = ""
    var returnAt: Date?
    var siteName: String?
    var metadataDescription: String?
    var previewImageUrl: String?
    var faviconUrl: String?
    var attachments: [SharedAttachment] = []
    var url: String? { Self.detectURL(content) }
    var type: ItemContentType {
        if let specified = ItemContentType(rawValue: contentType) { return specified }
        if let first = attachments.first {
            let attachmentType = UTType(first.typeIdentifier)
            if attachmentType?.conforms(to: .movie) == true { return .video }
            if attachmentType?.conforms(to: .audio) == true { return .music }
            if attachmentType?.conforms(to: .image) == true { return .image }
            if attachmentType?.conforms(to: .pdf) == true ||
               attachmentType?.conforms(to: .text) == true { return .document }
            let name = first.name.lowercased()
            if [".jpg", ".jpeg", ".png", ".heic", ".webp"].contains(where: name.hasSuffix) { return .image }
            if [".pdf", ".doc", ".docx", ".txt"].contains(where: name.hasSuffix) { return .document }
            return .file
        }
        guard let url else { return .note }
        let host = URL(string: url)?.host?.lowercased() ?? ""
        if ["youtube.com", "youtu.be", "vimeo.com"].contains(where: { host == $0 || host.hasSuffix("." + $0) }) { return .video }
        if ["spotify.com", "music.apple.com", "soundcloud.com"].contains(where: { host == $0 || host.hasSuffix("." + $0) }) { return .music }
        if URL(string: url)?.path.lowercased().hasSuffix(".pdf") == true { return .document }
        if ["medium.com", "substack.com"].contains(where: { host == $0 || host.hasSuffix("." + $0) }) { return .article }
        return .link
    }
    static func detectURL(_ text: String) -> String? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue),
              let url = detector.firstMatch(in: text, range: NSRange(text.startIndex..., in: text))?.url,
              ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { return nil }
        return url.absoluteString
    }
    /// Normalize Share Extension and Shortcut payloads into the same capture model.
    static func fromShared(_ capture: SharedCapture) -> CaptureDraft {
        var draft = CaptureDraft()
        draft.id = capture.id
        draft.content = capture.content
        draft.title = capture.title
        draft.tags = capture.tags
        draft.category = capture.category
        let collection = capture.category.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.collectionName = collection.isEmpty ? nil : collection
        draft.returnAt = capture.returnAt
        draft.attachments = capture.attachments
        draft.previewImageUrl = capture.previewImageUrl
        draft.siteName = capture.siteName
        draft.metadataDescription = capture.metadataDescription
        return draft
    }

    static func manual(_ content: String) -> CaptureDraft {
        var draft = CaptureDraft(content: content)
        draft.title = String(content.split(separator: "\n").first.map(String.init)?.prefix(100) ?? "".prefix(100))
        if let url = draft.url { draft.title = URL(string: url)?.host ?? url }
        draft.tags = content.split(whereSeparator: \.isWhitespace).filter { $0.hasPrefix("#") }.map { String($0.dropFirst()) }
        return draft
    }
    static func weekend(now: Date = Date(), calendar: Calendar = .current) -> Date {
        calendar.nextDate(after: now, matching: DateComponents(hour: 9, weekday: 7), matchingPolicy: .nextTime) ?? now
    }
}

@MainActor
protocol LaterAIProvider { func respond(_ prompt: String) async throws -> AIAction }

/// Offline response engine used while hosted and on-device AI providers are deferred.
@MainActor
struct DeterministicLaterAIProvider: LaterAIProvider {
    func respond(_ prompt: String) async throws -> AIAction {
        let input = prompt.components(separatedBy: "Current input:\n").last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? prompt
        if input.lowercased().hasPrefix("search ") || input.lowercased().hasPrefix("find ") {
            let query = input.split(separator: " ", maxSplits: 1).dropFirst().joined(separator: " ")
            return AIAction(intent: "search", reply: "I’ll search your saved items for \(query).", query: query)
        }
        let content = input
        let url = CaptureDraft.detectURL(content)
        let title = url.flatMap { URL(string: $0)?.host } ?? String(content.split(separator: "\n").first.map(String.init)?.prefix(100) ?? "Saved item")
        let tags = CaptureDraft.manual(content).tags
        return AIAction(intent: "capture", reply: "I’m ready to save this as \(title).", content: content, title: title, category: url == nil ? "Notes" : "Links", contentType: url == nil ? "note" : "link", tags: tags, summary: String(content.prefix(220)), formattedContent: content)
    }
}

enum AIProviderError: LocalizedError {
    case remoteDisabled, remoteFailed, invalidCapture, missingApiKey(String), customModelError(String)
    var errorDescription: String? {
        switch self {
        case .remoteDisabled: return "Gemini fallback is disabled."
        case .remoteFailed: return "Gemini could not complete the request."
        case .invalidCapture: return "No valid content was prepared. Continue manually to preserve your input."
        case .missingApiKey(let provider): return "Missing API key for \(provider). Please add your key in Settings."
        case .customModelError(let msg): return msg
        }
    }
}

struct SearchInterpretation: Codable {
    var terms: String
    var contentType: String
    var returnWindow: String
}
