//
//  LibraryView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import SwiftUI
import SwiftData

public enum LibraryCategory: String, CaseIterable, Identifiable {
    case favorites = "Favorites"
    case kept = "Kept"
    case archived = "Archived"
    case deleted = "Recently Deleted"

    public var id: String { rawValue }

    public var systemIcon: String {
        switch self {
        case .favorites: return "star.fill"
        case .kept: return "bookmark.fill"
        case .archived: return "archivebox.fill"
        case .deleted: return "trash.fill"
        }
    }

    public var iconBackground: Color {
        switch self {
        case .favorites: return Color.lbAmber.opacity(0.18)
        case .kept: return AppTheme.accent
        case .archived: return Color.blue.opacity(0.15)
        case .deleted: return Color.red.opacity(0.15)
        }
    }

    public var iconForeground: Color {
        switch self {
        case .favorites: return Color.lbAmber
        case .kept: return Color.black
        case .archived: return Color.blue
        case .deleted: return Color.red
        }
    }
}

public struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LBItem.createdAt, order: .reverse) private var allItems: [LBItem]
    @Query(sort: \LBCollection.name, order: .forward) private var collections: [LBCollection]
    @ObservedObject var coordinator = SyncCoordinator.shared

    @State private var showingAddCollection: Bool = false
    @State private var newCollectionName: String = ""

    public init() {}

    private func itemCount(for category: LibraryCategory) -> Int {
        switch category {
        case .favorites:
            return allItems.filter { $0.favorite && $0.status != ItemStatus.deleted.rawValue }.count
        case .kept:
            return allItems.filter { $0.status == ItemStatus.saved.rawValue }.count
        case .archived:
            return allItems.filter { $0.status == ItemStatus.archived.rawValue }.count
        case .deleted:
            return allItems.filter { $0.status == ItemStatus.deleted.rawValue }.count
        }
    }

    private var allCollectionNames: [String] {
        let defaults = ["Design Systems", "Engineering", "Audio Vault", "Long Reads", "Research"]
        let fromCollections = collections.map { $0.name }
        let fromItems = allItems.compactMap { $0.collectionName }
        return Array(Set(defaults + fromCollections + fromItems)).sorted()
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Top Level Header (Scrolls normally, uncontainerized on canvas)
                        HStack(alignment: .center) {
                            HStack(spacing: 8) {
                                Image("LaterboxIconGreen")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 28, height: 28)
                                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                                Text("Library")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                            }

                            Spacer()

                            // Sync Status Indicator (No Container)
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(coordinator.syncState == .synced ? Color.lbGreenTheme : coordinator.syncState.statusColor)
                                    .frame(width: 7, height: 7)
                                Text(coordinator.syncState.rawValue)
                                    .font(.caption2.weight(.medium))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }
                        .padding(.top, 4)

                        // 4 Links Cards (2 per row: Favorites, Kept, Archived, Recently Deleted)
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            ForEach(LibraryCategory.allCases) { category in
                                NavigationLink(destination: LibrarySectionDetailView(category: category)) {
                                    VStack(alignment: .leading, spacing: 14) {
                                        HStack {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .fill(category.iconBackground)
                                                    .frame(width: 38, height: 38)
                                                Image(systemName: category.systemIcon)
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(category.iconForeground)
                                            }

                                            Spacer()

                                            Text("\(itemCount(for: category))")
                                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                                .foregroundColor(AppTheme.textPrimary)
                                        }

                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(category.rawValue)
                                                .font(.subheadline.weight(.bold))
                                                .foregroundColor(AppTheme.textPrimary)
                                                .lineLimit(1)

                                            HStack(spacing: 3) {
                                                Text("View items")
                                                    .font(.caption2.weight(.medium))
                                                    .foregroundColor(AppTheme.textSecondary)
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 8, weight: .bold))
                                                    .foregroundColor(AppTheme.textSecondary)
                                            }
                                        }
                                    }
                                    .padding(14)
                                    .liquidGlassCard(cornerRadius: 18, borderOpacity: 0.18, isInteractive: true)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // Collections / Folders Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .center) {
                                Text("COLLECTIONS")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(AppTheme.textSecondary)
                                    .tracking(0.6)

                                Spacer()

                                Button(action: {
                                    LBHaptic.light()
                                    showingAddCollection = true
                                }) {
                                    HStack(spacing: 5) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 11, weight: .bold))
                                        Text("Create Collection")
                                            .font(.caption.weight(.bold))
                                    }
                                    .foregroundColor(AppTheme.textPrimary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(AppTheme.accent)
                                    )
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.top, 6)

                            // Collections Folders Grid (click link to collection sub-pages)
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                                ForEach(allCollectionNames, id: \.self) { name in
                                    let count = allItems.filter { $0.collectionName == name && $0.status != ItemStatus.deleted.rawValue }.count
                                    NavigationLink(destination: CollectionDetailView(collectionName: name)) {
                                        VStack(alignment: .leading, spacing: 12) {
                                            HStack {
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                        .fill(Color.lbAmber.opacity(0.18))
                                                        .frame(width: 36, height: 36)
                                                    Image(systemName: "folder.fill")
                                                        .font(.system(size: 16))
                                                        .foregroundColor(Color.lbAmber)
                                                }

                                                Spacer()

                                                Text("\(count)")
                                                    .font(.subheadline.weight(.bold))
                                                    .foregroundColor(AppTheme.textSecondary)
                                            }

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(name)
                                                    .font(.subheadline.weight(.bold))
                                                    .foregroundColor(AppTheme.textPrimary)
                                                    .lineLimit(1)

                                                Text("Open folder →")
                                                    .font(.caption2.weight(.medium))
                                                    .foregroundColor(Color.lbAmber)
                                            }
                                        }
                                        .padding(14)
                                        .liquidGlassCard(cornerRadius: 18, borderOpacity: 0.18, isInteractive: true)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
            .alert("New Collection", isPresented: $showingAddCollection) {
                TextField("Collection name...", text: $newCollectionName)
                Button("Create") {
                    let trimmed = newCollectionName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        let coll = LBCollection(name: trimmed)
                        modelContext.insert(coll)
                        try? modelContext.save()
                        newCollectionName = ""
                        LBHaptic.success()
                    }
                }
                Button("Cancel", role: .cancel) { newCollectionName = "" }
            }
        }
    }
}

// MARK: - Dedicated Sub-Page for Favorites, Kept, Archived, and Recently Deleted
public struct LibrarySectionDetailView: View {
    public let category: LibraryCategory

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LBItem.createdAt, order: .reverse) private var allItems: [LBItem]
    @ObservedObject var coordinator = SyncCoordinator.shared

    @State private var searchText: String = ""
    @State private var isGridView: Bool = false
    @State private var showingEmptyTrashConfirmation: Bool = false

    public init(category: LibraryCategory) {
        self.category = category
    }

    private var sectionItems: [LBItem] {
        var base: [LBItem]
        switch category {
        case .favorites:
            base = allItems.filter { $0.favorite && $0.status != ItemStatus.deleted.rawValue }
        case .kept:
            base = allItems.filter { $0.status == ItemStatus.saved.rawValue }
        case .archived:
            base = allItems.filter { $0.status == ItemStatus.archived.rawValue }
        case .deleted:
            base = allItems.filter { $0.status == ItemStatus.deleted.rawValue }
        }

        let q = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return base }
        return base.filter {
            $0.title.lowercased().contains(q) ||
            ($0.url?.lowercased().contains(q) ?? false) ||
            ($0.noteContent?.lowercased().contains(q) ?? false)
        }
    }

    public var body: some View {
        ZStack {
            LiquidGlassBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Custom Header with Back Button
                    HStack(alignment: .center) {
                        Button(action: {
                            LBHaptic.light()
                            dismiss()
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 15, weight: .bold))
                                Text("Library")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .foregroundColor(AppTheme.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(AppTheme.cardBackground)
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        // Grid / List View Switcher
                        Button(action: {
                            LBHaptic.light()
                            isGridView.toggle()
                        }) {
                            Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(AppTheme.cardBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)

                        if category == .deleted && !sectionItems.isEmpty {
                            Button(action: {
                                LBHaptic.light()
                                showingEmptyTrashConfirmation = true
                            }) {
                                Text("Empty")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.red.opacity(0.12))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 4)

                    // Section Title & Badge
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(category.iconBackground)
                                .frame(width: 32, height: 32)
                            Image(systemName: category.systemIcon)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(category.iconForeground)
                        }

                        Text(category.rawValue)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)

                        Spacer()

                        Text("\(sectionItems.count) Items")
                            .font(.caption.weight(.bold))
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    // Search Bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)

                        TextField("Filter \(category.rawValue.lowercased())...", text: $searchText)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textPrimary)

                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(AppTheme.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                    )

                    // Content
                    if sectionItems.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: category.systemIcon)
                                .font(.system(size: 40))
                                .foregroundColor(AppTheme.textSecondary.opacity(0.4))
                            Text("No \(category.rawValue)")
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)
                            Text("Items filed under \(category.rawValue.lowercased()) will appear here.")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(48)
                        .liquidGlassCard(cornerRadius: 20)
                    } else if isGridView {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            ForEach(sectionItems) { item in
                                NavigationLink(destination: ItemDetailView(item: item)) {
                                    compactGridCard(for: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else {
                        ForEach(sectionItems) { item in
                            if category == .deleted {
                                deletedItemCard(item: item)
                            } else {
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
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .navigationBarHidden(true)
        .confirmationDialog("Empty Recently Deleted?", isPresented: $showingEmptyTrashConfirmation, titleVisibility: .visible) {
            Button("Permanently Delete All", role: .destructive) {
                for it in sectionItems {
                    coordinator.permanentlyDeleteItem(item: it, context: modelContext)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone. All recently deleted items will be permanently erased.")
        }
    }

    private func deletedItemCard(item: LBItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(item.parsedContentType.rawValue.capitalized)
                    .font(.caption2.weight(.bold))
                    .foregroundColor(AppTheme.textSecondary)
                Spacer()
                Text("Deleted")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.red)
            }

            Text(item.title)
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(2)

            HStack(spacing: 10) {
                Button(action: {
                    coordinator.restoreItem(item: item, context: modelContext)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 11, weight: .bold))
                        Text("Restore")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(AppTheme.accent)
                    )
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: {
                    coordinator.permanentlyDeleteItem(item: item, context: modelContext)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.system(size: 11, weight: .bold))
                        Text("Delete Forever")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundColor(.red)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.red.opacity(0.12))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .liquidGlassCard(cornerRadius: 18, borderOpacity: 0.18)
    }

    private func compactGridCard(for item: LBItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 70)
                Image(systemName: item.parsedContentType.systemIcon)
                    .font(.title2)
                    .foregroundColor(Color.lbAmber)
            }

            Text(item.title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(2)

            Spacer()

            HStack {
                Text(item.parsedContentType.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(1)
                Spacer()
                if item.favorite {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(Color.lbAmber)
                }
            }
        }
        .padding(12)
        .frame(height: 160)
        .liquidGlassCard(cornerRadius: 16, borderOpacity: 0.2)
    }
}

// MARK: - Dedicated Sub-Page for Collections / Folders
public struct CollectionDetailView: View {
    public let collectionName: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LBItem.createdAt, order: .reverse) private var allItems: [LBItem]
    @ObservedObject var coordinator = SyncCoordinator.shared

    @State private var searchText: String = ""
    @State private var isGridView: Bool = false

    public init(collectionName: String) {
        self.collectionName = collectionName
    }

    private var collectionItems: [LBItem] {
        let base = allItems.filter { $0.collectionName == collectionName && $0.status != ItemStatus.deleted.rawValue }
        let q = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return base }
        return base.filter {
            $0.title.lowercased().contains(q) ||
            ($0.url?.lowercased().contains(q) ?? false) ||
            ($0.noteContent?.lowercased().contains(q) ?? false)
        }
    }

    public var body: some View {
        ZStack {
            LiquidGlassBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Custom Header with Back Button
                    HStack(alignment: .center) {
                        Button(action: {
                            LBHaptic.light()
                            dismiss()
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 15, weight: .bold))
                                Text("Library")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .foregroundColor(AppTheme.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(AppTheme.cardBackground)
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        // Grid / List View Switcher
                        Button(action: {
                            LBHaptic.light()
                            isGridView.toggle()
                        }) {
                            Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(AppTheme.cardBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)

                    // Folder Title & Info
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.lbAmber.opacity(0.18))
                                .frame(width: 32, height: 32)
                            Image(systemName: "folder.fill")
                                .font(.system(size: 15))
                                .foregroundColor(Color.lbAmber)
                        }

                        Text(collectionName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        Text("\(collectionItems.count) Items")
                            .font(.caption.weight(.bold))
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    // Search Bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)

                        TextField("Search in \(collectionName)...", text: $searchText)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textPrimary)

                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(AppTheme.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                    )

                    // Content
                    if collectionItems.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "folder.badge.questionmark")
                                .font(.system(size: 40))
                                .foregroundColor(AppTheme.textSecondary.opacity(0.4))
                            Text("No items in \(collectionName)")
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)
                            Text("Assign items to this collection from their detail sheet to keep them organized.")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(48)
                        .liquidGlassCard(cornerRadius: 20)
                    } else if isGridView {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            ForEach(collectionItems) { item in
                                NavigationLink(destination: ItemDetailView(item: item)) {
                                    compactGridCard(for: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else {
                        ForEach(collectionItems) { item in
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
                .padding(.bottom, 24)
            }
        }
        .navigationBarHidden(true)
    }

    private func compactGridCard(for item: LBItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 70)
                Image(systemName: item.parsedContentType.systemIcon)
                    .font(.title2)
                    .foregroundColor(Color.lbAmber)
            }

            Text(item.title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(2)

            Spacer()

            HStack {
                Text(item.parsedContentType.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(1)
                Spacer()
                if item.favorite {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(Color.lbAmber)
                }
            }
        }
        .padding(12)
        .frame(height: 160)
        .liquidGlassCard(cornerRadius: 16, borderOpacity: 0.2)
    }
}
