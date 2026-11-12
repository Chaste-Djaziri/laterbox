// laterbox-ios/LaterBoxMac/MacArchivedView.swift
import SwiftUI

/// Web-style Archive: archived, non-deleted cloud items, newest first.
struct MacArchivedView: View {
    @ObservedObject var cloud: MacCloudSyncStore
    let onQuickSave: () -> Void
    let onOpenItem: (String) -> Void

    private var archivedItems: [MacInboxEntry] {
        cloud.allItems
            .filter { $0.lifecycleStatus == "archived" }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        VStack(spacing: 12) {
            MacInboxTableView(
                items: archivedItems,
                isConnected: cloud.isConnected,
                isLoading: cloud.loading,
                syncError: cloud.lastError,
                onRefresh: { await cloud.refresh() },
                onStar: { id, value in try await cloud.setStarred(id, starred: value) },
                onArchive: { id in try await cloud.archive(id) },
                onDelete: { id in try await cloud.delete(id) },
                onRestore: { id in try await cloud.restoreToInbox(id) },
                onQuickSave: onQuickSave,
                onOpenItem: onOpenItem,
                contextTitle: "Archived"
            )

            MacCloudSyncStatusView(
                isConnected: cloud.isConnected, isLoading: cloud.loading,
                isSaving: cloud.saving, lastError: cloud.lastError,
                lastSynced: cloud.lastSynced, lastPushed: cloud.lastPushed,
                onCheckUpdates: { await cloud.refresh() }
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 18)
    }
}
