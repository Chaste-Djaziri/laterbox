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
        case custom = "Pick a date"

        var id: String { rawValue }
        var symbol: String {
            switch self {
            case .now: "tray"
            case .laterToday: "clock"
            case .tomorrow: "sunrise"
            case .weekend: "calendar"
            case .someday: "moon.stars"
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
    @State private var preset: ReturnPreset = .now
    @State private var customDate = Date().addingTimeInterval(3600)
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var attachments: [URL] = []
    @State private var showFileImporter = false
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
        case .note, .task:
            return !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .file:
            return !attachments.isEmpty
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Divider().overlay(line)
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
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
            switch result {
            case .success(let urls):
                attachments.append(contentsOf: urls.filter { url in
                    !attachments.contains(url)
                })
                errorMessage = nil
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
        .onAppear { focusedInput = true }
    }

    private var topBar: some View {
        HStack(alignment: .center) {
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
            .help("Close")
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
        .overlay(alignment: .bottom) {
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    HStack(spacing: 5) {
                        Text("\(index + 1)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                        Text(["Capture", "Schedule", "Details"][index])
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(index == step ? CaptureStyle.ink : (index < step ? CaptureStyle.ink : muted))
                    .padding(.horizontal, 11)
                    .frame(height: 26)
                    .background(index == step ? CaptureStyle.lime : (index < step ? CaptureStyle.lime.opacity(0.55) : panel),
                                in: Capsule())
                }
            }
            .offset(y: 16)
        }
        .padding(.bottom, 15)
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
                        if option == .file { showFileImporter = true }
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
                Button { showFileImporter = true } label: {
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
            } else {
                sectionLabel(kind == .link ? "LINK" : kind == .task ? "TASK" : "YOUR NOTE")
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
                Label("Paste a website or article URL.", systemImage: "info.circle")
                    .font(.system(size: 11))
                    .foregroundStyle(muted)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
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
                    Button { preset = option } label: {
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
                Text("Title (optional)")
                    .font(.system(size: 12, weight: .medium))
                TextField("Give this a name…", text: $title)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(panel, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(line))
            }

            sectionLabel("TAGS")
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
                }
            }

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
        let text = title.isEmpty ? content : title
        if kind == .file { return attachments.map(\.lastPathComponent).joined(separator: ", ") }
        return text.isEmpty ? kind.rawValue : text
    }

    private func addTag() {
        let value = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard !value.isEmpty, !tags.contains(where: { $0.caseInsensitiveCompare(value) == .orderedSame }) else { return }
        tags.append(value)
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
                            kind == .file ? "Choose at least one file to continue." : "Add some content to continue."
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
        let draft = [
            "Type: \(kind.rawValue)",
            title.isEmpty ? nil : "Title: \(title)",
            content.isEmpty ? nil : "Content: \(content)",
            attachments.isEmpty ? nil : "Files: \(attachments.map(\.lastPathComponent).joined(separator: ", "))",
            "Schedule: \(schedule)",
            tags.isEmpty ? nil : "Tags: \(tags.map { "#" + $0 }.joined(separator: " "))"
        ].compactMap { $0 }.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(draft, forType: .string)
        copied = true
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
