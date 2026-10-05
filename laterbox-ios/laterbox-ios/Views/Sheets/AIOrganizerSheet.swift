import SwiftUI
import SwiftData

struct AISuggestion: Identifiable {
    var id: String { item.id }
    let item: LBItem
    var category: String
    var tags: [String]
    var summary: String
    var applied = false
}

public struct AIOrganizerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var items: [LBItem]
    @ObservedObject private var coordinator = SyncCoordinator.shared
    @State private var suggestions: [AISuggestion] = []
    @State private var processing = false
    @State private var error: String?
    public init() {}
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !coordinator.isProUser {
                        Text("AI Inbox Organizer is included with Pro.")
                        Button("View plans") { coordinator.showingPlansSheet = true; dismiss() }
                    } else {
                        Text("Organize your inbox").font(.title2.bold())
                        Text("Suggest categories and tags. Your reminder dates stay as you chose them.").font(.subheadline)
                        if processing { ProgressView("Preparing suggestions…") }
                        if let error { Text(error).foregroundStyle(.orange) }
                        Button("Generate suggestions") { Task { await generate() } }.disabled(processing)
                        ForEach($suggestions) { $suggestion in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(suggestion.item.title).font(.headline)
                                Text(suggestion.category)
                                Text(suggestion.tags.map { "#" + $0 }.joined(separator: " "))
                                Text(suggestion.summary).font(.caption)
                                Button(suggestion.applied ? "Applied" : "Apply") { apply(suggestion.id) }.disabled(suggestion.applied)
                            }.padding(16).liquidGlassCard(cornerRadius: 16)
                        }
                        if !suggestions.isEmpty {
                            Button("Apply all") { for suggestion in suggestions where !suggestion.applied { apply(suggestion.id) } }
                        }
                    }
                }.padding(20)
            }
            .navigationTitle("AI Inbox Organizer")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }
    private func generate() async {
        guard coordinator.isProUser, !processing else { return }
        processing = true; error = nil; suggestions = []
        defer { processing = false }
        do {
            for item in items.filter({ $0.status == "inbox" }).prefix(8) {
                guard coordinator.isProUser else { return }
                let prompt = "Prepare capture classification only, without changing content or scheduling a date. Content: \(item.title)\n\((item.textContent ?? item.url ?? "").prefix(2500))\nExisting tags: \(item.tags.joined(separator: ","))"
                let action: AIAction
                do { action = try await LaterAIModelManager.shared.activeProvider().respond(prompt) }
                catch {
                    if AppleLaterAIProvider.unavailableReason == nil { action = try await AppleLaterAIProvider().respond(prompt) }
                    else { action = try await GeminiLaterAIProvider().respond(prompt) }
                }
                suggestions.append(AISuggestion(item: item, category: action.category, tags: action.tags, summary: action.summary))
            }
        } catch { self.error = error.localizedDescription }
    }
    private func apply(_ id: String) {
        guard coordinator.isProUser, let index = suggestions.firstIndex(where: { $0.id == id }) else { return }
        let suggestion = suggestions[index]
        let item = suggestion.item
        let old = (item.category, item.tags, item.summary, item.collectionName, item.collectionId)
        item.category = suggestion.category
        item.tags = suggestion.tags
        item.summary = suggestion.summary
        if !suggestion.category.isEmpty {
            let coll = coordinator.ensureCollectionExists(named: suggestion.category, context: context)
            item.collectionName = coll?.name ?? suggestion.category
            item.collectionId = coll?.id ?? item.collectionId
        }
        item.updatedAt = Date(); item.isSyncPending = true
        do { try context.save(); suggestions[index].applied = true; Task { await coordinator.syncPendingItems(context: context) } }
        catch {
            item.category = old.0; item.tags = old.1; item.summary = old.2
            item.collectionName = old.3; item.collectionId = old.4
            self.error = error.localizedDescription
        }
    }
}
