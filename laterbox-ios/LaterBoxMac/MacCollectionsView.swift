// laterbox-ios/LaterBoxMac/MacCollectionsView.swift
import SwiftUI

struct MacCollectionsView: View {
    @ObservedObject var cloud: MacCloudSyncStore
    @Binding var selectedCollectionID: String?
    let onOpenItem: (String) -> Void
    let onQuickSave: () -> Void
    let compact: Bool
    var onChoose: (() -> Void)? = nil

    @State private var editingName = ""
    @State private var editingID: String?
    @State private var showingEditor = false
    @State private var toDelete: MacCollection?
    @State private var busy = false
    @State private var errorMessage: String?
    @Environment(\.colorScheme) private var scheme

    private let lime = Color(red: 230 / 255, green: 237 / 255, blue: 176 / 255)
    private var surface: Color { scheme == .dark ? Color(white: 0.16) : .white }
    private var muted: Color { scheme == .dark ? .white.opacity(0.55) : .black.opacity(0.55) }

    var body: some View {
        Group {
            if compact {
                VStack(spacing: 12) {
                    topBar
                    collectionList
                }
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(surface, in: RoundedRectangle(cornerRadius: 17))
            } else {
                HStack(spacing: 13) {
                    VStack(spacing: 12) {
                        topBar
                        collectionList
                    }
                    .padding(14)
                    .frame(width: 260)
                    .frame(maxHeight: .infinity)
                    .background(surface, in: RoundedRectangle(cornerRadius: 17))

                    selectedItems
                }
            }
        }
        .sheet(isPresented: $showingEditor) { editor }
        .confirmationDialog("Delete this collection?", isPresented: Binding(
            get: { toDelete != nil },
            set: { if !$0 { toDelete = nil } }
        )) {
            Button("Delete Collection", role: .destructive) {
                guard let target = toDelete else { return }
                run {
                    try await cloud.deleteCollection(target.id)
                    if selectedCollectionID == target.id { selectedCollectionID = nil }
                    toDelete = nil
                }
            }
            Button("Cancel", role: .cancel) { toDelete = nil }
        } message: {
            Text("Its items will stay saved in Laterbox.")
        }
        .alert("Collection update failed", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    @ViewBuilder
    private var collectionList: some View {
        if cloud.collections.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(cloud.collections) { collection in
                        collectionRow(collection)
                    }
                }
                .padding(2)
            }
            .frame(maxHeight: .infinity)
        }
    }

    private var topBar: some View {
        HStack {
            Image(systemName: "folder.fill")
                .font(.system(size: 17))
                .foregroundStyle(.black)
                .frame(width: 35, height: 35)
                .background(lime, in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading) {
                Text("Collections").font(.system(size: 15, weight: .bold))
                Text("\(cloud.collections.count) folders")
                    .font(.system(size: 11)).foregroundStyle(muted)
            }
            Spacer()
            Button {
                editingID = nil
                editingName = ""
                showingEditor = true
            } label: {
                Image(systemName: "plus")
                    .foregroundStyle(Color.black)
                    .frame(width: 32, height: 32)
                    .background(lime, in: RoundedRectangle(cornerRadius: 9))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("New collection")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 32)).foregroundStyle(muted)
            Text("No collections yet")
                .font(.system(size: 14, weight: .semibold))
            Text("Create a folder to organize saved items.")
                .font(.system(size: 12)).foregroundStyle(muted)
            Button("New collection") {
                editingID = nil
                editingName = ""
                showingEditor = true
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func collectionRow(_ collection: MacCollection) -> some View {
        HStack(spacing: 6) {
            Button {
                selectedCollectionID = collection.id
                onChoose?()
            } label: {
                HStack(spacing: 9) {
                    Image(systemName: selectedCollectionID == collection.id ? "folder.fill" : "folder")
                    Text(collection.name).lineLimit(1)
                    Spacer()
                    Text("\(cloud.collectionCount(collection.id))")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 11)
                .frame(height: 38)
                .background(selectedCollectionID == collection.id ? lime : Color.primary.opacity(0.045),
                            in: RoundedRectangle(cornerRadius: 10))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Menu {
                Button("Rename") {
                    editingID = collection.id
                    editingName = collection.name
                    showingEditor = true
                }
                Button("Delete", role: .destructive) { toDelete = collection }
            } label: {
                Image(systemName: "ellipsis")
                    .frame(width: 28, height: 38)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
        }
    }

    @ViewBuilder
    private var selectedItems: some View {
        if let id = selectedCollectionID,
           let collection = cloud.collections.first(where: { $0.id == id }) {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(muted)
                    Text(collection.name)
                        .font(.system(size: 16, weight: .bold))
                        .lineLimit(1)
                    Spacer()
                    Text("\(cloud.collectionCount(id)) items")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(muted)
                    Button {
                        Task { await cloud.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(cloud.loading)
                    .help("Refresh collection")
                }
                .padding(.horizontal, 9)

                MacInboxTableView(
                    items: cloud.collectionItems(id),
                    isConnected: cloud.isConnected,
                    isLoading: cloud.loading,
                    syncError: cloud.lastError,
                    onRefresh: { await cloud.refresh() },
                    onStar: { itemID, starred in try await cloud.setStarred(itemID, starred: starred) },
                    onArchive: { itemID in try await cloud.archive(itemID) },
                    onDelete: { itemID in try await cloud.delete(itemID) },
                    onRestore: { itemID in try await cloud.restoreToInbox(itemID) },
                    onQuickSave: onQuickSave,
                    onOpenItem: onOpenItem,
                    contextTitle: "Collection"
                )

                MacCloudSyncStatusView(
                    isConnected: cloud.isConnected,
                    isLoading: cloud.loading,
                    isSaving: cloud.saving,
                    lastError: cloud.lastError,
                    lastSynced: cloud.lastSynced,
                    lastPushed: cloud.lastPushed,
                    onCheckUpdates: { await cloud.refresh() }
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 10) {
                Image(systemName: "folder")
                    .font(.system(size: 36, weight: .ultraLight))
                Text("Choose a collection")
                    .font(.system(size: 15, weight: .semibold))
                Text("Its saved items will appear in the normal inbox-style table.")
                    .font(.system(size: 12))
                    .foregroundStyle(muted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(surface, in: RoundedRectangle(cornerRadius: 17))
        }
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(editingID == nil ? "Create collection" : "Rename collection")
                .font(.system(size: 19, weight: .bold))
            TextField("Name", text: $editingName)
                .textFieldStyle(.roundedBorder)
            HStack {
                Spacer()
                Button("Cancel") { showingEditor = false }
                Button("Save") { submitEditor() }
                    .buttonStyle(.borderedProminent)
                    .disabled(busy || editingName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 350)
    }

    private func submitEditor() {
        let id = editingID
        let name = editingName
        run {
            if let id { try await cloud.renameCollection(id, name: name) }
            else { try await cloud.createCollection(name) }
            showingEditor = false
        }
    }

    private func run(_ work: @escaping () async throws -> Void) {
        guard !busy else { return }
        busy = true
        Task {
            defer { busy = false }
            do { try await work() }
            catch { errorMessage = error.localizedDescription }
        }
    }
}
