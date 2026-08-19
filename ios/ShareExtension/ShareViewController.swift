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

        if let provider = providers.first(
            where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }
        ) {
            loadUrl(provider)
            return
        }

        if let provider = providers.first(
            where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }
        ) {
            loadText(provider)
            return
        }

        showFailure("No shareable content found")
    }

    private func loadUrl(_ provider: NSItemProvider) {
        provider.loadItem(
            forTypeIdentifier: UTType.url.identifier,
            options: nil
        ) { [weak self] item, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                guard let url = item as? URL else {
                    self.showFailure("Couldn't read the shared link")
                    return
                }
                self.save(value: url.absoluteString, kind: "url")
            }
        }
    }

    private func loadText(_ provider: NSItemProvider) {
        provider.loadItem(
            forTypeIdentifier: UTType.plainText.identifier,
            options: nil
        ) { [weak self] item, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                guard let text = item as? String else {
                    self.showFailure("Couldn't read the shared text")
                    return
                }
                self.save(value: text, kind: "text")
            }
        }
    }

    private func save(value: String, kind: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showFailure("Couldn't read the shared content")
            return
        }
        guard let queue else {
            showFailure("LaterBox storage is unavailable")
            return
        }
        let capture = PendingShareCapture(
            id: UUID().uuidString,
            value: trimmed,
            kind: kind,
            source: "iosShare",
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        if queue.enqueue(capture) {
            showSuccess(subtitle: displaySubtitle(for: trimmed, kind: kind))
        } else {
            showFailure("Couldn't write to LaterBox storage")
        }
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
    static let identifier = "group.com.example.laterbox"
}
