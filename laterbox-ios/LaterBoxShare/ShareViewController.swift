import UIKit
import SwiftUI
import UniformTypeIdentifiers
import UserNotifications
import PDFKit

@objc(ShareViewController)
final class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        let model = ShareCaptureModel(context: extensionContext)
        let host = UIHostingController(rootView: ShareCaptureView(model: model).preferredColorScheme(.dark))
        addChild(host)
        view.addSubview(host.view)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        host.didMove(toParent: self)
        Task { await model.load() }
    }
}

struct ShareChatMessage: Identifiable, Equatable {
    let id: UUID
    let text: String
    let isUser: Bool
    let timestamp: Date

    init(id: UUID = UUID(), text: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

@MainActor final class ShareCaptureModel: ObservableObject {
    @Published var capture = SharedCapture()
    @Published var messages: [ShareChatMessage] = []
    @Published var loading = true
    @Published var saving = false
    @Published var saved = false
    @Published var error: String?
    @Published var needsReturnDate = false
    @Published var isBlankMode = false

    let context: NSExtensionContext?

    init(context: NSExtensionContext?) { self.context = context }

    func load() async {
        loading = true
        defer { loading = false }

        var detectedUrl: String?
        for item in context?.inputItems as? [NSExtensionItem] ?? [] {
            for provider in item.attachments ?? [] {
                // Some share sources expose images only as data, while their
                // URL representation is just a filename. Capture the bytes
                // first so the item receives a real attachment and can sync
                // it to cloud storage.
                if let imageType = provider.registeredTypeIdentifiers.first(where: {
                    guard let type = UTType($0) else { return false }
                    return type.conforms(to: .image) ||
                        (type.conforms(to: .data) && !type.conforms(to: .text) && !type.conforms(to: .url))
                }) {
                    let data: Data? = await withCheckedContinuation { continuation in
                        _ = provider.loadDataRepresentation(forTypeIdentifier: imageType) { data, _ in
                            continuation.resume(returning: data)
                        }
                    }
                    if let data {
                        let ext = UTType(imageType)?.preferredFilenameExtension ?? "data"
                        let temp = FileManager.default.temporaryDirectory
                            .appendingPathComponent("share-\(UUID().uuidString).\(ext)")
                        if (try? data.write(to: temp)) != nil,
                           let attachment = try? SharedCaptureStore.copyFile(temp, type: imageType) {
                            try? FileManager.default.removeItem(at: temp)
                            capture.attachments.append(attachment)
                            continue
                        }
                        try? FileManager.default.removeItem(at: temp)
                    }
                }
                if provider.canLoadObject(ofClass: URL.self) {
                    let loadedUrl: URL? = await withCheckedContinuation { continuation in
                        _ = provider.loadObject(ofClass: URL.self) { obj, _ in
                            continuation.resume(returning: obj)
                        }
                    }
                    if let url = loadedUrl {
                        if url.isFileURL {
                            let ext = url.pathExtension.isEmpty ? "data" : url.pathExtension
                            let typeId = UTType(filenameExtension: ext)?.identifier ?? UTType.item.identifier
                            if let attachment = try? SharedCaptureStore.copyFile(url, type: typeId) {
                                capture.attachments.append(attachment)
                                continue
                            }
                        } else {
                            detectedUrl = url.absoluteString
                            capture.content += url.absoluteString + "\n"
                            continue
                        }
                    }
                }
                if provider.canLoadObject(ofClass: String.self) {
                    let loadedText: String? = await withCheckedContinuation { continuation in
                        _ = provider.loadObject(ofClass: String.self) { obj, _ in
                            continuation.resume(returning: obj)
                        }
                    }
                    if let text = loadedText {
                        capture.content += text + "\n"
                        if detectedUrl == nil,
                           let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue),
                           let match = detector.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                           let matchUrl = match.url {
                            detectedUrl = matchUrl.absoluteString
                        }
                        continue
                    }
                }
                guard let type = provider.registeredTypeIdentifiers.first else { continue }
                let attachment: SharedAttachment? = await withCheckedContinuation { continuation in
                    provider.loadFileRepresentation(forTypeIdentifier: type) { url, error in
                        guard let url, error == nil else {
                            continuation.resume(returning: nil)
                            return
                        }
                        do {
                            let copied = try SharedCaptureStore.copyFile(url, type: type)
                            continuation.resume(returning: copied)
                        } catch {
                            continuation.resume(returning: nil)
                        }
                    }
                }
                if let attachment {
                    capture.attachments.append(attachment)
                }
            }
        }

        let isBlank = capture.title.isEmpty && capture.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && capture.attachments.isEmpty
        isBlankMode = isBlank

        if isBlank {
            let greeting = "Quick Save: What would you like to save to LaterBox? Add a note, idea, or paste a link."
            messages.append(ShareChatMessage(text: greeting, isUser: false))
            needsReturnDate = false
            return
        }

        if capture.title.isEmpty {
            capture.title = capture.attachments.first?.name ?? String(capture.content.trimmingCharacters(in: .whitespacesAndNewlines).prefix(100))
        }
        if capture.content.isEmpty && !capture.title.isEmpty {
            capture.content = capture.title
        }

        // Inbuilt enrichment worker for web links & video embeds
        if let detectedUrl {
            await enrichIfLink(detectedUrl)
        }

        // Deterministic classification & contextual tags
        processLocalClassification()

        let tagSummary = capture.tags.isEmpty ? "" : " with tags " + capture.tags.prefix(3).map { "#\($0)" }.joined(separator: " ")
        let question = "I've drafted ‘\(capture.title)’\(tagSummary). When would you like to see it again?"
        messages.append(ShareChatMessage(text: question, isUser: false))
        needsReturnDate = true
    }

    private func isGenericTitle(_ title: String?) -> Bool {
        guard let raw = title?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return true }
        let stripped = raw.trimmingCharacters(in: CharacterSet(charactersIn: "-–—|: •\t\n\r"))
        let lower = stripped.lowercased()
        return lower.isEmpty ||
               lower == "youtube" ||
               lower == "- youtube" ||
               (lower.hasSuffix("youtube") && lower.count <= 14) ||
               lower == "video playlist" ||
               lower.contains("video playlist") ||
               lower == "untitled" ||
               lower.hasPrefix("http://") ||
               lower.hasPrefix("https://") ||
               lower == "watch" ||
               lower == "watch video" ||
               lower == "before you continue to youtube" ||
               lower == "vimeo" ||
               lower == "spotify" ||
               lower == "soundcloud"
    }

    private func cleanTitle(_ title: String?) -> String? {
        guard let raw = title?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return nil }
        if isGenericTitle(raw) { return nil }
        var cleaned = raw
        for suffix in [" - YouTube", " | YouTube", " – YouTube", " — YouTube", " - Vimeo", " | Vimeo", " on Spotify"] {
            if cleaned.hasSuffix(suffix) {
                cleaned = String(cleaned.dropLast(suffix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return isGenericTitle(cleaned) ? nil : cleaned
    }

    private func isGenericDescription(_ desc: String?) -> Bool {
        guard let raw = desc?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return true }
        return raw.contains("enjoy the videos and music you love") ||
               raw.contains("upload original content") ||
               raw.contains("share it all with friends, family")
    }

    private func processLocalClassification() {
        if let cleaned = cleanTitle(capture.title), !isGenericTitle(cleaned) {
            capture.title = cleaned
        }

        let host = capture.content.lowercased()
        let site = (capture.siteName ?? "").lowercased()
        let isVideo = site.contains("youtube") || site.contains("vimeo") || host.contains("youtube.com") || host.contains("youtu.be") || host.contains("vimeo.com") || host.contains("tiktok.com") || capture.tags.contains("video")
        let isAudio = site.contains("spotify") || site.contains("soundcloud") || host.contains("spotify.com") || host.contains("soundcloud.com") || capture.tags.contains("audio") || capture.tags.contains("podcast")
        let hasFiles = !capture.attachments.isEmpty

        if capture.category.isEmpty {
            if isVideo {
                capture.category = "Watch Later"
            } else if isAudio {
                capture.category = "Listen Later"
            } else if hasFiles {
                capture.category = "Documents"
            } else if host.contains("http://") || host.contains("https://") {
                capture.category = "Reading"
            } else {
                capture.category = "Inbox"
            }
        }

        var inferredTags = capture.tags
        if isVideo && !inferredTags.contains("video") {
            inferredTags.append("video")
        }
        if isAudio && !inferredTags.contains("audio") {
            inferredTags.append("audio")
        }

        // Detect tags from content #hashtags if present
        if let regex = try? NSRegularExpression(pattern: "#([\\w\\p{Unified_Ideograph}\\p{Hiragana}\\p{Katakana}]+)", options: []) {
            let fullText = "\(capture.title) \(capture.content)"
            let matches = regex.matches(in: fullText, range: NSRange(fullText.startIndex..., in: fullText))
            for match in matches {
                if let range = Range(match.range(at: 1), in: fullText) {
                    let tag = String(fullText[range]).lowercased()
                    if tag.count >= 2 && tag.count < 30 {
                        inferredTags.append(tag)
                    }
                }
            }
        }

        let junkTags: Set<String> = [
            "sharing", "camera phone", "video phone", "free", "upload", "playlist", "video playlist",
            "youtube", "watch", "vimeo", "spotify", "http", "https", "www", "untitled"
        ]
        let cleanedTags = inferredTags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "") }
            .filter { $0.count >= 2 && $0.count < 40 && !junkTags.contains($0.lowercased()) }

        capture.tags = Array(Set(cleanedTags)).sorted()
    }

    private func enrichIfLink(_ rawUrlString: String) async {
        guard let url = URL(string: rawUrlString.trimmingCharacters(in: .whitespacesAndNewlines)),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme) else { return }

        var oembedTitle: String?
        var oembedAuthor: String?
        var oembedThumb: String?
        var oembedSite = "Web"

        // Fast-path direct oEmbed for YouTube/Vimeo to get authentic video title & author
        let host = url.host?.lowercased() ?? ""
        if host.contains("youtube.com") || host == "youtu.be" || host.contains("vimeo.com") {
            oembedSite = host.contains("vimeo") ? "Vimeo" : "YouTube"
            var oembedUrlString: String?
            if let encoded = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                if host.contains("vimeo") {
                    oembedUrlString = "https://vimeo.com/api/oembed.json?url=\(encoded)"
                } else {
                    oembedUrlString = "https://www.youtube.com/oembed?url=\(encoded)&format=json"
                }
            }
            if let oembedUrlString, let oembedUrl = URL(string: oembedUrlString) {
                var ytReq = URLRequest(url: oembedUrl)
                ytReq.timeoutInterval = 5
                if let (ytData, ytResp) = try? await URLSession.shared.data(for: ytReq),
                   (ytResp as? HTTPURLResponse)?.statusCode == 200,
                   let ytJson = try? JSONSerialization.jsonObject(with: ytData) as? [String: Any] {
                    if let rawTitle = (ytJson["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !rawTitle.isEmpty {
                        oembedTitle = cleanTitle(rawTitle) ?? rawTitle
                    }
                    if let author = (ytJson["author_name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !author.isEmpty {
                        oembedAuthor = author
                    }
                    if let thumb = (ytJson["thumbnail_url"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !thumb.isEmpty {
                        oembedThumb = thumb.replacingOccurrences(of: "/hqdefault.jpg", with: "/mqdefault.jpg")
                                           .replacingOccurrences(of: "/sddefault.jpg", with: "/mqdefault.jpg")
                    }
                }
            }
        }

        if let oembedTitle, !isGenericTitle(oembedTitle) {
            capture.title = oembedTitle
        }
        if let oembedAuthor {
            capture.siteName = oembedSite
            capture.metadataDescription = "Video by \(oembedAuthor) on \(oembedSite)"
            let junkTags: Set<String> = ["sharing", "camera phone", "video phone", "free", "upload", "playlist", "video playlist", "youtube"]
            let parts = capture.title.components(separatedBy: CharacterSet(charactersIn: "|-:–—[]()•\""))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .filter { $0.count > 2 && $0.count < 35 && !junkTags.contains($0) }
            capture.tags = Array(Set(capture.tags.filter { !junkTags.contains($0) } + parts + [oembedAuthor.lowercased(), "video", oembedSite.lowercased()])).sorted()
        }
        if let oembedThumb {
            capture.previewImageUrl = oembedThumb
        }

        var request = URLRequest(url: URL(string: "https://laterbox.dev/api/enrich")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 7
        let body = ["url": url.absoluteString]
        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else { return }
        request.httpBody = httpBody

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

            let rawTitle = (json["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let site = ((json["siteName"] ?? json["site_name"]) as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let desc = (json["description"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let img = ((json["previewImageUrl"] ?? json["preview_image_url"]) as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let keywords = (json["keywords"] as? [String]) ?? []

            let cleanedTitle = cleanTitle(rawTitle)
            let currentIsGeneric = isGenericTitle(capture.title) || capture.title == rawUrlString
            if let cleanedTitle, !isGenericTitle(cleanedTitle) {
                if currentIsGeneric {
                    capture.title = cleanedTitle
                }
            } else if currentIsGeneric, let oembedTitle, !isGenericTitle(oembedTitle) {
                capture.title = oembedTitle
            }

            if let site, !site.isEmpty { capture.siteName = site }
            if let desc, !desc.isEmpty, !isGenericDescription(desc) {
                capture.metadataDescription = desc
            } else if capture.metadataDescription == nil || isGenericDescription(capture.metadataDescription) {
                if let oembedAuthor {
                    capture.metadataDescription = "Video by \(oembedAuthor) on \(capture.siteName ?? oembedSite)"
                }
            }
            if let img, !img.isEmpty, capture.previewImageUrl == nil || capture.previewImageUrl?.isEmpty == true {
                let cleanImg = img.replacingOccurrences(of: "/hqdefault.jpg", with: "/mqdefault.jpg")
                                  .replacingOccurrences(of: "/sddefault.jpg", with: "/mqdefault.jpg")
                capture.previewImageUrl = cleanImg
            }
            if !keywords.isEmpty {
                let junkTags: Set<String> = ["sharing", "camera phone", "video phone", "free", "upload", "playlist", "video playlist", "youtube"]
                let filteredCurrent = capture.tags.filter { !junkTags.contains($0.lowercased()) }
                let filteredKeywords = keywords.map { $0.lowercased() }.filter { !junkTags.contains($0) }
                capture.tags = Array(Set(filteredCurrent + filteredKeywords)).sorted()
            }
        } catch {
            // Non-critical, fallback safely
        }
    }

    func scheduleAndSave(date: Date?, optionLabel: String) async {
        messages.append(ShareChatMessage(text: optionLabel, isUser: true))
        capture.returnAt = date
        needsReturnDate = false
        await save()
    }

    func save() async {
        if capture.content.isEmpty && !capture.title.isEmpty {
            capture.content = capture.title
        }
        guard !saving, (!capture.content.isEmpty || !capture.attachments.isEmpty) else { return }
        saving = true
        defer { saving = false }
        do {
            try SharedCaptureStore.save(capture)
            saved = true
            _ = try? await ReturnNotification.update(id: capture.id, title: capture.title, description: capture.metadataDescription ?? capture.content, date: capture.returnAt)
            let desc = capture.returnAt.map { "for \($0.formatted(date: .abbreviated, time: .shortened))" } ?? "with no reminder (inbox)"
            messages.append(ShareChatMessage(text: "Scheduled ‘\(capture.title)’ \(desc). Saved to your LaterBox vault.", isUser: false))
        } catch {
            self.error = "Save failed: \(error.localizedDescription)"
        }
    }

    func undo() {
        messages.append(ShareChatMessage(text: "Undo save", isUser: true))
        do {
            let file = try SharedCaptureStore.root().appendingPathComponent("Captures/\(capture.id).json")
            if FileManager.default.fileExists(atPath: file.path) {
                try FileManager.default.removeItem(at: file)
            }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [capture.id])
            saved = false
            needsReturnDate = false
            messages.append(ShareChatMessage(text: "Removed ‘\(capture.title)’ from your vault. You can save again whenever you're ready.", isUser: false))
        } catch {
            self.error = error.localizedDescription
        }
    }

    func saveBlankItem(title: String, content: String, category: String, tags: [String], returnAt: Date?) async {
        let cleanContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        var cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanTitle.isEmpty {
            if let firstLine = cleanContent.components(separatedBy: .newlines).first, !firstLine.isEmpty {
                cleanTitle = String(firstLine.prefix(80))
            } else {
                cleanTitle = "Quick Note"
            }
        }
        capture.title = cleanTitle
        capture.content = cleanContent.isEmpty ? cleanTitle : cleanContent
        capture.category = category.isEmpty ? "Inbox" : category
        capture.tags = tags
        capture.returnAt = returnAt

        // Detect if link
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue),
           let match = detector.firstMatch(in: capture.content, range: NSRange(capture.content.startIndex..., in: capture.content)),
           let matchUrl = match.url {
            await enrichIfLink(matchUrl.absoluteString)
            processLocalClassification()
        }

        await save()
    }

    func reset() {
        messages = []
        saved = false
        error = nil
        if isBlankMode {
            needsReturnDate = false
            let greeting = "Quick Save: What would you like to save to LaterBox? Add a note, idea, or paste a link."
            messages.append(ShareChatMessage(text: greeting, isUser: false))
        } else {
            needsReturnDate = true
            let tagSummary = capture.tags.isEmpty ? "" : " with tags " + capture.tags.prefix(3).map { "#\($0)" }.joined(separator: " ")
            let question = "I've drafted ‘\(capture.title)’\(tagSummary). When would you like to see it again?"
            messages.append(ShareChatMessage(text: question, isUser: false))
        }
    }
}

private struct ShareAttachmentPreviewCard: View {
    let attachment: SharedAttachment
    @State private var preview: UIImage?
    @State private var fileSize: Int64 = 0
    @State private var isPDF = false

    private var type: UTType {
        UTType(attachment.typeIdentifier) ?? UTType(filenameExtension: (attachment.name as NSString).pathExtension) ?? .item
    }

    private var kindLabel: String {
        if type.conforms(to: .image) { return "Image" }
        if type.conforms(to: .pdf) { return "PDF document" }
        if type.conforms(to: .text) || type.conforms(to: .sourceCode) { return "Text document" }
        if type.conforms(to: .audio) { return "Audio" }
        if type.conforms(to: .movie) { return "Video" }
        return type.localizedDescription ?? "Document"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let preview {
                Image(uiImage: preview)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 170)
                    .background(Color.black.opacity(0.32))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(10)
            } else {
                HStack(spacing: 14) {
                    Image(systemName: iconName)
                        .font(.system(size: 25, weight: .semibold))
                        .foregroundColor(LaterAIStyle.accent)
                        .frame(width: 52, height: 52)
                        .background(LaterAIStyle.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 13))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(kindLabel.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.8)
                            .foregroundColor(LaterAIStyle.accent)
                        Text("Document ready to save")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(14)
            }

            VStack(alignment: .leading, spacing: 7) {
                Text(attachment.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    Text(kindLabel)
                    Text("•")
                    Text(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))
                    if isPDF { Text("• Preview") }
                    Spacer()
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.55))
            }
            .padding(.horizontal, 15)
            .padding(.bottom, 15)
        }
        .background(Color(white: 24.0 / 255), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.white.opacity(0.09), lineWidth: 1))
        .task { loadPreview() }
    }

    private var iconName: String {
        if type.conforms(to: .pdf) { return "doc.richtext.fill" }
        if type.conforms(to: .text) || type.conforms(to: .sourceCode) { return "doc.text.fill" }
        if type.conforms(to: .audio) { return "waveform" }
        if type.conforms(to: .movie) { return "film.fill" }
        if type.conforms(to: .archive) { return "archivebox.fill" }
        return "doc.fill"
    }

    private func loadPreview() {
        guard let url = try? SharedCaptureStore.fileURL(attachment) else { return }
        fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init) ?? attachment.byteSize ?? 0
        if type.conforms(to: .image) {
            preview = UIImage(contentsOfFile: url.path)
        } else if type.conforms(to: .pdf), let document = PDFDocument(url: url), let page = document.page(at: 0) {
            isPDF = true
            preview = page.thumbnail(of: CGSize(width: 900, height: 1200), for: .mediaBox)
        }
    }
}

// MARK: - Quick Save Composer Card
struct QuickSaveComposerCard: View {
    @ObservedObject var model: ShareCaptureModel
    @Binding var chooseReturnDate: Bool
    @Binding var selectedReturnDate: Date

    @State private var noteContent: String = ""
    @State private var noteTitle: String = ""
    @State private var selectedCategory: String = "Inbox"
    @State private var selectedReturnOption: String = "inbox"
    @State private var customReturnDate: Date? = nil

    private let categories = ["Inbox", "Reading", "Watch Later", "Listen Later", "Ideas", "Work"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header badge
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(LaterAIStyle.accent)
                Text("QUICK SAVE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(LaterAIStyle.accent)
                    .tracking(0.6)
                Spacer()
                Text("Vault")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.45))
            }

            // Note or URL input
            VStack(alignment: .leading, spacing: 6) {
                Text("NOTE OR LINK")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.45))
                    .tracking(0.5)

                ZStack(alignment: .topLeading) {
                    if noteContent.isEmpty {
                        Text("Type a note, idea, or paste a link...")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.30))
                            .padding(.top, 8)
                            .padding(.leading, 4)
                    }

                    TextEditor(text: $noteContent)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 80, maxHeight: 130)
                        .onChange(of: noteContent) { _, newValue in
                            detectLink(newValue)
                        }
                }
                .padding(10)
                .background(Color(white: 22.0/255), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
            }

            // Title field
            VStack(alignment: .leading, spacing: 6) {
                Text("TITLE (OPTIONAL)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.45))
                    .tracking(0.5)

                TextField("", text: $noteTitle, prompt: Text("Auto-generated if empty").foregroundColor(.white.opacity(0.30)))
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(white: 22.0/255), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
            }

            // Category picker
            VStack(alignment: .leading, spacing: 6) {
                Text("CATEGORY")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.45))
                    .tracking(0.5)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { cat in
                            Button(action: {
                                selectedCategory = cat
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }) {
                                Text(cat)
                                    .font(.system(size: 12, weight: selectedCategory == cat ? .bold : .medium))
                                    .foregroundColor(selectedCategory == cat ? .black : .white.opacity(0.80))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        selectedCategory == cat ? LaterAIStyle.accent : Color(white: 26.0/255),
                                        in: Capsule()
                                    )
                                    .overlay(
                                        Capsule().strokeBorder(
                                            selectedCategory == cat ? Color.clear : Color.white.opacity(0.10),
                                            lineWidth: 1
                                        )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // Return Schedule selector
            VStack(alignment: .leading, spacing: 6) {
                Text("RETURN SCHEDULE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.45))
                    .tracking(0.5)

                let returnPresets: [(id: String, label: String, icon: String)] = [
                    ("10m", "In 10m", "timer"),
                    ("1h", "In 1h", "clock.arrow.circlepath"),
                    ("tomorrow", "Tomorrow", "calendar.badge.clock"),
                    ("weekend", "Weekend", "sun.max.fill"),
                    ("custom", "Pick Date", "slider.horizontal.3"),
                    ("inbox", "No reminder", "tray")
                ]

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(returnPresets, id: \.id) { preset in
                            Button(action: {
                                selectedReturnOption = preset.id
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                if preset.id == "custom" {
                                    chooseReturnDate = true
                                }
                            }) {
                                HStack(spacing: 5) {
                                    Image(systemName: preset.icon)
                                        .font(.system(size: 10, weight: .bold))
                                    Text(preset.id == "custom" && customReturnDate != nil ? customReturnDate!.formatted(date: .abbreviated, time: .shortened) : preset.label)
                                        .font(.system(size: 12, weight: selectedReturnOption == preset.id ? .bold : .medium))
                                }
                                .foregroundColor(selectedReturnOption == preset.id ? .black : .white.opacity(0.85))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    selectedReturnOption == preset.id ? LaterAIStyle.accent : Color(white: 26.0/255),
                                    in: RoundedRectangle(cornerRadius: 10)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10).strokeBorder(
                                        selectedReturnOption == preset.id ? Color.clear : Color.white.opacity(0.12),
                                        lineWidth: 1
                                    )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // Save Action Button
            Button(action: performSave) {
                HStack(spacing: 8) {
                    if model.saving {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                    }
                    Text(model.saving ? "Saving..." : "Save to LaterBox")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    canSave ? LaterAIStyle.accent : Color(white: 35.0/255),
                    in: RoundedRectangle(cornerRadius: 14)
                )
            }
            .buttonStyle(.plain)
            .disabled(!canSave || model.saving)
        }
        .padding(18)
        .background(Color(white: 18.0 / 255), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
        .onChange(of: selectedReturnDate) { _, newDate in
            if selectedReturnOption == "custom" {
                customReturnDate = newDate
            }
        }
    }

    private var canSave: Bool {
        !noteContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !noteTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func detectLink(_ text: String) {
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue),
           let match = detector.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let matchUrl = match.url {
            let urlString = matchUrl.absoluteString
            if selectedCategory == "Inbox" {
                let lower = urlString.lowercased()
                if lower.contains("youtube") || lower.contains("vimeo") {
                    selectedCategory = "Watch Later"
                } else if lower.contains("spotify") || lower.contains("soundcloud") {
                    selectedCategory = "Listen Later"
                } else {
                    selectedCategory = "Reading"
                }
            }
        }
    }

    private func performSave() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let computedReturnDate: Date?
        switch selectedReturnOption {
        case "10m":
            computedReturnDate = Date().addingTimeInterval(600)
        case "1h":
            computedReturnDate = Date().addingTimeInterval(3600)
        case "tomorrow":
            computedReturnDate = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date().addingTimeInterval(86400)) ?? Date().addingTimeInterval(86400)
        case "weekend":
            computedReturnDate = Calendar.current.nextDate(after: Date(), matching: DateComponents(hour: 9, weekday: 7), matchingPolicy: .nextTime) ?? Date().addingTimeInterval(86400 * 2)
        case "custom":
            computedReturnDate = customReturnDate ?? selectedReturnDate
        default:
            computedReturnDate = nil
        }

        Task {
            await model.saveBlankItem(
                title: noteTitle,
                content: noteContent,
                category: selectedCategory,
                tags: [],
                returnAt: computedReturnDate
            )
        }
    }
}

struct ShareCaptureView: View {
    @ObservedObject var model: ShareCaptureModel
    @State private var chooseReturnDate = false
    @State private var selectedReturnDate = Date().addingTimeInterval(86400)
    @State private var showEditSheet = false

    var body: some View {
        VStack(spacing: 0) {
            LaterAIHeader(
                title: model.isBlankMode ? "Quick Save to LaterBox" : "Save to LaterBox",
                canReset: !model.messages.isEmpty,
                close: close,
                reset: {
                    withAnimation {
                        model.reset()
                    }
                }
            )

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        if model.isBlankMode && !model.saved {
                            QuickSaveComposerCard(
                                model: model,
                                chooseReturnDate: $chooseReturnDate,
                                selectedReturnDate: $selectedReturnDate
                            )
                        } else {
                            sharedPreviewCard

                            ForEach(model.messages) { message in
                                LaterAIChatRow(text: message.text, isUser: message.isUser, timestamp: message.timestamp)
                            }
                        }

                        if model.loading {
                            LaterAIThinkingIndicator(thinking: model.loading, statusText: "Preparing draft...")
                        }

                        if let error = model.error {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text(error)
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            .padding(14)
                            .background(Color(white: 20.0/255), in: RoundedRectangle(cornerRadius: 14))
                        }

                        Color.clear.frame(height: 20).id("bottomAnchor")
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 20)
                }
                .onChange(of: model.messages.count) { _, _ in
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo("bottomAnchor", anchor: .bottom)
                    }
                }
                .onChange(of: model.loading) { _, loading in
                    if loading {
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo("bottomAnchor", anchor: .bottom)
                        }
                    }
                }
            }

            // Bottom Area: Options Dock with multiple-choice buttons
            if !activeOptions.isEmpty {
                LaterAIOptionsDock(
                    title: optionsTitle,
                    options: activeOptions,
                    onManualType: nil
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Color.black.ignoresSafeArea())
        .foregroundStyle(.white)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $chooseReturnDate) {
            NavigationStack {
                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            DatePicker(
                                "Return Date",
                                selection: $selectedReturnDate,
                                in: Date()...,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.graphical)
                            .tint(LaterAIStyle.accent)
                            .environment(\.colorScheme, .dark)
                            .padding()
                            .background(Color(white: 20.0/255), in: RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(16)
                    }

                    // Pinned bottom confirmation dock (fixed even when half expanded)
                    VStack(spacing: 0) {
                        Divider().background(Color.white.opacity(0.10))
                        Button(action: {
                            chooseReturnDate = false
                            let label = selectedReturnDate.formatted(date: .abbreviated, time: .shortened)
                            sendOptionReply(label) {
                                Task { await model.scheduleAndSave(date: selectedReturnDate, optionLabel: label) }
                            }
                        }) {
                            Text("Confirm Return Date")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(LaterAIStyle.accent, in: RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 12)
                    }
                    .background(Color.black.ignoresSafeArea(edges: .bottom))
                }
                .background(Color.black.ignoresSafeArea())
                .navigationTitle("Select Return Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbarBackground(Color.black, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { chooseReturnDate = false }
                            .foregroundColor(LaterAIStyle.accent)
                    }
                }
            }
            .preferredColorScheme(.dark)
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showEditSheet) {
            ShareEditSheet(capture: $model.capture) {
                model.messages.append(ShareChatMessage(
                    text: "Updated details for ‘\(model.capture.title)’.",
                    isUser: false
                ))
                if model.saved {
                    try? SharedCaptureStore.save(model.capture)
                }
            }
        }
    }

    // MARK: - Shared Preview Card
    private var sharedPreviewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let imgUrl = model.capture.previewImageUrl, let url = URL(string: imgUrl), !imgUrl.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: 120)
                            .clipped()
                            .overlay(
                                LinearGradient(
                                    colors: [Color.clear, Color.black.opacity(0.85)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(alignment: .bottomLeading) {
                                HStack(spacing: 8) {
                                    Image(systemName: "globe")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(LaterAIStyle.accent)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(model.capture.title)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        if let site = model.capture.siteName {
                                            Text(site)
                                                .font(.caption2)
                                                .foregroundColor(.white.opacity(0.6))
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding(.horizontal, 14)
                                .padding(.bottom, 10)
                            }
                    default:
                        EmptyView()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            ForEach(model.capture.attachments) { file in
                ShareAttachmentPreviewCard(attachment: file)
            }

            // Return Countdown Badge
            if let returnDate = model.capture.returnAt {
                HStack(spacing: 10) {
                    Image(systemName: "timer")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(LaterAIStyle.accent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("RETURN SCHEDULED")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(LaterAIStyle.accent)
                            .tracking(0.6)

                        HStack(spacing: 4) {
                            Text("Returning in")
                                .foregroundColor(.white.opacity(0.85))
                            Text(returnDate, style: .relative)
                                .fontWeight(.bold)
                                .foregroundColor(LaterAIStyle.accent)
                            Text("(\(returnDate.formatted(date: .omitted, time: .shortened)))")
                                .foregroundColor(.white.opacity(0.55))
                        }
                        .font(.system(size: 12))
                    }

                    Spacer()

                    Button(action: {
                        withAnimation {
                            model.capture.returnAt = nil
                            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [model.capture.id])
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.40))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Color(white: 22.0/255), in: RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(LaterAIStyle.accent.opacity(0.25), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Options Popups Dock
    private var activeOptions: [LaterAIOptionItem] {
        guard !model.loading else { return [] }
        if model.isBlankMode && !model.saved {
            return []
        }

        if model.needsReturnDate {
            var options: [LaterAIOptionItem] = [
                LaterAIOptionItem(
                    title: "In 10 Minutes",
                    subtitle: "Quick return",
                    icon: "timer",
                    isPrimary: true
                ) {
                    let tenMin = Date().addingTimeInterval(600)
                    sendOptionReply("In 10 minutes") {
                        Task { await model.scheduleAndSave(date: tenMin, optionLabel: "In 10 minutes") }
                    }
                },
                LaterAIOptionItem(
                    title: "In 1 Hour",
                    subtitle: "Later today",
                    icon: "clock.arrow.circlepath",
                    isPrimary: false
                ) {
                    let oneHour = Date().addingTimeInterval(3600)
                    sendOptionReply("In 1 hour") {
                        Task { await model.scheduleAndSave(date: oneHour, optionLabel: "In 1 hour") }
                    }
                },
                LaterAIOptionItem(
                    title: "Tomorrow",
                    subtitle: "9:00 AM",
                    icon: "calendar.badge.clock",
                    isPrimary: false
                ) {
                    let tomorrow = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date().addingTimeInterval(86400)) ?? Date().addingTimeInterval(86400)
                    sendOptionReply("Tomorrow") {
                        Task { await model.scheduleAndSave(date: tomorrow, optionLabel: "Tomorrow") }
                    }
                },
                LaterAIOptionItem(
                    title: "This Weekend",
                    subtitle: "Saturday 9 AM",
                    icon: "sun.max.fill",
                    isPrimary: false
                ) {
                    let weekend = Calendar.current.nextDate(after: Date(), matching: DateComponents(hour: 9, weekday: 7), matchingPolicy: .nextTime) ?? Date().addingTimeInterval(86400 * 2)
                    sendOptionReply("This weekend") {
                        Task { await model.scheduleAndSave(date: weekend, optionLabel: "This weekend") }
                    }
                },
                LaterAIOptionItem(
                    title: "Next Week",
                    subtitle: "7 days from now",
                    icon: "calendar",
                    isPrimary: false
                ) {
                    let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date().addingTimeInterval(86400 * 7)
                    sendOptionReply("Next week") {
                        Task { await model.scheduleAndSave(date: nextWeek, optionLabel: "Next week") }
                    }
                },
                LaterAIOptionItem(
                    title: "No Reminder",
                    subtitle: "Inbox only",
                    icon: "tray",
                    isPrimary: false
                ) {
                    sendOptionReply("No reminder") {
                        Task { await model.scheduleAndSave(date: nil, optionLabel: "No reminder") }
                    }
                },
                LaterAIOptionItem(
                    title: "Choose Date",
                    subtitle: "Pick date & time",
                    icon: "slider.horizontal.3",
                    isPrimary: false
                ) {
                    chooseReturnDate = true
                }
            ]

            if model.saved {
                options.append(
                    LaterAIOptionItem(
                        title: "Keep Current",
                        subtitle: "Keep schedule",
                        icon: "arrow.uturn.backward",
                        isPrimary: false
                    ) {
                        sendOptionReply("Keep current schedule") {
                            model.needsReturnDate = false
                        }
                    }
                )
            }

            return options
        }

        if model.saved {
            return [
                LaterAIOptionItem(
                    title: "Done",
                    subtitle: "Close LaterBox",
                    icon: "checkmark.circle.fill",
                    isPrimary: true
                ) {
                    close()
                },
                LaterAIOptionItem(
                    title: "Change Return",
                    subtitle: "Reschedule date",
                    icon: "calendar.badge.clock",
                    isPrimary: false
                ) {
                    sendOptionReply("Change return date") {
                        model.needsReturnDate = true
                        model.messages.append(ShareChatMessage(text: "When would you like to see it again?", isUser: false))
                    }
                },
                LaterAIOptionItem(
                    title: "Edit Details",
                    subtitle: "Title & tags",
                    icon: "pencil",
                    isPrimary: false
                ) {
                    showEditSheet = true
                },
                LaterAIOptionItem(
                    title: "Undo Save",
                    subtitle: "Remove from vault",
                    icon: "arrow.uturn.backward",
                    isPrimary: false
                ) {
                    sendOptionReply("Undo save") {
                        model.undo()
                    }
                }
            ]
        }

        // State where item is not saved (e.g. after undo)
        return [
            LaterAIOptionItem(
                title: "Save to Vault",
                subtitle: "Store item",
                icon: "tray.and.arrow.down.fill",
                isPrimary: true
            ) {
                sendOptionReply("Save to vault") {
                    model.needsReturnDate = true
                    model.messages.append(ShareChatMessage(text: "When would you like to see it again?", isUser: false))
                }
            },
            LaterAIOptionItem(
                title: "Edit Details",
                subtitle: "Title & tags",
                icon: "pencil",
                isPrimary: false
            ) {
                showEditSheet = true
            },
            LaterAIOptionItem(
                title: "Done",
                subtitle: "Close",
                icon: "xmark.circle",
                isPrimary: false
            ) {
                close()
            }
        ]
    }

    private var optionsTitle: String? {
        if model.needsReturnDate {
            return "When would you like to return?"
        } else if model.saved {
            return "Saved item options"
        }
        return "Quick options"
    }

    private func sendOptionReply(_ title: String, action: @escaping () -> Void) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        action()
    }

    private func close() {
        model.context?.completeRequest(returningItems: nil)
    }
}

// MARK: - Dark Edit Sheet
struct ShareEditSheet: View {
    @Binding var capture: SharedCapture
    var onSaved: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var category: String = ""
    @State private var tagsString = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    fieldBlock(label: "Title") {
                        TextField("", text: $title, prompt: promptText("Enter title..."))
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                    }

                    fieldBlock(label: "Content or Link") {
                        TextField("", text: $content, prompt: promptText("URL or content note..."), axis: .vertical)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .lineLimit(2...6)
                    }

                    fieldBlock(label: "Category") {
                        TextField("", text: $category, prompt: promptText("e.g. Watch Later, Reading..."))
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                    }

                    fieldBlock(label: "Tags") {
                        TextField("", text: $tagsString, prompt: promptText("Comma separated tags..."))
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, 36)
            }
            .background(Color.black.ignoresSafeArea())
            .preferredColorScheme(.dark)
            .navigationTitle("Edit Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.7))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: saveChanges) {
                        Text("Done")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 7)
                            .background(LaterAIStyle.accent, in: Capsule())
                    }
                }
            }
            .onAppear {
                title = capture.title
                content = capture.content
                category = capture.category
                tagsString = capture.tags.joined(separator: ", ")
            }
        }
    }

    private func fieldBlock<Content: View>(label: String, @ViewBuilder input: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color.white.opacity(0.55))
                .tracking(0.6)

            HStack {
                input()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(white: 22.0/255), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            )
        }
    }

    private func promptText(_ text: String) -> Text {
        Text(text).foregroundColor(Color.white.opacity(0.32))
    }

    private func saveChanges() {
        capture.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        capture.content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        capture.category = category.trimmingCharacters(in: .whitespacesAndNewlines)
        capture.tags = tagsString.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "") }
            .filter { !$0.isEmpty }
        onSaved?()
        dismiss()
    }
}
