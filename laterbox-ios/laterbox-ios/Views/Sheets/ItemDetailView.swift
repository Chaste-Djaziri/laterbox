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

    // Follow-ups & Notes chat state
    @State private var threadData: ItemThreadData = ItemThreadData()
    @State private var followUpText: String = ""
    @State private var quotedSnippet: String? = nil
    @FocusState private var isInputFocused: Bool

    // Item metadata & sheets
    @State private var editedTitle: String = ""
    @State private var tagsText: String = ""
    @State private var showingDeleteConfirm: Bool = false
    @State private var showingCategoryEdit: Bool = false
    @State private var newCategoryText: String = ""
    @State private var saveError: String?
    @State private var previewDocumentURL: URL?
    @State private var showingSafariReader: Bool = false
    @State private var showingSchedulePicker: Bool = false
    @State private var scheduledDate: Date = Date().addingTimeInterval(86400)

    public var isModal: Bool

    public init(item: LBItem, isModal: Bool = false) {
        self.item = item
        self.isModal = isModal
        self._editedTitle = State(initialValue: item.title)
        self._tagsText = State(initialValue: item.tags.joined(separator: ", "))
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
                // 1. Top Navigation Bar (Full page, matching web top action row)
                topNavigationBar

                // 2. Scrollable Body Content & Follow-ups Stream
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            // Document & Files Preview Card
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
                            }

                            // Rich Visual Banner (OpenGraph Preview Image)
                            if mediaType == .none || mediaType == .webArticle(url: URL(string: item.url ?? "")!) {
                                RichMediaBanner(
                                    type: item.parsedContentType,
                                    url: item.url,
                                    title: item.title,
                                    previewImageUrl: item.previewImageUrl
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
                            }

                            // Main Saved Content Header Card
                            mainHeaderCard

                            // Quick Action Buttons Row (Reader, Safari, Share, Status)
                            quickActionsRow

                            // Return Schedule Info Card (if scheduled)
                            if let ret = item.returnAt {
                                returnScheduleCard(ret: ret)
                            }

                            // AI Summary Card (if present)
                            if !item.summary.isEmpty {
                                aiSummaryCard
                            }

                            // Captured Content / Full Article Text Viewer
                            let captured = item.textContent?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                            let formatted = item.formattedContent.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !captured.isEmpty || !formatted.isEmpty {
                                RichCapturedContentViewer(
                                    title: "Captured Content",
                                    content: !captured.isEmpty ? captured : formatted,
                                    formattedHTML: !formatted.isEmpty ? formatted : nil
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
                            }

                            // Follow-ups & Notes Chat Stream Header
                            followUpsStreamHeader

                            // Follow-ups & Notes Timeline Entries
                            if threadData.entries.isEmpty {
                                emptyFollowUpsCard
                            } else {
                                LazyVStack(spacing: 10) {
                                    ForEach(threadData.entries) { entry in
                                        followUpEntryCard(entry: entry)
                                    }
                                }
                            }

                            // Anchor for auto-scrolling to the bottom of the thread
                            Color.clear
                                .frame(height: 1)
                                .id("thread-bottom")

                            // Delete Item Button at the bottom
                            Button(role: .destructive, action: { showingDeleteConfirm = true }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Delete Item")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.red.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(Color.red.opacity(0.16), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 6)
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 12)
                        .padding(.bottom, 80) // Leave ample room for the bottom chat input bar
                    }
                    .onChange(of: threadData.entries.count) { _, _ in
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo("thread-bottom", anchor: .bottom)
                        }
                    }
                }

                // 3. Fixed Bottom Chat Prompt / Input Bar (Matching Web follow-ups bar)
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
        .alert("Edit Category", isPresented: $showingCategoryEdit) {
            TextField("Category or Collection", text: $newCategoryText)
            Button("Save") {
                let trimmed = newCategoryText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    let coll = coordinator.ensureCollectionExists(named: trimmed, context: modelContext)
                    item.category = trimmed
                    item.collectionName = coll?.name ?? trimmed
                    item.collectionId = coll?.id ?? item.collectionId
                } else {
                    item.category = ""
                    item.collectionName = nil
                    item.collectionId = nil
                }
                persistEdit()
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Are you sure you want to delete this item?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            Button("Delete Forever", role: .destructive) {
                coordinator.deleteItem(item: item, context: modelContext)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        .onDisappear {
            Task { await coordinator.syncPendingItems(context: modelContext) }
        }
        .task {
            // Re-parse thread from item.noteContent in case it was updated in background
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

    // MARK: - 1. Top Navigation Bar
    private var topNavigationBar: some View {
        HStack(spacing: 12) {
            // Back Button
            Button {
                dismiss()
                LBHaptic.light()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: isModal ? "xmark" : "chevron.left")
                        .font(.system(size: isModal ? 14 : 16, weight: .bold))
                    Text(isModal ? "Done" : "Back")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(AppTheme.textPrimary)
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
            }
            .buttonStyle(.plain)

            Spacer()

            // Center Domain / Sender badge
            HStack(spacing: 6) {
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
                    .lineLimit(1)
            }

            Spacer()

            // Right Quick Action Icons
            HStack(spacing: 6) {
                // Star Button
                Button {
                    coordinator.toggleFavorite(item: item, context: modelContext)
                    LBHaptic.medium()
                } label: {
                    Image(systemName: item.favorite ? "star.fill" : "star")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(item.favorite ? Color(hex: "F59E0B") : AppTheme.textPrimary)
                        .frame(width: 34, height: 34)
                        .background(Color.white, in: Circle())
                        .overlay(Circle().strokeBorder(Color.black.opacity(0.08), lineWidth: 1))
                }
                .buttonStyle(.plain)

                // Share Button
                if let urlStr = item.url, let url = URL(string: urlStr) {
                    ShareLink(item: url) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                            .frame(width: 34, height: 34)
                            .background(Color.white, in: Circle())
                            .overlay(Circle().strokeBorder(Color.black.opacity(0.08), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }

                // Overflow Options Menu
                Menu {
                    Button {
                        if item.status == ItemStatus.saved.rawValue {
                            coordinator.scheduleItem(item: item, date: Date(), context: modelContext)
                        } else {
                            coordinator.markDone(item: item, context: modelContext)
                        }
                    } label: {
                        Label(item.status == ItemStatus.saved.rawValue ? "Return Item" : "Mark as Done",
                              systemImage: item.status == ItemStatus.saved.rawValue ? "arrow.uturn.backward" : "checkmark")
                    }

                    Button {
                        scheduledDate = item.returnAt ?? Date().addingTimeInterval(86400)
                        showingSchedulePicker = true
                    } label: {
                        Label("Schedule Return...", systemImage: "calendar.badge.clock")
                    }

                    Button {
                        newCategoryText = item.category
                        showingCategoryEdit = true
                    } label: {
                        Label("Edit Category / Tags", systemImage: "folder")
                    }

                    if let urlStr = item.url, URL(string: urlStr) != nil {
                        Button {
                            showingSafariReader = true
                        } label: {
                            Label("Open Reader View", systemImage: "book.pages")
                        }
                    }

                    Divider()

                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        Label("Delete Item", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(width: 34, height: 34)
                        .background(Color.white, in: Circle())
                        .overlay(Circle().strokeBorder(Color.black.opacity(0.08), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(AppTheme.canvasBackground)
    }

    // MARK: - 2. Main Saved Content Header Card
    private var mainHeaderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top sender & metadata chips
            HStack(spacing: 8) {
                // Sender circle
                ZStack {
                    Circle()
                        .fill(Color(hex: "171711"))
                        .frame(width: 24, height: 24)
                    Text(senderInitial)
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(Color(hex: "E6EDB0"))
                }

                Text(domainOrSender)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)

                // Format pill
                Text(item.parsedContentType.rawValue.capitalized)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color(hex: "E6EDB0"), in: Capsule())
                    .foregroundColor(Color(hex: "171711"))

                Spacer()

                // Date
                Text(item.createdAt, format: .dateTime.month().day().year())
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.secondary)
            }

            // Title (Editable on tap)
            TextField("Title", text: $editedTitle, axis: .vertical)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(1...5)
                .onChange(of: editedTitle) { _, newVal in
                    item.title = newVal
                    persistEdit()
                }

            // Description / text preview snippet
            if let desc = item.metadataDescription, !desc.isEmpty, !LinkMetadataLoader.isGenericDescription(desc) {
                Text(desc)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(hex: "45443F"))
                    .lineLimit(4)
                    .lineSpacing(2)
            }

            // Category & Tags Chips
            HStack(spacing: 6) {
                if !item.category.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 10))
                        Text(item.category)
                            .font(.system(size: 11, weight: .bold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "E6EDB0").opacity(0.6), in: RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color(hex: "D0DB84"), lineWidth: 1)
                    )
                    .foregroundColor(Color(hex: "171711"))
                }

                ForEach(item.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
                        .foregroundColor(Color.secondary)
                }

                Spacer()

                // Reply to root content shortcut
                Button {
                    quotedSnippet = item.title
                    isInputFocused = true
                    LBHaptic.light()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "arrowshape.turn.up.left.fill")
                            .font(.system(size: 10))
                        Text("Reply")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(Color.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.04), in: Capsule())
                }
                .buttonStyle(.plain)
            }
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

    // MARK: - 3. Quick Actions Row (Reader, Safari, Share, Status)
    private var quickActionsRow: some View {
        HStack(spacing: 8) {
            // In-app Reader View
            if let urlStr = item.url, URL(string: urlStr) != nil {
                Button {
                    LBHaptic.light()
                    showingSafariReader = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "book.pages")
                            .font(.system(size: 13, weight: .bold))
                        Text("Reader")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.black.opacity(0.07), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                // Safari external link
                Link(destination: URL(string: urlStr)!) {
                    HStack(spacing: 5) {
                        Image(systemName: "safari")
                            .font(.system(size: 13, weight: .bold))
                        Text("Safari")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.black.opacity(0.07), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }

            // Return / Done Button
            Button {
                if item.status == ItemStatus.saved.rawValue {
                    coordinator.scheduleItem(item: item, date: Date(), context: modelContext)
                } else {
                    coordinator.markDone(item: item, context: modelContext)
                }
                LBHaptic.medium()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: item.status == ItemStatus.saved.rawValue ? "arrow.uturn.backward" : "checkmark")
                        .font(.system(size: 13, weight: .bold))
                    Text(item.status == ItemStatus.saved.rawValue ? "Return" : "Done")
                        .font(.system(size: 13, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(
                    item.status == ItemStatus.saved.rawValue
                        ? Color(hex: "E6EDB0")
                        : Color(hex: "171711")
                )
                .foregroundColor(item.status == ItemStatus.saved.rawValue ? Color(hex: "171711") : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 4. Return Schedule Card
    private func returnScheduleCard(ret: Date) -> some View {
        let isTodayOrOverdue = Calendar.current.isDateInToday(ret) || ret < Date()
        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isTodayOrOverdue ? Color(hex: "171711") : Color(hex: "E6EDB0"))
                    .frame(width: 36, height: 36)
                Image(systemName: isTodayOrOverdue ? "exclamationmark.clock.fill" : "calendar.badge.clock")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(isTodayOrOverdue ? Color(hex: "E6EDB0") : Color(hex: "171711"))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(isTodayOrOverdue ? "Due Today" : "Scheduled Return")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Text(ret, format: .dateTime.month().day().year())
                    .font(.system(size: 11))
                    .foregroundColor(Color.secondary)
            }

            Spacer()

            Button("Clear") {
                item.returnAt = nil
                item.status = ItemStatus.inbox.rawValue
                persistEdit()
                Task {
                    _ = try? await ReturnNotification.update(id: item.id, title: item.title, date: nil)
                }
                LBHaptic.light()
            }
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.red)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.red.opacity(0.08), in: Capsule())
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, y: 2)
    }

    // MARK: - 5. AI Summary Card
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

    // MARK: - 6. Document Attachments Card
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

    // MARK: - 7. Follow-ups & Notes Stream Header
    private var followUpsStreamHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 13))
                .foregroundColor(Color.secondary)
            Text("FOLLOW-UPS & NOTES (\(threadData.entries.count))")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color.secondary)
                .tracking(0.6)

            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(height: 1)
        }
        .padding(.top, 8)
        .padding(.bottom, 2)
    }

    // MARK: - 8. Empty Follow-ups State
    private var emptyFollowUpsCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 24))
                .foregroundColor(Color.secondary.opacity(0.7))
            Text("No follow-ups added yet")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
            Text("Use the prompt below to add notes, attach thoughts, or track progress.")
                .font(.system(size: 11))
                .foregroundColor(Color.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(Color.white.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.black.opacity(0.08), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        )
    }

    // MARK: - 9. Individual Follow-up Entry Card
    private func followUpEntryCard(entry: ItemThreadEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Author info & Actions
            HStack(spacing: 8) {
                // Author Avatar
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

                if entry.type == "note" {
                    Text("Note")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color(hex: "E6EDB0"), in: RoundedRectangle(cornerRadius: 4))
                        .foregroundColor(Color(hex: "171711"))
                }

                Text(entry.formattedRelativeTime)
                    .font(.system(size: 10))
                    .foregroundColor(Color.secondary)

                Spacer()

                // Reply to this entry button
                Button {
                    quotedSnippet = entry.content
                    isInputFocused = true
                    LBHaptic.light()
                } label: {
                    Image(systemName: "arrowshape.turn.up.left")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color.secondary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)

                // Delete entry button
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

            // Attached Quote Snippet (if replying)
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

            // Main Message Content
            Text(entry.content)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(AppTheme.textPrimary)
                .lineSpacing(2)
                .textSelection(.enabled)

            // Reactions Bar
            HStack(spacing: 6) {
                let reactions = ["👍", "❤️", "💡", "🔥"]
                ForEach(reactions, id: \.self) { emoji in
                    let count = entry.reactions?[emoji] ?? 0
                    let hasReacted = (entry.userReactions ?? []).contains(emoji)

                    Button {
                        toggleReaction(entryId: entry.id, emoji: emoji)
                    } label: {
                        HStack(spacing: 3) {
                            Text(emoji)
                                .font(.system(size: 11))
                            if count > 0 {
                                Text("\(count)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(hasReacted ? Color(hex: "171711") : Color.secondary)
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(hasReacted ? Color(hex: "E6EDB0") : Color.black.opacity(0.03), in: Capsule())
                        .overlay(
                            Capsule().strokeBorder(hasReacted ? Color(hex: "D0DB84") : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 2)
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, y: 2)
    }

    // MARK: - 10. Fixed Bottom Chat Input Bar (Matching Web style)
    private var bottomChatInputBar: some View {
        VStack(spacing: 0) {
            // Quoted banner above the bar if replying
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
                // Text Input
                TextField("Add follow-up, thought, or note...", text: $followUpText, axis: .vertical)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1...4)
                    .focused($isInputFocused)
                    .submitLabel(.send)
                    .padding(.leading, 6)
                    .onSubmit {
                        sendFollowUp()
                    }

                // Send Button
                let canSend = !followUpText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                Button {
                    sendFollowUp()
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

    // MARK: - Schedule Picker Sheet
    private var schedulePickerSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                DatePicker("Scheduled Return", selection: $scheduledDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .padding()

                HStack(spacing: 12) {
                    Button("Tomorrow") {
                        scheduledDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(hex: "E6EDB0"), in: Capsule())
                    .foregroundColor(Color(hex: "171711"))

                    Button("Next Week") {
                        scheduledDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white, in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.black.opacity(0.1), lineWidth: 1))
                    .foregroundColor(AppTheme.textPrimary)
                }

                Spacer()
            }
            .navigationTitle("Schedule Return")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingSchedulePicker = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Set") {
                        coordinator.scheduleItem(item: item, date: scheduledDate, context: modelContext)
                        showingSchedulePicker = false
                        LBHaptic.medium()
                    }
                    .font(.system(size: 14, weight: .bold))
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Actions & Persistence
    private func sendFollowUp() {
        let text = followUpText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let snippet = quotedSnippet
        threadData = ItemThreadParser.addEntry(
            to: threadData,
            authorName: "Me",
            content: text,
            attachedSnippet: snippet
        )

        followUpText = ""
        quotedSnippet = nil
        persistThread()
        LBHaptic.medium()
    }

    private func deleteFollowUp(id: String) {
        threadData.entries.removeAll { $0.id == id }
        persistThread()
        LBHaptic.light()
    }

    private func toggleReaction(entryId: String, emoji: String) {
        guard let idx = threadData.entries.firstIndex(where: { $0.id == entryId }) else { return }
        var entry = threadData.entries[idx]
        var reactions = entry.reactions ?? [:]
        var userReactions = entry.userReactions ?? []

        if userReactions.contains(emoji) {
            userReactions.removeAll { $0 == emoji }
            reactions[emoji] = max(0, (reactions[emoji] ?? 1) - 1)
            if reactions[emoji] == 0 { reactions.removeValue(forKey: emoji) }
        } else {
            userReactions.append(emoji)
            reactions[emoji] = (reactions[emoji] ?? 0) + 1
        }

        entry.reactions = reactions
        entry.userReactions = userReactions
        threadData.entries[idx] = entry
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
