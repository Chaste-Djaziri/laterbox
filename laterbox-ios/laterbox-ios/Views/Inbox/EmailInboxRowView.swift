//
//  EmailInboxRowView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 11.10.26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import ImageIO

public struct EmailInboxRowView: View {
    @State private var attachmentThumbnail: UIImage?
    public let item: LBItem
    public var isSelectionMode: Bool = false
    public var isSelected: Bool = false
    public var topRadius: CGFloat = 4
    public var bottomRadius: CGFloat = 4
    public var onToggleSelect: () -> Void = {}
    public var onToggleFavorite: () -> Void = {}
    public var onMarkDone: () -> Void = {}
    public var onSchedule: (Date) -> Void = { _ in }
    public var onOpenSchedule: (() -> Void)? = nil
    public var onDelete: () -> Void = {}
    public var onDeletePermanently: (() -> Void)? = nil
    public var onRestore: (() -> Void)? = nil
    public var onAddToCollection: (() -> Void)? = nil

    public init(
        item: LBItem,
        isSelectionMode: Bool = false,
        isSelected: Bool = false,
        topRadius: CGFloat = 4,
        bottomRadius: CGFloat = 4,
        onToggleSelect: @escaping () -> Void = {},
        onToggleFavorite: @escaping () -> Void = {},
        onMarkDone: @escaping () -> Void = {},
        onSchedule: @escaping (Date) -> Void = { _ in },
        onOpenSchedule: (() -> Void)? = nil,
        onDelete: @escaping () -> Void = {},
        onDeletePermanently: (() -> Void)? = nil,
        onRestore: (() -> Void)? = nil,
        onAddToCollection: (() -> Void)? = nil
    ) {
        self.item = item
        self.isSelectionMode = isSelectionMode
        self.isSelected = isSelected
        self.topRadius = topRadius
        self.bottomRadius = bottomRadius
        self.onToggleSelect = onToggleSelect
        self.onToggleFavorite = onToggleFavorite
        self.onMarkDone = onMarkDone
        self.onSchedule = onSchedule
        self.onOpenSchedule = onOpenSchedule
        self.onDelete = onDelete
        self.onDeletePermanently = onDeletePermanently
        self.onRestore = onRestore
        self.onAddToCollection = onAddToCollection
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

    private var avatarColor: Color {
        let colors: [Color] = [
            Color(hex: "A855F7"), // Purple (like screenshot)
            Color(hex: "3B82F6"), // Blue
            Color(hex: "10B981"), // Emerald
            Color(hex: "F59E0B"), // Amber
            Color(hex: "EC4899"), // Pink
            Color(hex: "6366F1"), // Indigo
            Color(hex: "14B8A6"), // Teal
            Color(hex: "8B5CF6")  // Violet
        ]
        let hash = abs(senderText.hashValue)
        return colors[hash % colors.count]
    }

    private var avatarInitial: String {
        let clean = senderText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = clean.first else { return "L" }
        return String(first).uppercased()
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
            return formatter.string(from: date).lowercased()
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

    private var hasAttachments: Bool {
        item.attachmentsData != nil
    }

    private var effectivePreviewImageUrl: String? {
        var raw: String?
        if let p = item.previewImageUrl, !p.isEmpty {
            raw = p
        } else if let urlStr = item.url, let url = URL(string: urlStr) {
            if let videoId = EmbeddedMediaType.extractYouTubeId(from: url) {
                raw = "https://img.youtube.com/vi/\(videoId)/mqdefault.jpg"
            }
        }
        guard var url = raw else { return nil }
        // Sanitize YouTube letterboxed 4:3 hqdefault.jpg/sddefault.jpg to true 16:9 mqdefault.jpg (no black bars)
        if url.contains("youtube.com") || url.contains("ytimg.com") {
            url = url.replacingOccurrences(of: "/hqdefault.jpg", with: "/mqdefault.jpg")
                     .replacingOccurrences(of: "/sddefault.jpg", with: "/mqdefault.jpg")
        }
        return url
    }

    public var body: some View {
        ZStack(alignment: .trailing) {
            // Right-aligned fading OG / Video cover image watermark (matching web anime-card style)
            if let previewUrlStr = effectivePreviewImageUrl, let previewUrl = URL(string: previewUrlStr) {
                GeometryReader { geo in
                    let cardHeight = geo.size.height
                    let watermarkWidth = max(geo.size.width * 0.45, 185)
                    AsyncImage(url: previewUrl) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: watermarkWidth, height: cardHeight)
                                .scaleEffect(1.08, anchor: .center)
                                .clipped()
                                .opacity(0.70)
                                .mask(
                                    LinearGradient(
                                        stops: [
                                            .init(color: .clear, location: 0.0),
                                            .init(color: .black.opacity(0.4), location: 0.35),
                                            .init(color: .black.opacity(0.85), location: 0.65),
                                            .init(color: .black, location: 1.0)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .overlay(
                                    LinearGradient(
                                        stops: [
                                            .init(color: Color.white.opacity(0.92), location: 0.0),
                                            .init(color: Color.white.opacity(0.2), location: 0.6),
                                            .init(color: .clear, location: 1.0)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: watermarkWidth, height: cardHeight)
                        default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                }
                .allowsHitTesting(false)
            }

            HStack(alignment: .top, spacing: 14) {
                // Multi-select Checkbox (if in selection mode)
                if isSelectionMode {
                    Button(action: onToggleSelect) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundColor(isSelected ? AppTheme.textPrimary : Color.gray.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)
                }

                // Left: Colored Avatar Circle (Matching Gmail screenshot)
                ZStack {
                    if let attachmentThumbnail {
                        Image(uiImage: attachmentThumbnail)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 52, height: 52)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .accessibilityLabel("Image attachment preview")
                    } else {
                    Circle()
                        .fill(avatarColor)
                        .frame(width: 40, height: 40)
                    Text(avatarInitial)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    }
                }
                .task(id: item.attachmentsData) {
                    attachmentThumbnail = nil
                    guard let data = item.attachmentsData,
                          let files = try? JSONDecoder().decode([SharedAttachment].self, from: data),
                          let image = files.first(where: {
                              UTType($0.typeIdentifier)?.conforms(to: .image) == true ||
                              $0.mimeType?.hasPrefix("image/") == true ||
                              ["jpg", "jpeg", "png", "gif", "webp", "heic", "heif", "avif"].contains(URL(fileURLWithPath: $0.name).pathExtension.lowercased())
                          }),
                          let url = try? SharedCaptureStore.fileURL(image),
                          let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                          let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                            kCGImageSourceCreateThumbnailFromImageAlways: true,
                            kCGImageSourceCreateThumbnailWithTransform: true,
                            kCGImageSourceThumbnailMaxPixelSize: 160
                          ] as CFDictionary) else { return }
                    attachmentThumbnail = UIImage(cgImage: thumbnail)
                }

                // Middle & Right: 3-line email summary layout
                VStack(alignment: .leading, spacing: 2.5) {
                    // Line 1: Sender Name + Timestamp
                    HStack(alignment: .firstTextBaseline) {
                        Text(senderText)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        Text(formattedDate)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color.secondary)
                    }

                    // Line 2: Subject / Title
                    Text(item.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(1)

                    // Line 3: Snippet text + Bottom-Right Star Icon
                    HStack(alignment: .center, spacing: 6) {
                        Text(snippetText)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color.secondary)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Button(action: onToggleFavorite) {
                            Image(systemName: item.favorite ? "star.fill" : "star")
                                .font(.system(size: 16))
                                .foregroundColor(item.favorite ? AppTheme.amber : Color.black.opacity(0.28))
                        }
                        .buttonStyle(.plain)
                    }

                    // Optional Action Chip / Pill (e.g. Collection tag or attachment badge)
                    if let collection = item.collectionName, !collection.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 9))
                            Text(collection)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(hex: "E8F0FE"), in: Capsule())
                        .foregroundColor(Color(hex: "1967D2"))
                        .padding(.top, 2)
                    } else if hasAttachments {
                        HStack(spacing: 4) {
                            Image(systemName: "paperclip")
                                .font(.system(size: 9))
                            Text("Attachment")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(hex: "E8F0FE"), in: Capsule())
                        .foregroundColor(Color(hex: "1967D2"))
                        .padding(.top, 2)
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: topRadius,
                bottomLeadingRadius: bottomRadius,
                bottomTrailingRadius: bottomRadius,
                topTrailingRadius: topRadius,
                style: .continuous
            )
            .fill(Color.white)
        )
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: topRadius,
                bottomLeadingRadius: bottomRadius,
                bottomTrailingRadius: bottomRadius,
                topTrailingRadius: topRadius,
                style: .continuous
            )
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: topRadius,
                bottomLeadingRadius: bottomRadius,
                bottomTrailingRadius: bottomRadius,
                topTrailingRadius: topRadius,
                style: .continuous
            )
            .strokeBorder(Color.black.opacity(0.04), lineWidth: 0.5)
        )
        .contentShape(
            UnevenRoundedRectangle(
                topLeadingRadius: topRadius,
                bottomLeadingRadius: bottomRadius,
                bottomTrailingRadius: bottomRadius,
                topTrailingRadius: topRadius,
                style: .continuous
            )
        )
        .swipeActions(edge: .leading) {
            Button {
                onToggleFavorite()
            } label: {
                Label(item.favorite ? "Unstar" : "Star", systemImage: item.favorite ? "star.slash.fill" : "star.fill")
            }
            .tint(AppTheme.amber)

            if let onAddToCollection {
                Button {
                    onAddToCollection()
                } label: {
                    Label("Collection", systemImage: "folder.fill")
                }
                .tint(Color(hex: "0284C7"))
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash.fill")
            }

            Button {
                if let onOpenSchedule {
                    onOpenSchedule()
                } else {
                    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                    onSchedule(tomorrow)
                }
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
                if let onOpenSchedule {
                    onOpenSchedule()
                } else {
                    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                    onSchedule(tomorrow)
                }
            } label: {
                Label("Snooze...", systemImage: "clock")
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

            if item.status == ItemStatus.deleted.rawValue {
                if let onRestore {
                    Button {
                        onRestore()
                    } label: {
                        Label("Restore to Inbox", systemImage: "arrow.uturn.backward")
                    }
                }

                Button(role: .destructive) {
                    if let onDeletePermanently {
                        onDeletePermanently()
                    } else {
                        onDelete()
                    }
                } label: {
                    Label("Delete Permanently", systemImage: "trash.fill")
                }
            } else {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}
