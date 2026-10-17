import Foundation
import Combine

enum AIProviderType: String, CaseIterable, Identifiable, Codable {
    case local
    var id: String { rawValue }
    var displayName: String { "Local responses" }
    var shortName: String { "Local" }
    var subtitle: String { "Offline deterministic capture assistant" }
    var iconName: String { "wand.and.stars" }
    var isCustomKey: Bool { false }
}

@MainActor
final class LaterAIModelManager: ObservableObject {
    static let shared = LaterAIModelManager()
    @Published var selectedProvider: AIProviderType = .local
    @Published var enableSearchRefine = true

    var activeModelName: String { "Local assistant" }
    var canRefineSearch: Bool { true }
    func activeProvider() -> any LaterAIProvider { DeterministicLaterAIProvider() }
    func interpretSearch(_ query: String) async throws -> SearchInterpretation {
        SearchInterpretation(terms: query.trimmingCharacters(in: .whitespacesAndNewlines), contentType: "", returnWindow: "")
    }
    func testConnection(for provider: AIProviderType) async throws -> String {
        "Cloud and custom AI providers are coming soon. Local responses are available offline."
    }
}
