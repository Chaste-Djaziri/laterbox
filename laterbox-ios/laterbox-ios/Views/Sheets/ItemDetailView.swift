//
//  ItemDetailView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import SwiftUI
import SwiftData
import QuickLook
import SafariServices

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

public struct ItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable public var item: LBItem
    @ObservedObject var coordinator = SyncCoordinator.shared
    @Query(sort: \LBCollection.name) private var availableCollections: [LBCollection]

    // Follow-ups & Notes state
    @State private var threadData: ItemThreadData = ItemThreadData()
    @State private var noteDraftText: String = ""
    @State private var quotedSnippet: String? = nil
    @FocusState private var isNoteFocused: Bool

    // Item metadata & sheets
    @State private var editedTitle: String = ""
    @State private var showingDeleteConfirm: Bool = false
    @State private var showingCollectionSheet: Bool = false
    @State private var newCollectionName: String = ""
    @State private var saveError: String?
    @State private var previewDocumentURL: URL?
    @State private var showingSafariReader: Bool = false
    @State private var showingTagsSheet: Bool = false
    @State private var newTagInput: String = ""
    @State private var showingSchedulePicker: Bool = false
    @State private var scheduledDate: Date = Date().addingTimeInterval(86400)
    @State private var newChecklistTaskText: String = ""

    public var isModal: Bool

    public init(item: LBItem, isModal: Bool = false) {
        self.item = item
        self.isModal = isModal
        self._editedTitle = State(initialValue: item.title)
        self._threadData = State(initialValue: ItemThreadParser.parse(from: item.noteContent))
    }

    private var domainOrSender: String {
        if let domain = item.domain, !domain.isEmpty {
            return domain
        }
        if let host = URL(string: item.url ?? "")?.host {
            return host.replacingOccurrences(of: "www.", with: "")
        }
        return item.parsedContentType.rawValue.capitalized
    }

    private var senderInitial: String {
        let name = domainOrSender
        if let first = name.first {
            return String(first).uppercased()
        }
        return "L"
    }

    public var body: some View {
        ZStack {
            // Warm signature canvas background matching web & mobile inbox
            AppTheme.canvasBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 1. Top Navigation Bar with web-aligned action controls at top right
                topNavigationBar

                // 2. Focused scrollable body: Show what the user came back for
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        // Return Schedule Banner (if scheduled)
                        if item.status == ItemStatus.inbox.rawValue {
                            inboxAgeBanner
                        } else if let ret = item.returnAt {
                            returnScheduleBanner(ret: ret)
                        }

                        // Attachments & Files Card (if any)
                        if let data = item.attachmentsData,
                           let files = try? JSONDecoder().decode([SharedAttachment].self, from: data),
                           !files.isEmpty {
                            attachmentsCard(files: files)
                        }

                        // Embedded In-App Media Player (YouTube, Vimeo, Spotify, Apple Music)
                        let mediaType = EmbeddedMediaType.detect(url: item.url)
                        if mediaType != .none && mediaType != .webArticle(url: URL(string: item.url ?? "")!) {
                            VStack(alignment: .leading, spacing: 6) {
                                InlineVideoEmbedView(embedType: mediaType, previewImageUrl: item.previewImageUrl)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
                        } else if let preview = item.previewImageUrl, !preview.isEmpty, URL(string: preview) != nil {
                            // Rich Visual Banner (OpenGraph Preview Image)
                            RichMediaBanner(
                                type: item.parsedContentType,
                                url: item.url,
                                title: item.title,
                                previewImageUrl: item.previewImageUrl
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
                        }

                        // Main Header Card (Title, Domain, Metadata, Collections/Tags)
                        mainHeaderCard

                        // Captured Highlight Quote (if saved via extension text highlight)
                        if let highlight = item.textSelector, !highlight.isEmpty, let text = item.textContent, !text.isEmpty {
                            capturedHighlightCard(text: text)
                        }

                        // AI Summary Card (if present)
                        if !item.summary.isEmpty {
                            aiSummaryCard
                        }

                        // Tasks / Captured Content / Full Article Text Viewer
                        let captured = item.textContent?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        let formatted = item.formattedContent.trimmingCharacters(in: .whitespacesAndNewlines)
                        if item.parsedContentType == .task || isTaskChecklistContent(captured) {
                            taskChecklistCard(content: captured)
                        } else if (!captured.isEmpty && item.textSelector == nil) || !formatted.isEmpty {
                            RichCapturedContentViewer(
                                title: "Captured Content",
                                content: !captured.isEmpty ? captured : formatted,
                                formattedHTML: !formatted.isEmpty ? formatted : nil
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
                        }

                        // Personal Notes & Follow-ups Section (Clean & Non-intrusive)
                        notesAndFollowUpsCard
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                }

                // 3. Docked Bottom Input Bar for quick notes & follow-ups
                bottomChatInputBar
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingSafariReader) {
            if let urlStr = item.url, let url = URL(string: urlStr) {
                SFSafariViewWrapper(url: url, entersReaderIfAvailable: true)
                    .ignoresSafeArea()
            }
        }
        .sheet(item: Binding<IdentifiableURL?>(
            get: { previewDocumentURL.map { IdentifiableURL(url: $0) } },
            set: { previewDocumentURL = $0?.url }
        )) { doc in
            DocumentReaderSheet(url: doc.url, title: doc.url.lastPathComponent)
        }
        .sheet(isPresented: $showingSchedulePicker) {
            schedulePickerSheet
        }
        .sheet(isPresented: $showingCollectionSheet) {
            collectionPickerSheet
        }
        .sheet(isPresented: $showingTagsSheet) {
            tagsPopupSheet
        }
        .confirmationDialog("Are you sure you want to delete this item?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            Button("Delete Item", role: .destructive) {
                coordinator.deleteItem(item: item, context: modelContext)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        .onDisappear {
            Task { await coordinator.syncPendingItems(context: modelContext) }
        }
        .task {
            if item.parsedStatus == .inbox && !item.seen {
                coordinator.markItemSeen(item: item, context: modelContext)
            }
            threadData = ItemThreadParser.parse(from: item.noteContent)

            let needsTitleHeal = LinkMetadataLoader.isGenericTitle(item.title)
            let needsDescHeal = item.metadataDescription != nil && LinkMetadataLoader.isGenericDescription(item.metadataDescription)
            let junkTags: Set<String> = ["sharing", "camera phone", "video phone", "free", "upload", "playlist", "video playlist"]
            let hasJunkTags = item.tags.contains { junkTags.contains($0.lowercased()) }
            if (needsTitleHeal || needsDescHeal || hasJunkTags) && item.url != nil {
                await coordinator.enrich(item: item, context: modelContext)
            }
            let trimmedCategory = item.category.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedCategory.isEmpty && (item.collectionName == nil || item.collectionId == nil) {
                let coll = coordinator.ensureCollectionExists(named: trimmedCategory, context: modelContext)
                item.collectionName = coll?.name ?? trimmedCategory
                item.collectionId = coll?.id ?? item.collectionId
                persistEdit()
            }
        }
    }

    // MARK: - 1. Top Navigation Bar (Controls at top right like web)
    private var topNavigationBar: some View {
        HStack(spacing: 8) {
            // Left: Back Button
            Button {
                dismiss()
                LBHaptic.light()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: isModal ? "xmark" : "chevron.left")
                        .font(.system(size: isModal ? 14 : 16, weight: .bold))
                    Text(isModal ? "Done" : "Back")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(AppTheme.textPrimary)
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
            }
            .buttonStyle(.plain)

            Spacer()

            // Right Action Controls: Grouped together exactly like web
            HStack(spacing: 6) {
                // 1. Star / Favorite Button
                Button {
                    coordinator.toggleFavorite(item: item, context: modelContext)
                    LBHaptic.medium()
                } label: {
                    Image(systemName: item.favorite ? "star.fill" : "star")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(item.favorite ? Color(hex: "F59E0B") : Color(hex: "6C6B63"))
                        .frame(width: 34, height: 34)
                        .background(item.favorite ? Color(hex: "FEF3C7") : Color.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                // 2. Keep / Archive / Move to Inbox Status Action Pill
                statusActionButton

                // 3. Snooze / Return Schedule Button
                Button {
                    scheduledDate = item.returnAt ?? (SnoozePreset.oneDay.calculateDate() ?? Date().addingTimeInterval(86400))
                    showingSchedulePicker = true
                    LBHaptic.light()
                } label: {
                    Image(systemName: item.returnAt != nil ? "clock.fill" : "clock")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(item.returnAt != nil ? Color(hex: "F59E0B") : Color(hex: "6C6B63"))
                        .frame(width: 34, height: 34)
                        .background(item.returnAt != nil ? Color(hex: "FEF3C7") : Color.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                // 4. Collections Button
                Button {
                    showingCollectionSheet = true
                    LBHaptic.light()
                } label: {
                    Image(systemName: (item.collectionName != nil && !item.collectionName!.isEmpty) ? "folder.fill" : "folder.badge.plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "0369A1"))
                        .frame(width: 34, height: 34)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                // 4. Share / Copy Link Button
                if let urlStr = item.url, let url = URL(string: urlStr) {
                    ShareLink(item: url) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "6C6B63"))
                            .frame(width: 34, height: 34)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        let textToCopy = item.title + (item.textContent.map { "\n\n\($0)" } ?? "")
                        UIPasteboard.general.string = textToCopy
                        LBHaptic.success()
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "6C6B63"))
                            .frame(width: 34, height: 34)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }

                // 5. External Safari Link (if URL exists)
                if let urlStr = item.url, let url = URL(string: urlStr) {
                    Link(destination: url) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "6C6B63"))
                            .frame(width: 34, height: 34)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }

                // 6. Delete Button
                Button {
                    showingDeleteConfirm = true
                    LBHaptic.light()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "EF4444"))
                        .frame(width: 34, height: 34)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(AppTheme.canvasBackground)
    }

    // MARK: - Status Action Button (Keep / Archive / Move to Inbox)
    private var statusActionButton: some View {
        Button {
            if item.status == ItemStatus.inbox.rawValue || item.status == ItemStatus.deferred.rawValue {
                coordinator.markDone(item: item, context: modelContext) // Moves to saved (Kept)
            } else if item.status == ItemStatus.saved.rawValue {
                item.status = ItemStatus.archived.rawValue
                persistEdit()
                Task { await coordinator.syncPendingItems(context: modelContext) }
                LBHaptic.medium()
            } else {
                item.status = ItemStatus.inbox.rawValue
                persistEdit()
                Task { await coordinator.syncPendingItems(context: modelContext) }
                LBHaptic.light()
            }
        } label: {
            HStack(spacing: 4) {
                if item.status == ItemStatus.inbox.rawValue || item.status == ItemStatus.deferred.rawValue {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text("Keep")
                        .font(.system(size: 12, weight: .bold))
                } else if item.status == ItemStatus.saved.rawValue {
                    Image(systemName: "archivebox.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text("Archive")
                        .font(.system(size: 12, weight: .bold))
                } else {
                    Image(systemName: "tray.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text("Inbox")
                        .font(.system(size: 12, weight: .bold))
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 34)
            .background(
                (item.status == ItemStatus.inbox.rawValue || item.status == ItemStatus.deferred.rawValue)
                    ? Color(hex: "E6EDB0")
                    : Color.white,
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .foregroundColor(Color(hex: "171711"))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 2. Return Schedule Banner
    private var inboxAgeBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "tray.full.fill")
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(width: 30, height: 30)
                .background(AppTheme.accent, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("In Inbox")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                HStack(spacing: 3) {
                    Text("Saved")
                    Text(item.createdAt, style: .relative)
                }
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            }

            Spacer()

            if item.returnAt == nil {
                Button("Reschedule") {
                    scheduledDate = SnoozePreset.oneDay.calculateDate() ?? Date().addingTimeInterval(86400)
                    showingSchedulePicker = true
                    LBHaptic.light()
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.04), in: Capsule())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func returnScheduleBanner(ret: Date) -> some View {
        let isTodayOrOverdue = Calendar.current.isDateInToday(ret) || ret < Date()
        return HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(isTodayOrOverdue ? Color(hex: "171711") : Color(hex: "E6EDB0"))
                    .frame(width: 30, height: 30)
                Image(systemName: isTodayOrOverdue ? "exclamationmark.clock.fill" : "calendar.badge.clock")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(isTodayOrOverdue ? Color(hex: "E6EDB0") : Color(hex: "171711"))
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(isTodayOrOverdue ? "Due Today" : "Scheduled Return")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Text(ret, format: .dateTime.month().day().year().hour().minute())
                    .font(.system(size: 11))
                    .foregroundColor(Color.secondary)
            }

            Spacer()

            Button("Reschedule") {
                scheduledDate = ret
                showingSchedulePicker = true
                LBHaptic.light()
            }
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(AppTheme.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.black.opacity(0.04), in: Capsule())

            Button {
                item.returnAt = nil
                item.status = ItemStatus.inbox.rawValue
                persistEdit()
                Task {
                    _ = try? await ReturnNotification.update(id: item.id, title: item.title, date: nil)
                }
                LBHaptic.light()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 4, y: 1)
    }

    // MARK: - 3. Main Header Card
    private var mainHeaderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSenderRow
            headerTitleAndDescription
            headerTagsPreview
            headerActionControlsRow
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, y: 2)
    }

    private var headerSenderRow: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color(hex: "171711"))
                    .frame(width: 22, height: 22)
                Text(senderInitial)
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(Color(hex: "E6EDB0"))
            }

            Text(domainOrSender)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)

            Text(item.parsedContentType.rawValue.capitalized)
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color(hex: "E6EDB0"), in: Capsule())
                .foregroundColor(Color(hex: "171711"))

            Spacer()

            Text(item.createdAt, format: .dateTime.month().day().year())
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.secondary)
        }
    }

    private var headerTitleAndDescription: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Title", text: $editedTitle, axis: .vertical)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(1...5)
                .onChange(of: editedTitle) { _, newVal in
                    item.title = newVal
                    persistEdit()
                }

            if let desc = item.metadataDescription, !desc.isEmpty, !LinkMetadataLoader.isGenericDescription(desc) {
                Text(desc)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(hex: "45443F"))
                    .lineLimit(4)
                    .lineSpacing(2)
            }
        }
    }

    @ViewBuilder
    private var headerTagsPreview: some View {
        if !item.tags.isEmpty {
            let previewLimit = 3
            let remainingCount = max(0, item.tags.count - previewLimit)
            LBFlowLayout(spacing: 6, lineSpacing: 6) {
                ForEach(Array(item.tags.prefix(previewLimit)), id: \.self) { tag in
                    tagChip(tag)
                }

                if remainingCount > 0 {
                    Button {
                        showingTagsSheet = true
                        LBHaptic.light()
                    } label: {
                        HStack(spacing: 3) {
                            Text("+\(remainingCount) more")
                                .font(.system(size: 11, weight: .semibold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8, weight: .bold))
                        }
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4.5)
                        .background(Color.black.opacity(0.05), in: Capsule())
                        .overlay(Capsule().strokeBorder(Color.black.opacity(0.08), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 2)
        }
    }

    @ViewBuilder
    private var headerActionControlsRow: some View {
        let hasCollection = (item.collectionName != nil && !item.collectionName!.isEmpty) || !item.category.isEmpty
        let hasReader = (item.url != nil && URL(string: item.url!) != nil)

        if hasCollection || hasReader {
            HStack(spacing: 8) {
                if let collName = item.collectionName ?? (item.category.isEmpty ? nil : item.category), !collName.isEmpty {
                    Button {
                        showingCollectionSheet = true
                        LBHaptic.light()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 11, weight: .semibold))
                            Text(collName)
                                .font(.system(size: 12, weight: .bold))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .foregroundColor(Color(hex: "0369A1"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .frame(minHeight: 32)
                        .background(Color(hex: "E0F2FE"), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(Color(hex: "BAE6FD"), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 8)

                if let urlStr = item.url, URL(string: urlStr) != nil {
                    Button {
                        showingSafariReader = true
                        LBHaptic.light()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "book.pages")
                                .font(.system(size: 12, weight: .bold))
                            Text("Reader")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .frame(minHeight: 32)
                        .background(Color(hex: "F7F5EE"), in: Capsule())
                        .overlay(Capsule().strokeBorder(Color.black.opacity(0.12), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .fixedSize()
                }
            }
            .padding(.top, 2)
        }
    }

    // MARK: - 4. Captured Highlight Quote Card
    private func capturedHighlightCard(text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 11, weight: .bold))
                Text("CAPTURED HIGHLIGHT")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.5)
            }
            .foregroundColor(Color(hex: "B45309"))

            Text("“\(text)”")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "92400E"))
                .italic()
                .lineSpacing(3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "FEF3C7").opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color(hex: "FDE68A"), lineWidth: 1)
        )
    }

    // MARK: - 5. Document Attachments Card
    private func attachmentsCard(files: [SharedAttachment]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "paperclip")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.secondary)
                Text("ATTACHMENTS & FILES (\(files.count))")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.secondary)
                    .tracking(0.6)
                if files.allSatisfy({ $0.remoteObjectKey != nil }) {
                    Label("Cloud synced", systemImage: "checkmark.icloud.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(hex: "166534"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "DCFCE7"), in: Capsule())
                }
            }

            ForEach(files) { file in
                let fileURL = try? SharedCaptureStore.fileURL(file)
                Button {
                    if let fileURL {
                        previewDocumentURL = fileURL
                    }
                } label: {
                    HStack(spacing: 12) {
                        fileIcon(for: file.name)
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: "171711"))
                            .frame(width: 36, height: 36)
                            .background(Color(hex: "F7F5EE"), in: RoundedRectangle(cornerRadius: 10))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(file.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)
                                .lineLimit(1)
                            Text(file.typeIdentifier.uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color.secondary)
                        }

                        Spacer()

                        if file.remoteObjectKey != nil {
                            Image(systemName: "checkmark.icloud.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: "16A34A"))
                                .accessibilityLabel("Uploaded to cloud")
                        }

                        Image(systemName: "eye.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.secondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - 6. AI Summary Card
    private var aiSummaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "1A73E8"))
                Text("AI Summary")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
            }

            Text(item.summary)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color(hex: "45443F"))
                .lineSpacing(3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, y: 2)
    }

    // MARK: - 6. Tasks & To-Do Checklist Card
    private struct ChecklistTaskItem: Identifiable {
        let id = UUID()
        let rawLineIndex: Int
        var isDone: Bool
        var text: String
    }

    private func isTaskChecklistContent(_ text: String) -> Bool {
        let pattern = #"(?m)^[-*•+]?\s*\[[ xX]\]"#
        return (try? NSRegularExpression(pattern: pattern).firstMatch(in: text, range: NSRange(location: 0, length: (text as NSString).length))) != nil
    }

    private func parseChecklistItems(from text: String) -> (prelude: [String], tasks: [ChecklistTaskItem]) {
        let lines = text.components(separatedBy: .newlines)
        var tasks: [ChecklistTaskItem] = []
        var prelude: [String] = []

        let checkboxRegex = try? NSRegularExpression(pattern: #"^[-*•+]?\s*\[([ xX])\]\s*(.*)$"#)

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            let fullRange = NSRange(location: 0, length: (trimmed as NSString).length)
            if let match = checkboxRegex?.firstMatch(in: trimmed, range: fullRange), match.numberOfRanges >= 3 {
                let mark = (trimmed as NSString).substring(with: match.range(at: 1))
                let isDone = mark.lowercased() == "x"
                let itemText = (trimmed as NSString).substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespaces)
                tasks.append(ChecklistTaskItem(rawLineIndex: index, isDone: isDone, text: itemText))
            } else if tasks.isEmpty {
                prelude.append(trimmed)
            } else {
                tasks.append(ChecklistTaskItem(rawLineIndex: index, isDone: false, text: trimmed))
            }
        }

        // If no explicit checkboxes were found, but this item is marked as task format, parse lines into tasks
        if tasks.isEmpty && item.parsedContentType == .task {
            for (index, line) in lines.enumerated() {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { continue }
                let cleanText = trimmed.replacingOccurrences(of: #"^[-*•+]\s+|^\d+[\.\)]\s+"#, with: "", options: .regularExpression)
                tasks.append(ChecklistTaskItem(rawLineIndex: index, isDone: false, text: cleanText))
            }
            prelude.removeAll()
        }

        return (prelude, tasks)
    }

    private func toggleChecklistTask(_ task: ChecklistTaskItem) {
        var lines = (item.textContent ?? "").components(separatedBy: .newlines)
        if task.rawLineIndex < lines.count {
            let line = lines[task.rawLineIndex]
            let checkboxRegex = try? NSRegularExpression(pattern: #"^([ \t]*[-*•+]?\s*\[)([ xX])(\]\s*.*)$"#)
            let fullRange = NSRange(location: 0, length: (line as NSString).length)
            if let match = checkboxRegex?.firstMatch(in: line, range: fullRange), match.numberOfRanges >= 4 {
                let prefix = (line as NSString).substring(with: match.range(at: 1))
                let suffix = (line as NSString).substring(with: match.range(at: 3))
                let newMark = task.isDone ? " " : "x"
                lines[task.rawLineIndex] = "\(prefix)\(newMark)\(suffix)"
            } else {
                let newMark = task.isDone ? "[ ]" : "[x]"
                lines[task.rawLineIndex] = "- \(newMark) \(task.text)"
            }
        }
        item.textContent = lines.joined(separator: "\n")
        LBHaptic.medium()
        persistEdit()
    }

    private func deleteChecklistTask(_ task: ChecklistTaskItem) {
        var lines = (item.textContent ?? "").components(separatedBy: .newlines)
        if task.rawLineIndex < lines.count {
            lines.remove(at: task.rawLineIndex)
            item.textContent = lines.joined(separator: "\n")
            LBHaptic.light()
            persistEdit()
        }
    }

    private func addChecklistTask() {
        let trimmed = newChecklistTaskText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let current = (item.textContent ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let newLine = "- [ ] \(trimmed)"
        if current.isEmpty {
            item.textContent = newLine
        } else {
            item.textContent = current + "\n" + newLine
        }
        newChecklistTaskText = ""
        LBHaptic.success()
        persistEdit()
    }

    private func taskChecklistCard(content: String) -> some View {
        let (prelude, tasks) = parseChecklistItems(from: content)
        let completedCount = tasks.filter(\.isDone).count
        let totalCount = tasks.count
        let progress = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0.0

        return VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "checklist")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: "0284C7"))
                    Text("TASKS & TO-DO")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                        .tracking(0.6)
                }

                Spacer()

                if totalCount > 0 {
                    HStack(spacing: 5) {
                        Text("\(completedCount)/\(totalCount)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(completedCount == totalCount ? Color(hex: "16A34A") : Color(hex: "0284C7"))

                        if completedCount == totalCount && totalCount > 0 {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(hex: "16A34A"))
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        (completedCount == totalCount ? Color(hex: "DCFCE7") : Color(hex: "E0F2FE")),
                        in: Capsule()
                    )
                }
            }

            // Progress bar if more than 1 task
            if totalCount > 1 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.black.opacity(0.06))
                            .frame(height: 5)

                        Capsule()
                            .fill(completedCount == totalCount ? Color(hex: "16A34A") : Color(hex: "0284C7"))
                            .frame(width: max(geo.size.width * CGFloat(progress), 0), height: 5)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: progress)
                    }
                }
                .frame(height: 5)
            }

            // Prelude lines (e.g., intro notes or list title before tasks)
            if !prelude.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(prelude.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "45443F"))
                    }
                }
                .padding(.bottom, 2)
            }

            // Tasks List
            if !tasks.isEmpty {
                VStack(spacing: 8) {
                    ForEach(tasks) { task in
                        HStack(alignment: .center, spacing: 10) {
                            Button {
                                toggleChecklistTask(task)
                            } label: {
                                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(task.isDone ? Color(hex: "16A34A") : Color.black.opacity(0.3))
                                    .frame(width: 28, height: 28)
                            }
                            .buttonStyle(.plain)

                            Text(task.text)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(task.isDone ? Color.secondary : AppTheme.textPrimary)
                                .strikethrough(task.isDone, color: Color.secondary.opacity(0.7))
                                .lineLimit(nil)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    toggleChecklistTask(task)
                                }

                            Button {
                                deleteChecklistTask(task)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Color.black.opacity(0.25))
                                    .frame(width: 24, height: 24)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(
                            task.isDone ? Color.black.opacity(0.02) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                        )
                    }
                }
            } else {
                Text("No tasks added yet.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            }

            // Add new task row
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "0284C7"))

                TextField("Add a new task or item...", text: $newChecklistTaskText)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textPrimary)
                    .submitLabel(.done)
                    .onSubmit {
                        addChecklistTask()
                    }

                if !newChecklistTaskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button {
                        addChecklistTask()
                    } label: {
                        Text("Add")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(hex: "0284C7"), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(hex: "F8FAFC"), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color(hex: "E2E8F0"), lineWidth: 1)
            )
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, y: 2)
    }

    // MARK: - 7. Notes & Follow-ups Card (Unobtrusive & Cleanly Integrated)
    private var notesAndFollowUpsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.secondary)
                Text("NOTES & FOLLOW-UPS (\(threadData.entries.count))")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.secondary)
                    .tracking(0.6)
            }

            // Existing entries list
            if !threadData.entries.isEmpty {
                VStack(spacing: 8) {
                    ForEach(threadData.entries) { entry in
                        followUpEntryCard(entry: entry)
                    }
                }
            } else {
                Text("No notes or follow-ups yet. Use the prompt below to add thoughts anytime.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 4, y: 1)
    }

    // MARK: - Bottom Input Bar
    private var bottomChatInputBar: some View {
        VStack(spacing: 0) {
            // Quoted reply banner if replying to a specific snippet
            if let snippet = quotedSnippet {
                HStack(spacing: 8) {
                    Image(systemName: "arrowshape.turn.up.left.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color.secondary)

                    Text("Replying to: \"\(snippet)\"")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    Button {
                        quotedSnippet = nil
                        LBHaptic.light()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color(hex: "F7F5EE"))
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            // Input Pill
            HStack(spacing: 10) {
                TextField("Add a note or thought...", text: $noteDraftText, axis: .vertical)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1...4)
                    .focused($isNoteFocused)
                    .submitLabel(.send)
                    .padding(.leading, 6)
                    .onSubmit {
                        sendNote()
                    }

                let canSend = !noteDraftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                Button {
                    sendNote()
                } label: {
                    ZStack {
                        Circle()
                            .fill(canSend ? Color(hex: "171711") : Color.black.opacity(0.12))
                            .frame(width: 32, height: 32)
                        Image(systemName: "arrow.up")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(canSend ? Color(hex: "E6EDB0") : Color.white)
                    }
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 8, y: 3)
            .padding(.horizontal, 14)
            .padding(.top, 6)
            .padding(.bottom, 8)
        }
        .background(
            AppTheme.canvasBackground
                .shadow(color: Color.black.opacity(0.03), radius: 4, y: -2)
        )
    }

    // MARK: - Follow-up Entry Card
    private func followUpEntryCard(entry: ItemThreadEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "171711"))
                        .frame(width: 22, height: 22)
                    Text((entry.authorName ?? "Me").prefix(1).uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "E6EDB0"))
                }

                Text(entry.authorName ?? "Me")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)

                Text(entry.formattedRelativeTime)
                    .font(.system(size: 10))
                    .foregroundColor(Color.secondary)

                Spacer()

                Button {
                    quotedSnippet = entry.content
                    isNoteFocused = true
                    LBHaptic.light()
                } label: {
                    Image(systemName: "arrowshape.turn.up.left")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color.secondary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)

                Button {
                    deleteFollowUp(id: entry.id)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color.secondary.opacity(0.7))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }

            if let snippet = entry.attachedSnippet, !snippet.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Rectangle()
                        .fill(Color(hex: "171711"))
                        .frame(width: 2)
                    Text("\"\(snippet)\"")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color.secondary)
                        .italic()
                        .lineLimit(2)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "F7F5EE"), in: RoundedRectangle(cornerRadius: 6))
            }

            Text(entry.content)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(AppTheme.textPrimary)
                .lineSpacing(2)
                .textSelection(.enabled)
        }
        .padding(12)
        .background(Color(hex: "FAFAF8"))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Collection Picker Sheet
    private var collectionPickerSheet: some View {
        NavigationStack {
            List {
                Section("Current Collection") {
                    if let current = item.collectionName, !current.isEmpty {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(Color(hex: "0369A1"))
                            Text(current)
                                .font(.system(size: 15, weight: .semibold))
                            Spacer()
                            Button("Remove") {
                                item.collectionName = nil
                                item.collectionId = nil
                                item.category = ""
                                persistEdit()
                                showingCollectionSheet = false
                                LBHaptic.light()
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.red)
                        }
                    } else {
                        Text("No collection assigned")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }

                Section("Available Collections") {
                    ForEach(availableCollections) { coll in
                        Button {
                            item.collectionName = coll.name
                            item.collectionId = coll.id
                            item.category = coll.name
                            persistEdit()
                            showingCollectionSheet = false
                            LBHaptic.medium()
                        } label: {
                            HStack {
                                Image(systemName: coll.iconName)
                                    .foregroundColor(Color(hex: coll.colorHex))
                                Text(coll.name)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(AppTheme.textPrimary)
                                Spacer()
                                if item.collectionName == coll.name {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(Color(hex: "0369A1"))
                                }
                            }
                        }
                    }
                }

                Section("Create New Collection") {
                    HStack {
                        TextField("New collection name", text: $newCollectionName)
                            .font(.system(size: 14))
                        Button("Add") {
                            let trimmed = newCollectionName.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty {
                                let coll = coordinator.ensureCollectionExists(named: trimmed, context: modelContext)
                                item.collectionName = coll?.name ?? trimmed
                                item.collectionId = coll?.id ?? item.collectionId
                                item.category = trimmed
                                persistEdit()
                                newCollectionName = ""
                                showingCollectionSheet = false
                                LBHaptic.medium()
                            }
                        }
                        .disabled(newCollectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .font(.system(size: 13, weight: .bold))
                    }
                }
            }
            .navigationTitle("Collections")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showingCollectionSheet = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Tag Chip View
    private func tagChip(_ tag: String) -> some View {
        Button {
            showingTagsSheet = true
            LBHaptic.light()
        } label: {
            HStack(spacing: 2) {
                Text("#")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.secondary.opacity(0.8))
                Text(tag)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
            }
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, 8)
            .padding(.vertical, 4.5)
            .background(Color.black.opacity(0.04), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.06), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tags Popup Sheet
    private var tagsPopupSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(item.tags.count) \(item.tags.count == 1 ? "Tag" : "Tags")")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                            Text("Tags associated with this item. Tap any tag to copy.")
                                .font(.system(size: 13))
                                .foregroundColor(Color.secondary)
                        }
                        Spacer()
                    }

                    // Add new tag field
                    HStack(spacing: 8) {
                        Image(systemName: "number")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.secondary)
                        TextField("Add a tag...", text: $newTagInput)
                            .font(.system(size: 14))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .onSubmit {
                                addTag()
                            }

                        if !newTagInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Button("Add") {
                                addTag()
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(hex: "171711"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(hex: "E6EDB0"), in: Capsule())
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.04), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                    // All Tags in Flow Layout
                    if item.tags.isEmpty {
                        Text("No tags yet.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 12)
                    } else {
                        LBFlowLayout(spacing: 8, lineSpacing: 8) {
                            ForEach(item.tags, id: \.self) { tag in
                                HStack(spacing: 6) {
                                    Button {
                                        UIPasteboard.general.string = "#\(tag)"
                                        LBHaptic.light()
                                    } label: {
                                        HStack(spacing: 3) {
                                            Text("#")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(Color.secondary)
                                            Text(tag)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(AppTheme.textPrimary)
                                        }
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        removeTag(tag)
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(Color.secondary.opacity(0.7))
                                            .frame(width: 14, height: 14)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .strokeBorder(Color.black.opacity(0.08), lineWidth: 0.5)
                                )
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(AppTheme.canvasBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showingTagsSheet = false
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                }
            }
        }
        .presentationDetents([.fraction(0.5), .large])
        .presentationDragIndicator(.visible)
    }

    private func addTag() {
        let trimmed = newTagInput.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        guard !trimmed.isEmpty else { return }
        if !item.tags.contains(trimmed) {
            item.tags.append(trimmed)
            persistEdit()
            LBHaptic.medium()
        }
        newTagInput = ""
    }

    private func removeTag(_ tag: String) {
        item.tags.removeAll { $0 == tag }
        persistEdit()
        LBHaptic.light()
    }

    // MARK: - Schedule Picker Sheet
    private var schedulePickerSheet: some View {
        SnoozeDatePickerSheet(
            itemTitle: item.title,
            initialDate: item.returnAt,
            onSchedule: { newDate in
                coordinator.scheduleItem(item: item, date: newDate, context: modelContext)
            },
            onUnsnooze: {
                item.status = ItemStatus.inbox.rawValue
                item.returnAt = nil
                persistEdit()
                Task { await coordinator.syncPendingItems(context: modelContext) }
            }
        )
    }

    // MARK: - Actions & Persistence
    private func sendNote() {
        let text = noteDraftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let snippet = quotedSnippet
        threadData = ItemThreadParser.addEntry(
            to: threadData,
            authorName: "Me",
            content: text,
            attachedSnippet: snippet
        )

        noteDraftText = ""
        quotedSnippet = nil
        isNoteFocused = false
        persistThread()
        LBHaptic.medium()
    }

    private func deleteFollowUp(id: String) {
        threadData.entries.removeAll { $0.id == id }
        persistThread()
        LBHaptic.light()
    }

    private func persistThread() {
        let serialized = ItemThreadParser.serialize(threadData)
        item.noteContent = serialized
        persistEdit()
    }

    private func persistEdit() {
        item.updatedAt = Date()
        item.isSyncPending = true
        do {
            try modelContext.save()
            saveError = nil
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func fileIcon(for filename: String) -> Image {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf": return Image(systemName: "doc.text.fill")
        case "jpg", "jpeg", "png", "heic", "webp", "gif": return Image(systemName: "photo.fill")
        case "mp3", "m4a", "wav", "aac": return Image(systemName: "music.note")
        case "mp4", "mov", "m4v": return Image(systemName: "film.fill")
        case "csv", "xlsx", "xls": return Image(systemName: "tablecells.fill")
        case "md", "txt", "rtf": return Image(systemName: "doc.plaintext.fill")
        case "json", "js", "ts", "swift", "py", "html": return Image(systemName: "chevron.left.forwardslash.chevron.right")
        default: return Image(systemName: "doc.fill")
        }
    }
}

// MARK: - Adaptive Flow Layout for Tags and Chips
struct LBFlowLayout: Layout {
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        guard maxWidth > 0, !subviews.isEmpty else { return .zero }

        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + lineSpacing
                lineHeight = 0
            }
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
        }

        let computedWidth = (maxWidth == .infinity) ? totalWidth : min(maxWidth, totalWidth)
        return CGSize(width: computedWidth, height: currentY + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += lineHeight + lineSpacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(size))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
    }
}
