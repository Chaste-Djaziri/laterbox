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
        AppTheme.accent
    }

    public var iconForeground: Color {
        Color(hex: "171711")
    }
}

public struct LibraryView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LBItem.createdAt, order: .reverse) private var allItems: [LBItem]
    @Query(sort: \LBCollection.name, order: .forward) private var collections: [LBCollection]
    @ObservedObject var coordinator = SyncCoordinator.shared
    @State private var showingAddCollection: Bool = false
    @State private var newCollectionName: String = ""

    @State private var collectionToRename: String? = nil
    @State private var renamedCollectionName: String = ""
    @State private var showingRenameCollection: Bool = false

    @State private var collectionToDelete: String? = nil
    @State private var showingDeleteCollectionConfirmation: Bool = false

    public init() {}

    private var deduplicatedItems: [LBItem] {
        allItems.deduplicatedForDisplay()
    }

    private func itemCount(for category: LibraryCategory) -> Int {
        switch category {
        case .favorites:
            return deduplicatedItems.filter { $0.favorite && $0.status != ItemStatus.deleted.rawValue }.count
        case .kept:
            return deduplicatedItems.filter { $0.status == ItemStatus.saved.rawValue }.count
        case .archived:
            return deduplicatedItems.filter { $0.status == ItemStatus.archived.rawValue }.count
        case .deleted:
            return deduplicatedItems.filter { $0.status == ItemStatus.deleted.rawValue }.count
        }
    }

    // Purely user-created collections (no mock or hardcoded defaults)
    private var allCollectionNames: [String] {
        let fromCollections = collections.map { $0.name }
        let fromItems = allItems.compactMap { $0.collectionName }
        return Array(Set(fromCollections + fromItems)).sorted()
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                InboxGrainBackground().ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Top Level Header (Scrolls normally, uncontainerized on canvas)
                        HStack(alignment: .center) {
                            HStack(spacing: 11) {
                                Image("LaterboxIconGreen")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 36, height: 36)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Library")
                                        .font(.system(size: 27, weight: .bold, design: .rounded))
                                        .foregroundColor(InboxAppearance.textPrimary(for: colorScheme))

                                    Text("Your saved space")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(InboxAppearance.textSecondary(for: colorScheme))
                                }
                            }

                            Spacer()

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
                                        .foregroundColor(InboxAppearance.textSecondary(for: colorScheme))
                                }
                            }
                            .buttonStyle(.plain)
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
                                                .foregroundColor(InboxAppearance.textPrimary(for: colorScheme))
                                        }

                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(category.rawValue)
                                                .font(.subheadline.weight(.bold))
                                                .foregroundColor(InboxAppearance.textPrimary(for: colorScheme))
                                                .lineLimit(1)

                                            HStack(spacing: 3) {
                                                Text("View items")
                                                    .font(.caption2.weight(.medium))
                                                    .foregroundColor(InboxAppearance.textSecondary(for: colorScheme))
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 8, weight: .bold))
                                                    .foregroundColor(InboxAppearance.textSecondary(for: colorScheme))
                                            }
                                        }
                                    }
                                    .padding(14)
                                    .libraryCard(for: colorScheme, cornerRadius: 18)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // Collections / Folders Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .center) {
                                Text("COLLECTIONS")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(InboxAppearance.textSecondary(for: colorScheme))
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
                                    .foregroundColor(Color(hex: "171711"))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(AppTheme.accent)
                                    )
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(InboxAppearance.border(for: colorScheme), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.top, 6)

                            // Collections Folders Grid or Clean Empty State
                            if allCollectionNames.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "folder.badge.plus")
                                        .font(.system(size: 34))
                                        .foregroundColor(InboxAppearance.textSecondary(for: colorScheme).opacity(0.55))
                                    Text("No collections yet")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(InboxAppearance.textPrimary(for: colorScheme))
                                    Text("Tap '+ Create Collection' to organize your items into custom folders.")
                                        .font(.caption)
                                        .foregroundColor(InboxAppearance.textSecondary(for: colorScheme))
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 28)
                                .padding(.horizontal, 20)
                                .libraryCard(for: colorScheme, cornerRadius: 18)
                            } else {
                                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                                    ForEach(allCollectionNames, id: \.self) { name in
                                        let count = deduplicatedItems.filter { $0.collectionName == name && $0.status != ItemStatus.deleted.rawValue }.count
                                        NavigationLink(destination: CollectionDetailView(collectionName: name)) {
                                            VStack(alignment: .leading, spacing: 12) {
                                                HStack {
                                                    ZStack {
                                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                            .fill(AppTheme.accent)
                                                            .frame(width: 36, height: 36)
                                                        Image(systemName: "folder.fill")
                                                            .font(.system(size: 16))
                                                            .foregroundColor(Color(hex: "171711"))
                                                    }

                                                    Spacer()

                                                    Text("\(count)")
                                                        .font(.subheadline.weight(.bold))
                                                        .foregroundColor(InboxAppearance.textSecondary(for: colorScheme))
                                                }

                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(name)
                                                        .font(.subheadline.weight(.bold))
                                                        .foregroundColor(InboxAppearance.textPrimary(for: colorScheme))
                                                        .lineLimit(1)

                                                    Text("Open folder →")
                                                        .font(.caption2.weight(.medium))
                                                        .foregroundColor(InboxAppearance.textSecondary(for: colorScheme))
                                                }
                                            }
                                            .padding(14)
                                            .libraryCard(for: colorScheme, cornerRadius: 18)
                                        }
                                        .buttonStyle(.plain)
                                        .contextMenu {
                                            Button {
                                                collectionToRename = name
                                                renamedCollectionName = name
                                                showingRenameCollection = true
                                            } label: {
                                                Label("Rename Collection", systemImage: "pencil")
                                            }

                                            Button(role: .destructive) {
                                                collectionToDelete = name
                                                showingDeleteCollectionConfirmation = true
                                            } label: {
                                                Label("Delete Collection", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
                .refreshable {
                    LBHaptic.medium()
                    await coordinator.syncPendingItems(context: modelContext, announceFailure: false)
                }
                .scrollBounceBehavior(.always)
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
            .alert("Rename Collection", isPresented: $showingRenameCollection) {
                TextField("New collection name...", text: $renamedCollectionName)
                Button("Save") {
                    let trimmed = renamedCollectionName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty, let oldName = collectionToRename {
                        renameCollection(from: oldName, to: trimmed)
                    }
                    collectionToRename = nil
                    renamedCollectionName = ""
                }
                Button("Cancel", role: .cancel) {
                    collectionToRename = nil
                    renamedCollectionName = ""
                }
            }
            .confirmationDialog(
                "Delete \"\(collectionToDelete ?? "Collection")\"?",
                isPresented: $showingDeleteCollectionConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Folder", role: .destructive) {
                    if let col = collectionToDelete {
                        deleteCollection(named: col)
                    }
                    collectionToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    collectionToDelete = nil
                }
            } message: {
                Text("Items inside this collection will not be deleted; they will simply be unassigned from this folder.")
            }
        }
    }

    private func renameCollection(from oldName: String, to newName: String) {
        guard oldName != newName else { return }

        let matchingCollections = collections.filter { $0.name == oldName }
        for coll in matchingCollections {
            coll.name = newName
            coll.updatedAt = Date()
        }

        if matchingCollections.isEmpty {
            let coll = LBCollection(name: newName)
            modelContext.insert(coll)
        }

        for item in allItems where item.collectionName == oldName {
            item.collectionName = newName
            item.updatedAt = Date()
            item.isSyncPending = true
        }

        try? modelContext.save()
        LBHaptic.success()
    }

    private func deleteCollection(named name: String) {
        for coll in collections where coll.name == name {
            modelContext.delete(coll)
        }

        for item in allItems where item.collectionName == name {
            item.collectionName = nil
            item.collectionId = nil
            item.updatedAt = Date()
            item.isSyncPending = true
        }

        try? modelContext.save()
        LBHaptic.medium()
    }
}

// MARK: - Dedicated Sub-Page for Favorites, Kept, Archived, and Recently Deleted
public struct LibrarySectionDetailView: View {
    public let category: LibraryCategory

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LBItem.createdAt, order: .reverse) private var allItems: [LBItem]
    @ObservedObject var coordinator = SyncCoordinator.shared

    @State private var searchText: String = ""
    @StateObject private var search = LocalSearchController()
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

        let deduped = base.deduplicatedForDisplay()
        let q = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return deduped }
        return search.results.filter { candidate in deduped.contains { $0.id == candidate.id } }.deduplicatedForDisplay()
    }

    public var body: some View {
        ZStack {
            InboxGrainBackground().ignoresSafeArea()

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
                            .foregroundColor(InboxAppearance.textPrimary(for: colorScheme))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(InboxAppearance.surface(for: colorScheme))
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(InboxAppearance.border(for: colorScheme), lineWidth: 1)
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
                                .foregroundColor(InboxAppearance.textPrimary(for: colorScheme))
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(InboxAppearance.surface(for: colorScheme))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(InboxAppearance.border(for: colorScheme), lineWidth: 1)
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
                            .foregroundColor(InboxAppearance.textPrimary(for: colorScheme))

                        Spacer()

                        Text("\(sectionItems.count) Items")
                            .font(.caption.weight(.bold))
                            .foregroundColor(InboxAppearance.textSecondary(for: colorScheme))
                    }

                    // Search Bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(InboxAppearance.textSecondary(for: colorScheme))

                        TextField("Filter \(category.rawValue.lowercased())...", text: $searchText)
                            .task(id: searchText + allItems.map { $0.updatedAt.ISO8601Format() }.joined()) { search.update(searchText, items: allItems, includeDeleted: category == .deleted) }
                            .font(.subheadline)
                            .foregroundColor(InboxAppearance.textPrimary(for: colorScheme))

                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(InboxAppearance.textSecondary(for: colorScheme))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(InboxAppearance.surface(for: colorScheme))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(InboxAppearance.border(for: colorScheme), lineWidth: 1)
                    )

                    // Content
                    if sectionItems.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: category.systemIcon)
                                .font(.system(size: 40))
                                .foregroundColor(InboxAppearance.textSecondary(for: colorScheme).opacity(0.55))
                            Text(searchText.isEmpty ? "No \(category.rawValue)" : "No matching items")
                                .font(.headline)
                                .foregroundColor(InboxAppearance.textPrimary(for: colorScheme))
                            Text(searchText.isEmpty ? "Items filed under \(category.rawValue.lowercased()) will appear here." : "Try a different search or clear the filter.")
                                .font(.caption)
                                .foregroundColor(InboxAppearance.textSecondary(for: colorScheme))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(48)
                        .libraryCard(for: colorScheme, cornerRadius: 20)
                    } else if isGridView {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            ForEach(sectionItems) { item in
                                NavigationLink(destination: ItemDetailView(item: item, usesNativeNavigation: true)) {
                                    compactGridCard(for: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else {
                        LazyVStack(spacing: 4) {
                            ForEach(Array(sectionItems.enumerated()), id: \.element.id) { index, item in
                                if category == .deleted {
                                    deletedItemCard(item: item)
                                } else {
                                    NavigationLink(destination: ItemDetailView(item: item, usesNativeNavigation: true)) {
                                        EmailInboxRowView(
                                            item: item,
                                            topRadius: index == 0 ? 14 : 5,
                                            bottomRadius: index == sectionItems.count - 1 ? 14 : 5,
                                            onToggleFavorite: { coordinator.toggleFavorite(item: item, context: modelContext) },
                                            onMarkDone: { coordinator.markDone(item: item, context: modelContext) },
                                            onSchedule: { date in coordinator.scheduleItem(item: item, date: date, context: modelContext) },
                                            onDelete: { coordinator.deleteItem(item: item, context: modelContext) }
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .id("\(item.status)-library-\(item.id)")
                                }
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
                    .foregroundColor(InboxAppearance.textSecondary(for: colorScheme))
                Spacer()
                Text("Deleted")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.red)
            }

            Text(item.title)
                .font(.headline)
                .foregroundColor(InboxAppearance.textPrimary(for: colorScheme))
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
                    .foregroundColor(Color(hex: "171711"))
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
        .libraryCard(for: colorScheme, cornerRadius: 18)
    }

    private func compactGridCard(for item: LBItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(InboxAppearance.background(for: colorScheme))
                    .frame(height: 70)
                Image(systemName: item.parsedContentType.systemIcon)
                    .font(.title2)
                    .foregroundColor(InboxAppearance.textPrimary(for: colorScheme))
            }

            Text(item.title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(InboxAppearance.textPrimary(for: colorScheme))
                .lineLimit(2)

            Spacer()

            HStack {
                Text(item.parsedContentType.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundColor(InboxAppearance.textSecondary(for: colorScheme))
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
        .libraryCard(for: colorScheme, cornerRadius: 16)
    }
}

// MARK: - Dedicated Sub-Page for Collections / Folders
public struct CollectionDetailView: View {
    @State public var collectionName: String

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LBItem.createdAt, order: .reverse) private var allItems: [LBItem]
    @Query(sort: \LBCollection.name, order: .forward) private var collections: [LBCollection]
    @ObservedObject var coordinator = SyncCoordinator.shared

    @State private var searchText: String = ""
    @StateObject private var search = LocalSearchController()
    @State private var isGridView: Bool = false
    @State private var showingRename: Bool = false
    @State private var renameTitle: String = ""
    @State private var showingDeleteConfirm: Bool = false

    public init(collectionName: String) {
        self._collectionName = State(initialValue: collectionName)
    }

    private var collectionItems: [LBItem] {
        let base = allItems.filter { $0.collectionName == collectionName && $0.status != ItemStatus.deleted.rawValue }.deduplicatedForDisplay()
        let q = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return base }
        return search.results.filter { candidate in base.contains { $0.id == candidate.id } }.deduplicatedForDisplay()
    }

    public var body: some View {
        ZStack {
            InboxGrainBackground().ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Custom Header with Back Button and Folder Menu
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
                            .foregroundColor(InboxAppearance.textPrimary(for: colorScheme))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(InboxAppearance.surface(for: colorScheme))
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(InboxAppearance.border(for: colorScheme), lineWidth: 1)
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
                                .foregroundColor(InboxAppearance.textPrimary(for: colorScheme))
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(InboxAppearance.surface(for: colorScheme))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(InboxAppearance.border(for: colorScheme), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)

                        // Folder Options Menu
                        Menu {
                            Button {
                                renameTitle = collectionName
                                showingRename = true
                            } label: {
                                Label("Rename Folder", systemImage: "pencil")
                            }

                            Button(role: .destructive) {
                                showingDeleteConfirm = true
                            } label: {
                                Label("Delete Folder", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(InboxAppearance.textPrimary(for: colorScheme))
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(InboxAppearance.surface(for: colorScheme))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(InboxAppearance.border(for: colorScheme), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.top, 4)

                    // Folder Title & Info
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(AppTheme.accent)
                                .frame(width: 32, height: 32)
                            Image(systemName: "folder.fill")
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "171711"))
                        }

                        Text(collectionName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(InboxAppearance.textPrimary(for: colorScheme))
                            .lineLimit(1)

                        Spacer()

                        Text("\(collectionItems.count) Items")
                            .font(.caption.weight(.bold))
                            .foregroundColor(InboxAppearance.textSecondary(for: colorScheme))
                    }

                    // Search Bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(InboxAppearance.textSecondary(for: colorScheme))

                        TextField("Search in \(collectionName)...", text: $searchText)
                            .task(id: searchText + allItems.map { $0.updatedAt.ISO8601Format() }.joined()) { search.update(searchText, items: allItems) }
                            .font(.subheadline)
                            .foregroundColor(InboxAppearance.textPrimary(for: colorScheme))

                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(InboxAppearance.textSecondary(for: colorScheme))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(InboxAppearance.surface(for: colorScheme))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(InboxAppearance.border(for: colorScheme), lineWidth: 1)
                    )

                    // Content
                    if collectionItems.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "folder.badge.questionmark")
                                .font(.system(size: 40))
                                .foregroundColor(InboxAppearance.textSecondary(for: colorScheme).opacity(0.55))
                            Text(searchText.isEmpty ? "No items in \(collectionName)" : "No matching items")
                                .font(.headline)
                                .foregroundColor(InboxAppearance.textPrimary(for: colorScheme))
                            Text(searchText.isEmpty ? "Assign items to this collection from their detail sheet to keep them organized." : "Try a different search or clear the filter.")
                                .font(.caption)
                                .foregroundColor(InboxAppearance.textSecondary(for: colorScheme))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(48)
                        .libraryCard(for: colorScheme, cornerRadius: 20)
                    } else if isGridView {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            ForEach(collectionItems) { item in
                                NavigationLink(destination: ItemDetailView(item: item, usesNativeNavigation: true)) {
                                    compactGridCard(for: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else {
                        LazyVStack(spacing: 4) {
                            ForEach(Array(collectionItems.enumerated()), id: \.element.id) { index, item in
                                NavigationLink(destination: ItemDetailView(item: item, usesNativeNavigation: true)) {
                                    EmailInboxRowView(
                                        item: item,
                                        topRadius: index == 0 ? 14 : 5,
                                        bottomRadius: index == collectionItems.count - 1 ? 14 : 5,
                                        onToggleFavorite: { coordinator.toggleFavorite(item: item, context: modelContext) },
                                        onMarkDone: { coordinator.markDone(item: item, context: modelContext) },
                                        onSchedule: { date in coordinator.scheduleItem(item: item, date: date, context: modelContext) },
                                        onDelete: { coordinator.deleteItem(item: item, context: modelContext) }
                                    )
                                }
                                .buttonStyle(.plain)
                                .id("\(item.status)-collection-\(item.id)")
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
        .alert("Rename Collection", isPresented: $showingRename) {
            TextField("New collection name...", text: $renameTitle)
            Button("Save") {
                let trimmed = renameTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty && trimmed != collectionName {
                    for coll in collections where coll.name == collectionName {
                        coll.name = trimmed
                        coll.updatedAt = Date()
                    }
                    for item in allItems where item.collectionName == collectionName {
                        item.collectionName = trimmed
                        item.updatedAt = Date()
                        item.isSyncPending = true
                    }
                    try? modelContext.save()
                    collectionName = trimmed
                    LBHaptic.success()
                }
                renameTitle = ""
            }
            Button("Cancel", role: .cancel) { renameTitle = "" }
        }
        .confirmationDialog(
            "Delete \"\(collectionName)\"?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Folder", role: .destructive) {
                for coll in collections where coll.name == collectionName {
                    modelContext.delete(coll)
                }
                for item in allItems where item.collectionName == collectionName {
                    item.collectionName = nil
                    item.collectionId = nil
                    item.updatedAt = Date()
                    item.isSyncPending = true
                }
                try? modelContext.save()
                LBHaptic.medium()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Items inside this collection will not be deleted; they will simply be unassigned from this folder.")
        }
    }

    private func compactGridCard(for item: LBItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(InboxAppearance.background(for: colorScheme))
                    .frame(height: 70)
                Image(systemName: item.parsedContentType.systemIcon)
                    .font(.title2)
                    .foregroundColor(InboxAppearance.textPrimary(for: colorScheme))
            }

            Text(item.title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(InboxAppearance.textPrimary(for: colorScheme))
                .lineLimit(2)

            Spacer()

            HStack {
                Text(item.parsedContentType.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundColor(InboxAppearance.textSecondary(for: colorScheme))
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
        .libraryCard(for: colorScheme, cornerRadius: 16)
    }
}


// MARK: - Library surfaces use the same adaptive neutral palette as the Inbox.
private extension View {
    func libraryCard(for scheme: ColorScheme, cornerRadius: CGFloat = 18) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(InboxAppearance.surface(for: scheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(InboxAppearance.border(for: scheme), lineWidth: 1)
        )
    }
}
