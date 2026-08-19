import UIKit

final class ShareStatusView: UIView {
    enum State {
        case saving
        case success(String?)
        case failure(String)
    }

    private let iconView = UIImageView()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 22

        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textAlignment = .center

        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 2

        iconView.contentMode = .scaleAspectFit

        let stack = UIStackView(
            arrangedSubviews: [
                activityIndicator,
                iconView,
                titleLabel,
                subtitleLabel,
            ]
        )
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 10

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -24),
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 190),
        ])
    }

    func setState(_ state: State) {
        switch state {
        case .saving:
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
            iconView.isHidden = true
            titleLabel.text = "Saving…"
            subtitleLabel.text = nil

        case .success(let subtitle):
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            iconView.isHidden = false
            iconView.image = UIImage(systemName: "checkmark.circle.fill")
            titleLabel.text = "Saved to LaterBox"
            subtitleLabel.text = subtitle

        case .failure(let message):
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            iconView.isHidden = false
            iconView.image = UIImage(systemName: "exclamationmark.circle.fill")
            titleLabel.text = "Couldn't save"
            subtitleLabel.text = message
        }
    }
}
