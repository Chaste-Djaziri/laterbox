//
//  InboxView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import SwiftUI
import SwiftData

public enum InboxEmailTab: String, CaseIterable, Identifiable {
    case primary = "Primary"
    case articles = "Articles"
    case media = "Media"
    case updates = "Updates"

    public var id: String { rawValue }

    public var systemIcon: String {
        switch self {
        case .primary: return "tray.fill"
        case .articles: return "doc.text.fill"
        case .media: return "play.rectangle.fill"
        case .updates: return "note.text"
        }
    }
}

public struct InboxView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LBItem.createdAt, order: .reverse) private var allItems: [LBItem]
    @ObservedObject var coordinator = SyncCoordinator.shared

    @State private var activeTab: InboxEmailTab = .primary
    @State private var sortOrder: SortOrder = .latest
    @State private var isSelectionMode: Bool = false
    @State private var selectedIds: Set<String> = []
    @State private var showingSearch: Bool = false
    @State private var showingOrganizer: Bool = false

    public init() {}

    private enum SortOrder {
        case latest
        case oldest
    }

    private var rawInboxItems: [LBItem] {
        allItems.filter { $0.status == ItemStatus.inbox.rawValue }
    }

    private var articlesItems: [LBItem] {
        rawInboxItems.filter { item in
            let url = item.url?.lowercased() ?? ""
            let isMedia = item.type == ItemContentType.video.rawValue ||
                item.type == ItemContentType.music.rawValue ||
                url.contains("youtube.com") ||
                url.contains("youtu.be") ||
                url.contains("vimeo.com") ||
                url.contains("spotify.com")
            let isUpdate = item.type == ItemContentType.note.rawValue ||
                item.attachmentsData != nil
            return !isMedia && !isUpdate
        }
    }

    private var mediaItems: [LBItem] {
        rawInboxItems.filter { item in
            let url = item.url?.lowercased() ?? ""
            return item.type == ItemContentType.video.rawValue ||
                item.type == ItemContentType.music.rawValue ||
                url.contains("youtube.com") ||
                url.contains("youtu.be") ||
                url.contains("vimeo.com") ||
                url.contains("spotify.com")
        }
    }

    private var updatesItems: [LBItem] {
        rawInboxItems.filter { item in
            item.type == ItemContentType.note.rawValue ||
            item.attachmentsData != nil
        }
    }

    private func count(for tab: InboxEmailTab) -> Int {
        switch tab {
        case .primary: return rawInboxItems.count
        case .articles: return articlesItems.count
        case .media: return mediaItems.count
        case .updates: return updatesItems.count
        }
    }

    private var displayedItems: [LBItem] {
        let baseItems: [LBItem]
        switch activeTab {
        case .primary: baseItems = rawInboxItems
        case .articles: baseItems = articlesItems
        case .media: baseItems = mediaItems
        case .updates: baseItems = updatesItems
        }

        return baseItems.sorted { itemA, itemB in
            if sortOrder == .latest {
                return itemA.createdAt > itemB.createdAt
            } else {
                return itemA.createdAt < itemB.createdAt
            }
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                LiquidGlassBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // Top Level Header
                        HStack(alignment: .center) {
                            HStack(spacing: 8) {
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

                                Button {
                                    if coordinator.isProUser { showingOrganizer = true }
                                    else { coordinator.showingPlansSheet = true }
                                } label: { Image(systemName: "wand.and.stars") }
                                .accessibilityLabel("AI Inbox Organizer")

                                Button(action: {
                                    LBHaptic.light()
                                    showingSearch = true
                                }) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(AppTheme.textSecondary)
                                        .frame(width: 30, height: 30)
                                        .background(Color.clear)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 4)

                        // Search Vault Bar
                        Button { showingSearch = true } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "magnifyingglass")
                                Text("Search your vault...")
                                Spacer()
                            }
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                            .padding(14)
                            .liquidGlassCard(cornerRadius: 14)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Search your vault")

                        // Email Table Container (matching web email table view)
                        VStack(spacing: 0) {
                            // 1. Email Category Tabs Bar (Primary, Articles, Media, Updates)
                            HStack(spacing: 0) {
                                ForEach(InboxEmailTab.allCases) { tab in
                                    let isActive = activeTab == tab
                                    let tabCount = count(for: tab)
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            activeTab = tab
                                            selectedIds.removeAll()
                                        }
                                        LBHaptic.light()
                                    } label: {
                                        VStack(spacing: 8) {
                                            HStack(spacing: 5) {
                                                Image(systemName: tab.systemIcon)
                                                    .font(.system(size: 11, weight: isActive ? .bold : .medium))
                                                    .foregroundColor(isActive ? AppTheme.textPrimary : AppTheme.textSecondary)

                                                Text(tab.rawValue)
                                                    .font(.system(size: 12, weight: isActive ? .bold : .medium))
                                                    .foregroundColor(isActive ? AppTheme.textPrimary : AppTheme.textSecondary)

                                                if tabCount > 0 {
                                                    Text("\(tabCount)")
                                                        .font(.system(size: 10, weight: .bold))
                                                        .padding(.horizontal, 5)
                                                        .padding(.vertical, 1)
                                                        .background(
                                                            Capsule()
                                                                .fill(isActive ? AppTheme.accent : Color.black.opacity(0.06))
                                                        )
                                                        .foregroundColor(AppTheme.textPrimary)
                                                }
                                            }
                                            .padding(.top, 12)
                                            .padding(.horizontal, 4)

                                            // Active Underline Indicator Bar
                                            Rectangle()
                                                .fill(isActive ? AppTheme.textPrimary : Color.clear)
                                                .frame(height: 2.5)
                                                .cornerRadius(1)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .background(isActive ? Color.black.opacity(0.02) : Color.clear)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .background(Color.white)

                            Divider().overlay(Color.black.opacity(0.06))

                            // 2. Table Action Toolbar (Count, Multi-select, Sort)
                            HStack {
                                if isSelectionMode {
                                    Button {
                                        if selectedIds.count == displayedItems.count {
                                            selectedIds.removeAll()
                                        } else {
                                            selectedIds = Set(displayedItems.map { $0.id })
                                        }
                                        LBHaptic.light()
                                    } label: {
                                        HStack(spacing: 5) {
                                            Image(systemName: selectedIds.count == displayedItems.count && !displayedItems.isEmpty ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 13))
                                            Text(selectedIds.count == displayedItems.count && !displayedItems.isEmpty ? "Deselect All" : "Select All")
                                                .font(.caption2.weight(.bold))
                                        }
                                        .foregroundColor(AppTheme.textPrimary)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    Text("\(displayedItems.count) in \(activeTab.rawValue.lowercased())")
                                        .font(.caption2.weight(.bold))
                                        .foregroundColor(AppTheme.textSecondary)
                                        .textCase(.uppercase)
                                }

                                Spacer()

                                HStack(spacing: 12) {
                                    // Sort Order Button
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.18)) {
                                            sortOrder = (sortOrder == .latest) ? .oldest : .latest
                                        }
                                        LBHaptic.light()
                                    } label: {
                                        HStack(spacing: 3) {
                                            Image(systemName: "arrow.up.arrow.down")
                                                .font(.system(size: 10, weight: .bold))
                                            Text(sortOrder == .latest ? "Newest" : "Oldest")
                                                .font(.caption2.weight(.medium))
                                        }
                                        .foregroundColor(AppTheme.textSecondary)
                                    }
                                    .buttonStyle(.plain)

                                    // Multi-select Toggle Button
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            isSelectionMode.toggle()
                                            if !isSelectionMode { selectedIds.removeAll() }
                                        }
                                        LBHaptic.light()
                                    } label: {
                                        Text(isSelectionMode ? "Done" : "Select")
                                            .font(.caption2.weight(.bold))
                                            .foregroundColor(isSelectionMode ? AppTheme.amber : AppTheme.textPrimary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color(hex: "FAF8F5").opacity(0.8))

                            Divider().overlay(Color.black.opacity(0.06))

                            // 3. Email Rows List
                            if displayedItems.isEmpty {
                                VStack(spacing: 14) {
                                    Image(systemName: "tray.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary.opacity(0.35))
                                    Text("Inbox Zero!")
                                        .font(.headline)
                                        .foregroundColor(AppTheme.textPrimary)
                                    Text("All caught up. Everything saved has been processed or reviewed.")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(40)
                                .background(Color.white)
                            } else {
                                LazyVStack(spacing: 0) {
                                    ForEach(displayedItems) { item in
                                        if isSelectionMode {
                                            EmailInboxRowView(
                                                item: item,
                                                isSelectionMode: true,
                                                isSelected: selectedIds.contains(item.id),
                                                onToggleSelect: {
                                                    if selectedIds.contains(item.id) {
                                                        selectedIds.remove(item.id)
                                                    } else {
                                                        selectedIds.insert(item.id)
                                                    }
                                                    LBHaptic.light()
                                                },
                                                onToggleFavorite: { coordinator.toggleFavorite(item: item, context: modelContext) },
                                                onMarkDone: { coordinator.markDone(item: item, context: modelContext) },
                                                onSchedule: { date in coordinator.scheduleItem(item: item, date: date, context: modelContext) },
                                                onDelete: { coordinator.deleteItem(item: item, context: modelContext) }
                                            )
                                        } else {
                                            NavigationLink(destination: ItemDetailView(item: item)) {
                                                EmailInboxRowView(
                                                    item: item,
                                                    isSelectionMode: false,
                                                    isSelected: false,
                                                    onToggleSelect: {},
                                                    onToggleFavorite: { coordinator.toggleFavorite(item: item, context: modelContext) },
                                                    onMarkDone: { coordinator.markDone(item: item, context: modelContext) },
                                                    onSchedule: { date in coordinator.scheduleItem(item: item, date: date, context: modelContext) },
                                                    onDelete: { coordinator.deleteItem(item: item, context: modelContext) }
                                                )
                                            }
                                            .buttonStyle(.plain)
                                        }

                                        if item.id != displayedItems.last?.id {
                                            Divider()
                                                .overlay(Color.black.opacity(0.05))
                                                .padding(.leading, 42)
                                        }
                                    }
                                }
                            }
                        }
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, isSelectionMode && !selectedIds.isEmpty ? 90 : 30)
                }
                .trackPullDownForLaterAI()

                // Floating Batch Selection Toolbar (when items selected)
                if isSelectionMode && !selectedIds.isEmpty {
                    HStack(spacing: 16) {
                        Text("\(selectedIds.count) selected")
                            .font(.caption.weight(.bold))
                            .foregroundColor(AppTheme.textOnDark)

                        Spacer()

                        Button(action: {
                            let items = displayedItems.filter { selectedIds.contains($0.id) }
                            for item in items {
                                if !item.favorite {
                                    coordinator.toggleFavorite(item: item, context: modelContext)
                                }
                            }
                            selectedIds.removeAll()
                            isSelectionMode = false
                        }) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.amber)
                        }
                        .accessibilityLabel("Star selected")

                        Button(action: {
                            let items = displayedItems.filter { selectedIds.contains($0.id) }
                            for item in items {
                                coordinator.markDone(item: item, context: modelContext)
                            }
                            selectedIds.removeAll()
                            isSelectionMode = false
                        }) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 15))
                                .foregroundColor(.green)
                        }
                        .accessibilityLabel("Mark selected as kept")

                        Button(action: {
                            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                            let items = displayedItems.filter { selectedIds.contains($0.id) }
                            for item in items {
                                coordinator.scheduleItem(item: item, date: tomorrow, context: modelContext)
                            }
                            selectedIds.removeAll()
                            isSelectionMode = false
                        }) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 15))
                                .foregroundColor(.orange)
                        }
                        .accessibilityLabel("Snooze selected")

                        Button(action: {
                            let items = displayedItems.filter { selectedIds.contains($0.id) }
                            for item in items {
                                coordinator.deleteItem(item: item, context: modelContext)
                            }
                            selectedIds.removeAll()
                            isSelectionMode = false
                        }) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 15))
                                .foregroundColor(.red)
                        }
                        .accessibilityLabel("Delete selected")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(AppTheme.darkSurface, in: Capsule())
                    .shadow(color: Color.black.opacity(0.22), radius: 12, y: 6)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showingSearch) { VaultSearchView() }
        .sheet(isPresented: $showingOrganizer) { AIOrganizerSheet() }
    }
}
