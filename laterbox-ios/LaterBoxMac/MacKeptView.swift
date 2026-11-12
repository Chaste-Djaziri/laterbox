// laterbox-ios/LaterBoxMac/MacKeptView.swift
import SwiftUI

/// Matches Web's savedItems: non-deleted items with the "saved" status.
/// All rows share native inbox visuals and actionable cloud mutations.
struct MacKeptView: View {
    @ObservedObject var cloud: MacCloudSyncStore
    let onQuickSave: () -> Void
    let onOpenItem: (String) -> Void

    private var keptItems: [MacInboxEntry] {
        cloud.allItems
            .filter { $0.lifecycleStatus == "saved" }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        VStack(spacing: 12) {
            MacInboxTableView(
                items: keptItems,
                isConnected: cloud.isConnected,
                isLoading: cloud.loading,
                syncError: cloud.lastError,
                onRefresh: { await cloud.refresh() },
                onStar: { id, starred in try await cloud.setStarred(id, starred: starred) },
                onArchive: { id in try await cloud.archive(id) },
                onDelete: { id in try await cloud.delete(id) },
                onQuickSave: onQuickSave,
                onOpenItem: onOpenItem,
                contextTitle: "Kept"
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
