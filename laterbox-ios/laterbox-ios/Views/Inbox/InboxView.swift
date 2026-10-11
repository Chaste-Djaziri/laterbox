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
    @State private var showingLibrary: Bool = false
    @State private var showingPlans: Bool = false
    @State private var navigateToSettings: Bool = false
    @State private var showingQuickCapture: Bool = false
    @State private var showingEmptyTrashConfirm: Bool = false

    // Search Interaction States
    @State private var isSearchActive: Bool = false
    @State private var searchQuery: String = ""
    @FocusState private var isSearchFocused: Bool
    @State private var selectedSearchFormat: ItemContentType? = nil
    @State private var searchStarredOnly: Bool = false
    @State private var searchHasAttachmentOnly: Bool = false

    public init() {}

    private var rawInboxItems: [LBItem] {
        if let col = selectedCollection {
            return allItems.filter {
                $0.status != ItemStatus.deleted.rawValue &&
                ($0.category.localizedCaseInsensitiveCompare(col) == .orderedSame ||
                 $0.collectionName?.localizedCaseInsensitiveCompare(col) == .orderedSame)
            }
        }
        switch selectedMailbox {
        case .inbox:
            return allItems.filter { $0.status == ItemStatus.inbox.rawValue }
        case .today:
            let cal = Calendar.current
            let endOfToday = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: Date())) ?? Date()
            return allItems.filter {
                $0.status != ItemStatus.deleted.rawValue &&
                $0.status != ItemStatus.archived.rawValue &&
                $0.returnAt != nil &&
                ($0.returnAt! <= endOfToday)
            }
        case .scheduled:
            let cal = Calendar.current
            let endOfToday = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: Date())) ?? Date()
            return allItems.filter {
                $0.status != ItemStatus.deleted.rawValue &&
                $0.status != ItemStatus.archived.rawValue &&
                $0.returnAt != nil &&
                ($0.returnAt! > endOfToday)
            }
        case .someday:
            return allItems.filter {
                $0.status == ItemStatus.deferred.rawValue && $0.returnAt == nil
            }
        case .starred:
            return allItems.filter { $0.favorite && $0.status != ItemStatus.deleted.rawValue }
        case .kept:
            return allItems.filter { $0.status == ItemStatus.saved.rawValue }
        case .archived:
            return allItems.filter { $0.status == ItemStatus.archived.rawValue }
        case .trash:
            return allItems.filter { $0.status == ItemStatus.deleted.rawValue }
        }
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
        if let col = selectedCollection { return "Items tagged with this collection will appear here." }
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
            return list
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
        }
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

                                Menu {
                                    Section {
                                        Button {
                                            navigateToSettings = true
                                        } label: {
                                            Label("Settings", systemImage: "gearshape")
                                        }
                                    }

                                    if let email = coordinator.currentUserEmail, !email.isEmpty {
                                        Section(email) {
                                            Button(role: .destructive) {
                                                coordinator.signOut()
                                            } label: {
                                                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                            }
                                        }
                                    } else {
                                        Section("Guest Mode") {
                                            Button(role: .destructive) {
                                                coordinator.signOut()
                                            } label: {
                                                Label("Sign In / Exit Guest", systemImage: "rectangle.portrait.and.arrow.right")
                                            }
                                        }
                                    }
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
                                                        onDelete: { coordinator.deleteItem(item: item, context: modelContext) },
                                                        onDeletePermanently: { deletePermanently(item: item) },
                                                        onRestore: { restoreItem(item: item) }
                                                    )
                                                }
                                                .buttonStyle(.plain)
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
                                                onDelete: { coordinator.deleteItem(item: item, context: modelContext) },
                                                onDeletePermanently: { deletePermanently(item: item) },
                                                onRestore: { restoreItem(item: item) }
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 12)
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }

                bottomStatusBar
            }
            .ignoresSafeArea(edges: .bottom)

            // Floating Action Button (+): Home Page Only
            if !isSearchActive && !showingSidebar {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            LaterAIManager.shared.open()
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(AppTheme.accent)
                                .frame(width: 56, height: 56)
                                .background(AppTheme.darkSurface, in: Circle())
                                .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Open Later AI")
                        .padding(.trailing, 20)
                        .padding(.bottom, max(10, bottomSafeAreaInset) + 56)
                    }
                }
                .ignoresSafeArea(edges: .bottom)
                .transition(.scale.combined(with: .opacity))
                .zIndex(10)
            }

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
                        onOpenLibrary: {
                            showingLibrary = true
                        },
                        onOpenPlans: {
                            showingPlans = true
                        },
                        onOpenSettings: {
                            navigateToSettings = true
                        },
                        onOpenSaveItem: {
                            showingQuickCapture = true
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
            .sheet(isPresented: $showingOrganizer) {
                AIOrganizerSheet()
            }
            .sheet(isPresented: $showingLibrary) {
                LibraryView()
            }
            .sheet(isPresented: $showingPlans) {
                PlansView()
            }
            .navigationDestination(isPresented: $navigateToSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingQuickCapture) {
                QuickCaptureSheet()
            }
        }
    }

    // MARK: - Permanent Delete & Restore Actions

    private func deletePermanently(item: LBItem) {
        modelContext.delete(item)
        try? modelContext.save()
        LBHaptic.warning()
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
                // Pro Member status (motivational)
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

                    Text("Cloud sync active • Unlimited AI unlocked. Keep conquering!")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Button {
                    showingPlans = true
                    LBHaptic.light()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                        Text("Active")
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
