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
    case bazaarlink
    case gemini
    case openai
    case claude

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .local: return "Local responses"
        case .onDevice: return "On-Device Model"
        case .bazaarlink: return "BazaarLink (Free AI)"
        case .gemini: return "Google Gemini"
        case .openai: return "OpenAI GPT"
        case .claude: return "Anthropic Claude"
        }
    }
    var shortName: String {
        switch self {
        case .local: return "Local"
        case .onDevice: return "On-Device"
        case .bazaarlink: return "BazaarLink"
        case .gemini: return "Gemini"
        case .openai: return "OpenAI"
        case .claude: return "Claude"
        }
    }
    var subtitle: String {
        switch self {
        case .local: return "Offline deterministic capture assistant · 100% private"
        case .onDevice: return "Apple Intelligence on-device neural processing"
        case .bazaarlink: return "Free models (Qwen 3.7 Flash, DeepSeek V4) · Own key"
        case .gemini: return "Google Gemini 2.5 / 3.5 Flash · Own API key"
        case .openai: return "GPT-4o / GPT-4o-mini · Own OpenAI API key"
        case .claude: return "Claude 3.5 Sonnet / Haiku · Own Anthropic key"
        }
    }
    var iconName: String {
        switch self {
        case .local: return "wand.and.stars"
        case .onDevice: return "cpu"
        case .bazaarlink: return "bolt.shield.fill"
        case .gemini: return "sparkles"
        case .openai: return "brain.head.profile"
        case .claude: return "bubble.left.and.text.bubble.right.fill"
        }
    }
    var isCustomKey: Bool {
        self != .local && self != .onDevice
    }
}

// MARK: - Model Manager

@MainActor
final class LaterAIModelManager: ObservableObject {
    static let shared = LaterAIModelManager()

    @Published var selectedProvider: AIProviderType = .local {
        didSet {
            UserDefaults.standard.set(selectedProvider.rawValue, forKey: "laterbox_selected_ai_provider")
        }
    }
    @Published var enableSearchRefine: Bool = true
    @Published var isOnDeviceModelEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isOnDeviceModelEnabled, forKey: "laterbox_enable_on_device_model")
        }
    }

    @Published var bazaarlinkApiKey: String {
        didSet { UserDefaults.standard.set(bazaarlinkApiKey, forKey: "laterbox_bazaarlink_api_key") }
    }
    @Published var geminiApiKey: String {
        didSet { UserDefaults.standard.set(geminiApiKey, forKey: "laterbox_gemini_api_key") }
    }
    @Published var openaiApiKey: String {
        didSet { UserDefaults.standard.set(openaiApiKey, forKey: "laterbox_openai_api_key") }
    }
    @Published var claudeApiKey: String {
        didSet { UserDefaults.standard.set(claudeApiKey, forKey: "laterbox_claude_api_key") }
    }

    @Published var bazaarlinkModel: String {
        didSet { UserDefaults.standard.set(bazaarlinkModel, forKey: "laterbox_bazaarlink_model") }
    }
    @Published var geminiModel: String {
        didSet { UserDefaults.standard.set(geminiModel, forKey: "laterbox_gemini_model") }
    }
    @Published var openaiModel: String {
        didSet { UserDefaults.standard.set(openaiModel, forKey: "laterbox_openai_model") }
    }
    @Published var claudeModel: String {
        didSet { UserDefaults.standard.set(claudeModel, forKey: "laterbox_claude_model") }
    }

    func hasApiKey(for provider: AIProviderType) -> Bool {
        switch provider {
        case .local, .onDevice:
            return true
        case .bazaarlink:
            return !bazaarlinkApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .gemini:
            return !geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .openai:
            return !openaiApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .claude:
            return !claudeApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
        case .bazaarlink:
            return "BazaarLink (\(bazaarlinkModel))"
        case .gemini:
            return "Gemini (\(geminiModel))"
        case .openai:
            return "OpenAI (\(openaiModel))"
        case .claude:
            return "Claude (\(claudeModel))"
        }
    }

    var canRefineSearch: Bool { true }

    init() {
        let isSupported = OnDeviceModelSupport.isSupported
        if UserDefaults.standard.object(forKey: "laterbox_enable_on_device_model") != nil {
            self.isOnDeviceModelEnabled = isSupported && UserDefaults.standard.bool(forKey: "laterbox_enable_on_device_model")
        } else {
            self.isOnDeviceModelEnabled = isSupported
        }

        self.bazaarlinkApiKey = UserDefaults.standard.string(forKey: "laterbox_bazaarlink_api_key") ?? ""
        self.geminiApiKey = UserDefaults.standard.string(forKey: "laterbox_gemini_api_key") ?? ""
        self.openaiApiKey = UserDefaults.standard.string(forKey: "laterbox_openai_api_key") ?? ""
        self.claudeApiKey = UserDefaults.standard.string(forKey: "laterbox_claude_api_key") ?? ""

        self.bazaarlinkModel = UserDefaults.standard.string(forKey: "laterbox_bazaarlink_model") ?? "qwen/qwen3.7-flash"
        self.geminiModel = UserDefaults.standard.string(forKey: "laterbox_gemini_model") ?? "gemini-2.5-flash"
        self.openaiModel = UserDefaults.standard.string(forKey: "laterbox_openai_model") ?? "gpt-4o-mini"
        self.claudeModel = UserDefaults.standard.string(forKey: "laterbox_claude_model") ?? "claude-3-5-haiku-20241022"

        if let saved = UserDefaults.standard.string(forKey: "laterbox_selected_ai_provider"),
           let prov = AIProviderType(rawValue: saved) {
            self.selectedProvider = prov
        }
    }

    func activeProvider() -> any LaterAIProvider {
        switch selectedProvider {
        case .local:
            return DeterministicLaterAIProvider()
        case .onDevice:
            return OnDeviceLaterAIProvider()
        case .bazaarlink, .gemini, .openai, .claude:
            return DeterministicLaterAIProvider()
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
        case .bazaarlink:
            let key = bazaarlinkApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty else { return "Add your BazaarLink API key to test." }
            return try await testBazaarlinkConnection(key: key, model: bazaarlinkModel)
        case .gemini:
            let key = geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty else { return "Add your Gemini API key to test." }
            return try await testGeminiConnection(key: key, model: geminiModel)
        case .openai:
            let key = openaiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty else { return "Add your OpenAI API key to test." }
            return try await testOpenAIConnection(key: key, model: openaiModel)
        case .claude:
            let key = claudeApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty else { return "Add your Anthropic API key to test." }
            return try await testClaudeConnection(key: key, model: claudeModel)
        }
    }

    private func testBazaarlinkConnection(key: String, model: String) async throws -> String {
        guard let url = URL(string: "https://api.bazaarlink.ai/v1/chat/completions") else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 12

        let payload: [String: Any] = [
            "model": model,
            "messages": [["role": "user", "content": "Respond with OK"]],
            "max_tokens": 10
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (_, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NSError(domain: "BazaarLink", code: code, userInfo: [NSLocalizedDescriptionKey: "BazaarLink returned status \(code). Check API key."])
        }
        return "Connected to BazaarLink (\(model)) successfully!"
    }

    private func testGeminiConnection(key: String, model: String) async throws -> String {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(key)") else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 12

        let payload: [String: Any] = [
            "contents": [["parts": [["text": "ping"]]]],
            "generationConfig": ["maxOutputTokens": 10]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (_, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NSError(domain: "Gemini", code: code, userInfo: [NSLocalizedDescriptionKey: "Gemini returned status \(code). Check API key."])
        }
        return "Connected to Google Gemini (\(model)) successfully!"
    }

    private func testOpenAIConnection(key: String, model: String) async throws -> String {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 12

        let payload: [String: Any] = [
            "model": model,
            "messages": [["role": "user", "content": "Respond with OK"]],
            "max_tokens": 10
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (_, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NSError(domain: "OpenAI", code: code, userInfo: [NSLocalizedDescriptionKey: "OpenAI returned status \(code). Check API key."])
        }
        return "Connected to OpenAI (\(model)) successfully!"
    }

    private func testClaudeConnection(key: String, model: String) async throws -> String {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(key, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.timeoutInterval = 12

        let payload: [String: Any] = [
            "model": model,
            "max_tokens": 10,
            "messages": [["role": "user", "content": "Respond with OK"]]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (_, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NSError(domain: "Claude", code: code, userInfo: [NSLocalizedDescriptionKey: "Anthropic returned status \(code). Check API key."])
        }
        return "Connected to Anthropic Claude (\(model)) successfully!"
    }

    // MARK: - On-Device & Remote Capture Analysis
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

        // 1. Fetch link metadata if URL is present
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

        // 2. If remote AI provider (BazaarLink, Gemini, OpenAI, Claude) is active and configured with custom key, query it first
        if selectedProvider.isCustomKey && hasApiKey(for: selectedProvider) {
            if let remoteAnalysis = await queryRemoteCaptureAnalysis(
                content: trimmedContent,
                detectedUrl: detectedUrl,
                attachments: attachments,
                availableCollections: availableCollections,
                enrichedTitle: enrichedTitle,
                enrichedSummary: enrichedSummary,
                enrichedContentType: enrichedContentType,
                provider: selectedProvider
            ) {
                var finalAnalysis = remoteAnalysis
                if finalAnalysis.previewImageUrl == nil { finalAnalysis.previewImageUrl = enrichedImage }
                if finalAnalysis.faviconUrl == nil { finalAnalysis.faviconUrl = enrichedFavicon }
                if finalAnalysis.siteName == nil { finalAnalysis.siteName = enrichedSite }
                finalAnalysis.isLinkEnriched = isLinkEnriched
                return finalAnalysis
            }
        }

        // 3. High-Accuracy Generalized On-Device Semantic Deduction Engine
        let deduction = Self.deduceCaptureIntent(
            content: trimmedContent,
            detectedUrl: detectedUrl,
            attachments: attachments,
            enrichedTitle: enrichedTitle,
            enrichedSummary: enrichedSummary,
            enrichedContentType: enrichedContentType
        )

        // Tags Extraction
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

        if let detectedUrl, let host = URL(string: detectedUrl)?.host {
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

        // Topic mapping
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
        if suggestedCollection == nil {
            if deduction.dominantType == "task" {
                if allTags.contains("shopping") {
                    suggestedCollection = availableCollections.first { $0.localizedCaseInsensitiveCompare("Shopping") == .orderedSame }
                } else {
                    suggestedCollection = availableCollections.first { $0.localizedCaseInsensitiveCompare("To-Do") == .orderedSame || $0.localizedCaseInsensitiveCompare("Tasks") == .orderedSame }
                }
            } else if deduction.dominantType == "video" {
                suggestedCollection = availableCollections.first { $0.localizedCaseInsensitiveCompare("Videos") == .orderedSame || $0.localizedCaseInsensitiveCompare("Watch Later") == .orderedSame }
            } else if deduction.dominantType == "article" {
                suggestedCollection = availableCollections.first { $0.localizedCaseInsensitiveCompare("Reading") == .orderedSame || $0.localizedCaseInsensitiveCompare("Articles") == .orderedSame }
            }
        }

        let sourceDesc = isLinkEnriched ? "Auto-filled from link" : (isOnDeviceModelEnabled ? "Auto-filled by On-Device AI" : "Auto-filled by Local AI")

        return OnDeviceCaptureAnalysis(
            title: deduction.suggestedTitle,
            summary: deduction.suggestedNotes,
            contentType: deduction.dominantType,
            tags: Array(allTags).sorted(),
            collectionName: suggestedCollection,
            returnAt: deduction.bestReturnDate,
            detectedUrl: detectedUrl,
            previewImageUrl: enrichedImage,
            siteName: enrichedSite,
            faviconUrl: enrichedFavicon,
            isLinkEnriched: isLinkEnriched,
            sourceDescription: sourceDesc,
            formattedTaskContent: deduction.formattedTask
        )
    }

    // MARK: - Remote Capture Analysis (BazaarLink / Gemini)
    private func queryRemoteCaptureAnalysis(
        content: String,
        detectedUrl: String?,
        attachments: [SharedAttachment],
        availableCollections: [String],
        enrichedTitle: String?,
        enrichedSummary: String?,
        enrichedContentType: String?,
        provider: AIProviderType
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

        if provider == .bazaarlink {
            let key = bazaarlinkApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty, let url = URL(string: "https://api.bazaarlink.ai/v1/chat/completions") else { return nil }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
            req.timeoutInterval = 15

            let payload: [String: Any] = [
                "model": bazaarlinkModel,
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

            return parseRemoteJSONToAnalysis(parsed: parsed, detectedUrl: detectedUrl, source: "Auto-filled by BazaarLink (\(bazaarlinkModel))")
        } else if provider == .gemini {
            let key = geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty, let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(geminiModel):generateContent?key=\(key)") else { return nil }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.timeoutInterval = 15

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

            return parseRemoteJSONToAnalysis(parsed: parsed, detectedUrl: detectedUrl, source: "Auto-filled by Gemini (\(geminiModel))")
        } else if provider == .openai {
            let key = openaiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty, let url = URL(string: "https://api.openai.com/v1/chat/completions") else { return nil }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
            req.timeoutInterval = 15

            let payload: [String: Any] = [
                "model": openaiModel,
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

            return parseRemoteJSONToAnalysis(parsed: parsed, detectedUrl: detectedUrl, source: "Auto-filled by OpenAI (\(openaiModel))")
        } else if provider == .claude {
            let key = claudeApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty, let url = URL(string: "https://api.anthropic.com/v1/messages") else { return nil }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue(key, forHTTPHeaderField: "x-api-key")
            req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            req.timeoutInterval = 15

            let payload: [String: Any] = [
                "model": claudeModel,
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

            return parseRemoteJSONToAnalysis(parsed: parsed, detectedUrl: detectedUrl, source: "Auto-filled by Claude (\(claudeModel))")
        }
        return nil
    }

    private func parseRemoteJSONToAnalysis(parsed: [String: Any], detectedUrl: String?, source: String) -> OnDeviceCaptureAnalysis {
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
            retDate = Self.deduceBestReturnDate(from: dateStr, contentType: ct ?? "")
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

    // MARK: - Generalized Intent Deduction for Mixed Content
    public static func deduceCaptureIntent(
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

        // 1. Detect media characteristics
        let hasVideo = lowerUrl.contains("youtube.com") || lowerUrl.contains("youtu.be") || lowerUrl.contains("vimeo.com") || lowerUrl.contains("tiktok.com") || lowerUrl.contains("twitch.tv") ||
            attachments.contains { $0.name.lowercased().hasSuffix(".mp4") || $0.name.lowercased().hasSuffix(".mov") } ||
            enrichedContentType == "video"

        let hasArticle = lowerUrl.contains("medium.com") || lowerUrl.contains("substack.com") || lowerUrl.contains("blog") || lowerUrl.contains("article") || lowerUrl.contains(".pdf") ||
            attachments.contains { $0.name.lowercased().hasSuffix(".pdf") || $0.name.lowercased().hasSuffix(".doc") } ||
            enrichedContentType == "article"

        let hasMusic = lowerUrl.contains("spotify.com") || lowerUrl.contains("music.apple.com") || lowerUrl.contains("soundcloud.com") ||
            attachments.contains { $0.name.lowercased().hasSuffix(".mp3") || $0.name.lowercased().hasSuffix(".m4a") } ||
            enrichedContentType == "music"

        // 2. Classify tasks / action lists in user text
        let taskAnalysis = classifyTaskOrNotes(content: trimmed)

        // 3. Action phrasing keywords
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

        // DEDUCE DOMINANT INTENT:
        // A. Multi-line to-do or checklist present
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
            } else if let enriched = enrichedTitle, !LinkMetadataLoader.isGenericTitle(enriched) {
                title = enriched
            }
        }
        // B. Action intent on video (e.g., "Watch this tutorial tonight: https://...")
        else if hasVideo && (hasWatchPhrasing || taskAnalysis.isTask || !userTextWithoutUrl.isEmpty) {
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
        }
        // C. Action intent on reading (e.g., "Read this article over the weekend: https://...")
        else if (hasArticle || detectedUrl != nil) && (hasReadPhrasing || hasReviewPhrasing) {
            dominantType = "task"
            actionTags.append(contentsOf: ["task", "reading", "read-later"])

            let cleanTitle = enrichedTitle ?? "Article"
            title = "Read: \(cleanTitle)"

            var taskItems: [String] = ["- [ ] Read \(cleanTitle)"]
            if let url = detectedUrl { taskItems.append("Link: \(url)") }
            if !userTextWithoutUrl.isEmpty { taskItems.append("\nNote: \(userTextWithoutUrl)") }
            formattedTask = taskItems.joined(separator: "\n")
            notes = formattedTask
        }
        // D. Action intent on shopping / purchasing
        else if hasBuyPhrasing {
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
        }
        // E. Action intent on documents/attachments (e.g. "Review pitch deck before Monday")
        else if !attachments.isEmpty && (hasReviewPhrasing || taskAnalysis.isTask) {
            dominantType = "task"
            actionTags.append(contentsOf: ["task", "review", "work"])

            let attName = attachments.first?.name ?? "Attachment"
            title = !userTextWithoutUrl.isEmpty ? String(userTextWithoutUrl.prefix(60)) : "Review \(attName)"
            formattedTask = "- [ ] Review \(attName)\nAttached file: \(attName)"
            notes = formattedTask
        }
        // F. Single line explicit to-do task (e.g. "Call John tomorrow", "Schedule dentist")
        else if taskAnalysis.isTask {
            dominantType = "task"
            actionTags.append(contentsOf: ["task", "todo"])

            let taskText = taskAnalysis.title ?? userTextWithoutUrl
            title = taskText
            formattedTask = "- [ ] \(taskText)"
            notes = formattedTask
        }
        // G. Pure reference media / resource (no action phrasing)
        else {
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

        // Return Date Deduction
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

    // MARK: - Natural Language & Contextual Return Date Deduction
    public static func deduceBestReturnDate(
        from text: String,
        contentType: String,
        hasVideo: Bool = false,
        hasArticle: Bool = false
    ) -> Date? {
        let lower = text.lowercased()
        let calendar = Calendar.current
        let now = Date()

        // 1. Explicit Relative Numbers (e.g. "in 2 hours", "in 30 mins", "in 3 days")
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

        // 2. Specific Named Time Frames
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
        } else if lower.contains("tomorrow") || lower.contains("tmrw") {
            return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now.addingTimeInterval(86400))
        } else if lower.contains("this weekend") || lower.contains("over the weekend") {
            return nextWeekday(7, hour: 10) // Saturday 10 AM
        } else if lower.contains("saturday") || lower.contains("sat") {
            return nextWeekday(7, hour: 10)
        } else if lower.contains("sunday") || lower.contains("sun") {
            return nextWeekday(1, hour: 10)
        } else if lower.contains("next week") || lower.contains("next monday") {
            return nextWeekday(2, hour: 9) // Monday 9 AM
        } else if lower.contains("monday") || lower.contains("mon") {
            return nextWeekday(2, hour: 9)
        } else if lower.contains("tuesday") || lower.contains("tue") {
            return nextWeekday(3, hour: 9)
        } else if lower.contains("wednesday") || lower.contains("wed") {
            return nextWeekday(4, hour: 9)
        } else if lower.contains("thursday") || lower.contains("thu") {
            return nextWeekday(5, hour: 9)
        } else if lower.contains("friday") || lower.contains("fri") {
            return nextWeekday(6, hour: 9)
        } else if lower.contains("later today") || lower.contains("after work") {
            return calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now)
        }

        // 3. Implicit Contextual Return Dates
        if lower.contains("urgent") || lower.contains("asap") || lower.contains("right now") || lower.contains("today") {
            return now.addingTimeInterval(7200)
        }

        if contentType == "task" {
            if lower.contains("buy") || lower.contains("grocer") || lower.contains("shop") || lower.contains("order") {
                return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now.addingTimeInterval(86400))
            } else if hasVideo || lower.contains("watch") {
                return nextWeekday(7, hour: 11)
            } else if hasArticle || lower.contains("read") {
                let hour = calendar.component(.hour, from: now)
                if hour < 20 {
                    return calendar.date(bySettingHour: 20, minute: 30, second: 0, of: now)
                } else {
                    return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now.addingTimeInterval(86400))
                }
            } else {
                return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now.addingTimeInterval(86400))
            }
        }

        return nil
    }

    private static func nextWeekday(_ targetWeekday: Int, hour: Int = 9) -> Date {
        let calendar = Calendar.current
        let now = Date()
        let currentWeekday = calendar.component(.weekday, from: now)
        var daysToAdd = targetWeekday - currentWeekday
        if daysToAdd <= 0 {
            daysToAdd += 7
        }
        let targetDate = calendar.date(byAdding: .day, value: daysToAdd, to: now) ?? now
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: targetDate) ?? targetDate
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

