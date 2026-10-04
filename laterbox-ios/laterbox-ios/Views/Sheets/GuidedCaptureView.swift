import SwiftUI

struct GuidedCaptureView: View {
    @Binding var draft: CaptureDraft
    var save: () -> Void
    @State private var step = 0
    @State private var tagText = ""
    @State private var chooseDate = false
    @State private var date = Date().addingTimeInterval(86400)
    private let categories = ["General", "Reading", "Work", "Ideas", "Learning", "Personal"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Save an item · \(step + 1) of 4").font(.headline)
            switch step {
            case 0:
                Text("What would you like to save?")
                TextField("Paste a link or write your content", text: $draft.content, axis: .vertical).lineLimit(4...10).accessibilityIdentifier("capture.content")
            case 1:
                Text("Give it a title")
                TextField("Title", text: $draft.title).accessibilityIdentifier("capture.title")
            case 2:
                Text("Choose a category and tags")
                Picker("Format", selection: $draft.contentType) {
                    Text("Automatic").tag("")
                    ForEach(ItemContentType.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0.rawValue) }
                }
                Picker("Category", selection: $draft.category) {
                    Text("No category").tag("")
                    ForEach(categories, id: \.self) { Text($0).tag($0) }
                }
                TextField("Tags, separated by commas", text: $tagText).accessibilityIdentifier("capture.tags")
                HStack {
                    ForEach(suggestedTags, id: \.self) { tag in
                        Button(tag) {
                            let tags = tagText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                            if !tags.contains(tag) { tagText += tagText.isEmpty ? tag : ", \(tag)" }
                        }.buttonStyle(.bordered)
                    }
                }
            default:
                Text("When do you want to see it again?")
                Button("Tomorrow") { draft.returnAt = Calendar.current.date(byAdding: .day, value: 1, to: Date()) }
                Button("This weekend") { draft.returnAt = CaptureDraft.weekend() }
                Button("Choose date") { chooseDate = true; draft.returnAt = date }
                Button("No reminder") { draft.returnAt = nil; chooseDate = false }
                if chooseDate { DatePicker("Return", selection: $date).onChange(of: date) { _, value in draft.returnAt = value } }
                if let selected = draft.returnAt { Text(selected.formatted()).font(.caption) }
            }
            HStack {
                if step > 0 { Button("Back") { step -= 1 } }
                Spacer()
                Button(step == 3 ? "Save" : "Continue") {
                    if step == 0 {
                        let inferred = CaptureDraft.manual(draft.content)
                        if draft.title.isEmpty { draft.title = inferred.title }
                        if draft.tags.isEmpty { draft.tags = inferred.tags }
                        tagText = draft.tags.joined(separator: ", ")
                    }
                    if step == 2 { draft.tags = tagText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } }
                    if step == 3 { save() } else { step += 1 }
                }.buttonStyle(.borderedProminent)
                    .disabled(draft.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .task(id: draft.url) {
            guard let text = draft.url, let url = URL(string: text) else { return }
            do {
                let metadata = try await LinkMetadataLoader.load(url)
                guard !Task.isCancelled, draft.url == text else { return }
                if draft.title.isEmpty || draft.title == url.host || draft.title == text { draft.title = metadata.title ?? draft.title }
                if draft.summary.isEmpty { draft.summary = metadata.description ?? "" }
            } catch { /* Metadata is optional; manual saving stays available. */ }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
    private var suggestedTags: [String] {
        let text = draft.content.lowercased()
        return ["design", "work", "recipe", "travel", "code", "music"].filter { text.contains($0) }.prefix(3).map { $0 }
    }
}
