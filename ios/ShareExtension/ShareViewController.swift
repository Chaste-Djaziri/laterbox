import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private let queue = ShareCaptureQueue(appGroupId: AppGroup.identifier)
    private let statusView = ShareStatusView()
    private let actionStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        statusView.setState(.saving)
        processSharedContent()
    }

    // MARK: UI

    private func configureUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.18)

        view.addSubview(statusView)
        statusView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            statusView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            statusView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        actionStack.axis = .horizontal
        actionStack.spacing = 12
        actionStack.isHidden = true

        let cancel = makeButton(title: "Cancel", isDestructive: false)
        let retry = makeButton(title: "Try again", isDestructive: false)
        cancel.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        retry.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        actionStack.addArrangedSubview(cancel)
        actionStack.addArrangedSubview(retry)

        view.addSubview(actionStack)
        actionStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            actionStack.topAnchor.constraint(equalTo: statusView.bottomAnchor, constant: 20),
            actionStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    private func makeButton(title: String, isDestructive: Bool) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.cornerStyle = .medium
        if isDestructive {
            configuration.baseBackgroundColor = .systemGray
        } else {
            configuration.baseBackgroundColor = .tintColor
        }
        return UIButton(configuration: configuration)
    }

    // MARK: Processing

    private func processSharedContent() {
        guard
            let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
            let providers = extensionItem.attachments
        else {
            showFailure("No shareable content found")
            return
        }

        let captureId = UUID().uuidString
        let fileProviders = providers.compactMap { provider -> (NSItemProvider, String)? in
            guard let identifier = supportedFileIdentifier(for: provider) else { return nil }
            return (provider, identifier)
        }
        let initialText = extensionItem.attributedContentText?.string
        loadFilesSequentially(
            fileProviders,
            captureId: captureId,
            index: 0,
            paths: [],
            failureCount: 0
        ) { [weak self] paths, failureCount in
            guard let self else { return }
            self.loadOptionalText(from: providers, fallback: initialText) { text in
                DispatchQueue.main.async {
                    self.save(
                        captureId: captureId,
                        text: text,
                        filePaths: paths,
                        failureCount: failureCount
                    )
                }
            }
        }
    }

    private func supportedFileIdentifier(for provider: NSItemProvider) -> String? {
        provider.registeredTypeIdentifiers.first { identifier in
            guard let type = UTType(identifier) else { return false }
            if type.conforms(to: .image) || type.conforms(to: .pdf) { return true }
            let supportedExtensions = ["txt", "md", "doc", "docx"]
            guard
                let fileExtension = type.preferredFilenameExtension?.lowercased(),
                supportedExtensions.contains(fileExtension)
            else { return false }
            if type.conforms(to: .plainText) {
                return provider.suggestedName != nil
            }
            return true
        }
    }

    private func loadFilesSequentially(
        _ providers: [(NSItemProvider, String)],
        captureId: String,
        index: Int,
        paths: [String],
        failureCount: Int,
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
            var nextFailureCount = failureCount
            if let url, let staged = self.stageFile(
                source: url,
                provider: provider,
                identifier: identifier,
                captureId: captureId,
                existingPaths: paths
            ) {
                nextPaths.append(staged.path)
            } else {
                nextFailureCount += 1
            }
            self.loadFilesSequentially(
                providers,
                captureId: captureId,
                index: index + 1,
                paths: nextPaths,
                failureCount: nextFailureCount,
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
        guard
            let container = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: AppGroup.identifier
            )
        else { return nil }
        let directory = container
            .appendingPathComponent("PendingAttachments", isDirectory: true)
            .appendingPathComponent(captureId, isDirectory: true)
        do {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            let type = UTType(identifier)
            var fileName = provider.suggestedName ?? source.lastPathComponent
            if URL(fileURLWithPath: fileName).pathExtension.isEmpty,
               let suffix = type?.preferredFilenameExtension {
                fileName += ".\(suffix)"
            }
            fileName = safeFileName(fileName)
            let usedNames = Set(existingPaths.map { URL(fileURLWithPath: $0).lastPathComponent.lowercased() })
            fileName = uniqueFileName(fileName, excluding: usedNames)
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
        if let urlProvider = providers.first(where: {
            $0.hasItemConformingToTypeIdentifier(UTType.url.identifier)
        }) {
            urlProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                completion((item as? URL)?.absoluteString)
            }
            return
        }
        guard let textProvider = providers.first(where: {
            $0.suggestedName == nil &&
                $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier)
        }) else {
            completion(nil)
            return
        }
        textProvider.loadItem(
            forTypeIdentifier: UTType.plainText.identifier,
            options: nil
        ) { item, _ in
            completion(item as? String)
        }
    }

    private func save(
        captureId: String,
        text: String?,
        filePaths: [String],
        failureCount: Int
    ) {
        let trimmed = normalizedText(text)
        guard trimmed != nil || !filePaths.isEmpty else {
            deleteStagingDirectory(captureId: captureId)
            showFailure("Couldn't read the shared content")
            return
        }
        guard let queue else {
            deleteStagingDirectory(captureId: captureId)
            showFailure("LaterBox storage is unavailable")
            return
        }
        let capture = PendingShareCapture(
            id: captureId,
            value: trimmed,
            kind: filePaths.isEmpty ? "text" : "attachments",
            source: "iosShare",
            createdAt: ISO8601DateFormatter().string(from: Date()),
            filePaths: filePaths
        )
        if queue.enqueue(capture) {
            let subtitle: String?
            if filePaths.isEmpty, let trimmed {
                subtitle = displaySubtitle(for: trimmed, kind: "text")
            } else if failureCount > 0 {
                subtitle = "\(filePaths.count) saved, \(failureCount) couldn't be read"
            } else {
                subtitle = filePaths.count == 1
                    ? URL(fileURLWithPath: filePaths[0]).lastPathComponent
                    : "\(filePaths.count) files"
            }
            showSuccess(subtitle: subtitle)
        } else {
            deleteStagingDirectory(captureId: captureId)
            showFailure("Couldn't write to LaterBox storage")
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

    private func deleteStagingDirectory(captureId: String) {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppGroup.identifier
        ) else { return }
        let directory = container
            .appendingPathComponent("PendingAttachments", isDirectory: true)
            .appendingPathComponent(captureId, isDirectory: true)
        try? FileManager.default.removeItem(at: directory)
    }

    // MARK: States

    private func showSuccess(subtitle: String?) {
        actionStack.isHidden = true
        statusView.setState(.success(subtitle))
        triggerSuccessFeedback()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.finish()
        }
    }

    private func showFailure(_ message: String) {
        actionStack.isHidden = false
        statusView.setState(.failure(message))
    }

    @objc private func cancelTapped() {
        finish()
    }

    @objc private func retryTapped() {
        actionStack.isHidden = true
        statusView.setState(.saving)
        processSharedContent()
    }

    private func triggerSuccessFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    private func displaySubtitle(for value: String, kind: String) -> String? {
        if kind == "url", let url = URL(string: value), let host = url.host {
            return host.replacingOccurrences(of: "www.", with: "")
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(60))
    }

    private func finish() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}

enum AppGroup {
    static let identifier = "group.pro.micorp.laterbox"
}
