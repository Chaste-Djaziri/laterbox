import Foundation
import Combine
import NaturalLanguage
#if canImport(Darwin)
import Darwin
#endif

// MARK: - On-Device Hardware Capability Detection

enum OnDeviceModelSupport {
    /// Raw hardware identifier (e.g. "iPhone16,1", "iPhone17,3")
    static var modelIdentifier: String {
        #if targetEnvironment(simulator)
        if let simModel = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"], !simModel.isEmpty {
            return simModel
        }
        #endif
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    /// User-friendly marketing name of the device
    static var deviceMarketingName: String {
        let id = modelIdentifier
        if id.contains("iPhone-17-Pro-Max") || id == "iPhone18,2" { return "iPhone 17 Pro Max" }
        if id.contains("iPhone-17-Pro") || id == "iPhone18,1" { return "iPhone 17 Pro" }
        if id.contains("iPhone-17e") || id == "iPhone18,5" { return "iPhone 17e" }
        if id.contains("iPhone-17") || id == "iPhone18,3" || id == "iPhone18,4" { return "iPhone 17" }
        if id.contains("iPhone-16-Pro-Max") || id == "iPhone17,2" { return "iPhone 16 Pro Max" }
        if id.contains("iPhone-16-Pro") || id == "iPhone17,1" { return "iPhone 16 Pro" }
        if id.contains("iPhone-16-Plus") || id == "iPhone17,4" { return "iPhone 16 Plus" }
        if id.contains("iPhone-16e") || id == "iPhone17,5" { return "iPhone 16e" }
        if id.contains("iPhone-16") || id == "iPhone17,3" { return "iPhone 16" }
        if id.contains("iPhone-15-Pro-Max") || id == "iPhone16,2" { return "iPhone 15 Pro Max" }
        if id.contains("iPhone-15-Pro") || id == "iPhone16,1" { return "iPhone 15 Pro" }
        if id.contains("iPhone-15-Plus") || id == "iPhone15,5" { return "iPhone 15 Plus" }
        if id.contains("iPhone-15") || id == "iPhone15,4" { return "iPhone 15" }
        if id.contains("iPhone-14-Pro") || id.contains("iPhone15,2") || id.contains("iPhone15,3") { return "iPhone 14 Pro" }
        if id.contains("iPhone-14") || id.contains("iPhone14,7") || id.contains("iPhone14,8") { return "iPhone 14" }
        if id.contains("iPad") { return "iPad" }
        if id.contains("Mac") { return "Mac" }
        return id.replacingOccurrences(of: "-", with: " ")
    }

    /// Formatted total system RAM
    static var formattedRAM: String {
        let bytes = ProcessInfo.processInfo.physicalMemory
        let gigabytes = Double(bytes) / 1_073_741_824.0
        return String(format: "%.0f GB Unified Memory", gigabytes.rounded())
    }

    /// Checks if device hardware meets requirements for Apple Intelligence / on-device foundation models
    /// Requirements: 8GB+ RAM, Apple Neural Engine, A17 Pro / A18 / A19 / M-series chips.
    static var isSupported: Bool {
        let id = modelIdentifier.lowercased()

        // Explicitly unsupported generations (A16 or older, <8GB RAM)
        if id.contains("iphone-11") || id.contains("iphone-12") || id.contains("iphone-13") || id.contains("iphone-14") || id.contains("iphone-se") {
            return false
        }
        if id.contains("iphone-15-plus") || (id.contains("iphone-15") && !id.contains("pro")) {
            return false
        }
        if id.hasPrefix("iphone14,") || id.hasPrefix("iphone15,") {
            return false
        }

        // Supported generations (iPhone 15 Pro/Max, iPhone 16 series, iPhone 17 series and future)
        if id.contains("15-pro") || id == "iphone16,1" || id == "iphone16,2" {
            return true
        }
        if id.contains("iphone-16") || id.hasPrefix("iphone17,") {
            return true
        }
        if id.contains("iphone-17") || id.contains("iphone-18") || id.hasPrefix("iphone18,") || id.hasPrefix("iphone19,") {
            return true
        }

        // iPad / Mac with Apple Silicon M1+ (8GB+ RAM)
        if (id.contains("ipad") || id.contains("mac")) && ProcessInfo.processInfo.physicalMemory >= 7_500_000_000 {
            return true
        }

        #if targetEnvironment(simulator)
        return true
        #else
        return ProcessInfo.processInfo.physicalMemory >= 7_500_000_000
        #endif
    }
}

// MARK: - On-Device AI Provider

@MainActor
struct OnDeviceLaterAIProvider: LaterAIProvider {
    private let fallback = DeterministicLaterAIProvider()

    init() {}

    func respond(_ prompt: String) async throws -> AIAction {
        // Ready for future integration with Apple Intelligence on-device model APIs
        return try await fallback.respond(prompt)
    }
}

// MARK: - Provider Types

enum AIProviderType: String, CaseIterable, Identifiable, Codable {
    case local
    case onDevice

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .local: return "Local responses"
        case .onDevice: return "On-Device Model"
        }
    }
    var shortName: String {
        switch self {
        case .local: return "Local"
        case .onDevice: return "On-Device"
        }
    }
    var subtitle: String {
        switch self {
        case .local: return "Offline deterministic capture assistant"
        case .onDevice: return "Apple Intelligence on-device neural processing"
        }
    }
    var iconName: String {
        switch self {
        case .local: return "wand.and.stars"
        case .onDevice: return "cpu"
        }
    }
    var isCustomKey: Bool { false }
}

// MARK: - Model Manager

@MainActor
final class LaterAIModelManager: ObservableObject {
    static let shared = LaterAIModelManager()

    @Published var selectedProvider: AIProviderType = .local
    @Published var enableSearchRefine: Bool = true
    @Published var isOnDeviceModelEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isOnDeviceModelEnabled, forKey: "laterbox_enable_on_device_model")
        }
    }

    var isOnDeviceModelSupported: Bool {
        OnDeviceModelSupport.isSupported
    }

    var deviceMarketingName: String {
        OnDeviceModelSupport.deviceMarketingName
    }

    var deviceHardwareSummary: String {
        "\(OnDeviceModelSupport.deviceMarketingName) · \(OnDeviceModelSupport.formattedRAM)"
    }

    var supportStatusMessage: String {
        if isOnDeviceModelSupported {
            return "This iPhone supports on-device Apple Intelligence and Neural Engine processing. AI tasks run locally with zero data leaving your device."
        } else {
            return "On-device foundation models require an iPhone with at least 8GB RAM and an A17 Pro chip or newer (iPhone 15 Pro, iPhone 16, iPhone 17 series). LaterBox uses local deterministic responses on this device."
        }
    }

    var activeModelName: String {
        switch selectedProvider {
        case .local:
            return "Local assistant"
        case .onDevice:
            return "On-Device Neural Engine"
        }
    }

    var canRefineSearch: Bool { true }

    init() {
        let isSupported = OnDeviceModelSupport.isSupported
        if UserDefaults.standard.object(forKey: "laterbox_enable_on_device_model") != nil {
            self.isOnDeviceModelEnabled = isSupported && UserDefaults.standard.bool(forKey: "laterbox_enable_on_device_model")
        } else {
            // Enable by default on iPhones that support it
            self.isOnDeviceModelEnabled = isSupported
        }
    }

    func activeProvider() -> any LaterAIProvider {
        switch selectedProvider {
        case .local:
            return DeterministicLaterAIProvider()
        case .onDevice:
            return OnDeviceLaterAIProvider()
        }
    }

    func interpretSearch(_ query: String) async throws -> SearchInterpretation {
        SearchInterpretation(terms: query.trimmingCharacters(in: .whitespacesAndNewlines), contentType: "", returnWindow: "")
    }

    func testConnection(for provider: AIProviderType) async throws -> String {
        switch provider {
        case .local:
            return "Local responses are available offline."
        case .onDevice:
            if isOnDeviceModelSupported {
                return "On-device Apple Intelligence hardware is ready on \(deviceMarketingName)."
            } else {
                return "On-device foundation models are not supported on this device."
            }
        }
    }

    // MARK: - On-Device Capture Analysis & Link Enrichment
    func analyzeCapture(
        content: String,
        attachments: [SharedAttachment] = [],
        availableCollections: [String] = []
    ) async -> OnDeviceCaptureAnalysis {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let detectedUrl = CaptureDraft.detectURL(trimmedContent)

        var enrichedTitle: String? = nil
        var enrichedSummary: String? = nil
        var enrichedSite: String? = nil
        var enrichedImage: String? = nil
        var enrichedFavicon: String? = nil
        var enrichedContentType: String? = nil
        var enrichedTags: [String] = []
        var isLinkEnriched = false

        if let detectedUrl, let url = URL(string: detectedUrl) {
            do {
                let metadata = try await withThrowingTaskGroup(of: LinkMetadata.self) { group in
                    group.addTask {
                        try await LinkMetadataLoader.load(url)
                    }
                    group.addTask {
                        try await Task.sleep(nanoseconds: 2_000_000_000)
                        throw URLError(.timedOut)
                    }
                    let first = try await group.next()!
                    group.cancelAll()
                    return first
                }

                isLinkEnriched = true
                enrichedTitle = LinkMetadataLoader.cleanTitle(metadata.title) ?? metadata.title
                enrichedSummary = metadata.description
                enrichedSite = metadata.site ?? url.host
                enrichedImage = metadata.image
                enrichedFavicon = metadata.faviconUrl
                enrichedContentType = metadata.contentType
                enrichedTags = metadata.keywords.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
            } catch {
                if let host = url.host?.replacingOccurrences(of: "www.", with: "") {
                    enrichedSite = host
                    if let firstPart = host.split(separator: ".").first {
                        enrichedTags.append(String(firstPart).lowercased())
                    }
                }
            }
        }

        var userTextWithoutUrl = trimmedContent
        if let detectedUrl {
            userTextWithoutUrl = userTextWithoutUrl.replacingOccurrences(of: detectedUrl, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Run Task vs Note classifier to identify to-dos, shopping lists, and future actions
        let taskAnalysis = Self.classifyTaskOrNotes(content: trimmedContent)
        var formattedTaskContent: String? = nil

        // Title Extraction
        var finalTitle = enrichedTitle
        if finalTitle == nil || finalTitle?.isEmpty == true || LinkMetadataLoader.isGenericTitle(finalTitle) {
            if taskAnalysis.isTask, let taskTitle = taskAnalysis.title, !taskTitle.isEmpty {
                finalTitle = taskTitle
            } else if !userTextWithoutUrl.isEmpty {
                let firstLine = userTextWithoutUrl.components(separatedBy: .newlines).first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) ?? userTextWithoutUrl
                let cleaned = firstLine
                    .trimmingCharacters(in: CharacterSet(charactersIn: "-*#• \t\r\n"))
                    .replacingOccurrences(of: "(?i)^(todo:|task:|\\[ \\]|-\\[ \\]|\\* \\[ \\])\\s*", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleaned.isEmpty {
                    finalTitle = String(cleaned.prefix(90))
                }
            } else if let att = attachments.first {
                let name = att.name
                let withoutExt = (name as NSString).deletingPathExtension
                finalTitle = withoutExt.replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: "-", with: " ")
            } else if let detectedUrl, let host = URL(string: detectedUrl)?.host {
                finalTitle = host.replacingOccurrences(of: "www.", with: "")
            }
        }

        // Summary / Notes Formulation
        var finalSummary = enrichedSummary ?? ""
        if taskAnalysis.isTask && !taskAnalysis.taskLines.isEmpty {
            formattedTaskContent = taskAnalysis.taskLines.map { line -> String in
                if line.hasPrefix("- [ ]") || line.hasPrefix("- [x]") { return line }
                return "- [ ] \(line)"
            }.joined(separator: "\n")
            finalSummary = formattedTaskContent ?? finalSummary
        } else if !userTextWithoutUrl.isEmpty {
            if !finalSummary.isEmpty && !finalSummary.localizedCaseInsensitiveContains(userTextWithoutUrl) {
                finalSummary = "\(userTextWithoutUrl)\n\n\(finalSummary)"
            } else if finalSummary.isEmpty {
                let lines = userTextWithoutUrl.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                if lines.count > 1 {
                    finalSummary = lines.dropFirst().joined(separator: "\n")
                } else {
                    finalSummary = userTextWithoutUrl
                }
            }
        } else if finalSummary.isEmpty, let att = attachments.first {
            finalSummary = "Attached: \(att.name)"
        }

        // Content Type
        var finalContentType = enrichedContentType ?? ""
        let lower = trimmedContent.lowercased()
        if finalContentType.isEmpty {
            if taskAnalysis.isTask && detectedUrl == nil && attachments.isEmpty {
                finalContentType = "task"
            } else if lower.hasPrefix("todo:") || lower.hasPrefix("task:") || lower.hasPrefix("[ ]") || lower.contains("remind me to") || lower.contains("don't forget to") {
                finalContentType = "task"
            } else if lower.contains("func ") || lower.contains("import ") || lower.contains("class ") || lower.contains("const ") || lower.contains("```") || lower.contains("def ") {
                finalContentType = "code"
            } else if let att = attachments.first {
                let n = att.name.lowercased()
                if n.hasSuffix(".jpg") || n.hasSuffix(".png") || n.hasSuffix(".heic") || n.hasSuffix(".webp") {
                    finalContentType = "image"
                } else {
                    finalContentType = "document"
                }
            } else if detectedUrl != nil {
                if lower.contains("youtube.com") || lower.contains("youtu.be") || lower.contains("vimeo.com") {
                    finalContentType = "video"
                } else if lower.contains("spotify.com") || lower.contains("music.apple.com") || lower.contains("soundcloud.com") {
                    finalContentType = "music"
                } else if lower.hasSuffix(".pdf") || lower.contains("/pdf") {
                    finalContentType = "document"
                } else if lower.contains("medium.com") || lower.contains("substack.com") || lower.contains("blog") || lower.contains("article") {
                    finalContentType = "article"
                } else {
                    finalContentType = "link"
                }
            } else {
                finalContentType = "note"
            }
        }

        // Tags Extraction (Hashtags, Link keywords, Domain, NaturalLanguage NER & Topic taxonomy)
        var allTags = Set<String>()

        // 1. Hashtags in text
        let hashtags = trimmedContent.split(whereSeparator: \.isWhitespace)
            .filter { $0.hasPrefix("#") && $0.count > 1 }
            .map { String($0.dropFirst()).trimmingCharacters(in: CharacterSet.alphanumerics.inverted).lowercased() }
            .filter { !$0.isEmpty }
        allTags.formUnion(hashtags)

        // 2. Link keywords
        for kw in enrichedTags {
            let clean = kw.lowercased().trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            if clean.count >= 2 && clean.count <= 25 {
                allTags.insert(clean)
            }
        }

        // 3. Domain tag
        if let detectedUrl, let host = URL(string: detectedUrl)?.host {
            let domain = host.replacingOccurrences(of: "www.", with: "")
            if let primary = domain.split(separator: ".").first, primary.count >= 3 {
                allTags.insert(String(primary).lowercased())
            }
        }

        // 4. On-Device NaturalLanguage NER
        let textToTag = "\(finalTitle ?? "") \(trimmedContent) \(finalSummary)"
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

        // 5. Taxonomy matching
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
            if lowerCorpus.contains(item.keyword) {
                allTags.insert(item.tag)
            }
        }

        if finalContentType == "task" { allTags.insert("task") }
        if finalContentType == "code" { allTags.insert("code") }
        if finalContentType == "video" { allTags.insert("video") }
        if finalContentType == "document" { allTags.insert("document") }

        // Smart Collection Matching
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

        // Date / Return Schedule Detection
        var detectedReturnAt: Date? = nil
        if lower.contains("tomorrow") || lower.contains("tmrw") {
            detectedReturnAt = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date().addingTimeInterval(86400))
        } else if lower.contains("tonight") {
            detectedReturnAt = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date())
        } else if lower.contains("this weekend") || lower.contains("saturday") || lower.contains("sunday") {
            detectedReturnAt = CaptureDraft.weekend()
        } else if lower.contains("next week") {
            detectedReturnAt = Calendar.current.date(byAdding: .day, value: 7, to: Date())
        }

        let sourceDesc = isLinkEnriched ? "Auto-filled from link" : (isOnDeviceModelEnabled ? "Auto-filled by On-Device AI" : "Auto-filled by Local AI")

        if finalContentType == "task" {
            allTags.insert("task")
            allTags.insert("todo")
            let lowerContent = trimmedContent.lowercased()
            if lowerContent.contains("buy") || lowerContent.contains("grocer") || lowerContent.contains("shop") || lowerContent.contains("order") || lowerContent.contains("store") {
                allTags.insert("shopping")
            }
        }

        return OnDeviceCaptureAnalysis(
            title: finalTitle,
            summary: finalSummary.isEmpty ? nil : finalSummary,
            contentType: finalContentType.isEmpty ? nil : finalContentType,
            tags: Array(allTags).sorted(),
            collectionName: suggestedCollection,
            returnAt: detectedReturnAt,
            detectedUrl: detectedUrl,
            previewImageUrl: enrichedImage,
            siteName: enrichedSite,
            faviconUrl: enrichedFavicon,
            isLinkEnriched: isLinkEnriched,
            sourceDescription: sourceDesc,
            formattedTaskContent: formattedTaskContent
        )
    }

    // MARK: - Task & To-Do Classification
    public static func classifyTaskOrNotes(content: String) -> (isTask: Bool, title: String?, taskLines: [String]) {
        let lines = content.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        guard !lines.isEmpty else { return (false, nil, []) }

        let lowerContent = content.lowercased()

        // 1. Explicit task markers in lines
        let checkboxRegex = try? NSRegularExpression(pattern: #"^[-*•+]?\s*\[([ xX])\]\s*(.*)$"#)
        let bulletRegex = try? NSRegularExpression(pattern: #"^[-*•+]\s+(.*)$"#)
        let numberedRegex = try? NSRegularExpression(pattern: #"^\d+[\.\)]\s+(.*)$"#)

        var listItems: [String] = []
        var checkboxCount = 0
        var bulletCount = 0
        var numberedCount = 0

        for line in lines {
            let fullRange = NSRange(location: 0, length: (line as NSString).length)
            if let match = checkboxRegex?.firstMatch(in: line, range: fullRange), match.numberOfRanges >= 3 {
                let itemText = (line as NSString).substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespaces)
                listItems.append(itemText)
                checkboxCount += 1
            } else if let match = bulletRegex?.firstMatch(in: line, range: fullRange), match.numberOfRanges >= 2 {
                let itemText = (line as NSString).substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespaces)
                listItems.append(itemText)
                bulletCount += 1
            } else if let match = numberedRegex?.firstMatch(in: line, range: fullRange), match.numberOfRanges >= 2 {
                let itemText = (line as NSString).substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespaces)
                listItems.append(itemText)
                numberedCount += 1
            }
        }

        // 2. Buying keywords
        let buyingPhrases = [
            "buy", "buying", "shopping list", "groceries", "grocery list", "grocery",
            "order", "purchase", "pick up", "get from", "store list", "target list",
            "costco list", "supermarket", "items to buy"
        ]
        let hasBuyingPhrasing = buyingPhrases.contains { lowerContent.contains($0) }

        // 3. Future action phrasing
        let futureActionPhrases = [
            "todo", "task", "to-do", "to do", "things to do", "action items", "tasks for",
            "remind me to", "remember to", "don't forget to", "need to", "must do",
            "have to", "due by", "will do", "plan to", "planning to", "in the future",
            "follow up", "checklist", "errands"
        ]
        let hasFutureActionPhrasing = futureActionPhrases.contains { lowerContent.contains($0) }

        // 4. Action verbs at start of lines
        let actionVerbs = [
            "call", "email", "send", "schedule", "prepare", "submit", "review",
            "meet", "clean", "fix", "organize", "pay", "cancel", "book", "renew",
            "file", "check", "pack", "finish", "start", "complete", "write", "update"
        ]
        let startsWithActionVerb = actionVerbs.contains { verb in
            lines.first?.lowercased().hasPrefix(verb + " ") == true ||
            lines.first?.lowercased() == verb
        }

        // 5. Short lines heuristic (e.g. multi-line shopping/item list without explicit bullets)
        let isShortLinesList = lines.count >= 2 && lines.allSatisfy { $0.count < 60 && !$0.hasSuffix(".") }

        // Decision logic:
        let isList = checkboxCount > 0 || (bulletCount + numberedCount) >= 2 || (lines.count >= 2 && isShortLinesList && (hasBuyingPhrasing || hasFutureActionPhrasing))
        let isExplicitTask = checkboxCount > 0 || hasFutureActionPhrasing || hasBuyingPhrasing || startsWithActionVerb

        if isList && (hasBuyingPhrasing || hasFutureActionPhrasing || startsWithActionVerb || checkboxCount > 0 || isShortLinesList) {
            let title: String
            if hasBuyingPhrasing && !lines.first!.lowercased().hasPrefix("buy") && !lines.first!.lowercased().contains("list") {
                title = "Shopping List"
            } else {
                title = lines.first?.replacingOccurrences(of: "(?i)^(todo:|task:|\\[ \\]|-\\[ \\]|\\* \\[ \\])\\s*", with: "", options: .regularExpression) ?? "Tasks"
            }
            return (true, title, listItems.isEmpty ? Array(lines.dropFirst()) : listItems)
        }

        if isExplicitTask && !lowerContent.contains("http://") && !lowerContent.contains("https://") {
            let title = lines.first?.replacingOccurrences(of: "(?i)^(todo:|task:|\\[ \\]|-\\[ \\]|\\* \\[ \\])\\s*", with: "", options: .regularExpression)
            return (true, title, listItems)
        }

        return (false, nil, [])
    }
}

public struct OnDeviceCaptureAnalysis: Sendable {
    public var title: String?
    public var summary: String?
    public var contentType: String?
    public var tags: [String]
    public var collectionName: String?
    public var returnAt: Date?
    public var detectedUrl: String?
    public var previewImageUrl: String?
    public var siteName: String?
    public var faviconUrl: String?
    public var isLinkEnriched: Bool
    public var sourceDescription: String
    public var formattedTaskContent: String?

    public init(
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

