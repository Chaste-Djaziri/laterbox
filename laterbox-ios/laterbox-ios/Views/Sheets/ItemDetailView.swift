//
//  ItemDetailView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import SwiftUI
import SwiftData

public struct ItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable public var item: LBItem
    @ObservedObject var coordinator = SyncCoordinator.shared

    @State private var editedNote: String = ""
    @State private var showingDeleteConfirm = false
    @State private var saveError: String?
    @State private var tagsText = ""

    public init(item: LBItem) {
        self.item = item
        self._editedNote = State(initialValue: item.noteContent ?? "")
        self._tagsText = State(initialValue: item.tags.joined(separator: ", "))
    }

    public var body: some View {
        ZStack {
            LiquidGlassBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Rich Visual Banner
                    RichMediaBanner(
                        type: item.parsedContentType,
                        url: item.url,
                        title: item.title,
                        previewImageUrl: item.previewImageUrl
                    )

                    // Title & Domain
                    VStack(alignment: .leading, spacing: 6) {
                        if let domain = item.domain {
                            Text(domain.uppercased())
                                .font(.caption.weight(.bold))
                                .foregroundColor(Color.lbAmber)
                        }

                        TextField("Title", text: $item.title)
                            .onChange(of: item.title) { _, _ in persistEdit() }
                            .font(.title3.weight(.bold))
                            .foregroundColor(.primary)

                        HStack(spacing: 8) {
                            Text("Saved \(item.createdAt, format: .dateTime.month().day().year())")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("•")
                                .foregroundColor(.secondary)

                            Text(item.parsedStatus.title)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.white.opacity(0.08)))
                                .foregroundColor(.secondary)
                        }
                    }

                    // Actions Bar: Safari, Share, Status
                    HStack(spacing: 12) {
                        if let urlStr = item.url, let url = URL(string: urlStr) {
                            Link(destination: url) {
                                HStack {
                                    Image(systemName: "safari")
                                    Text("Open")
                                        .font(.subheadline.weight(.semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .liquidGlassCard(cornerRadius: 14)
                            }
                            .buttonStyle(.plain)

                            ShareLink(item: url) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share")
                                        .font(.subheadline.weight(.semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .liquidGlassCard(cornerRadius: 14)
                            }
                            .buttonStyle(.plain)
                        }

                        Button(action: {
                            if item.status == ItemStatus.saved.rawValue {
                                coordinator.scheduleItem(item: item, date: Date(), context: modelContext)
                            } else {
                                coordinator.markDone(item: item, context: modelContext)
                            }
                        }) {
                            HStack {
                                Image(systemName: item.status == ItemStatus.saved.rawValue ? "arrow.uturn.backward" : "checkmark")
                                Text(item.status == ItemStatus.saved.rawValue ? "Return" : "Done")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                item.status == ItemStatus.saved.rawValue
                                    ? AnyShapeStyle(.ultraThinMaterial)
                                    : AnyShapeStyle(Color.lbAmber)
                            )
                            .foregroundColor(item.status == ItemStatus.saved.rawValue ? .primary : .black)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }

                    // Return Schedule Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Return Schedule")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            if let ret = item.returnAt {
                                HStack {
                                    Image(systemName: "calendar")
                                    Text("Scheduled for \(ret, format: .dateTime.month().day())")
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                    Button("Clear") {
                                        item.returnAt = nil
                                        persistEdit()
                                        LBHaptic.light()
                                    }
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.red)
                                }
                                .padding(12)
                                .liquidGlassCard(cornerRadius: 12)
                            } else {
                                Button("+ Tomorrow") {
                                    coordinator.scheduleItem(item: item, date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!, context: modelContext)
                                }
                                .font(.caption.weight(.medium))
                                .liquidGlassPill()

                                Button("+ Weekend") {
                                    coordinator.scheduleItem(item: item, date: Calendar.current.date(byAdding: .day, value: 2, to: Date())!, context: modelContext)
                                }
                                .font(.caption.weight(.medium))
                                .liquidGlassPill()

                                Button("+ Next Week") {
                                    coordinator.scheduleItem(item: item, date: Calendar.current.date(byAdding: .day, value: 7, to: Date())!, context: modelContext)
                                }
                                .font(.caption.weight(.medium))
                                .liquidGlassPill()
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Category and tags").font(.subheadline.bold())
                        TextField("Category", text: $item.category).onChange(of: item.category) { _, _ in persistEdit() }
                        TextField("Tags, separated by commas", text: $tagsText).onChange(of: tagsText) { _, text in
                            item.tags = text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "") }
                            persistEdit()
                        }
                        if !item.summary.isEmpty { Text(item.summary).font(.subheadline) }
                        if let original = item.textContent, !original.isEmpty {
                            Text("Original content").font(.subheadline.bold())
                            Text(original).textSelection(.enabled)
                        }
                        if !item.formattedContent.isEmpty {
                            Text("Formatted content").font(.subheadline.bold())
                            Text(item.formattedContent).textSelection(.enabled)
                        }
                        if let saveError { Text(saveError).foregroundStyle(.red) }
                    }

                    // Notes Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Personal Notes & Thoughts")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)

                        TextEditor(text: $editedNote)
                            .frame(minHeight: 120)
                            .padding(10)
                            .liquidGlassCard(cornerRadius: 14)
                            .onChange(of: editedNote) { _, newVal in
                                item.noteContent = newVal
                                persistEdit()
                            }
                    }

                    // Delete Button
                    Button(role: .destructive, action: { showingDeleteConfirm = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Item")
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .liquidGlassCard(cornerRadius: 14)
                    }
                    .padding(.top, 10)
                }
                .padding(20)
            }
        }
        .onDisappear { Task { await coordinator.syncPendingItems(context: modelContext) } }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    coordinator.toggleFavorite(item: item, context: modelContext)
                }) {
                    Image(systemName: item.favorite ? "star.fill" : "star")
                        .foregroundColor(item.favorite ? Color.lbAmber : .primary)
                }
            }
        }
        .confirmationDialog("Are you sure you want to delete this item?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                coordinator.deleteItem(item: item, context: modelContext)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    private func persistEdit() {
        item.updatedAt = Date()
        item.isSyncPending = true
        do { try modelContext.save(); saveError = nil }
        catch { saveError = error.localizedDescription }
    }

}
