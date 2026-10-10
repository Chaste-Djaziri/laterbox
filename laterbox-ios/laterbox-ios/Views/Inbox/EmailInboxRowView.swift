//
//  EmailInboxRowView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 11.10.26.
//

import SwiftUI
import SwiftData

public struct EmailInboxRowView: View {
    public let item: LBItem
    public var isSelectionMode: Bool = false
    public var isSelected: Bool = false
    public var onToggleSelect: () -> Void = {}
    public var onToggleFavorite: () -> Void = {}
    public var onMarkDone: () -> Void = {}
    public var onSchedule: (Date) -> Void = { _ in }
    public var onDelete: () -> Void = {}

    public init(
        item: LBItem,
        isSelectionMode: Bool = false,
        isSelected: Bool = false,
        onToggleSelect: @escaping () -> Void = {},
        onToggleFavorite: @escaping () -> Void = {},
        onMarkDone: @escaping () -> Void = {},
        onSchedule: @escaping (Date) -> Void = { _ in },
        onDelete: @escaping () -> Void = {}
    ) {
        self.item = item
        self.isSelectionMode = isSelectionMode
        self.isSelected = isSelected
        self.onToggleSelect = onToggleSelect
        self.onToggleFavorite = onToggleFavorite
        self.onMarkDone = onMarkDone
        self.onSchedule = onSchedule
        self.onDelete = onDelete
    }

    private var senderText: String {
        if let site = item.siteName?.trimmingCharacters(in: .whitespacesAndNewlines), !site.isEmpty {
            return site
        }
        if let domain = item.domain?.trimmingCharacters(in: .whitespacesAndNewlines), !domain.isEmpty {
            let host = domain.replacingOccurrences(of: "www.", with: "")
            let parts = host.split(separator: ".")
            if parts.count >= 2 {
                let main = String(parts[0])
                return main.prefix(1).capitalized + main.dropFirst()
            }
            return host
        }
        if let urlStr = item.url, let url = URL(string: urlStr), let host = url.host {
            let cleanHost = host.replacingOccurrences(of: "www.", with: "")
            let parts = cleanHost.split(separator: ".")
            if parts.count >= 2 {
                let main = String(parts[0])
                return main.prefix(1).capitalized + main.dropFirst()
            }
            return cleanHost
        }
        if item.attachmentsData != nil {
            return "File"
        }
        if item.type == ItemContentType.note.rawValue {
            return "Note"
        }
        return "LaterBox"
    }

    private var snippetText: String {
        if !item.summary.isEmpty {
            return item.summary
        }
        if let desc = item.metadataDescription, !desc.isEmpty {
            return desc
        }
        if let note = item.noteContent, !note.isEmpty {
            return note
        }
        if let url = item.url {
            return url
        }
        return "Saved item"
    }

    private var formattedDate: String {
        let calendar = Calendar.current
        let date = item.createdAt
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        }
        let currentYear = calendar.component(.year, from: Date())
        let dateYear = calendar.component(.year, from: date)
        let formatter = DateFormatter()
        if currentYear == dateYear {
            formatter.dateFormat = "d MMM"
        } else {
            formatter.dateFormat = "M/d/yy"
        }
        return formatter.string(from: date)
    }

    private var isVideo: Bool {
        item.type == ItemContentType.video.rawValue ||
        (item.url?.lowercased().contains("youtube.com") ?? false) ||
        (item.url?.lowercased().contains("youtu.be") ?? false) ||
        (item.url?.lowercased().contains("vimeo.com") ?? false)
    }

    private var hasAttachments: Bool {
        item.attachmentsData != nil
    }

    public var body: some View {
        ZStack(alignment: .trailing) {
            // Right-aligned subtle fading OG watermark (matching web anime-card style)
            if let preview = item.previewImageUrl, let imgUrl = URL(string: preview) {
                AsyncImage(url: imgUrl) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 140, height: 64)
                            .clipped()
                            .mask(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.black.opacity(0.28),
                                        Color.black.opacity(0.12),
                                        Color.clear
                                    ]),
                                    startPoint: .trailing,
                                    endPoint: .leading
                                )
                            )
                    }
                }
                .allowsHitTesting(false)
            }

            // Row content
            HStack(spacing: 10) {
                // Multi-select Checkbox
                if isSelectionMode {
                    Button(action: onToggleSelect) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 18))
                            .foregroundColor(isSelected ? AppTheme.textPrimary : AppTheme.cardBorder)
                    }
                    .buttonStyle(.plain)
                }

                // Star Button
                Button(action: onToggleFavorite) {
                    Image(systemName: item.favorite ? "star.fill" : "star")
                        .font(.system(size: 14))
                        .foregroundColor(item.favorite ? AppTheme.amber : Color.black.opacity(0.22))
                }
                .buttonStyle(.plain)

                // Sender / Source Indicator
                HStack(spacing: 6) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(AppTheme.accent.opacity(0.5))
                            .frame(width: 20, height: 20)
                        Image(systemName: item.parsedContentType.systemIcon)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                    }

                    Text(senderText)
                        .font(.caption.weight(.bold))
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(1)
                }
                .frame(width: 88, alignment: .leading)

                // Middle: Title + Snippet + Badges
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(item.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppTheme.textPrimary)
                            .lineLimit(1)

                        // Attachment Chip
                        if hasAttachments {
                            HStack(spacing: 2) {
                                Image(systemName: "paperclip")
                                    .font(.system(size: 8, weight: .bold))
                                Text("File")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(Color(hex: "F0EDE4"), in: Capsule())
                            .foregroundColor(AppTheme.textPrimary)
                        }

                        // Video Chip
                        if isVideo {
                            HStack(spacing: 2) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 7, weight: .bold))
                                Text("Video")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(Color.red.opacity(0.1), in: Capsule())
                            .foregroundColor(Color.red)
                        }

                        // Collection Tag
                        if let collection = item.collectionName, !collection.isEmpty {
                            HStack(spacing: 2) {
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 7, weight: .bold))
                                Text(collection)
                                    .font(.system(size: 9, weight: .semibold))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(AppTheme.accent.opacity(0.4), in: Capsule())
                            .foregroundColor(AppTheme.textPrimary)
                        }
                    }

                    Text(snippetText)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Right Date Stamp
                Text(formattedDate)
                    .font(.caption2.weight(.medium))
                    .foregroundColor(AppTheme.textTertiary)
                    .lineLimit(1)
            }
            .padding(.vertical, 11)
            .padding(.horizontal, 14)
        }
        .background(AppTheme.cardBackground)
        .contentShape(Rectangle())
        .swipeActions(edge: .leading) {
            Button {
                onToggleFavorite()
            } label: {
                Label(item.favorite ? "Unstar" : "Star", systemImage: item.favorite ? "star.slash.fill" : "star.fill")
            }
            .tint(AppTheme.amber)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash.fill")
            }

            Button {
                let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                onSchedule(tomorrow)
            } label: {
                Label("Snooze", systemImage: "clock.fill")
            }
            .tint(Color.orange)

            Button {
                onMarkDone()
            } label: {
                Label("Keep", systemImage: "checkmark.circle.fill")
            }
            .tint(Color.green)
        }
        .contextMenu {
            if let urlStr = item.url, let url = URL(string: urlStr) {
                Link(destination: url) {
                    Label("Open Link", systemImage: "safari")
                }
            }

            Button {
                onToggleFavorite()
            } label: {
                Label(item.favorite ? "Unstar" : "Star", systemImage: item.favorite ? "star.slash" : "star")
            }

            Button {
                let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                onSchedule(tomorrow)
            } label: {
                Label("Snooze Until Tomorrow", systemImage: "clock")
            }

            Button {
                onMarkDone()
            } label: {
                Label("Mark as Kept / Done", systemImage: "checkmark.circle")
            }

            if let text = item.url ?? item.textContent {
                Button {
                    UIPasteboard.general.string = text
                    LBHaptic.light()
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
            }

            Divider()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
