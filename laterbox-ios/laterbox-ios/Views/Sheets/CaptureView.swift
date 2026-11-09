// laterbox-ios/laterbox-ios/Views/Sheets/CaptureView.swift
import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers

/// Capture and Quick Save are entry points into the same navigated Create Item page.
enum CaptureComposerMode: Equatable {
    case quick
    case guided

    var title: String { self == .quick ? "Quick Save" : "Create Item" }
}

struct CaptureComposerScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \LBCollection.name) private var collections: [LBCollection]

    let mode: CaptureComposerMode

    @State private var capture = SharedCapture()
    @State private var savedItem: LBItem?
    @State private var errorMessage: String?
    @State private var isAnalyzing = false
    @State private var showingItemDetails = false
    @State private var showingDiscard = false
    @State private var showingFilePicker = false
    @State private var showingPhotoPicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var tagInput = ""
    @State private var selectedReturn: ReturnChoice = .inbox
    @State private var chosenDate = Date().addingTimeInterval(86400)

    private enum ReturnChoice: String, CaseIterable, Identifiable {
        case inbox = "Inbox", soon = "10 min", tomorrow = "Tomorrow", date = "Pick date"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .inbox: return "tray"
            case .soon: return "timer"
            case .tomorrow: return "sunrise"
            case .date: return "calendar"
            }
        }
    }

    private var foreground: Color { InboxAppearance.textPrimary(for: colorScheme) }
    private var secondary: Color { InboxAppearance.textSecondary(for: colorScheme) }
    private var surface: Color { InboxAppearance.surface(for: colorScheme) }
    private var inset: Color { colorScheme == .dark ? Color(hex: "1B1D20") : .white }
    private var border: Color { InboxAppearance.border(for: colorScheme) }
    private var canSave: Bool {
        !capture.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !capture.attachments.isEmpty
    }
    private var hasDraft: Bool {
        canSave || !capture.title.isEmpty || !capture.category.isEmpty || !tagInput.isEmpty
    }


    var body: some View {
        ZStack {
            InboxGrainBackground().ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    if savedItem != nil {
                        successCard
                    } else {
                        contentCard
                        attachmentCard
                        organizationCard
                        returnCard
                        if let errorMessage {
                            Label(errorMessage, systemImage: "exclamationmark.triangle")
                                .font(.subheadline)
                                .foregroundStyle(.red)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .cardSurface(colorScheme)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showingItemDetails) {
            if let savedItem {
                ItemDetailView(item: savedItem, usesNativeNavigation: true)
            }
        }
        .confirmationDialog("Discard draft?", isPresented: $showingDiscard, titleVisibility: .visible) {
            Button("Discard Draft", role: .destructive) { dismiss() }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("Unsaved changes will be lost.")
        }
        .fileImporter(isPresented: $showingFilePicker, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
            switch result {
            case .success(let urls):
                for url in urls {
                    do {
                        let type = UTType(filenameExtension: url.pathExtension)?.identifier ?? UTType.item.identifier
                        capture.attachments.append(try SharedCaptureStore.copyFile(url, type: type))
                    } catch {
                        errorMessage = "Unable to attach \(url.lastPathComponent)."
                    }
                }
            case .failure:
                errorMessage = "Could not open the file picker."
            }
        }
        .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhoto, matching: .any(of: [.images, .videos]))
        .onChange(of: selectedPhoto) { _, photo in
            guard let photo else { return }
            Task {
                guard let data = try? await photo.loadTransferable(type: Data.self) else {
                    errorMessage = "Unable to open the selected photo or video."
                    return
                }
                let type = photo.supportedContentTypes.first ?? .jpeg
                let temporary = FileManager.default.temporaryDirectory
                    .appendingPathComponent("laterbox-\(UUID().uuidString).\(type.preferredFilenameExtension ?? "jpg")")
                do {
                    try data.write(to: temporary)
                    defer { try? FileManager.default.removeItem(at: temporary) }
                    capture.attachments.append(try SharedCaptureStore.copyFile(temporary, type: type.identifier))
                    errorMessage = nil
                } catch {
                    errorMessage = "Unable to attach the selected media."
                }
                selectedPhoto = nil
            }
        }
        .onAppear {
            SyncCoordinator.shared.isShowingCapture = true
            tagInput = capture.tags.joined(separator: ", ")
        }
        .onDisappear {
            SyncCoordinator.shared.isShowingCapture = false
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                if savedItem != nil || !hasDraft { dismiss() }
                else { showingDiscard = true }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(foreground)
                    .frame(width: 40, height: 40)
                    .background(surface, in: RoundedRectangle(cornerRadius: 13))
                    .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(border, lineWidth: 1))
            }
            .accessibilityLabel("Back")

            VStack(alignment: .leading, spacing: 3) {
                Text(savedItem == nil ? mode.title : "Item Saved")
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .foregroundStyle(foreground)
                Text(savedItem == nil ? "Keep what matters. Return when you're ready." : "Your item is safely in LaterBox.")
                    .font(.system(size: 12))
                    .foregroundStyle(secondary)
            }

            Spacer(minLength: 0)

            if savedItem == nil && hasDraft {
                Button("Clear") {
                    capture = SharedCapture()
                    tagInput = ""
                    selectedReturn = .inbox
                    errorMessage = nil
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private func sectionHeading(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .tracking(1)
                .foregroundStyle(foreground)
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundStyle(secondary)
        }
    }

    private var contentCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeading("CONTENT", subtitle: "Write a note, paste a link, or capture an idea.")
            VStack(alignment: .leading, spacing: 12) {
                Label("What are you saving?", systemImage: "square.and.pencil")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(foreground)
                ZStack(alignment: .topLeading) {
                    if capture.content.isEmpty {
                        Text("Type a note, drop a link, or write anything you want to remember…")
                            .font(.system(size: 15))
                            .foregroundStyle(secondary.opacity(0.8))
                            .padding(.horizontal, 13)
                            .padding(.top, 15)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $capture.content)
                        .scrollContentBackground(.hidden)
                        .font(.system(size: 15))
                        .foregroundStyle(foreground)
                        .tint(foreground)
                        .padding(7)
                        .frame(minHeight: 150)
                        .accessibilityIdentifier("capture.content")
                }
                .background(inset, in: RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(border, lineWidth: 1))
            }
            .padding(15)
            .cardSurface(colorScheme)
        }
    }

    private var attachmentCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeading("ATTACHMENTS", subtitle: "Add photos, videos, and documents.")
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    attachButton("Photos & Videos", icon: "photo.on.rectangle") { showingPhotoPicker = true }
                    attachButton("Files", icon: "doc.badge.plus") { showingFilePicker = true }
                }
                ForEach(capture.attachments) { attachment in
                    HStack(spacing: 10) {
                        Image(systemName: "paperclip").foregroundStyle(foreground)
                        Text(attachment.name).font(.subheadline).foregroundStyle(foreground).lineLimit(1)
                        Spacer(minLength: 3)
                        Button {
                            capture.attachments.removeAll { $0.id == attachment.id }
                        } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(secondary)
                        }
                        .accessibilityLabel("Remove \(attachment.name)")
                    }
                    .padding(12)
                    .background(inset, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(14)
            .cardSurface(colorScheme)
        }
    }

    private var organizationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionHeading("ORGANIZE", subtitle: "Optional details for finding it later.")
                Spacer()
                Button {
                    reviewCapture()
                } label: {
                    HStack(spacing: 5) {
                        if isAnalyzing { ProgressView().controlSize(.mini) }
                        else { Image(systemName: "sparkles") }
                        Text("Smart fill")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(foreground)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(inset, in: Capsule())
                    .overlay(Capsule().strokeBorder(border, lineWidth: 1))
                }
                .disabled(isAnalyzing || !canSave)
            }
            VStack(spacing: 0) {
                formField("Title", icon: "textformat", hint: "Auto-generated when left empty", value: $capture.title)
                Divider().overlay(border).padding(.leading, 14)
                HStack(spacing: 12) {
                    Image(systemName: "folder").frame(width: 22).foregroundStyle(secondary)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Collection").font(.caption.weight(.semibold)).foregroundStyle(secondary)
                        TextField("Optional collection name", text: $capture.category)
                            .font(.subheadline).foregroundStyle(foreground)
                    }
                    if !collections.isEmpty {
                        Menu {
                            Button("No collection") { capture.category = "" }
                            ForEach(collections) { collection in
                                Button(collection.name) { capture.category = collection.name }
                            }
                        } label: {
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                                .foregroundStyle(secondary)
                                .frame(width: 30, height: 30)
                        }
                    }
                }
                .padding(14)
                Divider().overlay(border).padding(.leading, 14)
                formField("Tags", icon: "number", hint: "ideas, research, reading", value: $tagInput)
                    .onChange(of: tagInput) { _, text in
                        capture.tags = text.split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "") }
                            .filter { !$0.isEmpty }
                    }
            }
            .cardSurface(colorScheme)
        }
    }

    private var returnCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeading("RETURN TO IT", subtitle: "Choose when this item should resurface.")
            VStack(alignment: .leading, spacing: 12) {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 9), GridItem(.flexible(), spacing: 9)], spacing: 9) {
                    ForEach(ReturnChoice.allCases) { choice in
                        Button {
                            selectReturn(choice)
                        } label: {
                            HStack(spacing: 7) {
                                Image(systemName: choice.icon)
                                Text(choice.rawValue)
                                Spacer(minLength: 1)
                                if selectedReturn == choice {
                                    Image(systemName: "checkmark").font(.caption2.bold())
                                }
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(selectedReturn == choice ? Color(hex: "171711") : foreground)
                            .padding(.horizontal, 12)
                            .frame(height: 43)
                            .background(selectedReturn == choice ? AppTheme.accent : inset, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(selectedReturn == choice ? .clear : border, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                if selectedReturn == .date {
                    DatePicker("Return date", selection: $chosenDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.graphical)
                        .tint(foreground)
                        .padding(8)
                        .background(inset, in: RoundedRectangle(cornerRadius: 12))
                        .onChange(of: chosenDate) { _, date in capture.returnAt = date }
                }
                Label(
                    capture.returnAt.map { "Returns \($0.formatted(date: .abbreviated, time: .shortened))" }
                        ?? "No reminder — kept in Inbox",
                    systemImage: capture.returnAt == nil ? "tray" : "clock"
                )
                .font(.caption)
                .foregroundStyle(secondary)
            }
            .padding(14)
            .cardSurface(colorScheme)
        }
    }

    private var successCard: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark")
                .font(.system(size: 27, weight: .bold))
                .foregroundStyle(Color(hex: "171711"))
                .frame(width: 72, height: 72)
                .background(AppTheme.accent, in: Circle())
            Text("Saved to LaterBox").font(.title2.bold()).foregroundStyle(foreground)
            Text("You can open the saved item to edit its details, or go back to your inbox.")
                .font(.subheadline)
                .foregroundStyle(secondary)
                .multilineTextAlignment(.center)
            Button { showingItemDetails = true } label: {
                Label("View saved item", systemImage: "arrow.up.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(foreground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(inset, in: RoundedRectangle(cornerRadius: 13))
                    .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(border, lineWidth: 1))
            }
            Button { undoCapture() } label: {
                Label("Undo save", systemImage: "arrow.uturn.backward")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(secondary)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .cardSurface(colorScheme)
        .padding(.top, 28)
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            if savedItem != nil {
                Button { dismiss() } label: {
                    Label("Done", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .foregroundStyle(Color(hex: "171711"))
                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 15))
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Save to LaterBox").font(.system(size: 13, weight: .semibold)).foregroundStyle(foreground)
                    Text(selectedReturn == .inbox ? "Available in Inbox" : "Scheduled for later")
                        .font(.system(size: 11)).foregroundStyle(secondary)
                }
                Spacer(minLength: 6)
                Button { saveCapture() } label: {
                    Label("Save Item", systemImage: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(hex: "171711"))
                        .padding(.horizontal, 19)
                        .frame(height: 48)
                        .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!canSave || isAnalyzing)
                .opacity(canSave && !isAnalyzing ? 1 : 0.5)
                .accessibilityIdentifier("capture.save")
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .overlay(alignment: .top) { Rectangle().fill(border).frame(height: 0.5) }
    }

    private func formField(_ title: String, icon: String, hint: String, value: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).frame(width: 22).foregroundStyle(secondary)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.caption.weight(.semibold)).foregroundStyle(secondary)
                TextField(hint, text: value).font(.subheadline).foregroundStyle(foreground)
            }
        }
        .padding(14)
    }

    private func attachButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(foreground)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(inset, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func selectReturn(_ choice: ReturnChoice) {
        selectedReturn = choice
        switch choice {
        case .inbox: capture.returnAt = nil
        case .soon: capture.returnAt = Date().addingTimeInterval(600)
        case .tomorrow:
            capture.returnAt = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date().addingTimeInterval(86400))
        case .date:
            chosenDate = capture.returnAt ?? Date().addingTimeInterval(86400)
            capture.returnAt = chosenDate
        }
        LBHaptic.light()
    }

    private func reviewCapture() {
        guard !isAnalyzing, savedItem == nil else { return }
        let snapshot = capture
        let names = collections.map(\.name)
        let suggestion = LaterAISharedAnalyzer.quickSuggestions(content: snapshot.content, collections: names)
        if capture.category.isEmpty { capture.category = suggestion.category }
        if capture.returnAt == nil { capture.returnAt = suggestion.returnAt }
        errorMessage = nil
        isAnalyzing = true

        Task {
            let result = await LaterAISharedAnalyzer.analyze(
                content: snapshot.content,
                attachments: snapshot.attachments,
                availableCollections: names,
                settings: SharedCaptureStore.loadAISettings()
            )
            defer { isAnalyzing = false }

            // Do not replace edits made in the composer while AI was preparing.
            guard capture.id == snapshot.id,
                  capture.content == snapshot.content,
                  capture.attachments == snapshot.attachments,
                  savedItem == nil else { return }

            if capture.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                capture.title = result.title ?? snapshot.attachments.first?.name ?? ""
            }
            if capture.category.isEmpty {
                capture.category = result.collectionName ?? ""
            }
            if capture.tags.isEmpty {
                capture.tags = result.tags
            }
            if capture.metadataDescription == nil {
                capture.metadataDescription = result.summary
            }
            if capture.siteName == nil {
                capture.siteName = result.siteName
            }
            if capture.previewImageUrl == nil {
                capture.previewImageUrl = result.previewImageUrl
            }
            // A suggestion is only provisional; the final user choice wins.
            if capture.returnAt == nil, selectedReturn == .inbox, let suggestionDate = result.returnAt {
                capture.returnAt = suggestionDate
                chosenDate = suggestionDate
                selectedReturn = .date
            }
        }
    }

    private func saveCapture() {
        if let savedItem {
            // Post-save Change Return updates the existing SwiftData item,
            // rather than trying to create another capture.
            guard let date = capture.returnAt else { return }
            SyncCoordinator.shared.scheduleItem(item: savedItem, date: date, context: modelContext)
            capture.returnAt = savedItem.returnAt
            return
        }

        var draft = CaptureDraft.fromShared(capture)
        if draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let firstLine = String(draft.content.split(separator: "\n").first?.prefix(100) ?? "")
            draft.title = draft.attachments.first?.name ??
                (draft.url.flatMap { URL(string: $0)?.host } ??
                    (firstLine.isEmpty ? "Saved item" : firstLine))
        }

        do {
            savedItem = try SyncCoordinator.shared.saveDraft(draft, context: modelContext)
            errorMessage = nil
            LBHaptic.success()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func undoCapture() {
        guard let item = savedItem else { return }
        let statusBefore = item.status
        let updatedBefore = item.updatedAt
        let pendingBefore = item.isSyncPending
        item.status = "deleted"
        item.updatedAt = Date()
        item.isSyncPending = true

        do {
            try modelContext.save()
            savedItem = nil
            // An undone item remains in Recently Deleted. A subsequent capture
            // must have its own identity, never revive the deleted item.
            capture.id = UUID().uuidString
            Task {
                _ = try? await ReturnNotification.update(id: item.id, title: item.title, date: nil)
                await SyncCoordinator.shared.syncPendingItems(context: modelContext)
            }
            LBHaptic.medium()
        } catch {
            item.status = statusBefore
            item.updatedAt = updatedBefore
            item.isSyncPending = pendingBefore
            errorMessage = error.localizedDescription
        }
    }
}

public struct CaptureView: View {
    public init() {}

    public var body: some View {
        CaptureComposerScreen(mode: .guided)
    }
}

private extension View {
    func cardSurface(_ scheme: ColorScheme) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(InboxAppearance.surface(for: scheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(InboxAppearance.border(for: scheme), lineWidth: 1)
        )
    }
}
