// laterbox-ios/LaterBoxMac/MacTodayView.swift
import SwiftUI

/// Matches Web Today: active Inbox arrivals from the preceding 24 elapsed
/// hours, including scheduled returns at their due time (not calendar midnight).
struct MacTodayView: View {
    @ObservedObject var cloud: MacCloudSyncStore
    let now: Date
    let onQuickSave: () -> Void
    let onOpenItem: (String) -> Void

    @Environment(\.colorScheme) private var scheme

    private var arrivals: [MacInboxEntry] {
        let cutoff = now.addingTimeInterval(-24 * 3600)
        return cloud.activeItems.filter { item in
            let isDue = item.isUnread || (item.returnDate.map { $0 <= now } ?? false)
            guard isDue, let arrival = item.inboxArrival else { return false }
            return arrival >= cutoff && arrival <= now
        }.sorted {
            let lhs = $0.inboxArrival ?? $0.date
            let rhs = $1.inboxArrival ?? $1.date
            return lhs == rhs ? $0.date > $1.date : lhs > rhs
        }
    }

    private var dark: Bool { scheme == .dark }
    private var bannerBackground: Color {
        dark ? Color(red: 42 / 255, green: 48 / 255, blue: 39 / 255)
             : Color(red: 244 / 255, green: 247 / 255, blue: 233 / 255)
    }
    private var bannerBorder: Color {
        dark ? Color.white.opacity(0.12)
             : Color(red: 228 / 255, green: 231 / 255, blue: 216 / 255)
    }
    private var bannerText: Color {
        dark ? Color(red: 222 / 255, green: 232 / 255, blue: 211 / 255)
             : Color(red: 77 / 255, green: 98 / 255, blue: 64 / 255)
    }
    private let lime = Color(red: 230 / 255, green: 237 / 255, blue: 176 / 255)

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 11) {
                Image(systemName: "clock")
                    .font(.system(size: 16, weight: .medium))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Last 24 hours.")
                        .font(.system(size: 13, weight: .bold))
                    Text("Items that arrived in your Inbox, including scheduled returns.")
                        .font(.system(size: 12))
                }
                Spacer(minLength: 10)
                if !cloud.loading {
                    Text("\(arrivals.count) \(arrivals.count == 1 ? "arrival" : "arrivals")")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(red: 51 / 255, green: 69 / 255, blue: 43 / 255))
                        .padding(.horizontal, 12)
                        .frame(height: 27)
                        .background(lime, in: Capsule())
                        .accessibilityLabel("\(arrivals.count) arrivals in the last 24 hours")
                } else if !cloud.isConnected {
                    ProgressView().controlSize(.small)
                }
            }
            .foregroundStyle(bannerText)
            .padding(.horizontal, 17)
            .frame(maxWidth: .infinity, minHeight: 65)
            .background(bannerBackground, in: RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(bannerBorder))

            MacInboxTableView(
                items: arrivals,
                isConnected: cloud.isConnected,
                isLoading: cloud.loading,
                syncError: cloud.lastError,
                onRefresh: { await cloud.refresh() },
                onStar: { id, starred in try await cloud.setStarred(id, starred: starred) },
                onArchive: { id in try await cloud.archive(id) },
                onDelete: { id in try await cloud.delete(id) },
                onQuickSave: onQuickSave,
                onOpenItem: onOpenItem,
                contextTitle: "Today",
                sortByInboxArrival: true
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
