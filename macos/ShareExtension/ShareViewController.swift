import Cocoa
import UniformTypeIdentifiers

final class ShareViewController: NSViewController {
    private let queue = ShareCaptureQueue(appGroupId: AppGroup.identifier)
    private let statusLabel = NSTextField(labelWithString: "Saving to LaterBox…")

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 360, height: 120))
        statusLabel.alignment = .center
        statusLabel.font = .systemFont(ofSize: 15, weight: .medium)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        processSharedContent()
    }

    private func processSharedContent() {
        let items = (extensionContext?.inputItems as? [NSExtensionItem]) ?? []
        let providers = items.flatMap { $0.attachments ?? [] }
        guard !providers.isEmpty || items.contains(where: { $0.attributedContentText != nil }) else {
            finishWithFailure("No shareable content found")
            return
        }

        let captureId = UUID().uuidString
        let fileProviders = providers.compactMap { provider -> (NSItemProvider, String)? in
            guard let identifier = supportedFileIdentifier(for: provider) else { return nil }
            return (provider, identifier)
        }
        let initialText = items.compactMap { $0.attributedContentText?.string }.first
        loadFilesSequentially(fileProviders, captureId: captureId, index: 0, paths: []) {
            [weak self] paths, failures in
            guard let self else { return }
            self.loadOptionalText(from: providers, fallback: initialText) { text in
                DispatchQueue.main.async {
                    self.save(captureId: captureId, text: text, filePaths: paths, failureCount: failures)
                }
            }
        }
    }

    private func supportedFileIdentifier(for provider: NSItemProvider) -> String? {
        provider.registeredTypeIdentifiers.first { identifier in
            guard let type = UTType(identifier) else { return false }
            if type.conforms(to: .jpeg) || type.conforms(to: .png) ||
                type.conforms(to: .webP) || type.conforms(to: .heic) ||
                type.conforms(to: .pdf) { return true }
            guard let suffix = type.preferredFilenameExtension?.lowercased() else { return false }
            return ["txt", "md", "doc", "docx"].contains(suffix)
        }
    }

    private func loadFilesSequentially(
        _ providers: [(NSItemProvider, String)],
        captureId: String,
        index: Int,
        paths: [String],
        failureCount: Int = 0,
        completion: @escaping ([String], Int) -> Void
    ) {
        guard index < providers.count else {
            completion(paths, failureCount)
            return
        }
        let (provider, identifier) = providers[index]
        provider.loadFileRepresentation(forTypeIdentifier: identifier) { [weak self] url, _ in
            guard let self else { return }
            var nextPaths = paths
            var nextFailures = failureCount
            if let url, let staged = self.stageFile(
                source: url,
                provider: provider,
                identifier: identifier,
                captureId: captureId,
                existingPaths: paths
            ) {
                nextPaths.append(staged.path)
            } else {
                nextFailures += 1
            }
            self.loadFilesSequentially(
                providers,
                captureId: captureId,
                index: index + 1,
                paths: nextPaths,
                failureCount: nextFailures,
                completion: completion
            )
        }
    }

    private func stageFile(
        source: URL,
        provider: NSItemProvider,
        identifier: String,
        captureId: String,
        existingPaths: [String]
    ) -> URL? {
        let directory = queue.stagingDirectory(for: captureId)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let type = UTType(identifier)
            var fileName = provider.suggestedName ?? source.lastPathComponent
            if URL(fileURLWithPath: fileName).pathExtension.isEmpty,
               let suffix = type?.preferredFilenameExtension {
                fileName += ".\(suffix)"
            }
            fileName = safeFileName(fileName)
            let used = Set(existingPaths.map { URL(fileURLWithPath: $0).lastPathComponent.lowercased() })
            fileName = uniqueFileName(fileName, excluding: used)
            let destination = directory.appendingPathComponent(fileName)
            try FileManager.default.copyItem(at: source, to: destination)
            return destination
        } catch {
            return nil
        }
    }

    private func loadOptionalText(
        from providers: [NSItemProvider],
        fallback: String?,
        completion: @escaping (String?) -> Void
    ) {
        if let fallback = normalizedText(fallback) {
            completion(fallback)
            return
        }
        guard let provider = providers.first(where: {
            $0.suggestedName == nil && $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier)
        }) else {
            completion(nil)
            return
        }
        provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
            completion(item as? String)
        }
    }

    private func save(captureId: String, text: String?, filePaths: [String], failureCount: Int) {
        let trimmed = normalizedText(text)
        guard trimmed != nil || !filePaths.isEmpty else {
            queue.deleteStagingDirectory(id: captureId)
            finishWithFailure("LaterBox could not read this content")
            return
        }
        let capture = PendingShareCapture(
            id: captureId,
            value: trimmed,
            kind: filePaths.isEmpty ? "text" : "attachments",
            source: "macosShare",
            createdAt: ISO8601DateFormatter().string(from: Date()),
            filePaths: filePaths
        )
        guard queue.enqueue(capture) else {
            queue.deleteStagingDirectory(id: captureId)
            finishWithFailure("LaterBox could not save this content")
            return
        }
        statusLabel.stringValue = failureCount == 0 ? "Saved to LaterBox" : "Saved \(filePaths.count) files"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil)
        }
    }

    private func finishWithFailure(_ message: String) {
        statusLabel.stringValue = message
        let error = NSError(domain: "pro.micorp.laterbox.ShareExtension", code: 1,
                            userInfo: [NSLocalizedDescriptionKey: message])
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.extensionContext?.cancelRequest(withError: error)
        }
    }

    private func normalizedText(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed?.isEmpty == false ? trimmed : nil
    }

    private func safeFileName(_ value: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\").union(.controlCharacters)
        return value.components(separatedBy: invalid).joined(separator: "_").prefix(180).description
    }

    private func uniqueFileName(_ value: String, excluding usedNames: Set<String>) -> String {
        guard usedNames.contains(value.lowercased()) else { return value }
        let url = URL(fileURLWithPath: value)
        let suffix = url.pathExtension
        let stem = url.deletingPathExtension().lastPathComponent
        var index = 2
        while true {
            let candidate = suffix.isEmpty ? "\(stem)-\(index)" : "\(stem)-\(index).\(suffix)"
            if !usedNames.contains(candidate.lowercased()) { return candidate }
            index += 1
        }
    }

    private func deleteStagingDirectory(_ captureId: String) {
        queue.deleteStagingDirectory(id: captureId)
    }
}

enum AppGroup {
    static let identifier = "group.pro.micorp.laterbox"
}
