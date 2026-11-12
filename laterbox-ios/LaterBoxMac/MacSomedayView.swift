// laterbox-ios/LaterBoxMac/MacSomedayView.swift
import SwiftUI

/// Mirrors the Web Someday filter: active deferred captures without a
/// return date. Items remain here until rescheduled or moved elsewhere.
struct MacSomedayView: View {
    @ObservedObject var cloud: MacCloudSyncStore
    let onQuickSave: () -> Void
    let onOpenItem: (String) -> Void

    private var somedayItems: [MacInboxEntry] {
        cloud.activeItems
            .filter { !$0.isUnread && $0.returnDate == nil }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        VStack(spacing: 12) {
            MacInboxTableView(
                items: somedayItems,
                isConnected: cloud.isConnected,
                isLoading: cloud.loading,
                syncError: cloud.lastError,
                onRefresh: { await cloud.refresh() },
                onStar: { id, starred in try await cloud.setStarred(id, starred: starred) },
                onArchive: { id in try await cloud.archive(id) },
                onDelete: { id in try await cloud.delete(id) },
                onQuickSave: onQuickSave,
                onOpenItem: onOpenItem,
                contextTitle: "Someday"
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
