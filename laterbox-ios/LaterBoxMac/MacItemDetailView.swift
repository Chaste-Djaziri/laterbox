// laterbox-ios/LaterBoxMac/MacItemDetailView.swift
import SwiftUI
import AppKit
import WebKit
import AVKit

struct MacItemDetailView: View {
    let item: MacInboxEntry
    let backDestination: String
    let onBack: () -> Void
    let onStar: (String, Bool) async throws -> Void
    let onKeep: (String) async throws -> Void
    let onArchive: (String) async throws -> Void
    var onRestore: ((String) async throws -> Void)? = nil
    let onDelete: (String) async throws -> Void
    var onPermanentlyDelete: ((String) async throws -> Void)? = nil
    let onReschedule: (String, Date?) async throws -> Void
    let onChecklist: (String, [MacChecklistEntry]) async throws -> Void
    let onAttachments: (String) async throws -> [MacCloudAttachment]
    let onAttachmentURL: (String) async throws -> URL

    @Environment(\.colorScheme) private var scheme
    @State private var busy = false
    @State private var errorMessage: String?
    @State private var confirmingDelete = false
    @State private var confirmingPermanentDelete = false
    @State private var scheduling = false
    @State private var selectedDate = Date().addingTimeInterval(86400)
    @State private var checklistState: [MacChecklistEntry] = []
    @State private var showingInlinePreview = false
    @State private var attachments: [MacCloudAttachment] = []
    @State private var downloadURLs: [String: URL] = [:]

    private let lime = Color(red: 230 / 255, green: 237 / 255, blue: 176 / 255)
    private var dark: Bool { scheme == .dark }
    private var surface: Color { dark ? Color(red: 38 / 255, green: 40 / 255, blue: 43 / 255) : .white }
    private var muted: Color { dark ? .white.opacity(0.6) : .black.opacity(0.55) }
    private var border: Color { dark ? .white.opacity(0.14) : .black.opacity(0.11) }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    scheduleCard
                    mainCard
                    if showingInlinePreview { inlinePreview }
                    if !attachments.isEmpty { attachmentsCard }
                    if !item.checklist.isEmpty && item.lifecycleStatus != "deleted" { tasksCard }
                    if !item.tags.isEmpty || !item.collectionNames.isEmpty { organizationCard }
                    sourceFooter
                }
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
                .padding(22)
            }
        }
        .onAppear { checklistState = item.checklist }
        .task(id: item.id) { await loadAttachments() }
        .onChange(of: item.id) { _, _ in checklistState = item.checklist }
        .confirmationDialog("Move this item to Recently Deleted?", isPresented: $confirmingDelete) {
            Button("Move to Recently Deleted", role: .destructive) {
                update {
                    try await onDelete(item.id)
                    onBack()
                }
            }
        }
        .confirmationDialog("Permanently delete this item?", isPresented: $confirmingPermanentDelete) {
            if let onPermanentlyDelete {
                Button("Delete Forever", role: .destructive) {
                    update {
                        try await onPermanentlyDelete(item.id)
                        onBack()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone, and cloud attachments will be removed.")
        }
        .sheet(isPresented: $scheduling) { schedulingSheet }
        .alert("Could not update item", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: { Text(errorMessage ?? "Please try again.") }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Label("Back to \(backDestination)", systemImage: "arrow.left")
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 13)
                    .frame(height: 36)
                    .background(surface, in: Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back to \(backDestination)")
            Spacer()
            if item.lifecycleStatus != "deleted" {
            control(item.isStarred ? "star.fill" : "star", label: item.isStarred ? "Unstar" : "Star") {
                update { try await onStar(item.id, !item.isStarred) }
            }
            if item.lifecycleStatus != "saved" {
            Button {
                update {
                    try await onKeep(item.id)
                    onBack()
                }
            } label: {
                Label("Keep", systemImage: "checkmark.circle")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.black)
                    .padding(10)
                    .background(lime, in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .disabled(busy)
            }
            if item.lifecycleStatus == "archived", let onRestore {
                control("arrow.uturn.backward", label: "Restore to Inbox") {
                    update {
                        try await onRestore(item.id)
                        onBack()
                    }
                }
            } else if item.lifecycleStatus != "archived" {
                control("archivebox", label: "Archive") {
                    update {
                        try await onArchive(item.id)
                        onBack()
                    }
                }
            }
            control("calendar", label: "Reschedule") {
                selectedDate = item.returnDate ?? Date().addingTimeInterval(86400)
                scheduling = true
            }
            control("doc.on.doc", label: "Copy") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(item.url?.absoluteString ?? item.snippet, forType: .string)
            }
            if let url = item.url {
                control("arrow.up.right.square", label: "Open source") {
                    NSWorkspace.shared.open(url)
                }
            }
            control("trash", label: "Delete") { confirmingDelete = true }
            }
            if item.lifecycleStatus == "deleted" {
                if let onRestore {
                    control("arrow.uturn.backward", label: "Restore to Inbox") {
                        update {
                            try await onRestore(item.id)
                            onBack()
                        }
                    }
                }
                if onPermanentlyDelete != nil {
                    control("trash", label: "Delete Forever") { confirmingPermanentDelete = true }
                }
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 56)
        .background(surface.opacity(0.6))
    }

    private func control(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 15)).frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
        .disabled(busy)
        .help(label)
    }

    private var scheduleCard: some View {
        HStack(spacing: 11) {
            Image(systemName: "clock")
            VStack(alignment: .leading, spacing: 4) {
                Text(item.lifecycleStatus == "deleted" ? "Recently Deleted" : item.lifecycleStatus == "archived" ? "Archived" : item.lifecycleStatus == "saved" ? "Kept in Library" : item.lifecycleStatus == "deferred" ? (item.returnDate == nil ? "Someday" : "Scheduled") : "In Inbox").font(.system(size: 12, weight: .semibold))
                if let date = item.returnDate {
                    Text((date > Date() ? "Returns " : "Returned ") + date.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 11)).foregroundStyle(muted)
                } else {
                    Text("Ready whenever you are").font(.system(size: 11)).foregroundStyle(muted)
                }
            }
            Spacer()
            if item.lifecycleStatus != "deleted" {
            Button("Reschedule") {
                selectedDate = item.returnDate ?? Date().addingTimeInterval(86400)
                scheduling = true
            }
            .buttonStyle(.plain)
            }
        }
        .padding(15)
        .background(surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(border))
    }

    private var mainCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let url = item.previewImageURL {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Rectangle().fill(lime.opacity(0.2))
                        .overlay(Image(systemName: "photo").foregroundStyle(muted))
                }
                .frame(height: 210).frame(maxWidth: .infinity).clipped()
            }
            VStack(alignment: .leading, spacing: 15) {
                HStack(spacing: 7) {
                    Label(item.source, systemImage: "globe")
                    Text("·")
                    Text(item.itemType.capitalized)
                    Spacer()
                    Text(item.date, style: .date)
                }
                .font(.system(size: 11)).foregroundStyle(muted)
                Text(item.title)
                    .font(.system(size: 27, weight: .bold))
                    .textSelection(.enabled)
                if !item.snippet.isEmpty {
                    Text(item.snippet)
                        .font(.system(size: 13))
                        .foregroundStyle(muted)
                        .textSelection(.enabled)
                }
                if let url = item.url {
                    Divider()
                    HStack {
                        Label(url.host ?? "Link", systemImage: "link")
                            .font(.system(size: 12)).foregroundStyle(muted)
                        Spacer()
                        Button { showingInlinePreview.toggle() } label: {
                            Label(showingInlinePreview ? "Hide preview" : (item.category == .media ? "Play here" : "Preview here"), systemImage: "play.rectangle")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .buttonStyle(.plain)
                        Button {
                            NSWorkspace.shared.open(url)
                        } label: {
                            Label("Open original", systemImage: "arrow.up.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.black)
                                .padding(11)
                                .background(lime, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(22)
        }
        .background(surface, in: RoundedRectangle(cornerRadius: 22))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(border, lineWidth: 1.5))
    }

    private var inlinePreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(item.category == .media ? "Play in Laterbox" : "Read in Laterbox", systemImage: "play.rectangle")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Button("Close preview") { showingInlinePreview = false }
                    .font(.system(size: 12))
                    .buttonStyle(.plain)
            }
            if let url = item.url {
                if ["mp4", "mov", "m4v", "mp3", "m4a", "wav"].contains(url.pathExtension.lowercased()) {
                    VideoPlayer(player: AVPlayer(url: url))
                        .frame(height: 300)
                } else {
                    MacEmbeddedSource(url: url)
                        .frame(height: 390)
                }
            }
        }
        .padding(17)
        .background(surface, in: RoundedRectangle(cornerRadius: 17))
        .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(border))
    }

    private var attachmentsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Attachments", systemImage: "paperclip")
                .font(.system(size: 15, weight: .semibold))
            ForEach(attachments) { attachment in
                VStack(alignment: .leading, spacing: 9) {
                    if let url = downloadURLs[attachment.id] {
                        if attachment.mime_type.hasPrefix("image/") {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFit()
                            } placeholder: {
                                ProgressView().frame(maxWidth: .infinity)
                            }
                            .frame(maxHeight: 270)
                        } else if attachment.mime_type.hasPrefix("video/") || attachment.mime_type.hasPrefix("audio/") {
                            VideoPlayer(player: AVPlayer(url: url))
                                .frame(height: attachment.mime_type.hasPrefix("audio/") ? 95 : 280)
                        }
                    }
                    HStack(spacing: 9) {
                        Image(systemName: "doc")
                        VStack(alignment: .leading, spacing: 3) {
                            Text(attachment.original_file_name)
                                .font(.system(size: 12, weight: .semibold)).lineLimit(1)
                            Text(ByteCountFormatter.string(fromByteCount: attachment.byte_size, countStyle: .file))
                                .font(.system(size: 10)).foregroundStyle(muted)
                        }
                        Spacer()
                        Button {
                            Task { await openAttachment(attachment) }
                        } label: {
                            Label("Open / Download", systemImage: "arrow.down.circle")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .background(border.opacity(0.22), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(18)
        .background(surface, in: RoundedRectangle(cornerRadius: 17))
        .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(border))
    }

    private func loadAttachments() async {
        do {
            let files = try await onAttachments(item.id)
            attachments = files
            for file in files {
                if Task.isCancelled { return }
                if let url = try? await onAttachmentURL(file.id) {
                    downloadURLs[file.id] = url
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func openAttachment(_ attachment: MacCloudAttachment) async {
        do {
            let url = try await onAttachmentURL(attachment.id)
            NSWorkspace.shared.open(url)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var tasksCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Label("Checklist", systemImage: "checklist").font(.system(size: 15, weight: .semibold))
                Spacer()
                Text("\(checklistState.filter { $0.done }.count)/\(checklistState.count)")
                    .font(.system(size: 12)).foregroundStyle(muted)
            }
            ForEach(checklistState.indices, id: \.self) { index in
                Toggle(isOn: Binding(
                    get: { checklistState[index].done },
                    set: { done in
                        checklistState[index].done = done
                        let entries = checklistState
                        update { try await onChecklist(item.id, entries) }
                    }
                )) {
                    Text(checklistState[index].title)
                        .font(.system(size: 13))
                }
                .toggleStyle(.checkbox)
                .disabled(busy)
            }
        }
        .padding(18)
        .background(surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(border))
    }

    private var organizationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Organize", systemImage: "folder")
                .font(.system(size: 14, weight: .semibold))
            if !item.collectionNames.isEmpty {
                Text("Collections: " + item.collectionNames.joined(separator: " · "))
                    .font(.system(size: 12))
            }
            if !item.tags.isEmpty {
                Text("Tags: " + item.tags.map { "#" + $0 }.joined(separator: "  "))
                    .font(.system(size: 12))
                    .foregroundStyle(muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(border))
    }

    private var sourceFooter: some View {
        HStack {
            Image(systemName: "info.circle")
            Text("Saved \(item.date.formatted(date: .abbreviated, time: .shortened))")
            Spacer()
            Text("Laterbox cloud")
        }
        .font(.system(size: 11))
        .foregroundStyle(muted)
        .padding(8)
    }

    private var schedulingSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Change return date").font(.system(size: 20, weight: .bold))
            DatePicker("Return", selection: $selectedDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
            HStack {
                Button("Someday") {
                    scheduling = false
                    update { try await onReschedule(item.id, nil); onBack() }
                }
                Spacer()
                Button("Cancel") { scheduling = false }
                Button("Schedule") {
                    let date = selectedDate
                    scheduling = false
                    update { try await onReschedule(item.id, date); onBack() }
                }
            }
        }
        .padding(25)
        .frame(width: 420)
    }

    private func update(_ operation: @escaping () async throws -> Void) {
        guard !busy else { return }
        busy = true
        Task {
            defer { busy = false }
            do { try await operation() }
            catch { errorMessage = error.localizedDescription }
        }
    }
}


private struct MacEmbeddedSource: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsAirPlayForMediaPlayback = true
        return WKWebView(frame: .zero, configuration: configuration)
    }

    func updateNSView(_ view: WKWebView, context: Context) {
        guard ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { return }
        let destination = embeddedVideoURL ?? url
        if view.url != destination {
            view.load(URLRequest(url: destination))
        }
    }

    private var embeddedVideoURL: URL? {
        guard let host = url.host?.lowercased() else { return nil }
        let id: String?
        if host == "youtu.be" {
            id = url.pathComponents.dropFirst().first
        } else if host == "youtube.com" || host.hasSuffix(".youtube.com") {
            if url.path == "/watch" {
                id = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                    .queryItems?.first(where: { $0.name == "v" })?.value
            } else if url.path.hasPrefix("/shorts/") || url.path.hasPrefix("/live/") {
                id = url.pathComponents.dropFirst(2).first
            } else { id = nil }
        } else { id = nil }
        guard let id, id.range(of: "^[A-Za-z0-9_-]{11}$", options: .regularExpression) != nil else {
            return nil
        }
        return URL(string: "https://www.youtube-nocookie.com/embed/\(id)?playsinline=1")
    }
}
