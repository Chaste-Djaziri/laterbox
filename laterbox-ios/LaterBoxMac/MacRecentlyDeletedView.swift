// laterbox-ios/LaterBoxMac/MacRecentlyDeletedView.swift
import SwiftUI

/// Soft-deleted items can be restored, or removed permanently along with
/// their cloud attachments. Destructive operations always require confirmation.
struct MacRecentlyDeletedView: View {
    @ObservedObject var cloud: MacCloudSyncStore
    let onQuickSave: () -> Void
    let onOpenItem: (String) -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var confirmingEmpty = false
    @State private var deletingAll = false
    @State private var errorMessage: String?

    private var deletedItems: [MacInboxEntry] {
        cloud.deletedItems.sorted { $0.date > $1.date }
    }

    var body: some View {
        VStack(spacing: 12) {
            if !deletedItems.isEmpty {
                HStack(spacing: 11) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                    Text("Items in Recently Deleted can be restored or permanently removed.")
                        .font(.system(size: 12))
                        .lineLimit(2)
                    Spacer(minLength: 10)
                    Button {
                        confirmingEmpty = true
                    } label: {
                        Label(deletingAll ? "Deleting…" : "Empty Trash Now", systemImage: "trash")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 13)
                            .frame(height: 33)
                            .background(Color(red: 220 / 255, green: 38 / 255, blue: 38 / 255),
                                        in: RoundedRectangle(cornerRadius: 10))
                            .contentShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .disabled(deletingAll || cloud.loading)
                }
                .foregroundStyle(scheme == .dark ? Color.orange.opacity(0.93) :
                    Color(red: 120 / 255, green: 53 / 255, blue: 15 / 255))
                .padding(.horizontal, 15)
                .frame(minHeight: 54)
                .background(scheme == .dark ? Color.orange.opacity(0.13) :
                    Color(red: 255 / 255, green: 251 / 255, blue: 235 / 255),
                    in: RoundedRectangle(cornerRadius: 15))
                .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(Color.orange.opacity(0.25)))
            }

            MacInboxTableView(
                items: deletedItems,
                isConnected: cloud.isConnected,
                isLoading: cloud.loading,
                syncError: cloud.lastError,
                onRefresh: { await cloud.refresh() },
                onStar: { id, value in try await cloud.setStarred(id, starred: value) },
                onArchive: { id in try await cloud.archive(id) },
                onDelete: { id in try await cloud.delete(id) },
                onRestore: { id in try await cloud.restoreToInbox(id) },
                onPermanentlyDelete: { id in try await cloud.permanentlyDelete(id) },
                onQuickSave: onQuickSave,
                onOpenItem: onOpenItem,
                contextTitle: "Recently Deleted"
            )

            MacCloudSyncStatusView(
                isConnected: cloud.isConnected,
                isLoading: cloud.loading,
                isSaving: cloud.saving || deletingAll,
                lastError: cloud.lastError ?? errorMessage,
                lastSynced: cloud.lastSynced,
                lastPushed: cloud.lastPushed,
                onCheckUpdates: { await cloud.refresh() }
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 18)
        .confirmationDialog("Permanently delete all items in Recently Deleted?",
                            isPresented: $confirmingEmpty) {
            Button("Empty Trash Now", role: .destructive) {
                guard !deletingAll else { return }
                deletingAll = true
                Task {
                    defer { deletingAll = false }
                    do { try await cloud.emptyTrash() }
                    catch { errorMessage = error.localizedDescription }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone. All listed cloud items and their uploaded files will be permanently removed.")
        }
        .alert("Couldn't empty Trash", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Please retry.")
        }
    }
}
