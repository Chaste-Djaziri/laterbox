//
//  LaterAIModelManager.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 05.10.26.
//

import Foundation
import Combine
import SwiftUI
import OSLog

enum AIProviderType: String, CaseIterable, Identifiable, Codable {
    case cloudGemini = "cloudGemini"
    case onDevice = "onDevice"
    case customGemini = "customGemini"
    case customOpenAI = "customOpenAI"
    case customClaude = "customClaude"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cloudGemini: return "LaterBox Cloud (Gemini)"
        case .onDevice: return "On-Device (Apple Intelligence)"
        case .customGemini: return "Google Gemini"
        case .customOpenAI: return "OpenAI"
        case .customClaude: return "Anthropic Claude"
        }
    }

    var shortName: String {
        switch self {
        case .cloudGemini: return "Cloud Gemini"
        case .onDevice: return "On-Device"
        case .customGemini: return "Gemini"
        case .customOpenAI: return "OpenAI"
        case .customClaude: return "Claude"
        }
    }

    var subtitle: String {
        switch self {
        case .cloudGemini: return "Pro-managed server intelligence (Default)"
        case .onDevice: return "Private & offline using Apple Foundation Models"
        case .customGemini: return "Direct Google AI Studio connection with your API key"
        case .customOpenAI: return "Direct OpenAI connection with your API key"
        case .customClaude: return "Direct Anthropic connection with your API key"
        }
    }

    var iconName: String {
        switch self {
        case .cloudGemini: return "sparkles"
        case .onDevice: return "brain"
        case .customGemini: return "wand.and.stars"
        case .customOpenAI: return "cpu"
        case .customClaude: return "atom"
        }
    }

    var isCustomKey: Bool {
        switch self {
        case .cloudGemini, .onDevice: return false
        case .customGemini, .customOpenAI, .customClaude: return true
        }
    }
}

struct AIModelPresets {
    static let geminiModels = [
        "gemini-2.5-flash",
        "gemini-2.5-pro",
        "gemini-1.5-flash",
        "gemini-1.5-pro"
    ]

    static let openAIModels = [
        "gpt-4o-mini",
        "gpt-4o",
        "gpt-4.5-preview",
        "o3-mini"
    ]

    static let claudeModels = [
        "claude-3-7-sonnet-latest",
        "claude-3-5-sonnet-latest",
        "claude-3-5-haiku-latest"
    ]
}

@MainActor
final class LaterAIModelManager: ObservableObject {
    static let shared = LaterAIModelManager()

    private let defaults: UserDefaults

    // Storage Keys
    private let kSelectedProvider = "laterai_provider_type"
    private let kGeminiApiKey = "laterai_gemini_api_key"
    private let kGeminiModel = "laterai_gemini_model_name"
    private let kOpenAIApiKey = "laterai_openai_api_key"
    private let kOpenAIModel = "laterai_openai_model_name"
    private let kClaudeApiKey = "laterai_claude_api_key"
    private let kClaudeModel = "laterai_claude_model_name"
    private let kEnableSearchRefine = "laterai_enable_search_refine"

    @Published var selectedProvider: AIProviderType {
        didSet { defaults.set(selectedProvider.rawValue, forKey: kSelectedProvider) }
    }

    @Published var geminiApiKey: String {
        didSet { defaults.set(geminiApiKey, forKey: kGeminiApiKey) }
    }

    @Published var geminiModel: String {
        didSet { defaults.set(geminiModel, forKey: kGeminiModel) }
    }

    @Published var openAIApiKey: String {
        didSet { defaults.set(openAIApiKey, forKey: kOpenAIApiKey) }
    }

    @Published var openAIModel: String {
        didSet { defaults.set(openAIModel, forKey: kOpenAIModel) }
    }

    @Published var claudeApiKey: String {
        didSet { defaults.set(claudeApiKey, forKey: kClaudeApiKey) }
    }

    @Published var claudeModel: String {
        didSet { defaults.set(claudeModel, forKey: kClaudeModel) }
    }

    @Published var enableSearchRefine: Bool {
        didSet { defaults.set(enableSearchRefine, forKey: kEnableSearchRefine) }
    }

    init() {
        let store = UserDefaults(suiteName: SharedCaptureStore.group) ?? .standard
        self.defaults = store

        let rawProvider = store.string(forKey: kSelectedProvider) ?? AIProviderType.cloudGemini.rawValue
        self.selectedProvider = AIProviderType(rawValue: rawProvider) ?? .cloudGemini

        self.geminiApiKey = store.string(forKey: kGeminiApiKey) ?? ""
        self.geminiModel = store.string(forKey: kGeminiModel) ?? "gemini-2.5-flash"

        self.openAIApiKey = store.string(forKey: kOpenAIApiKey) ?? ""
        self.openAIModel = store.string(forKey: kOpenAIModel) ?? "gpt-4o-mini"

        self.claudeApiKey = store.string(forKey: kClaudeApiKey) ?? ""
        self.claudeModel = store.string(forKey: kClaudeModel) ?? "claude-3-5-haiku-latest"

        if store.object(forKey: kEnableSearchRefine) != nil {
            self.enableSearchRefine = store.bool(forKey: kEnableSearchRefine)
        } else {
            self.enableSearchRefine = true
        }
    }

    var activeModelName: String {
        switch selectedProvider {
        case .cloudGemini:
            return "Gemini 2.5 (Pro)"
        case .onDevice:
            return "Apple Intelligence"
        case .customGemini:
            return geminiModel.isEmpty ? "gemini-2.5-flash" : geminiModel
        case .customOpenAI:
            return openAIModel.isEmpty ? "gpt-4o-mini" : openAIModel
        case .customClaude:
            return claudeModel.isEmpty ? "claude-3-5-haiku" : claudeModel
        }
    }

    func activeProvider() -> any LaterAIProvider {
        switch selectedProvider {
        case .cloudGemini:
            return GeminiLaterAIProvider()

        case .onDevice:
            if AppleLaterAIProvider.unavailableReason == nil {
                return AppleLaterAIProvider()
            } else {
                return GeminiLaterAIProvider()
            }

        case .customGemini:
            let key = geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if !key.isEmpty {
                return CustomGeminiLaterAIProvider(apiKey: key, model: geminiModel)
            } else {
                return GeminiLaterAIProvider()
            }

        case .customOpenAI:
            let key = openAIApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if !key.isEmpty {
                return OpenAILaterAIProvider(apiKey: key, model: openAIModel)
            } else {
                return GeminiLaterAIProvider()
            }

        case .customClaude:
            let key = claudeApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if !key.isEmpty {
                return ClaudeLaterAIProvider(apiKey: key, model: claudeModel)
            } else {
                return GeminiLaterAIProvider()
            }
        }
    }

    func interpretSearch(_ query: String) async throws -> SearchInterpretation {
        guard enableSearchRefine else {
            return SearchInterpretation(terms: query, contentType: "", returnWindow: "")
        }

        switch selectedProvider {
        case .onDevice:
            if AppleLaterAIProvider.unavailableReason == nil {
                return try await AppleSearchInterpreter.interpret(query)
            }
            fallthrough

        case .cloudGemini:
            // Use AppleSearchInterpreter if on-device is available, or fallback to lexical query
            if AppleLaterAIProvider.unavailableReason == nil {
                return try await AppleSearchInterpreter.interpret(query)
            }
            return SearchInterpretation(terms: query, contentType: "", returnWindow: "")

        case .customGemini:
            let key = geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty else { return SearchInterpretation(terms: query, contentType: "", returnWindow: "") }
            return try await CustomGeminiLaterAIProvider(apiKey: key, model: geminiModel).interpretSearch(query)

        case .customOpenAI:
            let key = openAIApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty else { return SearchInterpretation(terms: query, contentType: "", returnWindow: "") }
            return try await OpenAILaterAIProvider(apiKey: key, model: openAIModel).interpretSearch(query)

        case .customClaude:
            let key = claudeApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty else { return SearchInterpretation(terms: query, contentType: "", returnWindow: "") }
            return try await ClaudeLaterAIProvider(apiKey: key, model: claudeModel).interpretSearch(query)
        }
    }

    func testConnection(for provider: AIProviderType) async throws -> String {
        switch provider {
        case .cloudGemini:
            _ = try await GeminiLaterAIProvider().respond("Ping test. Reply with a short greeting.")
            return "LaterBox Cloud Gemini is connected and responsive."

        case .onDevice:
            if let reason = AppleLaterAIProvider.unavailableReason {
                throw AIProviderError.customModelError(reason)
            }
            _ = try await AppleLaterAIProvider().respond("Ping test. Reply with a short greeting.")
            return "Apple Intelligence on-device engine is operational."

        case .customGemini:
            let key = geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty else { throw AIProviderError.missingApiKey("Google Gemini") }
            let testProvider = CustomGeminiLaterAIProvider(apiKey: key, model: geminiModel)
            _ = try await testProvider.respond("Ping test. Reply in JSON.")
            return "Google Gemini (\(geminiModel)) connection verified successfully."

        case .customOpenAI:
            let key = openAIApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty else { throw AIProviderError.missingApiKey("OpenAI") }
            let testProvider = OpenAILaterAIProvider(apiKey: key, model: openAIModel)
            _ = try await testProvider.respond("Ping test. Reply in JSON.")
            return "OpenAI (\(openAIModel)) connection verified successfully."

        case .customClaude:
            let key = claudeApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty else { throw AIProviderError.missingApiKey("Anthropic Claude") }
            let testProvider = ClaudeLaterAIProvider(apiKey: key, model: claudeModel)
            _ = try await testProvider.respond("Ping test. Reply in JSON.")
            return "Anthropic Claude (\(claudeModel)) connection verified successfully."
        }
    }
}

// MARK: - JSON Action Parser Helper
enum LaterAIJSONParser {
    static func extractCleanJSON(_ text: String) -> String {
        var clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasPrefix("```json") {
            clean = String(clean.dropFirst(7))
        } else if clean.hasPrefix("```") {
            clean = String(clean.dropFirst(3))
        }
        if clean.hasSuffix("```") {
            clean = String(clean.dropLast(3))
        }
        clean = clean.trimmingCharacters(in: .whitespacesAndNewlines)

        // Find outer curly braces if extra text surrounds the JSON
        if let start = clean.firstIndex(of: "{"), let end = clean.lastIndex(of: "}"), start < end {
            clean = String(clean[start...end])
        }
        return clean
    }

    static func parseAIAction(from text: String) throws -> AIAction {
        let clean = extractCleanJSON(text)
        guard let data = clean.data(using: .utf8),
              let dict = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            return AIAction(
                intent: "chat",
                reply: text.trimmingCharacters(in: .whitespacesAndNewlines),
                content: "",
                title: "",
                category: "",
                contentType: "",
                tags: [],
                summary: "",
                formattedContent: "",
                query: "",
                returnDate: ""
            )
        }

        let intent = dict["intent"] as? String ?? "chat"
        let reply = dict["reply"] as? String ?? ""
        let content = dict["content"] as? String ?? ""
        let title = dict["title"] as? String ?? ""
        let category = dict["category"] as? String ?? ""
        let contentType = dict["contentType"] as? String ?? ""
        let tags = (dict["tags"] as? [String]) ?? []
        let summary = dict["summary"] as? String ?? ""
        let formattedContent = dict["formattedContent"] as? String ?? ""
        let query = dict["query"] as? String ?? ""
        let returnDate = dict["returnDate"] as? String ?? ""

        return AIAction(
            intent: intent,
            reply: reply,
            content: content,
            title: title,
            category: category,
            contentType: contentType,
            tags: tags,
            summary: summary,
            formattedContent: formattedContent,
            query: query,
            returnDate: returnDate
        )
    }

    static func parseSearchInterpretation(from text: String, fallbackQuery: String) -> SearchInterpretation {
        let clean = extractCleanJSON(text)
        guard let data = clean.data(using: .utf8),
              let dict = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            return SearchInterpretation(terms: fallbackQuery, contentType: "", returnWindow: "")
        }

        let terms = dict["terms"] as? String ?? fallbackQuery
        let contentType = dict["contentType"] as? String ?? ""
        let returnWindow = dict["returnWindow"] as? String ?? ""
        return SearchInterpretation(terms: terms, contentType: contentType, returnWindow: returnWindow)
    }
}

// MARK: - Custom Gemini Provider (BYOK)
@MainActor
struct CustomGeminiLaterAIProvider: LaterAIProvider {
    let apiKey: String
    let model: String

    init(apiKey: String, model: String) {
        self.apiKey = apiKey
        self.model = model.isEmpty ? "gemini-2.5-flash" : model
    }

    private var systemInstruction: String {
        """
        You are Later AI, a concise assistant for a personal saved-content library.
        Always reply strictly in JSON format adhering to:
        {
          "intent": "chat" | "capture" | "search" | "clarify",
          "reply": "Conversational assistant reply to user",
          "content": "Exact content or URL to save, without the user's instructions. Empty for chat.",
          "title": "Clean concise title",
          "category": "Suggested collection or category name",
          "contentType": "link" | "article" | "video" | "music" | "document" | "note",
          "tags": ["tag1", "tag2"],
          "summary": "Brief summary",
          "formattedContent": "Formatted presentation text",
          "query": "Search query without conversational filler if intent is search",
          "returnDate": "ISO8601 date if an explicit return/snooze date is requested, or empty"
        }
        """
    }

    func respond(_ prompt: String) async throws -> AIAction {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)") else {
            throw AIProviderError.customModelError("Invalid Gemini URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 25

        let body: [String: Any] = [
            "systemInstruction": [
                "parts": [["text": systemInstruction]]
            ],
            "contents": [
                ["parts": [["text": prompt]]]
            ],
            "generationConfig": [
                "responseMimeType": "application/json"
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AIProviderError.customModelError("Network request failed")
        }

        if http.statusCode != 200 {
            let errorText = String(decoding: data, as: UTF8.self)
            throw AIProviderError.customModelError("Google Gemini API error (\(http.statusCode)): \(errorText.prefix(200))")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let candidates = json?["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw AIProviderError.customModelError("Empty or invalid candidate response from Gemini.")
        }

        return try LaterAIJSONParser.parseAIAction(from: text)
    }

    func interpretSearch(_ query: String) async throws -> SearchInterpretation {
        let prompt = "Extract search query topics and filters from this user search: \"\(query)\". Return JSON with keys: terms, contentType (link, article, video, music, document, note), returnWindow (today, thisWeek, upcoming)."
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)") else {
            return SearchInterpretation(terms: query, contentType: "", returnWindow: "")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10

        let body: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]],
            "generationConfig": ["responseMimeType": "application/json"]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200,
              let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            return SearchInterpretation(terms: query, contentType: "", returnWindow: "")
        }

        return LaterAIJSONParser.parseSearchInterpretation(from: text, fallbackQuery: query)
    }
}

// MARK: - Custom OpenAI Provider (BYOK)
@MainActor
struct OpenAILaterAIProvider: LaterAIProvider {
    let apiKey: String
    let model: String

    init(apiKey: String, model: String) {
        self.apiKey = apiKey
        self.model = model.isEmpty ? "gpt-4o-mini" : model
    }

    private var systemInstruction: String {
        """
        You are Later AI, a concise assistant for a personal saved-content library.
        Always reply strictly in JSON format adhering to:
        {
          "intent": "chat" | "capture" | "search" | "clarify",
          "reply": "Conversational assistant reply to user",
          "content": "Exact content or URL to save, without the user's instructions. Empty for chat.",
          "title": "Clean concise title",
          "category": "Suggested collection or category name",
          "contentType": "link" | "article" | "video" | "music" | "document" | "note",
          "tags": ["tag1", "tag2"],
          "summary": "Brief summary",
          "formattedContent": "Formatted presentation text",
          "query": "Search query without conversational filler if intent is search",
          "returnDate": "ISO8601 date if an explicit return/snooze date is requested, or empty"
        }
        """
    }

    func respond(_ prompt: String) async throws -> AIAction {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw AIProviderError.customModelError("Invalid OpenAI URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 25

        let body: [String: Any] = [
            "model": model,
            "response_format": ["type": "json_object"],
            "messages": [
                ["role": "system", "content": systemInstruction],
                ["role": "user", "content": prompt]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AIProviderError.customModelError("Network request failed")
        }

        if http.statusCode != 200 {
            let errorText = String(decoding: data, as: UTF8.self)
            throw AIProviderError.customModelError("OpenAI API error (\(http.statusCode)): \(errorText.prefix(200))")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let text = message["content"] as? String else {
            throw AIProviderError.customModelError("Empty or invalid choices response from OpenAI.")
        }

        return try LaterAIJSONParser.parseAIAction(from: text)
    }

    func interpretSearch(_ query: String) async throws -> SearchInterpretation {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            return SearchInterpretation(terms: query, contentType: "", returnWindow: "")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10

        let body: [String: Any] = [
            "model": model,
            "response_format": ["type": "json_object"],
            "messages": [
                ["role": "system", "content": "Extract search criteria from user query into JSON keys: terms, contentType (link, article, video, music, document, note), returnWindow (today, thisWeek, upcoming)."],
                ["role": "user", "content": query]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200,
              let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let text = message["content"] as? String else {
            return SearchInterpretation(terms: query, contentType: "", returnWindow: "")
        }

        return LaterAIJSONParser.parseSearchInterpretation(from: text, fallbackQuery: query)
    }
}

// MARK: - Custom Claude Provider (BYOK)
@MainActor
struct ClaudeLaterAIProvider: LaterAIProvider {
    let apiKey: String
    let model: String

    init(apiKey: String, model: String) {
        self.apiKey = apiKey
        self.model = model.isEmpty ? "claude-3-5-haiku-latest" : model
    }

    private var systemInstruction: String {
        """
        You are Later AI, a concise assistant for a personal saved-content library.
        Output ONLY raw, strictly valid JSON (no markdown formatting, no code fences, no preamble) adhering to:
        {
          "intent": "chat" | "capture" | "search" | "clarify",
          "reply": "Conversational assistant reply to user",
          "content": "Exact content or URL to save, without the user's instructions. Empty for chat.",
          "title": "Clean concise title",
          "category": "Suggested collection or category name",
          "contentType": "link" | "article" | "video" | "music" | "document" | "note",
          "tags": ["tag1", "tag2"],
          "summary": "Brief summary",
          "formattedContent": "Formatted presentation text",
          "query": "Search query without conversational filler if intent is search",
          "returnDate": "ISO8601 date if an explicit return/snooze date is requested, or empty"
        }
        """
    }

    func respond(_ prompt: String) async throws -> AIAction {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw AIProviderError.customModelError("Invalid Claude URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 25

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "system": systemInstruction,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AIProviderError.customModelError("Network request failed")
        }

        if http.statusCode != 200 {
            let errorText = String(decoding: data, as: UTF8.self)
            throw AIProviderError.customModelError("Claude API error (\(http.statusCode)): \(errorText.prefix(200))")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let contentList = json?["content"] as? [[String: Any]],
              let firstContent = contentList.first,
              let text = firstContent["text"] as? String else {
            throw AIProviderError.customModelError("Empty or invalid content response from Claude.")
        }

        return try LaterAIJSONParser.parseAIAction(from: text)
    }

    func interpretSearch(_ query: String) async throws -> SearchInterpretation {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            return SearchInterpretation(terms: query, contentType: "", returnWindow: "")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 256,
            "system": "Output only raw JSON with keys: terms, contentType (link, article, video, music, document, note), returnWindow (today, thisWeek, upcoming).",
            "messages": [["role": "user", "content": query]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200,
              let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let contentList = json["content"] as? [[String: Any]],
              let text = contentList.first?["text"] as? String else {
            return SearchInterpretation(terms: query, contentType: "", returnWindow: "")
        }

        return LaterAIJSONParser.parseSearchInterpretation(from: text, fallbackQuery: query)
    }
}
