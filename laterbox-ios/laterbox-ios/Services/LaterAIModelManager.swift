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
            syncToSharedSettings()
        }
    }
    @Published var enableSearchRefine: Bool = true
    @Published var isOnDeviceModelEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isOnDeviceModelEnabled, forKey: "laterbox_enable_on_device_model")
            syncToSharedSettings()
        }
    }

    @Published var bazaarlinkApiKey: String {
        didSet {
            UserDefaults.standard.set(bazaarlinkApiKey, forKey: "laterbox_bazaarlink_api_key")
            syncToSharedSettings()
        }
    }
    @Published var geminiApiKey: String {
        didSet {
            UserDefaults.standard.set(geminiApiKey, forKey: "laterbox_gemini_api_key")
            syncToSharedSettings()
        }
    }
    @Published var openaiApiKey: String {
        didSet {
            UserDefaults.standard.set(openaiApiKey, forKey: "laterbox_openai_api_key")
            syncToSharedSettings()
        }
    }
    @Published var claudeApiKey: String {
        didSet {
            UserDefaults.standard.set(claudeApiKey, forKey: "laterbox_claude_api_key")
            syncToSharedSettings()
        }
    }

    @Published var bazaarlinkModel: String {
        didSet {
            UserDefaults.standard.set(bazaarlinkModel, forKey: "laterbox_bazaarlink_model")
            syncToSharedSettings()
        }
    }
    @Published var geminiModel: String {
        didSet {
            UserDefaults.standard.set(geminiModel, forKey: "laterbox_gemini_model")
            syncToSharedSettings()
        }
    }
    @Published var openaiModel: String {
        didSet {
            UserDefaults.standard.set(openaiModel, forKey: "laterbox_openai_model")
            syncToSharedSettings()
        }
    }
    @Published var claudeModel: String {
        didSet {
            UserDefaults.standard.set(claudeModel, forKey: "laterbox_claude_model")
            syncToSharedSettings()
        }
    }

    private func syncToSharedSettings() {
        let settings = SharedAISettings(
            selectedProvider: selectedProvider.rawValue,
            isOnDeviceModelEnabled: isOnDeviceModelEnabled,
            bazaarlinkApiKey: bazaarlinkApiKey,
            geminiApiKey: geminiApiKey,
            openaiApiKey: openaiApiKey,
            claudeApiKey: claudeApiKey,
            bazaarlinkModel: bazaarlinkModel,
            geminiModel: geminiModel,
            openaiModel: openaiModel,
            claudeModel: claudeModel
        )
        SharedCaptureStore.saveAISettings(settings)
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
        let sharedSettings = SharedCaptureStore.loadAISettings()

        if UserDefaults.standard.object(forKey: "laterbox_enable_on_device_model") != nil {
            self.isOnDeviceModelEnabled = isSupported && UserDefaults.standard.bool(forKey: "laterbox_enable_on_device_model")
        } else {
            self.isOnDeviceModelEnabled = isSupported && sharedSettings.isOnDeviceModelEnabled
        }

        self.bazaarlinkApiKey = !sharedSettings.bazaarlinkApiKey.isEmpty ? sharedSettings.bazaarlinkApiKey : (UserDefaults.standard.string(forKey: "laterbox_bazaarlink_api_key") ?? "")
        self.geminiApiKey = !sharedSettings.geminiApiKey.isEmpty ? sharedSettings.geminiApiKey : (UserDefaults.standard.string(forKey: "laterbox_gemini_api_key") ?? "")
        self.openaiApiKey = !sharedSettings.openaiApiKey.isEmpty ? sharedSettings.openaiApiKey : (UserDefaults.standard.string(forKey: "laterbox_openai_api_key") ?? "")
        self.claudeApiKey = !sharedSettings.claudeApiKey.isEmpty ? sharedSettings.claudeApiKey : (UserDefaults.standard.string(forKey: "laterbox_claude_api_key") ?? "")

        self.bazaarlinkModel = !sharedSettings.bazaarlinkModel.isEmpty ? sharedSettings.bazaarlinkModel : (UserDefaults.standard.string(forKey: "laterbox_bazaarlink_model") ?? "qwen/qwen3.7-flash")
        self.geminiModel = !sharedSettings.geminiModel.isEmpty ? sharedSettings.geminiModel : (UserDefaults.standard.string(forKey: "laterbox_gemini_model") ?? "gemini-2.5-flash")
        self.openaiModel = !sharedSettings.openaiModel.isEmpty ? sharedSettings.openaiModel : (UserDefaults.standard.string(forKey: "laterbox_openai_model") ?? "gpt-4o-mini")
        self.claudeModel = !sharedSettings.claudeModel.isEmpty ? sharedSettings.claudeModel : (UserDefaults.standard.string(forKey: "laterbox_claude_model") ?? "claude-3-5-haiku-20241022")

        if let prov = AIProviderType(rawValue: sharedSettings.selectedProvider) {
            self.selectedProvider = prov
        } else if let saved = UserDefaults.standard.string(forKey: "laterbox_selected_ai_provider"),
           let prov = AIProviderType(rawValue: saved) {
            self.selectedProvider = prov
        }
        syncToSharedSettings()
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

    // MARK: - Capture Analysis Delegation to LaterAISharedAnalyzer

    func analyzeCapture(
        content: String,
        attachments: [SharedAttachment] = [],
        availableCollections: [String] = []
    ) async -> OnDeviceCaptureAnalysis {
        if !availableCollections.isEmpty {
            SharedCaptureStore.saveAvailableCollections(availableCollections)
        }
        let settings = currentSharedSettings()
        return await LaterAISharedAnalyzer.analyze(
            content: content,
            attachments: attachments,
            availableCollections: availableCollections,
            settings: settings
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
        LaterAISharedAnalyzer.deduceCaptureIntent(
            content: content,
            detectedUrl: detectedUrl,
            attachments: attachments,
            enrichedTitle: enrichedTitle,
            enrichedSummary: enrichedSummary,
            enrichedContentType: enrichedContentType
        )
    }

    // MARK: - Natural Language & Contextual Return Date Deduction
    public static func deduceBestReturnDate(
        from text: String,
        contentType: String,
        hasVideo: Bool = false,
        hasArticle: Bool = false
    ) -> Date? {
        LaterAISharedAnalyzer.deduceBestReturnDate(
            from: text,
            contentType: contentType,
            hasVideo: hasVideo,
            hasArticle: hasArticle
        )
    }


    // MARK: - Task & To-Do Classification
    public static func classifyTaskOrNotes(content: String) -> (isTask: Bool, title: String?, taskLines: [String]) {
        LaterAISharedAnalyzer.classifyTaskOrNotes(content: content)
    }
}

