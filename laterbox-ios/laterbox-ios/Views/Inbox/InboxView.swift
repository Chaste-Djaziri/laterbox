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
    @Query(sort: \LBCollection.name) private var availableCollections: [LBCollection]
    @ObservedObject var coordinator = SyncCoordinator.shared
    @ObservedObject var storeKit = StoreKitManager.shared

    private var isGuest: Bool {
        coordinator.currentUserEmail == nil || coordinator.currentUserEmail?.isEmpty == true
    }

    private var isPro: Bool {
        coordinator.isProUser || storeKit.isProSubscriptionActive
    }

    @State private var showingSidebar: Bool = false
    @State private var showingOrganizer: Bool = false
    @State private var selectedMailbox: MailboxViewType = .inbox
    @State private var selectedCollection: String? = nil
    @State private var showingPlans: Bool = false
    @State private var navigateToSettings: Bool = false
    @State private var navigateToCapture: Bool = false
    @State private var showingQuickCapture: Bool = false
    @State private var showingEmptyTrashConfirm: Bool = false
    @State private var isRefreshingInbox: Bool = false
    @State private var showingExitGuestConfirm: Bool = false
    @State private var showingSignOutConfirm: Bool = false
    @State private var showingProfileMenu: Bool = false
    @State private var collectionTargetItem: LBItem? = nil
    @State private var snoozeTargetItem: LBItem? = nil
    @State private var newCollectionName: String = ""

    // Search Interaction States
    @State private var isSearchActive: Bool = false
    @State private var searchQuery: String = ""
    @FocusState private var isSearchFocused: Bool
    @State private var selectedSearchFormat: ItemContentType? = nil
    @State private var searchStarredOnly: Bool = false
    @State private var searchHasAttachmentOnly: Bool = false

    public init() {}

    private func profileMenuRow(_ title: String, icon: String, destructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .foregroundStyle(destructive ? Color.red : AppTheme.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var rawInboxItems: [LBItem] {
        let items: [LBItem]
        if let col = selectedCollection {
            items = allItems.filter {
                $0.status != ItemStatus.deleted.rawValue &&
                ($0.category.localizedCaseInsensitiveCompare(col) == .orderedSame ||
                 $0.collectionName?.localizedCaseInsensitiveCompare(col) == .orderedSame)
            }
        } else {
            let now = Date()
            let cal = Calendar.current
            let endOfToday = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: now)) ?? now

            switch selectedMailbox {
            case .inbox:
                items = allItems.filter {
                    $0.status == ItemStatus.inbox.rawValue ||
                    ($0.status == ItemStatus.deferred.rawValue && $0.returnAt != nil && $0.returnAt! <= now)
                }
            case .today:
                items = allItems.filter {
                    $0.status == ItemStatus.deferred.rawValue &&
                    $0.returnAt != nil &&
                    $0.returnAt! > now &&
                    $0.returnAt! <= endOfToday
                }
            case .scheduled:
                items = allItems.filter {
                    $0.status == ItemStatus.deferred.rawValue &&
                    $0.returnAt != nil &&
                    $0.returnAt! > endOfToday
                }
            case .someday:
                items = allItems.filter {
                    $0.status == ItemStatus.deferred.rawValue && $0.returnAt == nil
                }
            case .starred:
                items = allItems.filter { $0.favorite && $0.status != ItemStatus.deleted.rawValue }
            case .kept:
                items = allItems.filter { $0.status == ItemStatus.saved.rawValue }
            case .archived:
                items = allItems.filter { $0.status == ItemStatus.archived.rawValue }
            case .trash:
                items = allItems.filter { $0.status == ItemStatus.deleted.rawValue }
            }
        }
        return items.deduplicatedForDisplay()
    }

    private var emptyTitleText: String {
        if let col = selectedCollection { return "No items in #\(col)" }
        switch selectedMailbox {
        case .inbox: return "Inbox Zero!"
        case .today: return "No Items Due Today"
        case .scheduled: return "No Scheduled Items"
        case .someday: return "Someday Vault is Empty"
        case .starred: return "No Starred Items"
        case .kept: return "No Kept Items"
        case .archived: return "No Archived Items"
        case .trash: return "Trash is Empty"
        }
    }

    private var emptySubtitleText: String {
        if selectedCollection != nil { return "Items tagged with this collection will appear here." }
        switch selectedMailbox {
        case .inbox: return "All caught up. Everything saved has been processed or reviewed."
        case .today: return "You have no items scheduled for review today."
        case .scheduled: return "Items scheduled for upcoming dates will appear here."
        case .someday: return "Ideas, inspiration, and backlog items with no deadline appear here."
        case .starred: return "Star items to quickly find them here."
        case .kept: return "Items you've kept will appear here."
        case .archived: return "Archived items will appear here."
        case .trash: return "Deleted items will appear here before being permanently erased."
        }
    }

    private var userInitial: String {
        if let email = coordinator.currentUserEmail, let first = email.first {
            return String(first).uppercased()
        }
        return "U"
    }

    private var defaultRecentSearches: [String] {
        var recents: [String] = []
        for item in rawInboxItems.prefix(2) {
            if let domain = item.domain, !domain.isEmpty, !recents.contains(domain) {
                recents.append(domain)
            }
        }
        for item in ["Articles", "Starred", "LaterBox", "Video"] {
            if !recents.contains(item) { recents.append(item) }
        }
        return Array(recents.prefix(5))
    }

    private var searchResults: [LBItem] {
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var list = allItems.filter { $0.status != ItemStatus.deleted.rawValue }

        if let format = selectedSearchFormat {
            list = list.filter { $0.type == format.rawValue }
        }

        if searchStarredOnly {
            list = list.filter { $0.favorite }
        }

        if searchHasAttachmentOnly {
            list = list.filter { $0.attachmentsData != nil }
        }

        if q.isEmpty {
            return list.deduplicatedForDisplay()
        }

        return list.filter { item in
            let title = item.title.lowercased()
            let domain = (item.domain ?? item.url ?? "").lowercased()
            let desc = (item.metadataDescription ?? "").lowercased()
            let note = (item.noteContent ?? "").lowercased()
            let summary = item.summary.lowercased()
            let author = (item.siteName ?? "").lowercased()
            let tags = item.tags.map { $0.lowercased() }.joined(separator: " ")

            return title.contains(q) ||
                   domain.contains(q) ||
                   desc.contains(q) ||
                   note.contains(q) ||
                   summary.contains(q) ||
                   author.contains(q) ||
                   tags.contains(q)
        }.deduplicatedForDisplay()
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F7F5EE").ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                        // 1. Mobile Top Search Bar (Inactive vs Active Expanding state)
                        if !isSearchActive {
                            // Standard Top Bar
                            HStack(spacing: 10) {
                                Button {
                                    LBHaptic.light()
                                    withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                                        showingSidebar = true
                                    }
                                } label: {
                                    Image(systemName: "line.3.horizontal")
                                        .font(.system(size: 20, weight: .regular))
                                        .foregroundColor(AppTheme.textPrimary)
                                        .frame(width: 36, height: 36)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Open sidebar")

                                Button {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                        isSearchActive = true
                                    }
                                    isSearchFocused = true
                                    LBHaptic.light()
                                } label: {
                                    HStack(spacing: 8) {
                                        Text("Ask LaterBox")
                                            .font(.system(size: 16, weight: .regular))
                                            .foregroundColor(Color.secondary)

                                        Spacer()

                                        Image(systemName: "sparkles")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Color(hex: "1A73E8"))
                                    }
                                    .padding(.horizontal, 16)
                                    .frame(height: 48)
                                    .background(Color.white, in: Capsule())
                                    .overlay(
                                        Capsule().strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
                                    )
                                    .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Search inbox")

                                Button {
                                    showingProfileMenu = true
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: "171711"))
                                            .frame(width: 36, height: 36)
                                        Text(userInitial)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    .overlay(
                                        Circle().stroke(Color(hex: "1A73E8"), lineWidth: 2)
                                    )
                                }
                                .buttonStyle(.plain)
                                .popover(isPresented: $showingProfileMenu, arrowEdge: .top) {
                                    VStack(alignment: .leading, spacing: 0) {
                                        profileMenuRow("Settings", icon: "gearshape.fill") {
                                            showingProfileMenu = false
                                            navigateToSettings = true
                                        }

                                        Divider().padding(.vertical, 6)

                                        if let email = coordinator.currentUserEmail, !email.isEmpty {
                                            Text(email)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                                .padding(.horizontal, 16)
                                                .padding(.bottom, 6)
                                            profileMenuRow("Log Out", icon: "rectangle.portrait.and.arrow.right", destructive: true) {
                                                showingProfileMenu = false
                                                showingSignOutConfirm = true
                                            }
                                        } else {
                                            Text("Guest Mode")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                                .padding(.horizontal, 16)
                                                .padding(.bottom, 6)
                                            profileMenuRow("Log In", icon: "person.crop.circle.badge.plus") {
                                                showingProfileMenu = false
                                                coordinator.showingAuthSheet = true
                                                LBHaptic.medium()
                                            }
                                            profileMenuRow("Exit Guest & Clear Data", icon: "rectangle.portrait.and.arrow.right", destructive: true) {
                                                showingProfileMenu = false
                                                showingExitGuestConfirm = true
                                            }
                                        }
                                    }
                                    .padding(.vertical, 10)
                                    .frame(width: 285)
                                    .presentationCompactAdaptation(.popover)
                                }
                                .accessibilityLabel("Profile menu")
                            }
                            .padding(.horizontal, 14)
                            .padding(.top, 10)
                            .padding(.bottom, 8)
                        } else {
                            // Active Expanded Search Top Bar (Matching Image 1 & 2 layout)
                            HStack(spacing: 10) {
                                Button {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                        isSearchActive = false
                                        searchQuery = ""
                                        selectedSearchFormat = nil
                                        searchStarredOnly = false
                                        searchHasAttachmentOnly = false
                                    }
                                    isSearchFocused = false
                                    LBHaptic.light()
                                } label: {
                                    Image(systemName: "arrow.left")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(AppTheme.textPrimary)
                                        .frame(width: 36, height: 36)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Back to inbox")

                                HStack(spacing: 8) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(Color.secondary)

                                    TextField("Search in LaterBox", text: $searchQuery)
                                        .font(.system(size: 16))
                                        .foregroundColor(AppTheme.textPrimary)
                                        .focused($isSearchFocused)
                                        .submitLabel(.search)

                                    if !searchQuery.isEmpty {
                                        Button {
                                            searchQuery = ""
                                            LBHaptic.light()
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(Color.secondary.opacity(0.7))
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Color(hex: "1A73E8"))
                                    }
                                }
                                .padding(.horizontal, 14)
                                .frame(height: 48)
                                .background(Color.white, in: Capsule())
                                .overlay(
                                    Capsule().strokeBorder(Color.black.opacity(0.1), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
                            }
                            .padding(.horizontal, 14)
                            .padding(.top, 10)
                            .padding(.bottom, 4)

                            // Horizontal Filter Chips Bar (Labels, Format, Starred, Attachment)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    // Starred Toggle Pill
                                    Button {
                                        searchStarredOnly.toggle()
                                        LBHaptic.light()
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: searchStarredOnly ? "star.fill" : "star")
                                                .font(.system(size: 11, weight: .bold))
                                            Text("Starred")
                                                .font(.system(size: 12, weight: .medium))
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(searchStarredOnly ? Color(hex: "171711") : Color.white, in: Capsule())
                                        .foregroundColor(searchStarredOnly ? Color(hex: "E6EDB0") : AppTheme.textPrimary)
                                        .overlay(
                                            Capsule().strokeBorder(searchStarredOnly ? Color.clear : Color.black.opacity(0.08), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)

                                    // Has Attachment Toggle Pill
                                    Button {
                                        searchHasAttachmentOnly.toggle()
                                        LBHaptic.light()
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "paperclip")
                                                .font(.system(size: 11, weight: .bold))
                                            Text("Attachment")
                                                .font(.system(size: 12, weight: .medium))
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(searchHasAttachmentOnly ? Color(hex: "171711") : Color.white, in: Capsule())
                                        .foregroundColor(searchHasAttachmentOnly ? Color(hex: "E6EDB0") : AppTheme.textPrimary)
                                        .overlay(
                                            Capsule().strokeBorder(searchHasAttachmentOnly ? Color.clear : Color.black.opacity(0.08), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)

                                    // Format Pills
                                    ForEach([ItemContentType.article, ItemContentType.video, ItemContentType.note], id: \.self) { type in
                                        let isSelected = selectedSearchFormat == type
                                        Button {
                                            selectedSearchFormat = isSelected ? nil : type
                                            LBHaptic.light()
                                        } label: {
                                            HStack(spacing: 4) {
                                                Image(systemName: type.systemIcon)
                                                    .font(.system(size: 11, weight: .bold))
                                                Text(type.rawValue.capitalized)
                                                    .font(.system(size: 12, weight: .medium))
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(isSelected ? Color(hex: "171711") : Color.white, in: Capsule())
                                            .foregroundColor(isSelected ? Color(hex: "E6EDB0") : AppTheme.textPrimary)
                                            .overlay(
                                                Capsule().strokeBorder(isSelected ? Color.clear : Color.black.opacity(0.08), lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }

                                    // Reset filters if any active
                                    if searchStarredOnly || searchHasAttachmentOnly || selectedSearchFormat != nil {
                                        Button {
                                            searchStarredOnly = false
                                            searchHasAttachmentOnly = false
                                            selectedSearchFormat = nil
                                            LBHaptic.light()
                                        } label: {
                                            Text("Reset")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(Color.secondary)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 7)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                            }
                        }

                        // 2. Main Content Area
                        if isSearchActive {
                            if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !searchStarredOnly && !searchHasAttachmentOnly && selectedSearchFormat == nil {
                                // Recent Searches (Matching Image 2 layout with our theme)
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Recent searches")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(Color.secondary)
                                        .padding(.horizontal, 18)
                                        .padding(.top, 12)

                                    VStack(spacing: 1.5) {
                                        ForEach(defaultRecentSearches, id: \.self) { search in
                                            Button {
                                                searchQuery = search
                                                LBHaptic.light()
                                            } label: {
                                                HStack(spacing: 14) {
                                                    Image(systemName: "clock.arrow.circlepath")
                                                        .font(.system(size: 15))
                                                        .foregroundColor(Color.secondary)

                                                    Text(search)
                                                        .font(.system(size: 15, weight: .regular))
                                                        .foregroundColor(AppTheme.textPrimary)

                                                    Spacer()

                                                    Image(systemName: "arrow.up.left")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(Color.secondary.opacity(0.6))
                                                }
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 14)
                                                .background(Color.white)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                                    )
                                    .padding(.horizontal, 12)
                                }
                            } else {
                                // Search Quick Results (Matching Image 1 layout with our segmented email cards)
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Quick results (\(searchResults.count))")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(Color.secondary)
                                        .padding(.horizontal, 18)
                                        .padding(.top, 10)

                                    if searchResults.isEmpty {
                                        VStack(spacing: 12) {
                                            Image(systemName: "magnifyingglass")
                                                .font(.system(size: 36))
                                                .foregroundColor(.secondary.opacity(0.4))
                                            Text(searchQuery.isEmpty ? "No items matching filters" : "No results for \"\(searchQuery)\"")
                                                .font(.headline)
                                                .foregroundColor(AppTheme.textPrimary)
                                            Text("Try adjusting your keywords or clearing active filters.")
                                                .font(.caption)
                                                .foregroundColor(AppTheme.textSecondary)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(40)
                                        .background(Color.white)
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                                        )
                                        .padding(.horizontal, 12)
                                        .padding(.top, 10)
                                    } else {
                                        LazyVStack(spacing: 2.5) {
                                            ForEach(Array(searchResults.enumerated()), id: \.element.id) { index, item in
                                                let isFirst = index == 0
                                                let isLast = index == searchResults.count - 1
                                                let topRadius: CGFloat = isFirst ? 12 : 4
                                                let bottomRadius: CGFloat = isLast ? 12 : 4

                                                NavigationLink(destination: ItemDetailView(item: item)) {
                                                    EmailInboxRowView(
                                                        item: item,
                                                        topRadius: topRadius,
                                                        bottomRadius: bottomRadius,
                                                        onToggleFavorite: { coordinator.toggleFavorite(item: item, context: modelContext) },
                                                        onMarkDone: { coordinator.markDone(item: item, context: modelContext) },
                                                        onSchedule: { date in coordinator.scheduleItem(item: item, date: date, context: modelContext) },
                                                        onOpenSchedule: { snoozeTargetItem = item },
                                                        onDelete: { coordinator.deleteItem(item: item, context: modelContext) },
                                                        onDeletePermanently: { deletePermanently(item: item) },
                                                        onRestore: { restoreItem(item: item) },
                                                        onAddToCollection: { collectionTargetItem = item }
                                                    )
                                                }
                                                .buttonStyle(.plain)
                                        // Reset UIKit swipe state when an item moves between mailboxes.
                                        .id("\(item.status)-search-\(item.id)")
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                    }
                                }
                            }
                        } else {
                            // Inactive State: Section Title + Standard Inbox Segmented Cards
                            HStack {
                                Text(selectedCollection != nil ? "#\(selectedCollection!)" : selectedMailbox.rawValue)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Color.secondary)

                                if selectedCollection != nil || selectedMailbox != .inbox {
                                    Button {
                                        selectedMailbox = .inbox
                                        selectedCollection = nil
                                        LBHaptic.light()
                                    } label: {
                                        HStack(spacing: 3) {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 9, weight: .bold))
                                            Text("Show Inbox")
                                                .font(.system(size: 11, weight: .semibold))
                                        }
                                        .foregroundColor(Color(hex: "171711"))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color(hex: "E6EDB0"), in: Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }

                                Spacer()

                                if selectedMailbox == .trash && !rawInboxItems.isEmpty {
                                    Button(role: .destructive) {
                                        showingEmptyTrashConfirm = true
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "trash")
                                                .font(.system(size: 11, weight: .bold))
                                            Text("Delete All")
                                                .font(.system(size: 11, weight: .bold))
                                        }
                                        .foregroundColor(Color.red)
                                        .padding(.horizontal, 9)
                                        .padding(.vertical, 4)
                                        .background(Color.red.opacity(0.12), in: Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.top, 14)
                            .padding(.bottom, 8)

                            if rawInboxItems.isEmpty {
                                VStack(spacing: 14) {
                                    Image(systemName: selectedCollection != nil ? "tag.fill" : selectedMailbox.systemIcon)
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary.opacity(0.35))
                                    Text(emptyTitleText)
                                        .font(.headline)
                                        .foregroundColor(AppTheme.textPrimary)
                                    Text(emptySubtitleText)
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(48)
                                .background(Color.white)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                                )
                                .padding(.horizontal, 12)
                                .padding(.top, 12)
                            } else {
                                LazyVStack(spacing: 2.5) {
                                    ForEach(Array(rawInboxItems.enumerated()), id: \.element.id) { index, item in
                                        let isFirst = index == 0
                                        let isLast = index == rawInboxItems.count - 1
                                        let topRadius: CGFloat = isFirst ? 12 : 4
                                        let bottomRadius: CGFloat = isLast ? 12 : 4

                                        NavigationLink(destination: ItemDetailView(item: item)) {
                                            EmailInboxRowView(
                                                item: item,
                                                topRadius: topRadius,
                                                bottomRadius: bottomRadius,
                                                onToggleFavorite: { coordinator.toggleFavorite(item: item, context: modelContext) },
                                                onMarkDone: { coordinator.markDone(item: item, context: modelContext) },
                                                onSchedule: { date in coordinator.scheduleItem(item: item, date: date, context: modelContext) },
                                                onOpenSchedule: { snoozeTargetItem = item },
                                                onDelete: { coordinator.deleteItem(item: item, context: modelContext) },
                                                onDeletePermanently: { deletePermanently(item: item) },
                                                onRestore: { restoreItem(item: item) },
                                                onAddToCollection: { collectionTargetItem = item }
                                            )
                                        }
                                        .buttonStyle(.plain)
                                        // Reset UIKit swipe state when an item moves between mailboxes.
                                        .id("\(selectedMailbox.rawValue)-\(selectedCollection ?? "")-\(item.id)")
                                    }
                                }
                                .padding(.horizontal, 12)
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
                .refreshable {
                    LBHaptic.medium()
                    await MainActor.run { isRefreshingInbox = true }
                    await coordinator.syncPendingItems(context: modelContext, announceFailure: false)
                    await MainActor.run { isRefreshingInbox = false }
                }
                .tint(.clear)

                if isRefreshingInbox {
                    HStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(Color(hex: "2563EB"))
                        Text("Syncing…")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: Capsule())
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                bottomStatusBar
            }
            .ignoresSafeArea(edges: .bottom)

            // Floating Action Button (+)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        navigateToCapture = true
                        LBHaptic.medium()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(AppTheme.accent)
                            .frame(width: 56, height: 56)
                            .background(AppTheme.darkSurface, in: Circle())
                            .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Capture Item")
                    .accessibilityIdentifier("Open Later AI")
                    .padding(.trailing, 20)
                    .padding(.bottom, max(10, bottomSafeAreaInset) + 56)
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .zIndex(95)
            .transaction { $0.animation = nil }

                // Dimming backdrop
                if showingSidebar {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                                showingSidebar = false
                            }
                        }
                        .zIndex(90)
                }

                // Slide-in Left Drawer (physical horizontal slide in/out from left without fade)
                let drawerWidth = min(UIScreen.main.bounds.width * 0.82, 310)
                HStack(spacing: 0) {
                    MobileSidebarDrawer(
                        isPresented: $showingSidebar,
                        activeMailbox: selectedMailbox,
                        activeCollection: selectedCollection,
                        onSelectMailbox: { mailbox in
                            selectedMailbox = mailbox
                            selectedCollection = nil
                        },
                        onSelectCollection: { colName in
                            selectedCollection = colName
                        },
                        onOpenReturns: { segment in
                            switch segment {
                            case .today:
                                selectedMailbox = .today
                            case .upcoming:
                                selectedMailbox = .scheduled
                            case .someday:
                                selectedMailbox = .someday
                            }
                            selectedCollection = nil
                        },
                        onOpenPlans: {
                            showingPlans = true
                        },
                        onOpenSettings: {
                            navigateToSettings = true
                        }
                    )
                    .frame(width: drawerWidth)

                    Spacer()
                }
                .ignoresSafeArea()
                .offset(x: showingSidebar ? 0 : -drawerWidth - 30)
                .animation(.spring(response: 0.32, dampingFraction: 0.85), value: showingSidebar)
                .allowsHitTesting(showingSidebar)
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            if value.translation.width < -40 {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                                    showingSidebar = false
                                }
                            }
                        }
                )
                .zIndex(100)
            }
            .navigationBarHidden(true)
            .confirmationDialog(
                "Delete All Items?",
                isPresented: $showingEmptyTrashConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete All Permanently", role: .destructive) {
                    emptyTrashPermanently()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone. All items in the trash will be permanently erased.")
            }
            .confirmationDialog(
                "Exit Guest Mode",
                isPresented: $showingExitGuestConfirm,
                titleVisibility: .visible
            ) {
                Button("Exit & Clear Data", role: .destructive) {
                    coordinator.exitGuest(context: modelContext)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Exiting guest mode will clear all items saved on this device during this guest session.")
            }
            .confirmationDialog(
                "Sign Out",
                isPresented: $showingSignOutConfirm,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    coordinator.signOut()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your local items will be safely kept on this device.")
            }
            .sheet(isPresented: $showingOrganizer) {
                AIOrganizerSheet()
            }
            .sheet(isPresented: $showingPlans) {
                PlansView()
            }
            .navigationDestination(isPresented: $navigateToSettings) {
                SettingsView()
            }
            .navigationDestination(isPresented: $navigateToCapture) {
                CaptureView()
                    .whiteStatusBar()
            }
            .onChange(of: navigateToCapture) { _, isNavigating in
                coordinator.isShowingCapture = isNavigating
                StatusBarStyleModifier.apply(isNavigating ? .dark : .light)
            }
            .sheet(isPresented: $showingQuickCapture) {
                QuickCaptureSheet()
            }
            .sheet(item: $collectionTargetItem) { targetItem in
                collectionPickerSheet(for: targetItem)
            }
            .sheet(item: $snoozeTargetItem) { targetItem in
                SnoozeDatePickerSheet(
                    itemTitle: targetItem.title,
                    initialDate: targetItem.returnAt,
                    onSchedule: { newDate in
                        coordinator.scheduleItem(item: targetItem, date: newDate, context: modelContext)
                    },
                    onUnsnooze: {
                        targetItem.status = ItemStatus.inbox.rawValue
                        targetItem.returnAt = nil
                        targetItem.updatedAt = Date()
                        targetItem.isSyncPending = true
                        try? modelContext.save()
                        Task { await coordinator.syncPendingItems(context: modelContext) }
                    }
                )
            }
            .onAppear {
                LBItem.cleanupDuplicatesInStore(context: modelContext)
                coordinator.refreshPendingCounts(context: modelContext)
            }
        }
    }

    // MARK: - Permanent Delete & Restore Actions

    private func deletePermanently(item: LBItem) {
        modelContext.delete(item)
        try? modelContext.save()
        LBHaptic.warning()
    }

    // MARK: - Collection Picker Sheet

    private func collectionPickerSheet(for targetItem: LBItem) -> some View {
        NavigationStack {
            List {
                Section("Current Collection") {
                    if let current = targetItem.collectionName, !current.isEmpty {
                        HStack {
                            Text(current)
                                .font(.system(size: 15, weight: .semibold))
                            Spacer()
                            Button("Remove") {
                                targetItem.collectionName = nil
                                targetItem.collectionId = nil
                                targetItem.category = ""
                                targetItem.updatedAt = Date()
                                targetItem.isSyncPending = true
                                try? modelContext.save()
                                Task { await coordinator.syncPendingItems(context: modelContext) }
                                collectionTargetItem = nil
                                LBHaptic.light()
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.red)
                        }
                    } else {
                        Text("No collection assigned")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }

                Section("Available Collections") {
                    ForEach(availableCollections) { coll in
                        Button {
                            targetItem.collectionName = coll.name
                            targetItem.collectionId = coll.id
                            targetItem.category = coll.name
                            targetItem.updatedAt = Date()
                            targetItem.isSyncPending = true
                            try? modelContext.save()
                            Task { await coordinator.syncPendingItems(context: modelContext) }
                            collectionTargetItem = nil
                            LBHaptic.medium()
                        } label: {
                            HStack {
                                Image(systemName: coll.iconName)
                                    .foregroundColor(Color(hex: coll.colorHex))
                                Text(coll.name)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(AppTheme.textPrimary)
                                Spacer()
                                if targetItem.collectionName == coll.name {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(Color(hex: "0369A1"))
                                }
                            }
                        }
                    }
                }

                Section("Create New Collection") {
                    HStack {
                        TextField("New collection name", text: $newCollectionName)
                            .font(.system(size: 14))
                        Button("Add") {
                            let trimmed = newCollectionName.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty {
                                let coll = coordinator.ensureCollectionExists(named: trimmed, context: modelContext)
                                targetItem.collectionName = coll?.name ?? trimmed
                                targetItem.collectionId = coll?.id ?? targetItem.collectionId
                                targetItem.category = trimmed
                                targetItem.updatedAt = Date()
                                targetItem.isSyncPending = true
                                try? modelContext.save()
                                Task { await coordinator.syncPendingItems(context: modelContext) }
                                newCollectionName = ""
                                collectionTargetItem = nil
                                LBHaptic.medium()
                            }
                        }
                        .disabled(newCollectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .font(.system(size: 13, weight: .bold))
                    }
                }
            }
            .navigationTitle("Collections")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { collectionTargetItem = nil }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func restoreItem(item: LBItem) {
        item.status = ItemStatus.inbox.rawValue
        item.updatedAt = Date()
        item.isSyncPending = true
        try? modelContext.save()
        LBHaptic.success()
    }

    private func emptyTrashPermanently() {
        let itemsToDelete = rawInboxItems
        for item in itemsToDelete {
            modelContext.delete(item)
        }
        try? modelContext.save()
        LBHaptic.warning()
    }

    // MARK: - Bottom Status & Motivational Bar

    private var bottomStatusBar: some View {
        HStack(spacing: 12) {
            if isGuest {
                // Guest / Local Vault status
                ZStack {
                    Circle()
                        .fill(Color(hex: "3B82F6").opacity(0.12))
                        .frame(width: 34, height: 34)
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(hex: "2563EB"))
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Guest / Local Vault")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)

                        Circle()
                            .fill(Color(hex: "9E9B92"))
                            .frame(width: 4, height: 4)

                        Text("Offline")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    Text("Sign in to backup & sync across devices")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Button {
                    coordinator.showingAuthSheet = true
                    LBHaptic.medium()
                } label: {
                    Text("Sign In")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color(hex: "171711"), in: Capsule())
                }
                .buttonStyle(.plain)
            } else if !isPro {
                // Free Plan status
                ZStack {
                    Circle()
                        .fill(Color(hex: "F59E0B").opacity(0.14))
                        .frame(width: 34, height: 34)
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "D97706"))
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Free Plan")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)

                        Text("LIMITED")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundColor(Color(hex: "D97706"))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(Color(hex: "F59E0B").opacity(0.14), in: Capsule())
                    }

                    Text("Upgrade to Pro for cloud sync & AI")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Button {
                    showingPlans = true
                    LBHaptic.medium()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "E6EDB0"))
                        Text("Get Pro")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 13)
                    .padding(.vertical, 7)
                    .background(Color(hex: "171711"), in: Capsule())
                }
                .buttonStyle(.plain)
            } else {
                // Pro Member status with dynamic Pull / Push / Pull&Push actions
                let isSyncing = coordinator.syncState == .syncing || coordinator.isPulling || coordinator.isPushing
                let hasPull = coordinator.pendingPullCount > 0
                let hasPush = coordinator.pendingPushCount > 0

                if isSyncing {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "3B82F6").opacity(0.14))
                            .frame(width: 34, height: 34)
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "2563EB")))
                            .scaleEffect(0.85)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("Cloud Sync")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)

                            Text("SYNCING")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundColor(Color(hex: "2563EB"))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: "3B82F6").opacity(0.12), in: Capsule())
                        }

                        Text(coordinator.isPulling ? "Pulling latest changes from cloud…" : (coordinator.isPushing ? "Pushing local edits to cloud…" : "Resolving conflicts & syncing…"))
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(AppTheme.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)
                } else if hasPull && hasPush {
                    // Both available: Pull first, then push
                    ZStack {
                        Circle()
                            .fill(Color(hex: "8B5CF6").opacity(0.14))
                            .frame(width: 34, height: 34)
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(hex: "8B5CF6"))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("Sync Needed")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)

                            HStack(spacing: 2) {
                                Text("\(coordinator.pendingPullCount)↓")
                                Text("•")
                                Text("\(coordinator.pendingPushCount)↑")
                            }
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundColor(Color(hex: "8B5CF6"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: "8B5CF6").opacity(0.12), in: Capsule())
                        }

                        Text("Pull remote changes first, then push local edits")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(AppTheme.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    Button {
                        LBHaptic.medium()
                        Task {
                            await coordinator.pullAndPushChanges(context: modelContext)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 10, weight: .bold))
                            Text("Pull & Push")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(Color(hex: "8B5CF6"), in: Capsule())
                    }
                    .buttonStyle(.plain)
                } else if hasPull {
                    // Pull available
                    ZStack {
                        Circle()
                            .fill(Color(hex: "3B82F6").opacity(0.14))
                            .frame(width: 34, height: 34)
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: "2563EB"))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("Cloud Updates")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)

                            Text("\(coordinator.pendingPullCount) NEW")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundColor(Color(hex: "2563EB"))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: "3B82F6").opacity(0.12), in: Capsule())
                        }

                        Text("\(coordinator.pendingPullCount) change\(coordinator.pendingPullCount == 1 ? "" : "s") available to pull")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(AppTheme.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    Button {
                        LBHaptic.medium()
                        Task {
                            await coordinator.pullChanges(context: modelContext)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 10, weight: .bold))
                            Text("Pull Changes")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(Color(hex: "2563EB"), in: Capsule())
                    }
                    .buttonStyle(.plain)
                } else if hasPush {
                    // Push available
                    ZStack {
                        Circle()
                            .fill(Color(hex: "F59E0B").opacity(0.14))
                            .frame(width: 34, height: 34)
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: "D97706"))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("Unsynced Edits")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)

                            Text("\(coordinator.pendingPushCount) LOCAL")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundColor(Color(hex: "D97706"))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: "F59E0B").opacity(0.12), in: Capsule())
                        }

                        Text("\(coordinator.pendingPushCount) edit\(coordinator.pendingPushCount == 1 ? "" : "s") pending push")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(AppTheme.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    Button {
                        LBHaptic.medium()
                        Task {
                            await coordinator.pushChanges(context: modelContext)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 10, weight: .bold))
                            Text("Push Changes")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(Color(hex: "D97706"), in: Capsule())
                    }
                    .buttonStyle(.plain)
                } else {
                    // Up to date
                    ZStack {
                        Circle()
                            .fill(Color(hex: "10B981").opacity(0.14))
                            .frame(width: 34, height: 34)
                        Image(systemName: "crown.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(hex: "10B981"))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("Pro Member")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)

                            HStack(spacing: 3) {
                                Circle()
                                    .fill(Color(hex: "10B981"))
                                    .frame(width: 5, height: 5)
                                Text("ACTIVE")
                                    .font(.system(size: 9, weight: .heavy))
                                    .foregroundColor(Color(hex: "10B981"))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: "10B981").opacity(0.12), in: Capsule())
                        }

                        Text("Cloud sync active • All changes up to date")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(AppTheme.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    Button {
                        LBHaptic.light()
                        Task {
                            await coordinator.checkRemoteChanges(context: modelContext)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 10))
                            Text("Check Sync")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(Color(hex: "10B981"))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(Color(hex: "10B981").opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, max(8, bottomSafeAreaInset))
        .frame(maxWidth: .infinity)
        .background(
            Color.white
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.black.opacity(0.07)),
                    alignment: .top
                )
        )
    }

    private var bottomSafeAreaInset: CGFloat {
        #if canImport(UIKit)
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        if let bottom = keyWindow?.safeAreaInsets.bottom, bottom > 0 {
            return bottom
        }
        #endif
        return 16
    }
}

#Preview("Inbox with Sample Items") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: LBItem.self, LBCollection.self, configurations: config)
    let context = container.mainContext

    let sample1 = LBItem(
        title: "Designing Fluid Interfaces for iOS",
        textContent: "Notes on spring animations, touch tracking, and gestural responsiveness in modern iOS interfaces.",
        type: .article,
        favorite: true,
        status: .inbox,
        domain: "apple.com",
        siteName: "Apple Developer",
        metadataDescription: "An in-depth look at gestures, springs, and momentum physics in user interfaces.",
        collectionName: "Design"
    )
    let sample2 = LBItem(
        url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
        title: "WWDC26: Swift 6 Concurrency and Beyond",
        type: .video,
        favorite: false,
        status: .inbox,
        domain: "youtube.com",
        siteName: "YouTube",
        collectionName: "Development"
    )
    let sample3 = LBItem(
        title: "Key takeaways from Distributed Systems Paper",
        textContent: "Consensus algorithms, CRDTs, and offline-first state synchronization techniques.",
        type: .note,
        favorite: false,
        status: .inbox,
        collectionName: "Research"
    )
    let col1 = LBCollection(name: "Design", colorHex: "#3B82F6", iconName: "paintpalette.fill")
    let col2 = LBCollection(name: "Development", colorHex: "#10B981", iconName: "chevron.left.forwardslash.chevron.right")
    let col3 = LBCollection(name: "Research", colorHex: "#8B5CF6", iconName: "book.fill")

    context.insert(sample1)
    context.insert(sample2)
    context.insert(sample3)
    context.insert(col1)
    context.insert(col2)
    context.insert(col3)

    return InboxView()
        .modelContainer(container)
}

#Preview("Inbox Empty State") {
    InboxView()
        .modelContainer(for: [LBItem.self, LBCollection.self], inMemory: true)
}
