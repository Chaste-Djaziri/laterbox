//
//  ItemCardView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import SwiftUI

public struct ItemCardView: View {
    public let item: LBItem
    public var onMarkDone: () -> Void
    public var onToggleFavorite: () -> Void
    public var onSchedule: () -> Void
    public var onDelete: () -> Void

    public init(
        item: LBItem,
        onMarkDone: @escaping () -> Void,
        onToggleFavorite: @escaping () -> Void,
        onSchedule: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.item = item
        self.onMarkDone = onMarkDone
        self.onToggleFavorite = onToggleFavorite
        self.onSchedule = onSchedule
        self.onDelete = onDelete
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Row: Favicon/Icon + Domain + Time ago + Favorite Button
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(AppTheme.accent)
                        .frame(width: 24, height: 24)
                    Image(systemName: item.parsedContentType.systemIcon)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                }

                if let domain = item.domain, !domain.isEmpty {
                    Text(domain)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(1)
                } else {
                    Text(item.parsedContentType.rawValue.capitalized)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(1)
                }

                Text("•")
                    .foregroundColor(AppTheme.textTertiary)
                    .font(.caption2)

                Text(formattedRelativeTime(item.createdAt))
                    .font(.caption2)
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(1)

                Spacer()

                Button(action: onToggleFavorite) {
                    Image(systemName: item.favorite ? "star.fill" : "star")
                        .foregroundColor(item.favorite ? AppTheme.amber : AppTheme.textTertiary)
                        .font(.system(size: 15))
                }
                .buttonStyle(.plain)
            }

            // Rich media banner if URL/Content is enriched
            if item.parsedContentType != .link || item.url != nil {
                RichMediaBanner(
                    type: item.parsedContentType,
                    url: item.url,
                    title: item.title,
                    previewImageUrl: item.previewImageUrl
                )
            }

            // Title
            Text(item.title)
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(2)

            // Optional note preview
            if let note = item.noteContent, !note.isEmpty {
                Text(note)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(2)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(AppTheme.background)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                            )
                    )
            }

            // Footer row: Collection Tag + Actions
            HStack(spacing: 8) {
                if let coll = item.collectionName, !coll.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "folder.fill")
                            .font(.caption2)
                        Text(coll)
                            .font(.caption2.weight(.medium))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(AppTheme.background))
                    .overlay(Capsule().strokeBorder(AppTheme.cardBorder, lineWidth: 1))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(1)
                }

                if let returnAt = item.returnAt {
                    let isTodayOrOverdue = Calendar.current.isDateInToday(returnAt) || returnAt < Date()
                    HStack(spacing: 4) {
                        Image(systemName: isTodayOrOverdue ? "exclamationmark.clock.fill" : "calendar")
                            .font(.caption2)
                        Text(isTodayOrOverdue ? "Due Today" : returnAt.formatted(.dateTime.month().day()))
                            .font(.caption2.weight(.bold))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(isTodayOrOverdue ? AppTheme.darkSurface : AppTheme.accent)
                    )
                    .foregroundColor(isTodayOrOverdue ? AppTheme.textOnDark : AppTheme.textPrimary)
                    .lineLimit(1)
                } else if item.status == ItemStatus.deferred.rawValue {
                    HStack(spacing: 4) {
                        Image(systemName: "moon.fill")
                            .font(.caption2)
                        Text("Someday")
                            .font(.caption2.weight(.medium))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(AppTheme.background))
                    .overlay(Capsule().strokeBorder(AppTheme.cardBorder, lineWidth: 1))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(1)
                }

                Spacer()

                // Action buttons
                Button(action: onSchedule) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(AppTheme.background))
                        .overlay(Circle().strokeBorder(AppTheme.cardBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)

                Button(action: onMarkDone) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(AppTheme.accent))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .liquidGlassCard(cornerRadius: 20, borderOpacity: 0.22, isInteractive: true)
        .contextMenu {
            Button(action: onMarkDone) {
                Label("Mark as Done", systemImage: "checkmark.circle")
            }
            Button(action: onSchedule) {
                Label("Reschedule Return", systemImage: "clock")
            }
            Button(action: onToggleFavorite) {
                Label(item.favorite ? "Unstar" : "Star", systemImage: item.favorite ? "star.slash" : "star")
            }
            if let urlStr = item.url, let url = URL(string: urlStr) {
                Link(destination: url) {
                    Label("Open in Safari", systemImage: "safari")
                }
                Button(action: {
                    #if canImport(UIKit)
                    ClipboardDetectionManager.shared.recordInternalCopy(urlStr)
                    UIPasteboard.general.string = urlStr
                    #elseif canImport(AppKit)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(urlStr, forType: .string)
                    #endif
                    LBHaptic.success()
                }) {
                    Label("Copy Link", systemImage: "doc.on.doc")
                }
            }
            Divider()
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func formattedRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
