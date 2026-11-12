// laterbox-ios/LaterBoxMac/MacStarredView.swift
import SwiftUI

/// Starred mirrors Web's favorites collection across all non-deleted items:
/// Inbox, deferred, saved/kept, and archived.
struct MacStarredView: View {
    @ObservedObject var cloud: MacCloudSyncStore
    let onQuickSave: () -> Void
    let onOpenItem: (String) -> Void

    private var starredItems: [MacInboxEntry] {
        cloud.allItems
            .filter(\.isStarred)
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        VStack(spacing: 12) {
            MacInboxTableView(
                items: starredItems,
                isConnected: cloud.isConnected,
                isLoading: cloud.loading,
                syncError: cloud.lastError,
                onRefresh: { await cloud.refresh() },
                onStar: { id, starred in try await cloud.setStarred(id, starred: starred) },
                onArchive: { id in try await cloud.archive(id) },
                onDelete: { id in try await cloud.delete(id) },
                onQuickSave: onQuickSave,
                onOpenItem: onOpenItem,
                contextTitle: "Starred"
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
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 18)
    }
}
