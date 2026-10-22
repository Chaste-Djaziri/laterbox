// laterbox-ios/Shared/ChatCaptureComposer.swift
// Shared UI compiled into both the iOS app and Share Extension.
import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

/// Chat-first capture and review used for Quick Save, Capture, and incoming shares.
/// A host owns persistence; this view owns only the conversation and picker UI.
struct ChatCaptureComposer: View {
    @Binding var capture: SharedCapture

    var title = "Capture"
    var saved = false
    var isSaving = false
    var isWorking = false
    var savedEditorIsExternal = false
    var errorMessage: String?
    var onClose: () -> Void
    var onReview: () -> Void
    var onSave: () -> Void
    var onUndo: () -> Void
    var onEditSaved: () -> Void

    @State private var input = ""
    @State private var importError: String?
    @State private var reviewing = false
    @State private var showingDetails = false
    @State private var showingReturnDate = false
    @State private var chosenDate = Date().addingTimeInterval(86400)
    @State private var showingFilePicker = false
    @State private var showingPhotos = false
    @State private var selectedPhoto: PhotosPickerItem?

    private let accent = Color(red: 230.0 / 255.0, green: 237.0 / 255.0, blue: 176.0 / 255.0)
    private let panel = Color(white: 0.10)

    private var canSave: Bool {
        !capture.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !capture.attachments.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            LaterAIHeader(
                title: title,
                canReset: reviewing && !saved,
                close: onClose,
                reset: {
                    capture = SharedCapture()
                    input = ""
                    reviewing = false
                    importError = nil
                }
            )

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        assistantBubble("What would you like to save? Send a note, paste a link, or add a file.")
                        if reviewing || saved {
                            if !capture.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                LaterAIChatRow(text: capture.content,
                                               isUser: true,
                                               timestamp: nil)
                            }

                            if !capture.attachments.isEmpty {
                                VStack(spacing: 8) {
                                    ForEach(capture.attachments) { attachment in
                                        attachmentRow(attachment)
                                    }
                                }
                                .padding(12)
                                .background(panel, in: RoundedRectangle(cornerRadius: 16))
                            }

                            if saved {
                                assistantBubble("Saved to LaterBox. You can edit the item, undo the save, or finish.")
                            } else {
                                assistantBubble(isWorking ? "Preparing your capture…" : "Here's your saved-item draft. Choose when to bring it back, or save directly to your inbox.")
                                reviewCard
                            }
                        }

                        if let errorMessage = importError ?? errorMessage, !errorMessage.isEmpty {
                            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                                .font(.footnote)
                                .foregroundStyle(.orange)
                                .padding(12)
                                .background(panel, in: RoundedRectangle(cornerRadius: 12))
                        }
                        Color.clear.frame(height: 1).id("capture-bottom")
                    }
                    .padding(16)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: reviewing) { _, _ in
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("capture-bottom", anchor: .bottom)
                    }
                }
                .onChange(of: saved) { _, _ in
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("capture-bottom", anchor: .bottom)
                    }
                }
            }

            Divider().overlay(Color.white.opacity(0.08))
            if saved {
                savedActions
            } else if reviewing {
                reviewActions
            } else {
                composeBar
            }
        }
        .background(Color(white: 0.047).ignoresSafeArea())
        .foregroundStyle(.white)
        .preferredColorScheme(.dark)
        .onAppear {
            reviewing = canSave
        }
        .fileImporter(isPresented: $showingFilePicker,
                      allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
            switch result {
            case .success(let urls):
                for url in urls {
                    do {
                        let kind = UTType(filenameExtension: url.pathExtension)?.identifier ?? UTType.item.identifier
                        capture.attachments.append(try SharedCaptureStore.copyFile(url, type: kind))
                    } catch {
                        // Do not silently drop a failed file: leave existing content intact.
                        importError = "Unable to import \(url.lastPathComponent). Try again."
                    }
                }
                if !capture.attachments.isEmpty {
                    reviewing = true
                    onReview()
                }
            case .failure:
                break
            }
        }
        .photosPicker(isPresented: $showingPhotos, selection: $selectedPhoto,
                      matching: .any(of: [.images, .videos]))
        .onChange(of: selectedPhoto) { _, photo in
            guard let photo else { return }
            Task {
                guard let data = try? await photo.loadTransferable(type: Data.self) else { return }
                let kind = photo.supportedContentTypes.first ?? .jpeg
                let ext = kind.preferredFilenameExtension ?? "jpg"
                let temporary = FileManager.default.temporaryDirectory
                    .appendingPathComponent("laterbox-\(UUID().uuidString).\(ext)")
                do {
                    try data.write(to: temporary)
                    defer { try? FileManager.default.removeItem(at: temporary) }
                    let attachment = try SharedCaptureStore.copyFile(temporary, type: kind.identifier)
                    capture.attachments.append(attachment)
                    reviewing = true
                    onReview()
                } catch {
                    importError = "Unable to import the selected file. Try again."
                }
                selectedPhoto = nil
            }
        }
        .sheet(isPresented: $showingDetails) {
            ChatCaptureDetails(capture: $capture)
        }
        .sheet(isPresented: $showingReturnDate) {
            NavigationStack {
                VStack {
                    DatePicker("Return date", selection: $chosenDate, in: Date()...,
                               displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.graphical)
                        .tint(accent)
                        .padding()
                    Spacer()
                    Button {
                        capture.returnAt = chosenDate
                        showingReturnDate = false
                        onSave()
                    } label: {
                        Text("Schedule & Save")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .foregroundStyle(.black)
                            .background(accent, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!canSave || isSaving)
                    .padding()
                }
                .navigationTitle("Choose return date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingReturnDate = false }
                    }
                }
            }
            .preferredColorScheme(.dark)
            .presentationDetents([.medium, .large])
        }
    }

    private func assistantBubble(_ message: String) -> some View {
        LaterAIChatRow(text: message, isUser: false, timestamp: nil)
    }

    private var reviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("CAPTURE REVIEW", systemImage: "sparkles")
                    .font(.caption2.weight(.bold))
                    .tracking(0.5)
                    .foregroundStyle(accent)
                Spacer()
                Button {
                    showingDetails = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(accent)
            }

            if let imageURL = previewImageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .accessibilityLabel("Social preview image")
                    case .empty:
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 180)
                            .overlay {
                                ProgressView().tint(accent)
                            }
                    case .failure:
                        EmptyView() // Keep text preview when a remote image fails.
                    @unknown default:
                        EmptyView()
                    }
                }
            }

            Text(capture.title.isEmpty ? inferredTitle : capture.title)
                .font(.headline)
                .foregroundStyle(.white)
                .lineLimit(3)

            if let url = detectedURL {
                Label(URL(string: url)?.host ?? url, systemImage: "link")
                    .font(.caption)
                    .foregroundStyle(accent)
                    .lineLimit(1)
            }

            if let summary = capture.metadataDescription, !summary.isEmpty {
                Text(summary)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(3)
            }

            HStack(spacing: 10) {
                Label(capture.category.isEmpty ? "Inbox" : capture.category, systemImage: "folder")
                if !capture.tags.isEmpty {
                    Text(capture.tags.prefix(2).map { "#\($0)" }.joined(separator: " "))
                }
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.65))

            if let date = capture.returnAt {
                Label(date.formatted(date: .abbreviated, time: .shortened),
                      systemImage: "calendar.badge.clock")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(panel, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18)
            .strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
    }

    private var previewImageURL: URL? {
        guard let raw = capture.previewImageUrl?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty, let url = URL(string: raw),
              ["https", "http"].contains(url.scheme?.lowercased() ?? ""),
              url.host != nil else { return nil }
        return url
    }

    private var inferredTitle: String {
        capture.attachments.first?.name ??
        (detectedURL.flatMap { URL(string: $0)?.host } ??
            String(capture.content.split(separator: "\n").first?.prefix(100) ?? "Untitled"))
    }

    private var detectedURL: String? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue),
              let match = detector.firstMatch(in: capture.content,
                                             range: NSRange(capture.content.startIndex..., in: capture.content)),
              let url = match.url,
              ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { return nil }
        return url.absoluteString
    }

    private func attachmentRow(_ attachment: SharedAttachment) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "doc.fill")
                .foregroundStyle(accent)
            Text(attachment.name).lineLimit(1)
            Spacer()
            if !saved {
                Button {
                    capture.attachments.removeAll { $0.id == attachment.id }
                    if !canSave { reviewing = false }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.55))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove attachment")
            }
        }
        .font(.subheadline)
    }

    private var attachmentMenu: some View {
        Menu {
            Button {
                showingFilePicker = true
            } label: { Label("File or document", systemImage: "doc") }
            Button {
                showingPhotos = true
            } label: { Label("Photo or video", systemImage: "photo") }
        } label: {
            Image(systemName: "plus")
                .font(.title3.weight(.medium))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
        }
        .accessibilityLabel("Add attachment")
    }

    private var composeBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            attachmentMenu
            TextField("Type a note or paste a link…", text: $input, axis: .vertical)
                .lineLimit(1...5)
                .tint(accent)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 18))
                .accessibilityIdentifier("capture.message")
            Button {
                let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty || !capture.attachments.isEmpty else { return }
                capture.content = text
                input = ""
                reviewing = true
                onReview()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44)
                    .background(accent, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                      capture.attachments.isEmpty)
            .accessibilityLabel("Review capture")
            .accessibilityIdentifier("capture.send")
        }
        .padding(14)
    }

    private var reviewActions: some View {
        LaterAIOptionsDock(
            title: "When would you like to return?",
            options: reviewOptions
        )
        .disabled(!canSave || isSaving)
    }

    private var reviewOptions: [LaterAIOptionItem] {
        var options: [LaterAIOptionItem] = [
            LaterAIOptionItem(title: "No Reminder", subtitle: "Save in inbox",
                              icon: "tray", isPrimary: true) {
                capture.returnAt = nil
                onSave()
            },
            LaterAIOptionItem(title: "In 10 Minutes", subtitle: "Quick return",
                              icon: "timer") {
                capture.returnAt = Date().addingTimeInterval(600)
                onSave()
            },
            LaterAIOptionItem(title: "Tomorrow", subtitle: "9:00 AM",
                              icon: "calendar.badge.clock") {
                capture.returnAt = Calendar.current.date(
                    bySettingHour: 9, minute: 0, second: 0,
                    of: Date().addingTimeInterval(86400))
                onSave()
            },
            LaterAIOptionItem(title: "Choose Date", subtitle: "Pick a return time",
                              icon: "slider.horizontal.3") {
                chosenDate = capture.returnAt ?? Date().addingTimeInterval(86400)
                showingReturnDate = true
            },
            LaterAIOptionItem(title: "Edit Details", subtitle: "Title, tags, collection",
                              icon: "pencil") {
                showingDetails = true
            },
            LaterAIOptionItem(title: "Change Message", subtitle: "Return to composer",
                              icon: "keyboard") {
                input = capture.content
                reviewing = false
            }
        ]
        if let date = capture.returnAt, date > Date() {
            options.insert(
                LaterAIOptionItem(
                    title: "Recommended",
                    subtitle: date.formatted(date: .abbreviated, time: .shortened),
                    icon: "sparkles"
                ) {
                    onSave()
                }, at: 1
            )
        }
        return options
    }

    private var savedActions: some View {
        LaterAIOptionsDock(
            title: "Saved item options",
            options: [
                LaterAIOptionItem(title: "Done", subtitle: "Close LaterBox",
                                  icon: "checkmark.circle.fill", isPrimary: true) {
                    onClose()
                },
                LaterAIOptionItem(title: "Edit Details", subtitle: "Update saved item",
                                  icon: "pencil") {
                    onEditSaved()
                    if !savedEditorIsExternal { showingDetails = true }
                },
                LaterAIOptionItem(title: "Change Return", subtitle: "Reschedule",
                                  icon: "calendar.badge.clock") {
                    chosenDate = capture.returnAt ?? Date().addingTimeInterval(86400)
                    showingReturnDate = true
                },
                LaterAIOptionItem(title: "Undo Save", subtitle: "Move to Recently Deleted",
                                  icon: "arrow.uturn.backward") {
                    onUndo()
                }
            ]
        )
        .disabled(isSaving)
    }

}

private struct ChatCaptureDetails: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var capture: SharedCapture
    @State private var tagsText = ""
    private let accent = Color(red: 230.0 / 255.0, green: 237.0 / 255.0, blue: 176.0 / 255.0)

    var body: some View {
        NavigationStack {
            Form {
                Section("Content") {
                    TextField("Title", text: $capture.title)
                    TextField("Note or link", text: $capture.content, axis: .vertical)
                        .lineLimit(3...8)
                    TextField("Summary (optional)", text: Binding(
                        get: { capture.metadataDescription ?? "" },
                        set: { capture.metadataDescription = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                }
                Section("Organization") {
                    TextField("Collection", text: $capture.category)
                    TextField("Tags, comma separated", text: $tagsText)
                        .onChange(of: tagsText) { _, value in
                            capture.tags = value.split(separator: ",").map {
                                $0.trimmingCharacters(in: .whitespacesAndNewlines)
                                    .replacingOccurrences(of: "#", with: "")
                            }.filter { !$0.isEmpty }
                        }
                }
                Section("Attachments") {
                    if capture.attachments.isEmpty {
                        Text("No attachments").foregroundStyle(.secondary)
                    } else {
                        ForEach(capture.attachments) { attachment in
                            Label(attachment.name, systemImage: "doc")
                        }
                        .onDelete { offsets in
                            capture.attachments.remove(atOffsets: offsets)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(white: 0.06))
            .navigationTitle("Edit capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.tint(accent)
                }
            }
            .onAppear { tagsText = capture.tags.joined(separator: ", ") }
        }
        .preferredColorScheme(.dark)
    }
}
