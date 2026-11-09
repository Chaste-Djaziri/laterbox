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
    @ObservedObject private var coordinator = SyncCoordinator.shared
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
    @State private var assetOnlyImport = false
    @State private var step: CaptureStep = .capture
    @State private var selectedReturn: ReturnChoice = .suggested
    @State private var chosenDate = Date().addingTimeInterval(86400)
    @State private var scheduleTouched = false
    @State private var tagsTouched = false
    @State private var collectionTouched = false
    @State private var showingNewCollection = false
    @State private var newCollectionName = ""
    @State private var customTag = ""
    @State private var metadataLink: String?
    @State private var isLoadingMetadata = false
    @State private var summaryTouched = false
    @State private var titleTouched = false
    @State private var analyzedKey = ""

    private enum CaptureStep: Int, CaseIterable, Identifiable {
        case capture = 1, schedule = 2, details = 3
        var id: Int { rawValue }
        var label: String {
            switch self {
            case .capture: "Capture"
            case .schedule: "Schedule"
            case .details: "Details"
            }
        }
    }

    private enum ReturnChoice: String, CaseIterable, Identifiable {
        case suggested = "Suggested"
        case laterToday = "Later Today"
        case tomorrow = "Tomorrow"
        case weekend = "Weekend"
        case someday = "Someday"
        case now = "Now"
        case custom = "Custom"

        var id: String { rawValue }
        var icon: String {
            switch self {
            case .suggested: "sparkles"
            case .laterToday: "clock"
            case .tomorrow: "sunrise"
            case .weekend: "calendar"
            case .someday: "archivebox"
            case .now: "tray"
            case .custom: "calendar.badge.clock"
            }
        }
    }

    private let commonTags = ["Work", "Reading", "Personal", "Finance", "Inspiration", "Urgent"]
    private var foreground: Color { InboxAppearance.textPrimary(for: colorScheme) }
    private var secondary: Color { InboxAppearance.textSecondary(for: colorScheme) }
    private var surface: Color { InboxAppearance.surface(for: colorScheme) }
    private var inset: Color { colorScheme == .dark ? Color(hex: "1B1D20") : .white }
    private var border: Color { InboxAppearance.border(for: colorScheme) }
    private var accent: Color { AppTheme.accent }
    private var canSave: Bool {
        !capture.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !capture.attachments.isEmpty
    }
    private var hasDraft: Bool {
        canSave || !capture.title.isEmpty || !capture.category.isEmpty || !capture.tags.isEmpty
    }
    private var validCustomReturn: Bool {
        selectedReturn != .custom || chosenDate > Date()
    }


    var body: some View {
        GeometryReader { geometry in
            ZStack {
                InboxGrainBackground().ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        pageHeader
                        if savedItem != nil {
                            successCard
                        } else {
                            stepIndicators
                            Group {
                                switch step {
                                case .capture: captureStep(availableHeight: geometry.size.height)
                                case .schedule: scheduleStep
                                case .details: detailsStep
                                }
                            }
                            .id(step)
                            .transition(.opacity)
                        }

                        if savedItem == nil && coordinator.isCloudStorageFull {
                            Label("Storage full. New saves and attachments are paused. Permanently delete stored files or change your web plan.", systemImage: "exclamationmark.triangle.fill")
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .padding(13)
                                .cardSurface(colorScheme)
                        }

                        if let errorMessage {
                            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .cardSurface(colorScheme)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 22)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showingItemDetails) {
            if let savedItem {
                ItemDetailView(item: savedItem, usesNativeNavigation: true)
            }
        }
        .confirmationDialog("Discard draft?", isPresented: $showingDiscard, titleVisibility: .visible) {
            Button("Discard Draft", role: .destructive) { dismiss() }
            Button("Keep Editing", role: .cancel) {}
        } message: { Text("Your unsaved changes will be lost.") }
        .fileImporter(isPresented: $showingFilePicker, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
            switch result {
            case .success(let urls):
                var imported: [SharedAttachment] = []
                for url in urls {
                    do {
                        let type = UTType(filenameExtension: url.pathExtension)?.identifier ?? UTType.item.identifier
                        let attachment = try SharedCaptureStore.copyFile(url, type: type)
                        imported.append(attachment)
                        if !assetOnlyImport { capture.attachments.append(attachment) }
                    } catch {
                        errorMessage = "Unable to import \(url.lastPathComponent). Please try again."
                    }
                }
                if assetOnlyImport && !imported.isEmpty {
                    capture.attachments = imported
                    saveImportedAssets()
                }
            case .failure:
                errorMessage = "The file picker could not open that item."
            }
            assetOnlyImport = false
        }
        .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhoto, matching: .any(of: [.images, .videos]))
        .onChange(of: selectedPhoto) { _, photo in
            guard let photo else { return }
            Task {
                guard let data = try? await photo.loadTransferable(type: Data.self) else {
                    errorMessage = "Could not load the selected photo or video."
                    assetOnlyImport = false
                    selectedPhoto = nil
                    return
                }
                let type = photo.supportedContentTypes.first ?? .jpeg
                let filename = "laterbox-\(UUID().uuidString).\(type.preferredFilenameExtension ?? "jpg")"
                let temporary = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                do {
                    try data.write(to: temporary)
                    defer { try? FileManager.default.removeItem(at: temporary) }
                    let attachment = try SharedCaptureStore.copyFile(temporary, type: type.identifier)
                    if assetOnlyImport {
                        capture.attachments = [attachment]
                        saveImportedAssets()
                    } else {
                        capture.attachments.append(attachment)
                    }
                    errorMessage = nil
                } catch {
                    errorMessage = "Unable to attach the selected media."
                }
                assetOnlyImport = false
                selectedPhoto = nil
            }
        }
        .task(id: detectedWebURL) {
            guard let link = detectedWebURL else { return }
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled, detectedWebURL == link else { return }
            prepareAutoFill()
        }
        .onAppear { SyncCoordinator.shared.isShowingCapture = true }
        .onDisappear { SyncCoordinator.shared.isShowingCapture = false }
    }

    private var pageHeader: some View {
        HStack(spacing: 12) {
            Button {
                if savedItem != nil || !hasDraft { dismiss() }
                else if step != .capture { withAnimation(.easeInOut(duration: 0.2)) { step = .capture } }
                else { showingDiscard = true }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(foreground)
                    .frame(width: 40, height: 40)
                    .background(surface, in: RoundedRectangle(cornerRadius: 13))
                    .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(border, lineWidth: 1))
            }
            .accessibilityLabel(step == .capture ? "Close create item" : "Previous step")

            VStack(alignment: .leading, spacing: 3) {
                Text(savedItem == nil ? "Create Item" : "Item Saved")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(foreground)
                Text(savedItem == nil ? "Save it now. Come back when it matters." : "Added to your LaterBox")
                    .font(.system(size: 12))
                    .foregroundStyle(secondary)
            }

            Spacer(minLength: 0)
            if savedItem == nil && hasDraft {
                Button("Clear") { resetDraft() }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private var stepIndicators: some View {
        HStack(spacing: 6) {
            ForEach(CaptureStep.allCases) { target in
                Button {
                    guard target == .capture || canSave else { return }
                    if target != .capture { prepareAutoFill() }
                    withAnimation(.easeInOut(duration: 0.18)) { step = target }
                } label: {
                    HStack(spacing: 5) {
                        Text("\(target.rawValue).")
                            .opacity(0.7)
                        Text(target.label)
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(step == target ? (colorScheme == .dark ? Color(hex: "171711") : .white) : foreground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(
                        step == target
                            ? (colorScheme == .dark ? accent : Color(hex: "171711"))
                            : (target.rawValue < step.rawValue ? accent.opacity(0.7) : surface),
                        in: Capsule()
                    )
                    .overlay(Capsule().strokeBorder(step == target ? .clear : border, lineWidth: 1))
                }
                .disabled(target != .capture && !canSave)
                .buttonStyle(.plain)
                .accessibilityIdentifier("capture.step.\(target.rawValue)")
            }
        }
    }

    private func captureStep(availableHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("What would you like to save?")
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundStyle(foreground)
                    Text("A thought, a URL, a task, or just a file.")
                        .font(.subheadline)
                        .foregroundStyle(secondary)
                }
                Spacer(minLength: 2)
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 19))
                    .foregroundStyle(foreground)
            }
            ZStack(alignment: .topLeading) {
                if capture.content.isEmpty {
                    Text(capture.attachments.isEmpty
                         ? "Start typing here…"
                         : "Optional: add a note about your attachment…")
                        .font(.system(size: 16))
                        .foregroundStyle(secondary.opacity(0.7))
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $capture.content)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 16))
                    .foregroundStyle(foreground)
                    .tint(foreground)
                    .padding(10)
                    .frame(minHeight: max(availableHeight - 300, 260))
                    .accessibilityIdentifier("capture.content")
                    .disabled(coordinator.isCloudStorageFull)
                    .onChange(of: capture.content) { _, _ in
                        metadataLink = nil
                    }
            }
            .frame(maxWidth: .infinity)
            .background(inset, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(border, lineWidth: 1))

            if let link = detectedWebURL {
                HStack(spacing: 8) {
                    Image(systemName: "link")
                    Text(URL(string: link)?.host ?? link).lineLimit(1)
                    Spacer()
                    if isLoadingMetadata { ProgressView().controlSize(.mini) }
                    else { Image(systemName: "checkmark.circle.fill") }
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(secondary)
                .padding(.horizontal, 4)
            }

            if !capture.attachments.isEmpty {
                attachmentList
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var attachmentList: some View {
        VStack(spacing: 7) {
            ForEach(capture.attachments) { attachment in
                HStack(spacing: 9) {
                    Image(systemName: attachmentIcon(attachment))
                        .foregroundStyle(foreground)
                    Text(attachment.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(foreground)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Button {
                        capture.attachments.removeAll { $0.id == attachment.id }
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(secondary)
                    }
                    .accessibilityLabel("Remove \(attachment.name)")
                }
                .padding(10)
                .background(surface, in: RoundedRectangle(cornerRadius: 11))
            }
        }
    }

    private func attachmentIcon(_ attachment: SharedAttachment) -> String {
        let type = attachment.typeIdentifier.lowercased()
        if type.contains("image") { return "photo" }
        if type.contains("video") { return "play.rectangle" }
        if type.contains("audio") { return "music.note" }
        if type.contains("pdf") { return "doc.richtext" }
        return "doc"
    }

    private var scheduleStep: some View {
        VStack(alignment: .leading, spacing: 17) {
            sectionHeading("When should LaterBox bring this back?", subtitle: "You can always change the return date later.")
            summaryStrip

            HStack(spacing: 10) {
                Image(systemName: capture.returnAt == nil ? "archivebox" : "calendar.badge.clock")
                    .font(.system(size: 17))
                    .foregroundStyle(Color(hex: "171711"))
                    .frame(width: 42, height: 42)
                    .background(accent, in: RoundedRectangle(cornerRadius: 13))
                VStack(alignment: .leading, spacing: 5) {
                    Text(scheduleLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(foreground)
                    Text(selectedReturn == .suggested ? "Suggested based on what you're saving." : "Your selected return schedule.")
                        .font(.caption)
                        .foregroundStyle(secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(15)
            .cardSurface(colorScheme)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 112), spacing: 9)], spacing: 9) {
                ForEach(ReturnChoice.allCases) { choice in
                    Button {
                        chooseReturn(choice)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: choice.icon)
                                .font(.caption)
                            Text(choice.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundStyle(selectedReturn == choice ? Color(hex: "171711") : foreground)
                        .frame(maxWidth: .infinity)
                        .frame(height: 45)
                        .background(selectedReturn == choice ? accent : surface, in: Capsule())
                        .overlay(Capsule().strokeBorder(selectedReturn == choice ? .clear : border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("capture.return.\(choice.id)")
                }
            }

            if selectedReturn == .custom {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Choose a custom date and time")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(foreground)
                    DatePicker("Return on", selection: $chosenDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.graphical)
                        .tint(foreground)
                        .onChange(of: chosenDate) { _, newDate in
                            capture.returnAt = newDate
                        }
                }
                .padding(13)
                .cardSurface(colorScheme)
            }
            if isAnalyzing {
                Label("Finding a useful return time…", systemImage: "sparkles")
                    .font(.caption)
                    .foregroundStyle(secondary)
            }
        }
    }

    private var detailsStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                sectionHeading("Make this yours", subtitle: "Title, tags, and collections are optional.")
                Spacer(minLength: 4)
                Button {
                    prepareAutoFill(force: true)
                } label: {
                    HStack(spacing: 6) {
                        if isAnalyzing || isLoadingMetadata { ProgressView().controlSize(.mini) }
                        else { Image(systemName: "sparkles") }
                        Text("Auto Fill")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(foreground)
                    .padding(.horizontal, 11)
                    .frame(height: 34)
                    .background(surface, in: Capsule())
                    .overlay(Capsule().strokeBorder(border, lineWidth: 1))
                }
                .disabled(isAnalyzing || isLoadingMetadata)
            }
            summaryStrip
            if let image = capture.previewImageUrl, let url = URL(string: image), ["https", "http"].contains(url.scheme?.lowercased() ?? "") {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 135)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                    } else if phase.error == nil {
                        ProgressView().frame(maxWidth: .infinity).frame(height: 100)
                    }
                }
            }
            VStack(spacing: 0) {
                formField("Title", icon: "textformat", hint: suggestedTitle, value: Binding(
                    get: { capture.title },
                    set: { capture.title = $0; titleTouched = true }
                ))
                Divider().overlay(border).padding(.leading, 16)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Description / summary")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(secondary)
                    TextField("Optional summary", text: Binding(
                        get: { capture.metadataDescription ?? "" },
                        set: {
                            capture.metadataDescription = $0.isEmpty ? nil : $0
                            summaryTouched = true
                        }
                    ), axis: .vertical)
                    .lineLimit(2...4)
                    .font(.subheadline)
                    .foregroundStyle(foreground)
                }
                .padding(16)
            }
            .cardSurface(colorScheme)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Collection", systemImage: "folder")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(foreground)
                    Spacer()
                    if !capture.category.isEmpty {
                        Button("Clear") {
                            capture.category = ""
                            collectionTouched = true
                        }
                        .font(.caption)
                        .foregroundStyle(secondary)
                    }
                }
                Menu {
                    Button("No collection") {
                        capture.category = ""
                        collectionTouched = true
                    }
                    ForEach(collections) { collection in
                        Button {
                            capture.category = collection.name
                            collectionTouched = true
                        } label: {
                            Label(collection.name, systemImage: capture.category == collection.name ? "checkmark.circle.fill" : "folder")
                        }
                    }
                    Divider()
                    Button {
                        showingNewCollection = true
                    } label: {
                        Label("Create New Collection", systemImage: "folder.badge.plus")
                    }
                } label: {
                    HStack {
                        Image(systemName: "folder")
                        Text(capture.category.isEmpty ? "Choose a collection" : capture.category)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(foreground)
                    .padding(14)
                    .background(inset, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(border, lineWidth: 1))
                }
                .accessibilityIdentifier("capture.collection")
                if showingNewCollection {
                    HStack(spacing: 8) {
                        TextField("New collection name", text: $newCollectionName)
                            .textInputAutocapitalization(.words)
                            .font(.subheadline)
                            .padding(10)
                            .background(inset, in: RoundedRectangle(cornerRadius: 10))
                        Button("Create") { createCollection() }
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color(hex: "171711"))
                            .padding(.horizontal, 12)
                            .frame(height: 38)
                            .background(accent, in: RoundedRectangle(cornerRadius: 10))
                            .disabled(newCollectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .padding(15)
            .cardSurface(colorScheme)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Tags", systemImage: "number")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(foreground)
                    Spacer()
                    Text("\(capture.tags.count) selected")
                        .font(.caption)
                        .foregroundStyle(secondary)
                }
                Text("Tap to select or remove. Suggested tags can be changed.")
                    .font(.caption)
                    .foregroundStyle(secondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], spacing: 8) {
                    ForEach(visibleTags, id: \.self) { tag in
                        let isSelected = capture.tags.contains { $0.caseInsensitiveCompare(tag) == .orderedSame }
                        Button {
                            toggleTag(tag)
                        } label: {
                            Text("#\(tag)")
                                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                                .foregroundStyle(isSelected ? Color(hex: "171711") : foreground)
                                .frame(maxWidth: .infinity)
                                .frame(height: 33)
                                .background(isSelected ? accent : inset, in: Capsule())
                                .overlay(Capsule().strokeBorder(isSelected ? .clear : border, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                HStack(spacing: 8) {
                    TextField("Add a custom tag", text: $customTag)
                        .font(.subheadline)
                        .foregroundStyle(foreground)
                        .submitLabel(.done)
                        .onSubmit { addCustomTags() }
                        .padding(10)
                        .background(inset, in: RoundedRectangle(cornerRadius: 11))
                    Button {
                        addCustomTags()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color(hex: "171711"))
                            .frame(width: 38, height: 38)
                            .background(accent, in: RoundedRectangle(cornerRadius: 11))
                    }
                    .accessibilityLabel("Add tag")
                }
                Text("Separate multiple tags with commas.")
                    .font(.caption2)
                    .foregroundStyle(secondary)
            }
            .padding(15)
            .cardSurface(colorScheme)

            if !capture.attachments.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    sectionHeading("ATTACHMENTS", subtitle: "\(capture.attachments.count) file(s) included")
                    attachmentList
                }
            }
        }
    }

    private var summaryStrip: some View {
        HStack(spacing: 9) {
            Image(systemName: capture.attachments.isEmpty ? "text.alignleft" : "paperclip")
                .foregroundStyle(secondary)
            Text(capture.title.isEmpty ? suggestedTitle : capture.title)
                .lineLimit(2)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(foreground)
            Spacer(minLength: 0)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(surface, in: RoundedRectangle(cornerRadius: 13))
    }

    private var suggestedTitle: String {
        let title = capture.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !title.isEmpty { return title }
        if let filename = capture.attachments.first?.name { return filename }
        if let host = detectedWebURL.flatMap({ URL(string: $0)?.host }) { return host }
        return String(capture.content.split(separator: "\n").first?.prefix(100) ?? "Untitled")
    }

    private var scheduleLabel: String {
        if let date = capture.returnAt {
            return "Returning \(date.formatted(date: .abbreviated, time: .shortened))"
        }
        return selectedReturn == .now ? "Save to Inbox · No reminder" : "Someday · No deadline"
    }

    private var visibleTags: [String] {
        var tags = commonTags
        for tag in capture.tags where !tags.contains(where: { $0.caseInsensitiveCompare(tag) == .orderedSame }) {
            tags.append(tag)
        }
        return tags
    }

    private var successCard: some View {
        VStack(spacing: 17) {
            Image(systemName: "checkmark")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color(hex: "171711"))
                .frame(width: 72, height: 72)
                .background(accent, in: Circle())
            Text("Saved to LaterBox")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(foreground)
            Text("Your item is safely saved. Open it to review, or return to your inbox.")
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
                Label("Undo Save", systemImage: "arrow.uturn.backward")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(secondary)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .cardSurface(colorScheme)
        .padding(.top, 24)
    }

    private var footer: some View {
        HStack(spacing: 10) {
            if savedItem != nil {
                Button {
                    dismiss()
                } label: {
                    Label("Done", systemImage: "checkmark")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .foregroundStyle(Color(hex: "171711"))
                .background(accent, in: RoundedRectangle(cornerRadius: 14))
            } else {
                if step == .capture {
                    assetMenu
                } else {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            step = CaptureStep(rawValue: step.rawValue - 1) ?? .capture
                        }
                    } label: {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(foreground)
                            .frame(width: 44, height: 46)
                            .background(surface, in: RoundedRectangle(cornerRadius: 13))
                    }
                    .accessibilityLabel("Previous step")
                }

                if step != .details {
                    Button {
                        if step == .capture {
                            chooseReturn(.now)
                            saveCapture()
                        } else {
                            saveCapture()
                        }
                    } label: {
                        Text(step == .capture ? "Just Save" : "Save Now")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(foreground)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(surface, in: RoundedRectangle(cornerRadius: 13))
                            .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(border, lineWidth: 1))
                    }
                    .disabled(!canSave || !validCustomReturn || coordinator.isCloudStorageFull)
                    .opacity(canSave && validCustomReturn ? 1 : 0.45)
                }

                Button {
                    if step == .capture {
                        guard canSave else { return }
                        prepareAutoFill()
                        withAnimation(.easeInOut(duration: 0.18)) { step = .schedule }
                    } else if step == .schedule {
                        guard validCustomReturn else {
                            errorMessage = "Choose a future return date and time."
                            return
                        }
                        withAnimation(.easeInOut(duration: 0.18)) { step = .details }
                    } else {
                        saveCapture()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(step == .details ? "Save Item" : "Continue")
                        Image(systemName: step == .details ? "checkmark" : "arrow.right")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: "171711"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(accent, in: RoundedRectangle(cornerRadius: 13))
                }
                .disabled(!canSave || !validCustomReturn || coordinator.isCloudStorageFull)
                .opacity(canSave && validCustomReturn ? 1 : 0.45)
                .accessibilityIdentifier(step == .details ? "capture.save" : "capture.continue")
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(.regularMaterial)
        .overlay(alignment: .top) { Rectangle().fill(border).frame(height: 0.5) }
    }

    private var assetMenu: some View {
        Menu {
            Section("Add to this item") {
                Button {
                    assetOnlyImport = false
                    showingPhotoPicker = true
                } label: { Label("Photo or Video", systemImage: "photo") }
                Button {
                    assetOnlyImport = false
                    showingFilePicker = true
                } label: { Label("Files or Documents", systemImage: "doc") }
            }
            Section("Save only an asset") {
                Button {
                    assetOnlyImport = true
                    showingPhotoPicker = true
                } label: { Label("Save Photo or Video Only", systemImage: "photo.badge.plus") }
                Button {
                    assetOnlyImport = true
                    showingFilePicker = true
                } label: { Label("Save File Only", systemImage: "doc.badge.plus") }
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(foreground)
                .frame(width: 44, height: 46)
                .background(surface, in: RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(border, lineWidth: 1))
        }
        .accessibilityLabel("Add attachment or save asset only")
        .accessibilityIdentifier("capture.assets")
        .disabled(coordinator.isCloudStorageFull)
    }

    private func sectionHeading(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(foreground)
            Text(subtitle).font(.caption).foregroundStyle(secondary)
        }
    }

    private func formField(_ title: String, icon: String, hint: String, value: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 22)
                .foregroundStyle(secondary)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.caption.weight(.semibold)).foregroundStyle(secondary)
                TextField(hint, text: value)
                    .font(.subheadline)
                    .foregroundStyle(foreground)
            }
        }
        .padding(15)
    }

    private var detectedWebURL: String? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue),
              let match = detector.firstMatch(in: capture.content, range: NSRange(capture.content.startIndex..., in: capture.content)),
              let url = match.url, url.host != nil,
              ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { return nil }
        return url.absoluteString
    }

    private func prepareAutoFill(force: Bool = false) {
        guard canSave, savedItem == nil else { return }
        let snapshot = capture
        let key = snapshot.content + "|" + snapshot.attachments.map(\.id).joined(separator: "|")
        if !force && analyzedKey == key { return }
        // Do not mark a newer draft analyzed while an earlier analysis is still in flight.
        if isAnalyzing { return }
        analyzedKey = key
        let names = collections.map(\.name)
        let quick = LaterAISharedAnalyzer.quickSuggestions(content: snapshot.content, collections: names)
        if !scheduleTouched && selectedReturn == .suggested { capture.returnAt = quick.returnAt }
        if !collectionTouched && capture.category.isEmpty,
           let match = collections.first(where: { $0.name.caseInsensitiveCompare(quick.category) == .orderedSame }) {
            capture.category = match.name
        }

        if let link = detectedWebURL, link != metadataLink, let url = URL(string: link) {
            metadataLink = link
            isLoadingMetadata = true
            Task {
                defer { isLoadingMetadata = false }
                guard let metadata = try? await LinkMetadataLoader.load(url),
                      savedItem == nil, capture.id == snapshot.id,
                      detectedWebURL == link else { return }
                if !titleTouched,
                   let title = LinkMetadataLoader.cleanTitle(metadata.title) { capture.title = title }
                if !summaryTouched && (capture.metadataDescription ?? "").isEmpty,
                   let text = metadata.description, !LinkMetadataLoader.isGenericDescription(text) {
                    capture.metadataDescription = text
                }
                if capture.siteName == nil { capture.siteName = metadata.site }
                if capture.previewImageUrl == nil { capture.previewImageUrl = metadata.image }
                if !tagsTouched { capture.tags = normalizedTags(capture.tags + metadata.keywords) }
            }
        }

        guard !isAnalyzing else { return }
        isAnalyzing = true
        Task {
            let result = await LaterAISharedAnalyzer.analyze(
                content: snapshot.content, attachments: snapshot.attachments,
                availableCollections: names, settings: SharedCaptureStore.loadAISettings()
            )
            defer {
                isAnalyzing = false
                if savedItem == nil && (capture.content != snapshot.content || capture.attachments != snapshot.attachments) {
                    prepareAutoFill()
                }
            }
            guard savedItem == nil, capture.id == snapshot.id,
                  capture.content == snapshot.content,
                  capture.attachments == snapshot.attachments else { return }
            if capture.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                capture.title = result.title ?? snapshot.attachments.first?.name ?? ""
            }
            if !collectionTouched && capture.category.isEmpty,
               let name = result.collectionName,
               let match = collections.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
                capture.category = match.name
            }
            if !tagsTouched { capture.tags = normalizedTags(capture.tags + result.tags) }
            if !summaryTouched && (capture.metadataDescription ?? "").isEmpty {
                capture.metadataDescription = result.summary
            }
            if capture.siteName == nil { capture.siteName = result.siteName }
            if capture.previewImageUrl == nil { capture.previewImageUrl = result.previewImageUrl }
            if !scheduleTouched && selectedReturn == .suggested { capture.returnAt = result.returnAt }
        }
    }

    private func normalizedTags(_ candidates: [String]) -> [String] {
        var unique: [String] = []
        for raw in candidates {
            let name = raw.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
            guard !name.isEmpty, name.count <= 40,
                  !unique.contains(where: { $0.caseInsensitiveCompare(name) == .orderedSame }) else { continue }
            unique.append(name)
            if unique.count == 16 { break }
        }
        return unique
    }

    private func toggleTag(_ tag: String) {
        tagsTouched = true
        if let index = capture.tags.firstIndex(where: { $0.caseInsensitiveCompare(tag) == .orderedSame }) {
            capture.tags.remove(at: index)
        } else if capture.tags.count < 16 { capture.tags.append(tag) }
        LBHaptic.light()
    }

    private func addCustomTags() {
        for raw in customTag.split(whereSeparator: { $0 == "," || $0 == ";" }) {
            let tag = String(raw).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
            guard !tag.isEmpty, tag.count <= 40, capture.tags.count < 16,
                  !capture.tags.contains(where: { $0.caseInsensitiveCompare(tag) == .orderedSame }) else { continue }
            capture.tags.append(tag)
        }
        tagsTouched = true
        customTag = ""
        LBHaptic.light()
    }

    private func createCollection() {
        let name = newCollectionName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        guard let collection = SyncCoordinator.shared.ensureCollectionExists(named: name, context: modelContext) else {
            errorMessage = "Choose another collection name."
            return
        }
        capture.category = collection.name
        collectionTouched = true
        showingNewCollection = false
        newCollectionName = ""
        errorMessage = nil
        LBHaptic.success()
    }

    private func chooseReturn(_ choice: ReturnChoice) {
        selectedReturn = choice
        scheduleTouched = choice != .suggested
        let calendar = Calendar.current
        let now = Date()
        switch choice {
        case .suggested:
            capture.returnAt = LaterAISharedAnalyzer.quickSuggestions(
                content: capture.content, collections: collections.map(\.name)
            ).returnAt
        case .laterToday:
            let evening = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now) ?? now
            let oneHour = now.addingTimeInterval(3600)
            capture.returnAt = evening > now ? evening : (
                calendar.isDate(oneHour, inSameDayAs: now) ? oneHour :
                calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now.addingTimeInterval(86400))
            )
        case .tomorrow:
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now.addingTimeInterval(86400)
            capture.returnAt = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow)
        case .weekend:
            capture.returnAt = calendar.nextDate(
                after: now, matching: DateComponents(hour: 10, minute: 0, weekday: 7),
                matchingPolicy: .nextTime
            )
        case .someday, .now:
            capture.returnAt = nil
        case .custom:
            if chosenDate <= now { chosenDate = now.addingTimeInterval(3600) }
            capture.returnAt = chosenDate
        }
        errorMessage = nil
        LBHaptic.light()
    }

    private func saveImportedAssets() {
        guard !capture.attachments.isEmpty else { return }
        capture.content = ""
        capture.title = capture.attachments.first?.name ?? ""
        capture.category = ""
        capture.tags = []
        selectedReturn = .now
        scheduleTouched = true
        capture.returnAt = nil
        saveCapture()
    }

    private func resetDraft() {
        capture = SharedCapture()
        step = .capture
        selectedReturn = .suggested
        chosenDate = Date().addingTimeInterval(86400)
        scheduleTouched = false
        collectionTouched = false
        tagsTouched = false
        summaryTouched = false
        titleTouched = false
        analyzedKey = ""
        metadataLink = nil
        showingNewCollection = false
        newCollectionName = ""
        customTag = ""
        errorMessage = nil
    }

    private func saveCapture() {
        guard savedItem == nil else { return }
        guard canSave else {
            errorMessage = "Add a note, link, or attachment to save."
            return
        }
        guard validCustomReturn else {
            errorMessage = "Choose a future return date and time."
            return
        }
        var draft = CaptureDraft.fromShared(capture)
        draft.tags = normalizedTags(capture.tags)
        if draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let first = String(draft.content.split(separator: "\n").first?.prefix(100) ?? "")
            draft.title = draft.attachments.first?.name ??
                (draft.url.flatMap { URL(string: $0)?.host } ?? (first.isEmpty ? "Saved item" : first))
        }
        do {
            let isSomeday = selectedReturn == .someday ||
                (selectedReturn == .suggested && draft.returnAt == nil)
            savedItem = try SyncCoordinator.shared.saveDraft(
                draft, context: modelContext, status: isSomeday ? .deferred : nil
            )
            errorMessage = nil
            LBHaptic.success()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func undoCapture() {
        guard let item = savedItem else { return }
        let beforeStatus = item.status
        let beforeUpdated = item.updatedAt
        let beforePending = item.isSyncPending
        item.status = ItemStatus.deleted.rawValue
        item.updatedAt = Date()
        item.isSyncPending = true
        do {
            try modelContext.save()
            savedItem = nil
            resetDraft()
            Task {
                _ = try? await ReturnNotification.update(id: item.id, title: item.title, date: nil)
                await SyncCoordinator.shared.syncPendingItems(context: modelContext)
            }
            LBHaptic.medium()
        } catch {
            item.status = beforeStatus
            item.updatedAt = beforeUpdated
            item.isSyncPending = beforePending
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
