// laterbox-ios/laterbox-ios/Views/Sheets/CaptureView.swift
import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers

/// Quick Save and Inbox Capture use the same conversational composer and review.
enum CaptureComposerMode: Equatable {
    case quick
    case guided

    var title: String { self == .quick ? "Quick Save to LaterBox" : "Save to LaterBox" }
}

private struct CaptureChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let time = Date()
}

private enum CaptureChatPhase {
    case composing, reviewing, saved
}

struct CaptureComposerScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let mode: CaptureComposerMode

    @State private var draft = CaptureDraft()
    @State private var input = ""
    @State private var messages: [CaptureChatMessage] = []
    @State private var phase: CaptureChatPhase = .composing
    @State private var analyzing = false
    @State private var analysisSource = "LaterBox"
    @State private var recommendedReturn: Date?
    @State private var savedItem: LBItem?
    @State private var error: String?
    @State private var editingDetails = false
    @State private var choosingDate = false
    @State private var date = Date().addingTimeInterval(86400)
    @State private var chooseAttachments = false
    @State private var pickingFile = false
    @State private var pickingPhoto = false
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 0) {
            LaterAIHeader(
                title: mode.title,
                canReset: phase != .composing,
                close: { dismiss() },
                reset: resetConversation
            )

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        ForEach(messages) { message in
                            LaterAIChatRow(text: message.text,
                                           isUser: message.isUser,
                                           timestamp: message.time)
                        }

                        if phase == .composing && !draft.attachments.isEmpty {
                            attachmentList
                        }
                        if phase != .composing {
                            reviewCard
                        }
                        if analyzing {
                            LaterAIThinkingIndicator(thinking: true,
                                                     statusText: "Preparing your capture...")
                        }
                        if let error {
                            Label(error, systemImage: "exclamationmark.triangle.fill")
                                .font(.footnote)
                                .foregroundStyle(.orange)
                        }
                        Color.clear.frame(height: 4).id("captureBottom")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: messages.count) { _, _ in
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("captureBottom", anchor: .bottom)
                    }
                }
                .onChange(of: analyzing) { _, _ in
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("captureBottom", anchor: .bottom)
                    }
                }
            }

            if phase == .composing {
                LaterAIComposer(text: $input,
                                thinking: analyzing,
                                attach: { chooseAttachments = true },
                                send: submit)
                    .accessibilityIdentifier("capture.messageComposer")
                if !draft.attachments.isEmpty {
                    Button("Review attached files") { submit() }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(LaterAIStyle.accent)
                        .padding(.bottom, 10)
                }
            } else if !analyzing {
                LaterAIOptionsDock(
                    title: phase == .saved ? "Saved item options" : "When would you like to return?",
                    options: actionOptions
                )
                .padding(.bottom, 10)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .foregroundStyle(.white)
        .preferredColorScheme(.dark)
        .navigationBarHidden(true)
        .whiteStatusBar()
        .onAppear {
            if messages.isEmpty {
                messages.append(CaptureChatMessage(
                    text: "What would you like to save? Send a note or link, or attach a file. I'll prepare it for review.",
                    isUser: false))
            }
            SyncCoordinator.shared.isShowingCapture = true
            StatusBarStyleModifier.apply(.dark)
        }
        .onDisappear {
            SyncCoordinator.shared.isShowingCapture = false
            StatusBarStyleModifier.apply(.light)
        }
        .confirmationDialog("Add to LaterBox", isPresented: $chooseAttachments) {
            Button("Document or File", systemImage: "doc") { pickingFile = true }
            Button("Photo or Video", systemImage: "photo") { pickingPhoto = true }
        }
        .fileImporter(isPresented: $pickingFile,
                      allowedContentTypes: [.item],
                      allowsMultipleSelection: true,
                      onCompletion: importFiles)
        .photosPicker(isPresented: $pickingPhoto,
                      selection: $selectedPhoto,
                      matching: .any(of: [.images, .videos]))
        .onChange(of: selectedPhoto) { _, selected in
            importPhoto(selected)
        }
        .sheet(isPresented: $editingDetails) {
            if let savedItem {
                NavigationStack { ItemDetailView(item: savedItem) }
            } else {
                CaptureChatDetailsSheet(draft: $draft)
            }
        }
        .sheet(isPresented: $choosingDate) {
            NavigationStack {
                VStack(spacing: 18) {
                    DatePicker("Return Date", selection: $date, in: Date()...,
                               displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.graphical)
                        .tint(LaterAIStyle.accent)
                        .padding(16)
                    Spacer()
                    Button("Confirm Return Date") {
                        choosingDate = false
                        applyReturnDate(date)
                    }
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(15)
                    .background(LaterAIStyle.accent, in: RoundedRectangle(cornerRadius: 15))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                .background(Color.black)
                .navigationTitle("Choose Return Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { choosingDate = false }
                    }
                }
            }
            .preferredColorScheme(.dark)
            .presentationDetents([.medium, .large])
        }
    }

    private var attachmentList: some View {
        VStack(spacing: 8) {
            ForEach(draft.attachments) { attachment in
                HStack {
                    Image(systemName: "paperclip").foregroundStyle(LaterAIStyle.accent)
                    Text(attachment.name).font(.subheadline).lineLimit(1)
                    Spacer()
                    Button {
                        draft.attachments.removeAll { $0.id == attachment.id }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .accessibilityLabel("Remove attachment")
                }
                .padding(12)
                .background(LaterAIStyle.field, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var reviewCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Image(systemName: phase == .saved ? "checkmark.circle.fill" : "tray.and.arrow.down.fill")
                    .foregroundStyle(LaterAIStyle.accent)
                Text(phase == .saved ? "SAVED TO LATERBOX" : "READY FOR REVIEW")
                    .font(.caption.weight(.bold))
                    .tracking(0.7)
                    .foregroundStyle(LaterAIStyle.accent)
                Spacer()
                if phase == .reviewing {
                    Button("Edit", systemImage: "pencil") { editingDetails = true }
                        .font(.caption.weight(.semibold))
                        .tint(LaterAIStyle.accent)
                }
            }

            Text(draft.title.isEmpty ? (draft.attachments.first?.name ?? "Saved note") : draft.title)
                .font(.headline)
                .foregroundStyle(.white)
            if let url = draft.url {
                Label(url, systemImage: "link")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(2)
            }
            if !draft.summary.isEmpty {
                Text(draft.summary).font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(4)
            }
            if !draft.attachments.isEmpty {
                attachmentList
            }
            if !draft.tags.isEmpty {
                Text(draft.tags.prefix(4).map { "#\($0)" }.joined(separator: "  "))
                    .font(.caption).foregroundStyle(LaterAIStyle.accent)
            }
            if let collection = draft.collectionName, !collection.isEmpty {
                Label(collection, systemImage: "folder")
                    .font(.caption).foregroundStyle(.white.opacity(0.6))
            }
            if let scheduled = draft.returnAt {
                Label(scheduled.formatted(date: .abbreviated, time: .shortened),
                      systemImage: "calendar.badge.clock")
                    .font(.caption).foregroundStyle(LaterAIStyle.accent)
            } else {
                Label("Inbox · No reminder", systemImage: "tray")
                    .font(.caption).foregroundStyle(.white.opacity(0.55))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(17)
        .background(Color(white: 0.09), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.1)))
    }

    private var actionOptions: [LaterAIOptionItem] {
        if phase == .saved {
            return [
                LaterAIOptionItem(title: "Done", subtitle: "Close LaterBox",
                                  icon: "checkmark.circle.fill", isPrimary: true) {
                    dismiss()
                },
                LaterAIOptionItem(title: "Edit Details", subtitle: "Update saved item",
                                  icon: "pencil") {
                    editingDetails = true
                },
                LaterAIOptionItem(title: "Change Return", subtitle: "Reschedule",
                                  icon: "calendar.badge.clock") {
                    choosingDate = true
                },
                LaterAIOptionItem(title: "Undo Save", subtitle: "Move to Recently Deleted",
                                  icon: "arrow.uturn.backward") {
                    undoSave()
                }
            ]
        }
        var options: [LaterAIOptionItem] = [
            LaterAIOptionItem(title: "No Reminder", subtitle: "Save in inbox",
                              icon: "tray", isPrimary: true) {
                save(date: nil, choice: "No reminder")
            },
            LaterAIOptionItem(title: "In 10 Minutes", subtitle: "Quick return",
                              icon: "timer") {
                save(date: Date().addingTimeInterval(600), choice: "In 10 minutes")
            },
            LaterAIOptionItem(title: "Tomorrow", subtitle: "9:00 AM",
                              icon: "calendar.badge.clock") {
                let tomorrow = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0,
                                                      of: Date().addingTimeInterval(86400))
                save(date: tomorrow, choice: "Tomorrow")
            },
            LaterAIOptionItem(title: "Choose Date", subtitle: "Pick a return time",
                              icon: "slider.horizontal.3") {
                choosingDate = true
            },
            LaterAIOptionItem(title: "Edit Details", subtitle: "Title, tags, collection",
                              icon: "pencil") {
                editingDetails = true
            },
            LaterAIOptionItem(title: "Change Message", subtitle: "Return to composer",
                              icon: "keyboard") {
                input = draft.content
                phase = .composing
            }
        ]
        if let recommendedReturn {
            options.insert(LaterAIOptionItem(
                title: "Recommended", subtitle: recommendedReturn.formatted(date: .abbreviated,
                                                                           time: .shortened),
                icon: "sparkles") {
                    save(date: recommendedReturn, choice: "Recommended return")
                }, at: 1)
        }
        return options
    }

    private func submit() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty || !draft.attachments.isEmpty else { return }
        if !text.isEmpty { draft.content = text }
        if draft.title.isEmpty {
            draft.title = draft.attachments.first?.name ?? CaptureDraft.manual(draft.content).title
        }
        messages.append(CaptureChatMessage(
            text: text.isEmpty ? draft.attachments.map(\.name).joined(separator: ", ") : text,
            isUser: true))
        phase = .reviewing
        input = ""
        error = nil
        analyzing = true
        LBHaptic.light()

        Task {
            let contentBeforeAnalysis = draft.content
            let result = await LaterAIModelManager.shared.analyzeCapture(
                content: contentBeforeAnalysis,
                attachments: draft.attachments,
                availableCollections: [])
            guard phase == .reviewing, draft.content == contentBeforeAnalysis else {
                analyzing = false
                return
            }
            if let title = result.title, !title.isEmpty,
               (draft.title.isEmpty || draft.title == CaptureDraft.manual(contentBeforeAnalysis).title) {
                draft.title = title
            }
            if draft.summary.isEmpty, let summary = result.summary { draft.summary = summary }
            if draft.contentType.isEmpty, let type = result.contentType { draft.contentType = type }
            if draft.tags.isEmpty { draft.tags = result.tags }
            if draft.collectionName == nil, let collection = result.collectionName {
                draft.collectionName = collection
                draft.category = collection
            }
            if let site = result.siteName { draft.siteName = site }
            if let image = result.previewImageUrl { draft.previewImageUrl = image }
            if let favicon = result.faviconUrl { draft.faviconUrl = favicon }
            recommendedReturn = result.returnAt
            analysisSource = result.sourceDescription
            analyzing = false
            messages.append(CaptureChatMessage(
                text: "I've prepared “\(draft.title)” for your LaterBox. Choose when you'd like to see it again, or edit its details.",
                isUser: false))
        }
    }

    private func save(date: Date?, choice: String) {
        guard phase == .reviewing, !analyzing else { return }
        draft.returnAt = date
        if draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            draft.title = draft.attachments.first?.name ?? "Saved note"
        }
        do {
            savedItem = try SyncCoordinator.shared.saveDraft(draft, context: modelContext)
            phase = .saved
            error = nil
            messages.append(CaptureChatMessage(text: choice, isUser: true))
            messages.append(CaptureChatMessage(
                text: "Saved “\(draft.title)” to LaterBox. You can edit it, undo the save, or finish.",
                isUser: false))
            LBHaptic.success()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func applyReturnDate(_ selected: Date) {
        if let savedItem {
            SyncCoordinator.shared.scheduleItem(item: savedItem, date: selected, context: modelContext)
            draft.returnAt = selected
            messages.append(CaptureChatMessage(text: "Return changed to \(selected.formatted(date: .abbreviated, time: .shortened)).",
                                               isUser: false))
        } else {
            save(date: selected, choice: selected.formatted(date: .abbreviated, time: .shortened))
        }
    }

    private func undoSave() {
        guard let item = savedItem else { return }
        let originalStatus = item.status
        let oldDate = item.updatedAt
        let pending = item.isSyncPending
        item.status = "deleted"
        item.updatedAt = Date()
        item.isSyncPending = true
        do {
            try modelContext.save()
            savedItem = nil
            phase = .reviewing
            draft = CaptureDraft()
            input = ""
            messages.append(CaptureChatMessage(text: "Undo save", isUser: true))
            messages.append(CaptureChatMessage(
                text: "Moved to Recently Deleted. You can start another capture.",
                isUser: false))
            Task {
                _ = try? await ReturnNotification.update(id: item.id, title: item.title, date: nil)
                await SyncCoordinator.shared.syncPendingItems(context: modelContext)
            }
            phase = .composing
            LBHaptic.medium()
        } catch {
            item.status = originalStatus
            item.updatedAt = oldDate
            item.isSyncPending = pending
            error = error.localizedDescription
        }
    }

    private func resetConversation() {
        draft = CaptureDraft()
        input = ""
        savedItem = nil
        phase = .composing
        recommendedReturn = nil
        error = nil
        messages = [CaptureChatMessage(text: "What would you like to save next?", isUser: false)]
    }

    private func importFiles(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result else { return }
        for url in urls {
            do {
                let identifier = UTType(filenameExtension: url.pathExtension)?.identifier ?? UTType.item.identifier
                draft.attachments.append(try SharedCaptureStore.copyFile(url, type: identifier))
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    private func importPhoto(_ photo: PhotosPickerItem?) {
        guard let photo else { return }
        Task {
            guard let data = try? await photo.loadTransferable(type: Data.self) else { return }
            let identifier = photo.supportedContentTypes.first ?? .jpeg
            let ext = identifier.preferredFilenameExtension ?? "jpg"
            let temp = FileManager.default.temporaryDirectory
                .appendingPathComponent("capture-\(UUID().uuidString).\(ext)")
            do {
                try data.write(to: temp)
                defer { try? FileManager.default.removeItem(at: temp) }
                draft.attachments.append(try SharedCaptureStore.copyFile(temp, type: identifier.identifier))
            } catch {
                self.error = error.localizedDescription
            }
            selectedPhoto = nil
        }
    }
}

private struct CaptureChatDetailsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var draft: CaptureDraft
    @State private var tags = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Capture") {
                    TextField("Title", text: $draft.title)
                    TextField("Content", text: $draft.content, axis: .vertical)
                        .lineLimit(3...8)
                    TextField("Notes or summary", text: $draft.summary, axis: .vertical)
                        .lineLimit(2...5)
                }
                Section("Organize") {
                    TextField("Collection", text: Binding(
                        get: { draft.collectionName ?? "" },
                        set: { draft.collectionName = $0.isEmpty ? nil : $0; draft.category = $0 }
                    ))
                    TextField("Tags, separated by commas", text: $tags)
                }
                Section("Content Type") {
                    Picker("Format", selection: $draft.contentType) {
                        Text("Automatic").tag("")
                        ForEach(ItemContentType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(type.rawValue)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationTitle("Edit Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        draft.tags = tags.split(separator: ",").map {
                            $0.trimmingCharacters(in: .whitespacesAndNewlines)
                                .replacingOccurrences(of: "#", with: "")
                        }.filter { !$0.isEmpty }
                        dismiss()
                    }
                    .tint(LaterAIStyle.accent)
                }
            }
            .onAppear { tags = draft.tags.joined(separator: ", ") }
        }
        .preferredColorScheme(.dark)
    }
}

public struct CaptureView: View {
    public init() {}
    public var body: some View { CaptureComposerScreen(mode: .guided) }
}
