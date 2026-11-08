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
    @Environment(\.colorScheme) private var colorScheme
    @Bindable public var item: LBItem

    // Shared with the Inbox: white in Light Mode, graphite/grain in Dark Mode.
    private var primaryInk: Color { InboxAppearance.textPrimary(for: colorScheme) }
    private var secondaryInk: Color { InboxAppearance.textSecondary(for: colorScheme) }
    private var detailSurface: Color { InboxAppearance.surface(for: colorScheme) }
    private var detailBorder: Color { InboxAppearance.border(for: colorScheme) }
    private var insetSurface: Color {
        colorScheme == .dark ? Color(hex: "303438") : Color(hex: "F7F5EE")
    }
    private var subtleFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04)
    }
    private var mutedSymbol: Color {
        colorScheme == .dark ? Color.white.opacity(0.44) : Color.black.opacity(0.3)
    }
    private var highlightSurface: Color {
        colorScheme == .dark ? Color(hex: "413525") : Color(hex: "FEF3C7").opacity(0.7)
    }
    private var highlightInk: Color {
        colorScheme == .dark ? Color(hex: "FFE0A2") : Color(hex: "92400E")
    }
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
    @State private var didCopySource = false

    public var isModal: Bool
    public var usesNativeNavigation: Bool

    public init(item: LBItem, isModal: Bool = false, usesNativeNavigation: Bool = false) {
        self.item = item
        self.isModal = isModal
        self.usesNativeNavigation = usesNativeNavigation
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

    public var body: some View {
        ZStack {
            // The same adaptive white / graphite grain as the Inbox.
            InboxGrainBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Pushed details use the native navigation bar and edge-swipe back.
                // Modal details retain their custom controls.
                if !usesNativeNavigation {
                    topNavigationBar
                }

                // Match web detail hierarchy: one item card instead of a stack
                // of independent metadata, media and content panels.
                ScrollView {
                    VStack(spacing: 18) {
                        if item.status == ItemStatus.inbox.rawValue {
                            inboxAgeBanner
                        } else if let date = item.returnAt {
                            returnScheduleBanner(ret: date)
                        }

                        webStyleItemCard

                        // Personal notes live beneath the item, as on the web.
                        notesAndFollowUpsCard
                    }
                    .frame(maxWidth: 660)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }

            }
        }
        .toolbar(usesNativeNavigation ? .visible : .hidden, for: .navigationBar)
        // Let the graphite page show through the pushed system navigation bar.
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if usesNativeNavigation {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    favoriteAction
                    statusActionButton
                    moreItemActionsMenu
                }
            }
        }
        .toolbar(usesNativeNavigation ? .hidden : .automatic, for: .tabBar)
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

    // MARK: - Web-aligned primary item card

    private var webStyleItemCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            itemHero

            VStack(alignment: .leading, spacing: 18) {
                sourceMetadataRow

                // Editable item title and description are the visual focal point.
                headerTitleAndDescription
                headerTagsPreview
                headerActionControlsRow

                let captured = item.textContent?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let formatted = item.formattedContent.trimmingCharacters(in: .whitespacesAndNewlines)

                if item.parsedContentType == .task {
                    if isTaskChecklistContent(captured) {
                        taskChecklistCard(content: captured)
                    } else {
                        simpleTaskCompletionCard(content: captured)
                    }
                } else if isTaskChecklistContent(captured) {
                    taskChecklistCard(content: captured)
                }

                if let highlight = item.textSelector, !highlight.isEmpty,
                   !captured.isEmpty {
                    capturedHighlightCard(text: captured)
                } else if item.parsedContentType != .task &&
                            (!captured.isEmpty || !formatted.isEmpty) {
                    RichCapturedContentViewer(
                        title: item.parsedContentType == .note ? "Note" : "Saved Content",
                        content: !captured.isEmpty ? captured : formatted,
                        formattedHTML: !formatted.isEmpty ? formatted : nil
                    )
                }

                if !item.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Divider().overlay(detailBorder)
                    aiSummaryCard
                }

                if let data = item.attachmentsData,
                   let files = try? JSONDecoder().decode([SharedAttachment].self, from: data),
                   !files.isEmpty {
                    Divider().overlay(detailBorder)
                    attachmentsCard(files: files)
                }

                itemSourceFooter
            }
            .padding(18)
        }
        .background(detailSurface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(detailBorder, lineWidth: 1)
        }
        .accessibilityIdentifier("Item Detail Main Card")
    }

    @ViewBuilder
    private var itemHero: some View {
        let mediaType = EmbeddedMediaType.detect(url: item.url)
        switch mediaType {
        case .youtube, .vimeo, .spotify, .appleMusic, .pdf:
            InlineVideoEmbedView(embedType: mediaType, previewImageUrl: item.previewImageUrl)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 180)
                .background(insetSurface)
        case .webArticle, .none:
            if let preview = item.previewImageUrl,
               !preview.isEmpty,
               let url = URL(string: preview) {
                Button {
                    if item.url != nil { showingSafariReader = true }
                } label: {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .empty:
                            ZStack {
                                insetSurface
                                ProgressView()
                            }
                        case .failure:
                            sourceImageFallback
                        @unknown default:
                            sourceImageFallback
                        }
                    }
                    .frame(height: 208)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .overlay(alignment: .bottomTrailing) {
                        if item.url != nil {
                            Label("Open source", systemImage: "arrow.up.right")
                                .font(.system(size: 11, weight: .semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .foregroundStyle(.white)
                                .background(Color.black.opacity(0.7), in: Capsule())
                                .padding(12)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(item.url == nil)
            } else if item.parsedContentType == .task || item.parsedContentType == .note {
                HStack(spacing: 12) {
                    Image(systemName: item.parsedContentType == .task ? "checklist" : "note.text")
                        .font(.system(size: 22, weight: .semibold))
                        .frame(width: 42, height: 42)
                        .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 13))
                        .foregroundStyle(Color(hex: "171711"))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.parsedContentType == .task ? "Task" : "Personal note")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(primaryInk)
                        Text("Saved to LaterBox")
                            .font(.system(size: 12))
                            .foregroundStyle(secondaryInk)
                    }
                    Spacer()
                }
                .padding(16)
                .background(colorScheme == .dark ? Color(hex: "2B3028") : Color(hex: "F5F8E9"))
            }
        }
    }

    private var sourceImageFallback: some View {
        ZStack {
            insetSurface
            Image(systemName: "link")
                .font(.system(size: 29))
                .foregroundStyle(secondaryInk)
        }
    }

    private var sourceMetadataRow: some View {
        HStack(spacing: 8) {
            Image(systemName: item.url == nil ? "note.text" : "link")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(secondaryInk)

            Text(domainOrSender)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(primaryInk)
                .lineLimit(1)

            Text("·")
                .foregroundStyle(secondaryInk)

            Text(item.createdAt, style: .relative)
                .font(.system(size: 11))
                .foregroundStyle(secondaryInk)
                .lineLimit(1)

            Spacer(minLength: 0)

            Text(itemStatusLabel)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(itemStatusInk)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(itemStatusFill, in: Capsule())
        }
    }

    private var itemStatusLabel: String {
        switch item.parsedStatus {
        case .inbox: "Inbox"
        case .deferred: "Scheduled"
        case .saved: "Kept"
        case .archived: item.parsedContentType == .task ? "Completed" : "Archived"
        default: "Saved"
        }
    }

    private var itemStatusInk: Color {
        if item.parsedStatus == .saved { return Color(hex: "171711") }
        if colorScheme == .dark { return Color(hex: "BBD5F0") }
        return Color(hex: "0369A1")
    }

    private var itemStatusFill: Color {
        if item.parsedStatus == .saved { return AppTheme.accent }
        return colorScheme == .dark ? Color(hex: "27394A") : Color(hex: "E0F2FE")
    }

    @ViewBuilder
    private var itemSourceFooter: some View {
        if let urlText = item.url, let url = URL(string: urlText), url.scheme == "https" || url.scheme == "http" {
            Divider().overlay(detailBorder)
            HStack(spacing: 10) {
                Label(item.parsedContentType.rawValue.capitalized, systemImage: "bookmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(secondaryInk)
                Spacer()
                Button {
                    showingSafariReader = true
                    LBHaptic.light()
                } label: {
                    Label("Open original", systemImage: "arrow.up.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(colorScheme == .dark ? Color(hex: "171711") : Color.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(colorScheme == .dark ? AppTheme.accent : Color(hex: "171711"), in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("Open Original Item")
            }
        }
    }

    // MARK: - Navigation controls

    // The native Back button owns the swipe-back transition on pushed details.
    // Modal details use the same compact actions alongside a Done control.
    private var topNavigationBar: some View {
        HStack(spacing: 10) {
            Button {
                dismiss()
                LBHaptic.light()
            } label: {
                Label(isModal ? "Done" : "Back", systemImage: isModal ? "xmark" : "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(primaryInk)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)
            favoriteAction
            statusActionButton
            moreItemActionsMenu
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(Color.clear)
    }

    private var favoriteAction: some View {
        Button {
            coordinator.toggleFavorite(item: item, context: modelContext)
            LBHaptic.medium()
        } label: {
            Image(systemName: item.favorite ? "star.fill" : "star")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(item.favorite ? Color(hex: "F59E0B") : primaryInk)
                .frame(width: 34, height: 34)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.favorite ? "Unstar item" : "Star item")
    }

    private var moreItemActionsMenu: some View {
        Menu {
            Button("Manage Collections", systemImage: "folder.badge.plus") {
                showingCollectionSheet = true
            }
            Button("Schedule Return", systemImage: "clock") {
                showingSchedulePicker = true
            }
            Button("Edit Tags", systemImage: "tag") {
                showingTagsSheet = true
            }

            Divider()

            Button(didCopySource ? "Copied" : (item.url == nil ? "Copy Text" : "Copy Link"),
                   systemImage: didCopySource ? "checkmark" : "doc.on.doc") {
                let copyValue = item.url ?? item.textContent ?? item.title
                UIPasteboard.general.string = copyValue
                didCopySource = true
                LBHaptic.success()
            }

            if let rawURL = item.url,
               let url = URL(string: rawURL),
               url.scheme == "https" || url.scheme == "http" {
                Button("Open Original", systemImage: "arrow.up.right") {
                    showingSafariReader = true
                }
                ShareLink(item: url) {
                    Label("Share Link", systemImage: "square.and.arrow.up")
                }
            }

            Divider()
            Button("Delete Item", systemImage: "trash", role: .destructive) {
                showingDeleteConfirm = true
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(primaryInk)
                .frame(width: 34, height: 34)
        }
        .accessibilityLabel("More item actions")
        .accessibilityIdentifier("Item Detail Actions")
    }

    // MARK: - Status Action Button (Keep / Archive / Move to Inbox)
    private func performStatusAction() {
        if item.status == ItemStatus.inbox.rawValue || item.status == ItemStatus.deferred.rawValue {
            coordinator.markDone(item: item, context: modelContext)
        } else if item.status == ItemStatus.saved.rawValue {
            item.status = ItemStatus.archived.rawValue
            persistEdit()
            Task { await coordinator.syncPendingItems(context: modelContext) }
            LBHaptic.medium()
        } else {
            item.status = ItemStatus.inbox.rawValue
            item.inboxEnteredAt = Date()
            persistEdit()
            Task { await coordinator.syncPendingItems(context: modelContext) }
            LBHaptic.light()
        }
    }

    private var statusActionButton: some View {
        Button {
            performStatusAction()
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
                    : detailSurface,
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .foregroundColor(colorScheme == .dark && item.status != ItemStatus.inbox.rawValue && item.status != ItemStatus.deferred.rawValue ? primaryInk : Color(hex: "171711"))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(detailBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 2. Return Schedule Banner
    private var inboxAgeBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "tray.full.fill")
                .font(.system(size: 16))
                 .foregroundStyle(Color(hex: "171711"))
                .frame(width: 30, height: 30)
                .background(AppTheme.accent, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("In Inbox")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(primaryInk)
                HStack(spacing: 3) {
                    Text("Entered Inbox")
                    Text(item.inboxEnteredAt ?? item.createdAt, style: .relative)
                }
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Reschedule") {
                scheduledDate = item.returnAt ?? (SnoozePreset.oneDay.calculateDate() ?? Date().addingTimeInterval(86400))
                showingSchedulePicker = true
                LBHaptic.light()
            }
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(primaryInk)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(subtleFill, in: Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(detailSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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
                    .foregroundColor(primaryInk)
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
            .foregroundColor(primaryInk)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(subtleFill, in: Capsule())

            Button {
                item.returnAt = nil
                item.status = ItemStatus.inbox.rawValue
                item.inboxEnteredAt = Date()
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
        .background(detailSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(detailBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 4, y: 1)
    }

    // MARK: - Metadata and editable title

    private var headerTitleAndDescription: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Title", text: $editedTitle, axis: .vertical)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(primaryInk)
                .lineLimit(1...5)
                .onChange(of: editedTitle) { _, newVal in
                    item.title = newVal
                    persistEdit()
                }

            if let desc = item.metadataDescription, !desc.isEmpty, !LinkMetadataLoader.isGenericDescription(desc) {
                Text(desc)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(secondaryInk)
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
                        .foregroundColor(primaryInk)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4.5)
                        .background(subtleFill, in: Capsule())
                        .overlay(Capsule().strokeBorder(detailBorder, lineWidth: 1))
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
                         .foregroundColor(colorScheme == .dark ? Color(hex: "7DD3FC") : Color(hex: "0369A1"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .frame(minHeight: 32)
                         .background(colorScheme == .dark ? Color(hex: "173344") : Color(hex: "E0F2FE"), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                 .strokeBorder(colorScheme == .dark ? Color(hex: "28536B") : Color(hex: "BAE6FD"), lineWidth: 1)
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
                        .foregroundColor(primaryInk)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .frame(minHeight: 32)
                        .background(insetSurface, in: Capsule())
                        .overlay(Capsule().strokeBorder(detailBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .fixedSize()
                }
            }
            .padding(.top, 2)
        }
    }

    // Plain tasks use the web's single completion control; only structured
    // checklist tasks render the full editable checklist.
    private func simpleTaskCompletionCard(content: String) -> some View {
        let isCompleted = item.parsedStatus == .archived
        return VStack(alignment: .leading, spacing: 12) {
            Button {
                if isCompleted {
                    item.status = ItemStatus.inbox.rawValue
                    item.inboxEnteredAt = Date()
                } else {
                    item.status = ItemStatus.archived.rawValue
                    item.returnAt = nil
                }
                persistEdit()
                Task { await coordinator.syncPendingItems(context: modelContext) }
                LBHaptic.medium()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: isCompleted ? "checkmark.square.fill" : "square")
                        .font(.system(size: 25, weight: .medium))
                        .foregroundStyle(isCompleted ? Color(hex: "7D9B58") : secondaryInk)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isCompleted ? "Task completed" : "Mark as completed")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(primaryInk)
                        Text(isCompleted ? "Tap to reopen this task" : "Complete this when you are finished")
                            .font(.system(size: 12))
                            .foregroundStyle(secondaryInk)
                    }
                    Spacer(minLength: 0)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(colorScheme == .dark ? Color(hex: "2B3028") : Color(hex: "F8FBF0"),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(detailBorder, lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isCompleted ? "Reopen task" : "Mark task as completed")

            if !content.isEmpty && content != item.title {
                Text(content)
                    .font(.system(size: 14))
                    .foregroundStyle(primaryInk)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
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
             .foregroundColor(colorScheme == .dark ? Color(hex: "FFC374") : Color(hex: "B45309"))

            Text("“\(text)”")
                .font(.system(size: 14, weight: .medium))
                 .foregroundColor(highlightInk)
                .italic()
                .lineSpacing(3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(highlightSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                 .strokeBorder(colorScheme == .dark ? Color(hex: "745632") : Color(hex: "FDE68A"), lineWidth: 1)
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
                         .foregroundColor(colorScheme == .dark ? Color(hex: "86EFAC") : Color(hex: "166534"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                         .background(colorScheme == .dark ? Color(hex: "173B2D") : Color(hex: "DCFCE7"), in: Capsule())
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
                             .foregroundColor(primaryInk)
                            .frame(width: 36, height: 36)
                            .background(insetSurface, in: RoundedRectangle(cornerRadius: 10))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(file.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(primaryInk)
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
                    .background(detailSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(detailBorder, lineWidth: 1)
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
                    .foregroundColor(colorScheme == .dark ? Color(hex: "7DD3FC") : Color(hex: "1A73E8"))
                Text("AI Summary")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(primaryInk)
            }

            Text(item.summary)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(secondaryInk)
                .lineSpacing(3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)

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
                         .foregroundColor(colorScheme == .dark ? Color(hex: "7DD3FC") : Color(hex: "0284C7"))
                    Text("TASKS & TO-DO")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(primaryInk)
                        .tracking(0.6)
                }

                Spacer()

                if totalCount > 0 {
                    HStack(spacing: 5) {
                        Text("\(completedCount)/\(totalCount)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(completedCount == totalCount
                                ? (colorScheme == .dark ? Color(hex: "4ADE80") : Color(hex: "16A34A"))
                                : (colorScheme == .dark ? Color(hex: "7DD3FC") : Color(hex: "0284C7")))

                        if completedCount == totalCount && totalCount > 0 {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(hex: "16A34A"))
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        colorScheme == .dark
                            ? (completedCount == totalCount ? Color(hex: "173B2D") : Color(hex: "173344"))
                            : (completedCount == totalCount ? Color(hex: "DCFCE7") : Color(hex: "E0F2FE")),
                        in: Capsule()
                    )
                }
            }

            // Progress bar if more than 1 task
            if totalCount > 1 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(subtleFill)
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
                            .foregroundColor(secondaryInk)
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
                                     .foregroundColor(task.isDone ? Color(hex: "4ADE80") : mutedSymbol)
                                    .frame(width: 28, height: 28)
                            }
                            .buttonStyle(.plain)

                            Text(task.text)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(task.isDone ? Color.secondary : primaryInk)
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
                                     .foregroundColor(mutedSymbol)
                                    .frame(width: 24, height: 24)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(
                            task.isDone ? subtleFill : Color.clear,
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
                    .foregroundColor(colorScheme == .dark ? Color(hex: "7DD3FC") : Color(hex: "0284C7"))

                TextField("Add a new task or item...", text: $newChecklistTaskText)
                    .font(.system(size: 13))
                    .foregroundColor(primaryInk)
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
             .background(insetSurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                     .strokeBorder(detailBorder, lineWidth: 1)
            )
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(detailSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(detailBorder, lineWidth: 1)
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
            inlineNotesComposer
                .padding(.top, 4)
        }
        .padding(14)
        .background(detailSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(detailBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 4, y: 1)
    }

    // Web detail pages keep personal notes beneath the primary item card.
    // This editor sits in the notes section instead of occupying screen space
    // as a permanent bottom dock during article reading.
    private var inlineNotesComposer: some View {
        VStack(spacing: 8) {
            if let snippet = quotedSnippet {
                HStack(spacing: 8) {
                    Image(systemName: "quote.bubble")
                    Text("Replying to: \"\(snippet)\"")
                        .lineLimit(1)
                    Spacer()
                    Button {
                        quotedSnippet = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(secondaryInk)
                .padding(.horizontal, 9)
            }

            HStack(alignment: .bottom, spacing: 10) {
                TextField("Add a personal note...", text: $noteDraftText, axis: .vertical)
                    .font(.system(size: 14))
                    .foregroundStyle(primaryInk)
                    .lineLimit(1...5)
                    .focused($isNoteFocused)
                    .submitLabel(.send)
                    .onSubmit { sendNote() }
                    .padding(.vertical, 4)

                let canSend = !noteDraftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                Button {
                    sendNote()
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(canSend ? Color(hex: "171711") : secondaryInk)
                        .frame(width: 32, height: 32)
                        .background(canSend ? AppTheme.accent : subtleFill, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
                .accessibilityLabel("Add note")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(insetSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(detailBorder, lineWidth: 1)
            }
        }
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
                    .foregroundColor(primaryInk)

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
                         .fill(colorScheme == .dark ? AppTheme.accent : Color(hex: "171711"))
                        .frame(width: 2)
                    Text("\"\(snippet)\"")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color.secondary)
                        .italic()
                        .lineLimit(2)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(insetSurface, in: RoundedRectangle(cornerRadius: 6))
            }

            Text(entry.content)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(primaryInk)
                .lineSpacing(2)
                .textSelection(.enabled)
        }
        .padding(12)
        .background(insetSurface)
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
                                 .foregroundColor(colorScheme == .dark ? Color(hex: "7DD3FC") : Color(hex: "0369A1"))
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
                .listRowBackground(detailSurface)

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
                                    .foregroundColor(primaryInk)
                                Spacer()
                                if item.collectionName == coll.name {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .bold))
                                         .foregroundColor(colorScheme == .dark ? Color(hex: "7DD3FC") : Color(hex: "0369A1"))
                                }
                            }
                        }
                    }
                }
                .listRowBackground(detailSurface)

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
                .listRowBackground(detailSurface)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle("Collections")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showingCollectionSheet = false }
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .presentationBackground { InboxGrainBackground() }
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
                    .foregroundColor(primaryInk)
            }
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, 8)
            .padding(.vertical, 4.5)
            .background(subtleFill, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(detailBorder, lineWidth: 0.5)
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
                                .foregroundColor(primaryInk)
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
                    .background(subtleFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

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
                                                .foregroundColor(primaryInk)
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
                                .background(subtleFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .strokeBorder(detailBorder, lineWidth: 0.5)
                                )
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.clear)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showingTagsSheet = false
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(primaryInk)
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .presentationBackground { InboxGrainBackground() }
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
                item.inboxEnteredAt = Date()
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
