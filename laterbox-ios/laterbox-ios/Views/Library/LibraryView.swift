//
//  LibraryView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import SwiftUI
import SwiftData

public enum LibrarySegment: String, CaseIterable {
    case saved = "Saved"
    case favorites = "Favorites"
    case archived = "Archived"
    case collections = "Collections"
}

public struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LBItem.createdAt, order: .reverse) private var allItems: [LBItem]
    @Query(sort: \LBCollection.name, order: .forward) private var collections: [LBCollection]
    @ObservedObject var coordinator = SyncCoordinator.shared

    @State private var selectedSegment: LibrarySegment = .saved
    @State private var isGridView: Bool = false
    @State private var selectedCollection: String? = nil
    @State private var showingAddCollection: Bool = false
    @State private var newCollectionName: String = ""

    public init() {}

    private var filteredItems: [LBItem] {
        if let col = selectedCollection {
            return allItems.filter { $0.collectionName == col }
        }

        switch selectedSegment {
        case .saved:
            return allItems.filter { $0.status == ItemStatus.saved.rawValue }
        case .favorites:
            return allItems.filter { $0.favorite }
        case .archived:
            return allItems.filter { $0.status == ItemStatus.archived.rawValue }
        case .collections:
            return []
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // Drill-down header if inside a collection
                        if let col = selectedCollection {
                            HStack {
                                Button(action: {
                                    LBHaptic.light()
                                    selectedCollection = nil
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "chevron.left")
                                        Text("All Collections")
                                    }
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(Color.lbAmber)
                                }
                                Spacer()
                                Text(col)
                                    .font(.headline)
                            }
                            .padding(.horizontal, 4)
                        } else {
                            // Segments Bar
                            HStack(spacing: 8) {
                                ForEach(LibrarySegment.allCases, id: \.self) { seg in
                                    Button(action: {
                                        LBHaptic.light()
                                        selectedSegment = seg
                                    }) {
                                        Text(seg.rawValue)
                                            .font(.caption.weight(.semibold))
                                            .frame(maxWidth: .infinity)
                                            .liquidGlassPill(isSelected: selectedSegment == seg)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Subtitle & View Toggle
                        HStack {
                            Text(selectedCollection != nil ? "Collection Items (\(filteredItems.count))" : "\(selectedSegment.rawValue) • \(filteredItems.count) Items")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            Spacer()

                            if selectedSegment != .collections || selectedCollection != nil {
                                Button(action: {
                                    isGridView.toggle()
                                    LBHaptic.light()
                                }) {
                                    Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .padding(8)
                                        .liquidGlassCard(cornerRadius: 10)
                                }
                            } else {
                                Button(action: { showingAddCollection = true }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus")
                                        Text("New Folder")
                                    }
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(Color.lbAmber)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .liquidGlassCard(cornerRadius: 10)
                                }
                            }
                        }

                        // Content Presentation
                        if selectedSegment == .collections && selectedCollection == nil {
                            collectionsGrid
                        } else if filteredItems.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "books.vertical")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary.opacity(0.4))
                                Text("No items in \(selectedCollection ?? selectedSegment.rawValue.lowercased())")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Saved links, articles, notes, and collections will live here permanently.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(48)
                            .liquidGlassCard(cornerRadius: 20)
                        } else if isGridView {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                                ForEach(filteredItems) { item in
                                    NavigationLink(destination: ItemDetailView(item: item)) {
                                        compactGridCard(for: item)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        } else {
                            ForEach(filteredItems) { item in
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
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle(selectedCollection ?? "Library")
            .navigationBarTitleDisplayMode(.large)
            .alert("New Collection", isPresented: $showingAddCollection) {
                TextField("Collection name...", text: $newCollectionName)
                Button("Create") {
                    if !newCollectionName.trimmingCharacters(in: .whitespaces).isEmpty {
                        let coll = LBCollection(name: newCollectionName.trimmingCharacters(in: .whitespaces))
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

    private var collectionsGrid: some View {
        let defaultCollections = ["Design Systems", "Engineering", "Audio Vault", "Long Reads", "Research"]
        let allCollectionNames = Array(Set(defaultCollections + collections.map { $0.name } + allItems.compactMap { $0.collectionName })).sorted()

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            ForEach(allCollectionNames, id: \.self) { name in
                let count = allItems.filter { $0.collectionName == name }.count
                Button(action: {
                    LBHaptic.light()
                    selectedCollection = name
                }) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.lbAmber.opacity(0.18))
                                    .frame(width: 38, height: 38)
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color.lbAmber)
                            }
                            Spacer()
                            Text("\(count)")
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(.secondary)
                        }

                        Text(name)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Text("View collection →")
                            .font(.caption2.weight(.medium))
                            .foregroundColor(Color.lbAmber)
                    }
                    .padding(16)
                    .liquidGlassCard(cornerRadius: 18, borderOpacity: 0.22, isInteractive: true)
                }
                .buttonStyle(.plain)
            }
        }
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
                .foregroundColor(.primary)
                .lineLimit(2)

            Spacer()

            HStack {
                Text(item.parsedContentType.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundColor(.secondary)
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
