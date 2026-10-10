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

    @State private var showingSidebar: Bool = false
    @State private var showingOrganizer: Bool = false

    // Search Interaction States
    @State private var isSearchActive: Bool = false
    @State private var searchQuery: String = ""
    @FocusState private var isSearchFocused: Bool
    @State private var selectedSearchFormat: ItemContentType? = nil
    @State private var searchStarredOnly: Bool = false
    @State private var searchHasAttachmentOnly: Bool = false

    public init() {}

    private var rawInboxItems: [LBItem] {
        allItems.filter { $0.status == ItemStatus.inbox.rawValue }
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

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // 1. Mobile Top Search Bar (Inactive vs Active Expanding state)
                        if !isSearchActive {
                            // Standard Top Bar
                            HStack(spacing: 10) {
                                Button {
                                    LBHaptic.light()
                                    showingSidebar = true
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
                                                        onDelete: { coordinator.deleteItem(item: item, context: modelContext) }
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
                            Text("Inbox")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color.secondary)
                                .padding(.horizontal, 18)
                                .padding(.top, 14)
                                .padding(.bottom, 8)

                            if rawInboxItems.isEmpty {
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
                                                onDelete: { coordinator.deleteItem(item: item, context: modelContext) }
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 12)
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
                .trackPullDownForLaterAI()
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSidebar) {
                MobileSidebarDrawer()
            }
            .sheet(isPresented: $showingOrganizer) {
                AIOrganizerSheet()
            }
        }
    }
}
