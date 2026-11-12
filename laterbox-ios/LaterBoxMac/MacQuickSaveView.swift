// laterbox-ios/LaterBoxMac/MacQuickSaveView.swift
import SwiftUI
import AppKit
import UniformTypeIdentifiers

private enum CaptureStyle {
    static let lime = Color(red: 230 / 255, green: 237 / 255, blue: 176 / 255)
    static let ink = Color(red: 23 / 255, green: 23 / 255, blue: 17 / 255)
    static let cream = Color(red: 248 / 255, green: 249 / 255, blue: 245 / 255)
}

struct MacQuickSaveView: View {
    private enum CaptureKind: String, CaseIterable, Identifiable {
        case link = "Link"
        case note = "Note"
        case task = "Task"
        case file = "File"

        var id: String { rawValue }
        var symbol: String {
            switch self {
            case .link: "link"
            case .note: "note.text"
            case .task: "checkmark.square"
            case .file: "paperclip"
            }
        }
        var placeholder: String {
            switch self {
            case .link: "Paste a link you want to revisit…"
            case .note: "Write down something worth remembering…"
            case .task: "What needs to get done?"
            case .file: "Add a file or write a note about it…"
            }
        }
    }

    private enum ReturnPreset: String, CaseIterable, Identifiable {
        case now = "Now"
        case laterToday = "Later today"
        case tomorrow = "Tomorrow"
        case weekend = "This weekend"
        case someday = "Someday"
        case nextWeek = "Next week"
        case custom = "Pick a date"

        var id: String { rawValue }
        var symbol: String {
            switch self {
            case .now: "tray"
            case .laterToday: "clock"
            case .tomorrow: "sunrise"
            case .weekend: "calendar"
            case .someday: "moon.stars"
            case .nextWeek: "calendar.badge.clock"
            case .custom: "calendar.badge.clock"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @FocusState private var focusedInput: Bool

    @State private var step = 0
    @State private var kind: CaptureKind = .link
    @State private var content = ""
    @State private var title = ""
    @State private var linkPreview: MacLinkPreview?
    @State private var fetchingPreview = false
    @State private var previewError: String?
    @State private var enrichmentTask: Task<Void, Never>?
    @State private var suggestedReason = ""
    @State private var didEditTitle = false
    @State private var didEditTags = false
    @State private var didEditSchedule = false
    @State private var cloudCollections: [MacCloudCollection] = []
    @State private var selectedCollectionIDs: Set<String> = []
    @State private var newCollectionName = ""
    @State private var collectionNames: [String] = []
    @State private var collectionLoadError: String?
    @State private var isLoadingCollections = false
    @State private var preset: ReturnPreset = .now
    @State private var customDate = Date().addingTimeInterval(3600)
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var attachments: [URL] = []
    private enum TaskMode: String, CaseIterable {
        case single = "Single task"
        case checklist = "Checklist"
    }
    private struct TaskEntry: Identifiable {
        let id = UUID()
        var title = ""
    }
    @State private var taskMode: TaskMode = .single
    @State private var taskTitle = ""
    @State private var taskEntries: [TaskEntry] = [TaskEntry(), TaskEntry()]
    @State private var isChoosingFiles = false
    @State private var copied = false
    @State private var errorMessage: String?

    private var dark: Bool { scheme == .dark }
    private var surface: Color {
        dark ? Color(red: 33 / 255, green: 35 / 255, blue: 38 / 255) : Color.white
    }
    private var panel: Color {
        dark ? Color(red: 42 / 255, green: 44 / 255, blue: 47 / 255) : CaptureStyle.cream
    }
    private var line: Color {
        dark ? Color.white.opacity(0.12) : Color.black.opacity(0.09)
    }
    private var muted: Color {
        dark ? Color.white.opacity(0.57) : Color.black.opacity(0.53)
    }

    private var validCapture: Bool {
        switch kind {
        case .link:
            guard let url = URL(string: content.trimmingCharacters(in: .whitespacesAndNewlines)),
                  let scheme = url.scheme?.lowercased() else { return false }
            return ["http", "https"].contains(scheme) && url.host != nil
        case .note:
            return !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .task:
            guard !taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
            return taskMode == .single || taskEntries.filter {
                !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }.count >= 2
        case .file:
            return !attachments.isEmpty
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            stepNavigation
            Rectangle().fill(line).frame(height: 1)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    if step == 0 { captureStep }
                    if step == 1 { scheduleStep }
                    if step == 2 { detailsStep }
                }
                .padding(28)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            bottomBar
        }
        .frame(width: 570, height: 595)
        .background(surface)
        .preferredColorScheme(scheme)
        .onAppear {
            focusedInput = true
            suggestDetails()
            Task { await fetchCollections() }
        }
        .onChange(of: content) { _, _ in
            suggestDetails()
            if kind == .link { schedulePreview() }
        }
        .onChange(of: kind) { _, _ in
            suggestDetails()
            if kind == .link { schedulePreview() }
        }
        .onChange(of: taskTitle) { _, _ in suggestDetails() }
        .onDisappear { enrichmentTask?.cancel() }
    }

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("Quick Save")
                    .font(.system(size: 23, weight: .bold))
                    .tracking(-0.65)
                Text("Keep something for later")
                    .font(.system(size: 12))
                    .foregroundStyle(muted)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(muted)
                    .frame(width: 32, height: 32)
                    .background(panel, in: Circle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)
        }
        .padding(.horizontal, 28)
        .padding(.top, 23)
        .padding(.bottom, 16)
    }

    private var stepNavigation: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Button {
                    guard index <= step || validCapture else { return }
                    errorMessage = nil
                    step = index
                } label: {
                    HStack(spacing: 9) {
                        Text("\(index + 1)")
                            .font(.system(size: 11, weight: .bold))
                            .frame(width: 23, height: 23)
                            .background(Color.black.opacity(0.055), in: Circle())
                        Text(["Capture", "Schedule", "Details"][index])
                            .font(.system(size: 12, weight: .semibold))
                        Spacer(minLength: 0)
                        if index < step {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                        }
                    }
                    .foregroundStyle(index == step ? CaptureStyle.ink : .primary)
                    .padding(.horizontal, 11)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(index == step ? CaptureStyle.lime : panel,
                                in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(index > step && !validCapture)
            }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 16)
    }

    private var captureStep: some View {
        VStack(alignment: .leading, spacing: 17) {
            sectionLabel("WHAT ARE YOU SAVING?")
            HStack(spacing: 10) {
                ForEach(CaptureKind.allCases) { option in
                    let selected = kind == option
                    Button {
                        kind = option
                        errorMessage = nil
                        if option == .file { openFilePicker() }
                    } label: {
                        VStack(spacing: 9) {
                            Image(systemName: option.symbol)
                                .font(.system(size: 21, weight: .medium))
                            Text(option.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(selected ? CaptureStyle.ink : muted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 83)
                        .background(selected ? CaptureStyle.lime : panel,
                                    in: RoundedRectangle(cornerRadius: 15))
                        .overlay {
                            RoundedRectangle(cornerRadius: 15)
                                .strokeBorder(selected ? CaptureStyle.lime : line)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? [.isSelected] : [])
                }
            }

            if kind == .file {
                Button { openFilePicker() } label: {
                    Label("Choose files", systemImage: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                }
                .buttonStyle(.plain)
                .background(panel, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(line))
                if !attachments.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(attachments, id: \.absoluteString) { url in
                            HStack {
                                Image(systemName: "doc")
                                Text(url.lastPathComponent).lineLimit(1)
                                Spacer()
                                Button {
                                    attachments.removeAll { $0 == url }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                }
                                .buttonStyle(.plain)
                            }
                            .font(.system(size: 12))
                            .padding(10)
                            .background(panel, in: RoundedRectangle(cornerRadius: 9))
                        }
                    }
                }
            } else if kind == .task {
                taskCapture
            } else {
                sectionLabel(kind == .link ? "LINK" : "YOUR NOTE")
                if kind == .note {
                    TextEditor(text: $content)
                        .font(.system(size: 14))
                        .scrollContentBackground(.hidden)
                        .focused($focusedInput)
                        .padding(11)
                        .frame(height: 148)
                        .background(panel, in: RoundedRectangle(cornerRadius: 13))
                        .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(line))
                        .accessibilityLabel("Your note")
                } else {
                    HStack(spacing: 11) {
                        Image(systemName: kind.symbol)
                            .foregroundStyle(muted)
                        TextField(kind.placeholder, text: $content)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14))
                            .focused($focusedInput)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 52)
                    .background(panel, in: RoundedRectangle(cornerRadius: 13))
                    .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(line))
                }
            }

            if kind == .link {
                Label("Paste a website or article URL. Preview loads automatically.", systemImage: "info.circle")
                    .font(.system(size: 11))
                    .foregroundStyle(muted)
            }

            if kind == .link { linkPreviewCard }
            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
            }
        }
    }

    private var taskCapture: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("TASK FORMAT")
            HStack(spacing: 9) {
                ForEach(TaskMode.allCases, id: \.self) { mode in
                    Button {
                        taskMode = mode
                        errorMessage = nil
                    } label: {
                        Label(mode.rawValue, systemImage: mode == .single ? "checkmark.square" : "list.bullet.rectangle")
                            .font(.system(size: 12, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .foregroundStyle(taskMode == mode ? CaptureStyle.ink : .primary)
                            .background(taskMode == mode ? CaptureStyle.lime : panel,
                                        in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }

            sectionLabel(taskMode == .checklist ? "GROUP TITLE" : "TASK TITLE")
            TextField(taskMode == .checklist ? "Name this task group…" : "What needs to get done?", text: $taskTitle)
                .font(.system(size: 14))
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(panel, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(line))
                .accessibilityIdentifier("mac.quicksave.taskTitle")

            if taskMode == .checklist {
                HStack {
                    sectionLabel("TASKS")
                    Spacer()
                    Text("At least two")
                        .font(.system(size: 11))
                        .foregroundStyle(muted)
                }

                ForEach($taskEntries) { $entry in
                    HStack(spacing: 9) {
                        Image(systemName: "square").foregroundStyle(muted)
                        TextField("Task name…", text: $entry.title)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                        Button {
                            taskEntries.removeAll { $0.id == entry.id }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 11))
                                .foregroundStyle(muted)
                        }
                        .buttonStyle(.plain)
                        .disabled(taskEntries.count <= 2)
                        .help("Remove task")
                    }
                    .padding(.horizontal, 13)
                    .frame(height: 42)
                    .background(panel, in: RoundedRectangle(cornerRadius: 11))
                    .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(line))
                }

                Button {
                    taskEntries.append(TaskEntry())
                } label: {
                    Label("Add another task", systemImage: "plus.circle")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // Avoid stacking SwiftUI fileImporter sheets on the Quick Save sheet:
    // NSOpenPanel opens asynchronously and keeps the current draft intact.
    private func openFilePicker() {
        guard !isChoosingFiles else { return }
        isChoosingFiles = true
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.prompt = "Attach"
        panel.begin { response in
            Task { @MainActor in
                isChoosingFiles = false
                guard response == .OK else { return }
                for url in panel.urls where !attachments.contains(url) {
                    attachments.append(url)
                }
                errorMessage = nil
            }
        }
    }

    private var scheduleStep: some View {
        VStack(alignment: .leading, spacing: 17) {
            sectionLabel("WHEN SHOULD IT RETURN?")

            HStack(spacing: 12) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 20))
                    .foregroundStyle(CaptureStyle.ink)
                    .frame(width: 43, height: 43)
                    .background(CaptureStyle.lime, in: RoundedRectangle(cornerRadius: 13))
                VStack(alignment: .leading, spacing: 4) {
                    Text(preset.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                    Text(preset == .someday ? "Keep it for whenever you're ready." :
                            preset == .now ? "Leave it in your inbox." : "Bring it back when the time comes.")
                        .font(.system(size: 11))
                        .foregroundStyle(muted)
                }
                Spacer()
            }
            .padding(14)
            .background(panel, in: RoundedRectangle(cornerRadius: 15))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(ReturnPreset.allCases) { option in
                    let selected = preset == option
                    Button {
                        preset = option
                        didEditSchedule = true
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: option.symbol)
                                .font(.system(size: 18))
                            Text(option.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 79)
                        .foregroundStyle(selected ? CaptureStyle.ink : .primary)
                        .background(selected ? CaptureStyle.lime : panel, in: RoundedRectangle(cornerRadius: 13))
                        .overlay {
                            RoundedRectangle(cornerRadius: 13)
                                .strokeBorder(selected ? CaptureStyle.lime : line)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            if !suggestedReason.isEmpty {
                Label(suggestedReason, systemImage: "sparkles")
                    .font(.system(size: 11))
                    .foregroundStyle(muted)
            }
            if preset == .custom {
                DatePicker("Return date", selection: $customDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .font(.system(size: 13))
                    .padding(14)
                    .background(panel, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var detailsStep: some View {
        VStack(alignment: .leading, spacing: 17) {
            sectionLabel("FINISH THE DETAILS")
            VStack(alignment: .leading, spacing: 7) {
                Text(kind == .task ? "Description (optional)" : "Title (optional)")
                    .font(.system(size: 12, weight: .medium))
                TextField(kind == .task ? "Add a short description…" : "Give this a name…", text: Binding(get: { title }, set: { title = $0; didEditTitle = true }))
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(panel, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(line))
            }

            sectionLabel("TAGS")
            if !tags.isEmpty {
                Text("Suggested from your capture · edit freely")
                    .font(.system(size: 11))
                    .foregroundStyle(muted)
            }
            HStack(spacing: 9) {
                TextField("Add a tag…", text: $newTag)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .onSubmit(addTag)
                Button(action: addTag) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 29, height: 29)
                }
                .buttonStyle(.plain)
                .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(panel, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(line))

            if !tags.isEmpty {
                FlowTagList(tags: tags) { tag in
                    tags.removeAll { $0 == tag }
                    didEditTags = true
                }
            }

            collectionPicker
            VStack(alignment: .leading, spacing: 8) {
                Label("Ready to keep", systemImage: "checkmark.circle")
                    .font(.system(size: 13, weight: .semibold))
                Text(summary)
                    .font(.system(size: 12))
                    .foregroundStyle(muted)
                    .lineLimit(3)
                Label("Mac cloud saving is not connected yet. Copy your draft and save it on Laterbox Web.", systemImage: "info.circle")
                    .font(.system(size: 11))
                    .foregroundStyle(muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 5)
            }
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(panel, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var summary: String {
        let text = kind == .task ? taskTitle : (title.isEmpty ? content : title)
        if kind == .file { return attachments.map(\.lastPathComponent).joined(separator: ", ") }
        return kind == .task && taskMode == .checklist ? "\(text) · \(taskEntries.filter { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count) tasks" : (text.isEmpty ? kind.rawValue : text)
    }

    private func addTag() {
        let value = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard !value.isEmpty, !tags.contains(where: { $0.caseInsensitiveCompare(value) == .orderedSame }) else { return }
        tags.append(value)
        didEditTags = true
        newTag = ""
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            if step > 0 {
                Button { step -= 1 } label: {
                    Label("Back", systemImage: "arrow.left")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(height: 37)
                }
                .buttonStyle(.plain)
            } else {
                Button("Cancel") { dismiss() }
                    .font(.system(size: 13))
                    .buttonStyle(.plain)
            }

            Spacer()

            if step == 2 {
                Button {
                    copyDraft()
                } label: {
                    Label(copied ? "Copied" : "Copy draft", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(CaptureStyle.ink)
                        .padding(.horizontal, 19)
                        .frame(height: 40)
                        .background(CaptureStyle.lime, in: RoundedRectangle(cornerRadius: 11))
                }
                .buttonStyle(.plain)
                Link(destination: URL(string: "https://laterbox.dev/inbox")!) {
                    Label("Open Web", systemImage: "arrow.up.right")
                        .font(.system(size: 13))
                }
            } else {
                Button {
                    if step == 0 && !validCapture {
                        errorMessage = kind == .link ? "Enter a valid http or https URL." :
                            kind == .file ? "Choose at least one file to continue." : kind == .task ? (taskMode == .checklist ? "Add a group title and at least two named tasks." : "Give your task a title.") : "Add some content to continue."
                        return
                    }
                    errorMessage = nil
                    step += 1
                } label: {
                    HStack(spacing: 8) {
                        Text("Continue")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(CaptureStyle.ink)
                    .padding(.horizontal, 19)
                    .frame(height: 40)
                    .background(CaptureStyle.lime, in: RoundedRectangle(cornerRadius: 11))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 18)
        .background(surface)
        .overlay(alignment: .top) { line.frame(height: 1) }
    }

    private func copyDraft() {
        let schedule = preset == .custom ? customDate.formatted(date: .abbreviated, time: .shortened) : preset.rawValue
        let checklist = taskEntries
            .filter { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .enumerated()
            .map { "\($0.offset + 1). \($0.element.title)" }
            .joined(separator: "\n")
        let draft = [
            "Type: \(kind == .task && taskMode == .checklist ? "Task checklist" : kind.rawValue)",
            kind == .task ? "Title: \(taskTitle)" : (title.isEmpty ? nil : "Title: \(title)"),
            kind == .task && taskMode == .checklist ? "Tasks:\n" + checklist : nil,
            kind == .task && !title.isEmpty ? "Description: \(title)" : nil,
            kind == .task || content.isEmpty ? nil : "Content: \(content)",
            attachments.isEmpty ? nil : "Files: \(attachments.map(\.lastPathComponent).joined(separator: ", "))",
            "Schedule: \(schedule)",
            selectedCollections.isEmpty ? nil : "Collections: \(selectedCollections.joined(separator: ", "))",
            tags.isEmpty ? nil : "Tags: \(tags.map { "#" + $0 }.joined(separator: " "))"
        ].compactMap { $0 }.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(draft, forType: .string)
        copied = true
    }


    private var selectedCollections: [String] {
        cloudCollections.filter { selectedCollectionIDs.contains($0.id) }.map(\.name) + collectionNames
    }

    private var collectionPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionLabel("COLLECTIONS")
                Spacer()
                if isLoadingCollections { ProgressView().controlSize(.small) }
            }
            if let collectionLoadError {
                Text(collectionLoadError).font(.system(size: 11)).foregroundStyle(muted)
            }
            if !cloudCollections.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 142), spacing: 8)], spacing: 8) {
                    ForEach(cloudCollections) { collection in
                        let selected = selectedCollectionIDs.contains(collection.id)
                        Button {
                            if selected { selectedCollectionIDs.remove(collection.id) }
                            else { selectedCollectionIDs.insert(collection.id) }
                        } label: {
                            HStack(spacing: 7) {
                                Image(systemName: selected ? "checkmark.circle.fill" : "folder")
                                Text(collection.name).lineLimit(1)
                                Spacer(minLength: 0)
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(selected ? CaptureStyle.ink : .primary)
                            .padding(.horizontal, 11)
                            .frame(height: 36)
                            .background(selected ? CaptureStyle.lime : panel, in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            ForEach(collectionNames, id: \.self) { name in
                HStack {
                    Label(name, systemImage: "folder.badge.plus")
                    Spacer()
                    Button { collectionNames.removeAll { $0 == name } } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                }
                .font(.system(size: 12))
                .padding(9)
                .background(panel, in: RoundedRectangle(cornerRadius: 10))
            }
            HStack {
                Image(systemName: "folder.badge.plus").foregroundStyle(muted)
                TextField("New collection name…", text: $newCollectionName)
                    .textFieldStyle(.plain).font(.system(size: 12))
                    .onSubmit(addCollection)
                Button(action: addCollection) { Image(systemName: "plus.circle.fill") }
                    .buttonStyle(.plain)
                    .disabled(newCollectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 12)
            .frame(height: 43)
            .background(panel, in: RoundedRectangle(cornerRadius: 11))
            Text("Selections are included in the draft. New collections will be created when Mac cloud saving is connected.")
                .font(.system(size: 10)).foregroundStyle(muted)
        }
    }

    private func addCollection() {
        let name = newCollectionName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty,
              !collectionNames.contains(where: { $0.caseInsensitiveCompare(name) == .orderedSame }),
              !cloudCollections.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) else { return }
        collectionNames.append(name)
        newCollectionName = ""
    }

    private func fetchCollections() async {
        isLoadingCollections = true
        defer { isLoadingCollections = false }
        do {
            cloudCollections = try await MacCollectionLookup.fetch()
            collectionLoadError = nil
        } catch {
            collectionLoadError = "Existing collections are unavailable. You can still add names to your draft."
        }
    }

    private func suggestDetails() {
        let value = kind == .task ? taskTitle : (linkPreview?.title ?? "") + " " +
            (linkPreview?.description ?? "") + " " + (kind == .link ? "" : content)
        let source = kind == .link && linkPreview == nil ? (URL(string: content)?.host ?? "") : value
        let suggestion = MacCaptureSuggestions.returnSuggestion(for: source, kind: kind.rawValue)
        if !didEditSchedule, let matching = ReturnPreset.allCases.first(where: { $0.rawValue == suggestion.preset }) {
            preset = matching
        }
        suggestedReason = suggestion.reason
        if !didEditTags {
            tags = MacCaptureSuggestions.tags(for: value, kind: kind.rawValue)
        }
        if !didEditTitle {
            if kind == .link {
                title = linkPreview?.title ?? URL(string: content)?.host ?? ""
            } else if kind == .note {
                title = String(content.split(separator: "\n", maxSplits: 1).first ?? "").prefix(90).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if kind == .file {
                title = attachments.first?.deletingPathExtension().lastPathComponent ?? ""
            }
        }
    }

    private func schedulePreview() {
        enrichmentTask?.cancel()
        linkPreview = nil
        previewError = nil
        fetchingPreview = false
        guard kind == .link, let url = URL(string: content.trimmingCharacters(in: .whitespacesAndNewlines)),
              url.scheme?.lowercased() == "https", url.host != nil else { return }
        enrichmentTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            fetchingPreview = true
            defer { fetchingPreview = false }
            do {
                let preview = try await MacCaptureSuggestions.fetchLink(url)
                guard !Task.isCancelled, content.trimmingCharacters(in: .whitespacesAndNewlines) == url.absoluteString else { return }
                linkPreview = preview
                suggestDetails()
            } catch {
                guard !Task.isCancelled else { return }
                previewError = "Preview unavailable for this site. You can still save the link."
            }
        }
    }

    private var linkPreviewCard: some View {
        Group {
            if fetchingPreview {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Looking up page details…")
                }
                .font(.system(size: 12)).foregroundStyle(muted)
            } else if let preview = linkPreview {
                HStack(alignment: .top, spacing: 11) {
                    Image(systemName: "globe")
                        .font(.system(size: 19))
                        .foregroundStyle(CaptureStyle.ink)
                        .frame(width: 40, height: 40)
                        .background(CaptureStyle.lime, in: RoundedRectangle(cornerRadius: 11))
                    VStack(alignment: .leading, spacing: 5) {
                        Text(preview.title).font(.system(size: 13, weight: .semibold))
                        Text(preview.domain).font(.system(size: 11)).foregroundStyle(muted)
                        if !preview.description.isEmpty {
                            Text(preview.description).font(.system(size: 11))
                                .foregroundStyle(muted).lineLimit(3)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(13).background(panel, in: RoundedRectangle(cornerRadius: 13))
            } else if let previewError {
                Label(previewError, systemImage: "info.circle")
                    .font(.system(size: 11)).foregroundStyle(muted)
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .tracking(1.2)
            .foregroundStyle(muted)
    }
}

private struct FlowTagList: View {
    let tags: [String]
    let onRemove: (String) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 95), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Button { onRemove(tag) } label: {
                    HStack(spacing: 5) {
                        Text("#\(tag)").lineLimit(1)
                        Image(systemName: "xmark").font(.system(size: 9))
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background(Color.primary.opacity(0.07), in: Capsule())
                }
                .buttonStyle(.plain)
                .help("Remove \(tag)")
            }
        }
    }
}
