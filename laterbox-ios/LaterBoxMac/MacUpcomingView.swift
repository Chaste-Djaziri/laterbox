// laterbox-ios/LaterBoxMac/MacUpcomingView.swift
import SwiftUI

/// Web parity: deferred items scheduled from the start of tomorrow onward,
/// using the user's current local calendar and timezone.
struct MacUpcomingView: View {
    @ObservedObject var cloud: MacCloudSyncStore
    let now: Date
    let onQuickSave: () -> Void
    let onOpenItem: (String) -> Void

    private var scheduledItems: [MacInboxEntry] {
        let tomorrow = Calendar.current.date(
            byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: now)
        ) ?? now.addingTimeInterval(86400)
        return cloud.activeItems.filter { item in
            guard !item.isUnread, let date = item.returnDate else { return false }
            return date >= tomorrow
        }.sorted { ($0.returnDate ?? .distantFuture) < ($1.returnDate ?? .distantFuture) }
    }

    var body: some View {
        VStack(spacing: 12) {
            MacInboxTableView(
                items: scheduledItems,
                isConnected: cloud.isConnected,
                isLoading: cloud.loading,
                syncError: cloud.lastError,
                onRefresh: { await cloud.refresh() },
                onStar: { id, starred in try await cloud.setStarred(id, starred: starred) },
                onArchive: { id in try await cloud.archive(id) },
                onDelete: { id in try await cloud.delete(id) },
                onQuickSave: onQuickSave,
                onOpenItem: onOpenItem,
                contextTitle: "Upcoming",
                sortByReturnDate: true
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
