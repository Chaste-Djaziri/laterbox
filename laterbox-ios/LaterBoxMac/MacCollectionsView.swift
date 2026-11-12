// laterbox-ios/LaterBoxMac/MacCollectionsView.swift
import SwiftUI

struct MacCollectionsView: View {
    @ObservedObject var cloud: MacCloudSyncStore
    @Binding var selectedCollectionID: String?
    let onOpenItem: (String) -> Void
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
        VStack(spacing: 12) {
            topBar
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
                .frame(maxHeight: compact ? 300 : 220)
            }
            if !compact {
                selectedItems
            }
        }
        .padding(compact ? 12 : 17)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(surface, in: RoundedRectangle(cornerRadius: 17))
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
            let entries = cloud.collectionItems(id)
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(collection.name).font(.system(size: 15, weight: .bold))
                    Spacer()
                    Text("\(entries.count) items")
                        .font(.system(size: 11)).foregroundStyle(muted)
                }
                if entries.isEmpty {
                    Text("No items in this collection. Add them from Item Details.")
                        .font(.system(size: 12)).foregroundStyle(muted)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(entries) { entry in
                                HStack {
                                    Button { onOpenItem(entry.id) } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(entry.title).font(.system(size: 12, weight: .semibold))
                                            Text(entry.source).font(.system(size: 11)).foregroundStyle(muted)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 9)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    Button {
                                        run { try await cloud.setCollectionMembership(id, itemID: entry.id, included: false) }
                                    } label: {
                                        Image(systemName: "minus.circle")
                                            .frame(width: 32, height: 32)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Remove item from collection")
                                    .disabled(busy)
                                }
                                Divider()
                            }
                        }
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 12))
        } else {
            Text("Select a collection to browse its items.")
                .font(.system(size: 13))
                .foregroundStyle(muted)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
