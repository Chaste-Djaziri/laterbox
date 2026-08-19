import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private let queue = ShareCaptureQueue(appGroupId: AppGroup.identifier)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let label = UILabel()
        label.text = "Saved to LaterBox"
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        processSharedContent()
    }

    private func processSharedContent() {
        guard
            let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
            let providers = extensionItem.attachments
        else {
            finish()
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

        finish()
    }

    private func loadUrl(_ provider: NSItemProvider) {
        provider.loadItem(
            forTypeIdentifier: UTType.url.identifier,
            options: nil
        ) { [weak self] item, _ in
            guard let self else { return }
            if let url = item as? URL {
                enqueue(value: url.absoluteString, kind: "url")
            }
            finish()
        }
    }

    private func loadText(_ provider: NSItemProvider) {
        provider.loadItem(
            forTypeIdentifier: UTType.plainText.identifier,
            options: nil
        ) { [weak self] item, _ in
            guard let self else { return }
            if let text = item as? String {
                enqueue(value: text, kind: "text")
            }
            finish()
        }
    }

    private func enqueue(value: String, kind: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let capture = PendingShareCapture(
            id: UUID().uuidString,
            value: trimmed,
            kind: kind,
            source: "iosShare",
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        queue?.enqueue(capture)
    }

    private func finish() {
        DispatchQueue.main.async { [weak self] in
            self?.extensionContext?.completeRequest(
                returningItems: nil,
                completionHandler: nil
            )
        }
    }
}

enum AppGroup {
    static let identifier = "group.com.example.laterbox"
}