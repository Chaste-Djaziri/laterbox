//
//  InboxView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import SwiftUI
import SwiftData

public struct InboxView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LBItem.createdAt, order: .reverse) private var allItems: [LBItem]
    @ObservedObject var coordinator = SyncCoordinator.shared

    @State private var selectedFilter: ItemContentType? = nil
    @State private var searchText: String = ""

    public init() {}

    private var filteredInboxItems: [LBItem] {
        var items = allItems.filter { $0.status == ItemStatus.inbox.rawValue }

        if let filter = selectedFilter {
            items = items.filter { $0.type == filter.rawValue }
        }

        if !searchText.isEmpty {
            let q = searchText.lowercased()
            items = items.filter {
                $0.title.lowercased().contains(q) ||
                ($0.url?.lowercased().contains(q) ?? false) ||
                ($0.noteContent?.lowercased().contains(q) ?? false)
            }
        }

        // FIFO sorting: items scheduled to return earliest appear first, falling back to arrival date
        return items.sorted {
            let dateA = $0.returnAt ?? $0.createdAt
            let dateB = $1.returnAt ?? $1.createdAt
            return dateA < dateB
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search inbox...", text: $searchText)
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(12)
                        .liquidGlassCard(cornerRadius: 14)

                        // Format Filters
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                Button(action: {
                                    selectedFilter = nil
                                    LBHaptic.light()
                                }) {
                                    Text("All (\(allItems.filter { $0.status == ItemStatus.inbox.rawValue }.count))")
                                        .font(.caption.weight(.semibold))
                                        .liquidGlassPill(isSelected: selectedFilter == nil)
                                }
                                .buttonStyle(.plain)

                                ForEach(ItemContentType.allCases, id: \.self) { type in
                                    let count = allItems.filter { $0.status == ItemStatus.inbox.rawValue && $0.type == type.rawValue }.count
                                    Button(action: {
                                        selectedFilter = (selectedFilter == type) ? nil : type
                                        LBHaptic.light()
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: type.systemIcon)
                                            Text("\(type.rawValue.capitalized) (\(count))")
                                        }
                                        .font(.caption.weight(.semibold))
                                        .liquidGlassPill(isSelected: selectedFilter == type)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Queue Count Header
                        HStack {
                            Text("Queue • \(filteredInboxItems.count) To Review")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            Spacer()
                            Text("FIFO Sorted")
                                .font(.caption2.weight(.medium))
                                .foregroundColor(Color.lbAmber)
                        }
                        .padding(.top, 4)

                        // List of items
                        if filteredInboxItems.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "tray.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(.secondary.opacity(0.4))
                                Text("Inbox Zero!")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("All caught up. Everything saved has been processed or reviewed.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(48)
                            .liquidGlassCard(cornerRadius: 20)
                        } else {
                            ForEach(filteredInboxItems) { item in
                                NavigationLink(destination: ItemDetailView(item: item)) {
                                    ItemCardView(
                                        item: item,
                                        onMarkDone: { coordinator.markDone(item: item, context: modelContext) },
                                        onToggleFavorite: { coordinator.toggleFavorite(item: item, context: modelContext) },
                                        onSchedule: {
                                            coordinator.scheduleItem(item: item, date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!, context: modelContext)
                                        },
                                        onDelete: { coordinator.deleteItem(item: item, context: modelContext) }
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        LBHaptic.medium()
                        coordinator.showingQuickCapture = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.lbEmerald)
                    }
                }
            }
        }
    }
}
