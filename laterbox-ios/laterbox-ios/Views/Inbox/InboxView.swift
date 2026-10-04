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
    @State private var showingSearch: Bool = false

    public init() {}

    private var rawInboxItems: [LBItem] {
        allItems.filter { $0.status == ItemStatus.inbox.rawValue }
    }

    private var availableFilterTypes: [ItemContentType] {
        ItemContentType.allCases.filter { type in
            rawInboxItems.contains(where: { $0.type == type.rawValue })
        }
    }

    private var filteredInboxItems: [LBItem] {
        var items = rawInboxItems

        if let filter = selectedFilter, availableFilterTypes.contains(filter) {
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
                    VStack(alignment: .leading, spacing: 18) {
                        // Top Level Header (Scrolls normally, uncontainerized on canvas)
                        HStack(alignment: .center) {
                            HStack(spacing: 8) {
                                // Green background variant with black icon (icon-only version)
                                Image("LaterboxIconGreen")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 28, height: 28)
                                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                                Text("Inbox")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                            }

                            Spacer()

                            HStack(spacing: 10) {
                                // Sync Status Indicator (No Container)
                                Button(action: {
                                    if !coordinator.isProUser {
                                        LBHaptic.light()
                                        coordinator.showingPlansSheet = true
                                    }
                                }) {
                                    HStack(spacing: 5) {
                                        Circle()
                                            .fill(coordinator.syncHeaderColor)
                                            .frame(width: 7, height: 7)
                                        Text(coordinator.syncHeaderTitle)
                                            .font(.caption2.weight(.medium))
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                }
                                .buttonStyle(.plain)

                                // Search icon to the right of the synced status
                                Button(action: {
                                    LBHaptic.light()
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        showingSearch.toggle()
                                        if !showingSearch {
                                            searchText = ""
                                        }
                                    }
                                }) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(showingSearch ? AppTheme.textPrimary : AppTheme.textSecondary)
                                        .frame(width: 30, height: 30)
                                        .background(showingSearch ? AppTheme.accent : Color.clear)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 4)

                        // On-demand Search Bar (revealed only when search icon is tapped)
                        if showingSearch {
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
                            .padding(10)
                            .liquidGlassCard(cornerRadius: 12)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Format Filters (only show when contents are available to choose from)
                        if !availableFilterTypes.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    Button(action: {
                                        selectedFilter = nil
                                        LBHaptic.light()
                                    }) {
                                        Text("All (\(rawInboxItems.count))")
                                            .font(.caption.weight(.semibold))
                                            .liquidGlassPill(isSelected: selectedFilter == nil)
                                    }
                                    .buttonStyle(.plain)

                                    ForEach(availableFilterTypes, id: \.self) { type in
                                        let count = rawInboxItems.filter { $0.type == type.rawValue }.count
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
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                }
                .trackPullDownForLaterAI()
            }
            .navigationBarHidden(true)
            .onChange(of: availableFilterTypes) { _, newTypes in
                if let current = selectedFilter, !newTypes.contains(current) {
                    selectedFilter = nil
                }
            }
        }
    }
}
