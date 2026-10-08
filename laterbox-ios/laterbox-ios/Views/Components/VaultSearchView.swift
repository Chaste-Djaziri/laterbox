import SwiftUI
import SwiftData

/// Shared search destination, matching Home and Inbox's vault-wide Android search.
struct VaultSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LBItem.createdAt, order: .reverse) private var items: [LBItem]
    @StateObject private var search = LocalSearchController()
    @State private var query = ""
    @State private var selectedType: ItemContentType?
    @FocusState private var focused: Bool
    private let coordinator = SyncCoordinator.shared

    private var availableTypes: [ItemContentType] {
        ItemContentType.allCases.filter { type in items.contains { $0.status != "deleted" && $0.type == type.rawValue } }
    }
    private var results: [LBItem] {
        search.results.filter { selectedType == nil || $0.type == selectedType?.rawValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()
                VStack(spacing: 18) {
                    HStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            TextField("Search your vault...", text: $query)
                                .focused($focused)
                                .autocorrectionDisabled()
                                .accessibilityIdentifier("vault.search.input")
                            if !query.isEmpty {
                                Button { query = "" } label: { Image(systemName: "xmark.circle.fill") }
                                    .accessibilityLabel("Clear search")
                            }
                        }
                        .padding(14)
                        .liquidGlassCard(cornerRadius: 16)
                        Button { dismiss() } label: { Image(systemName: "xmark").font(.headline).padding(10) }
                            .accessibilityLabel("Close search")
                    }
                    if !availableTypes.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                Button { selectedType = nil } label: {
                                    Text("All").liquidGlassPill(isSelected: selectedType == nil)
                                }
                                ForEach(availableTypes, id: \.self) { type in
                                    Button { selectedType = selectedType == type ? nil : type } label: {
                                        Label(type.rawValue.capitalized, systemImage: type.systemIcon)
                                            .liquidGlassPill(isSelected: selectedType == type)
                                    }
                                }
                            }
                            .font(.caption.weight(.semibold))
                        }
                    }
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                searchMessage("Search across your entire vault", detail: "Search titles, links, text content, tags, or topics")
                            } else if results.isEmpty {
                                searchMessage("No matching items found", detail: "Try a different keyword or topic.")
                            } else {
                                Text("\(results.count) results")
                                    .font(.caption.weight(.semibold))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                ForEach(results) { item in
                                    NavigationLink(destination: ItemDetailView(item: item)) {
                                        ItemCardView(item: item,
                                            onMarkDone: { coordinator.markDone(item: item, context: modelContext) },
                                            onToggleFavorite: { coordinator.toggleFavorite(item: item, context: modelContext) },
                                            onSchedule: { coordinator.scheduleItem(item: item, date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!, context: modelContext) },
                                            onDelete: { coordinator.deleteItem(item: item, context: modelContext) })
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
                .padding(20)
            }
            .foregroundStyle(AppTheme.textPrimary)
            .toolbar(.hidden, for: .navigationBar)
            .task { focused = true }
            .task(id: query + items.map { $0.id + $0.updatedAt.ISO8601Format() + $0.status }.joined()) {
                search.update(query, items: items)
            }
            .onChange(of: availableTypes) { _, types in
                if let selectedType, !types.contains(selectedType) { self.selectedType = nil }
            }
        }
    }

    private func searchMessage(_ title: String, detail: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass").font(.largeTitle)
            Text(title).font(.headline)
            Text(detail).font(.subheadline).foregroundStyle(AppTheme.textSecondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}
