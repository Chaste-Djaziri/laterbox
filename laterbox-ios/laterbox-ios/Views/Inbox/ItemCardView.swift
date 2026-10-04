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
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.lbAmber.opacity(0.2))
                        .frame(width: 22, height: 22)
                    Image(systemName: item.parsedContentType.systemIcon)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.lbAmber)
                }

                if let domain = item.domain, !domain.isEmpty {
                    Text(domain)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.primary)
                } else {
                    Text(item.parsedContentType.rawValue.capitalized)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.primary)
                }

                Text("•")
                    .foregroundColor(.secondary)
                    .font(.caption2)

                Text(formattedRelativeTime(item.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: onToggleFavorite) {
                    Image(systemName: item.favorite ? "star.fill" : "star")
                        .foregroundColor(item.favorite ? Color.lbAmber : .secondary)
                        .font(.system(size: 14))
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
                .foregroundColor(.primary)
                .lineLimit(2)

            // Optional note preview
            if let note = item.noteContent, !note.isEmpty {
                Text(note)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.04)))
            }

            // Footer row: Collection Tag + Actions
            HStack(spacing: 8) {
                if let coll = item.collectionName, !coll.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "folder.fill")
                            .font(.caption2)
                        Text(coll)
                            .font(.caption2.weight(.medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
                    .foregroundColor(.secondary)
                }

                if let returnAt = item.returnAt {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(returnAt, format: .dateTime.month().day())
                            .font(.caption2.weight(.medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.lbAmber.opacity(0.15)))
                    .foregroundColor(Color.lbAmber)
                }

                Spacer()

                // Action buttons
                Button(action: onSchedule) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)

                Button(action: onMarkDone) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color.lbAmber)
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
