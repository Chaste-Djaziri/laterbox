import UIKit

final class ShareStatusView: UIView {
    enum State {
        case saving
        case success(subtitle: String?, kind: String?)
        case failure(String)
    }

    private let cardView = UIView()
    private let badgeContainer = UIView()
    private let iconImageView = UIImageView()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let titleLabel = UILabel()
    private let pillView = UIView()
    private let pillIconView = UIImageView()
    private let subtitleLabel = UILabel()
    private let progressTrack = UIView()
    private let progressBar = UIView()
    private var progressBarWidthConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        backgroundColor = .clear

        // Card container
        cardView.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 0.96)
                : UIColor(red: 0.98, green: 0.976, blue: 0.96, alpha: 0.98)
        }
        cardView.layer.cornerRadius = 26
        if #available(iOS 13.0, *) {
            cardView.layer.cornerCurve = .continuous
        }
        cardView.layer.borderWidth = 1.0
        cardView.layer.borderColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(white: 0.25, alpha: 0.6)
                : UIColor(white: 0.85, alpha: 0.8)
        }.cgColor

        // Shadow
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.18
        cardView.layer.shadowRadius = 24
        cardView.layer.shadowOffset = CGSize(width: 0, height: 10)

        addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false

        // Badge Container
        badgeContainer.layer.cornerRadius = 26
        if #available(iOS 13.0, *) {
            badgeContainer.layer.cornerCurve = .continuous
        }
        badgeContainer.backgroundColor = UIColor(red: 0.824, green: 0.973, blue: 0.012, alpha: 0.22)
        badgeContainer.translatesAutoresizingMaskIntoConstraints = false

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.824, green: 0.973, blue: 0.012, alpha: 1.0)
                : UIColor(red: 0.20, green: 0.55, blue: 0.05, alpha: 1.0)
        }
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        badgeContainer.addSubview(iconImageView)
        badgeContainer.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            badgeContainer.widthAnchor.constraint(equalToConstant: 52),
            badgeContainer.heightAnchor.constraint(equalToConstant: 52),
            iconImageView.centerXAnchor.constraint(equalTo: badgeContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: badgeContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 26),
            iconImageView.heightAnchor.constraint(equalToConstant: 26),
            activityIndicator.centerXAnchor.constraint(equalTo: badgeContainer.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: badgeContainer.centerYAnchor),
        ])

        // Title
        let fontDescriptor: UIFontDescriptor
        if #available(iOS 13.0, *) {
            fontDescriptor = UIFont.systemFont(ofSize: 18, weight: .bold).fontDescriptor.withDesign(.rounded) ?? UIFont.systemFont(ofSize: 18, weight: .bold).fontDescriptor
        } else {
            fontDescriptor = UIFont.systemFont(ofSize: 18, weight: .bold).fontDescriptor
        }
        titleLabel.font = UIFont(descriptor: fontDescriptor, size: 18)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Subtitle Pill
        pillView.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(white: 0.18, alpha: 0.7)
                : UIColor(white: 0.92, alpha: 0.8)
        }
        pillView.layer.cornerRadius = 14
        if #available(iOS 13.0, *) {
            pillView.layer.cornerCurve = .continuous
        }
        pillView.translatesAutoresizingMaskIntoConstraints = false

        pillIconView.contentMode = .scaleAspectFit
        pillIconView.tintColor = .secondaryLabel
        pillIconView.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .left
        subtitleLabel.lineBreakMode = .byTruncatingMiddle
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        pillView.addSubview(pillIconView)
        pillView.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            pillIconView.leadingAnchor.constraint(equalTo: pillView.leadingAnchor, constant: 10),
            pillIconView.centerYAnchor.constraint(equalTo: pillView.centerYAnchor),
            pillIconView.widthAnchor.constraint(equalToConstant: 14),
            pillIconView.heightAnchor.constraint(equalToConstant: 14),

            subtitleLabel.leadingAnchor.constraint(equalTo: pillIconView.trailingAnchor, constant: 6),
            subtitleLabel.trailingAnchor.constraint(equalTo: pillView.trailingAnchor, constant: -12),
            subtitleLabel.centerYAnchor.constraint(equalTo: pillView.centerYAnchor),
            pillView.heightAnchor.constraint(equalToConstant: 32),
        ])

        // Progress Bar
        progressTrack.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(white: 0.22, alpha: 0.4)
                : UIColor(white: 0.88, alpha: 0.5)
        }
        progressTrack.layer.cornerRadius = 1.5
        progressTrack.clipsToBounds = true
        progressTrack.translatesAutoresizingMaskIntoConstraints = false

        progressBar.backgroundColor = UIColor(red: 0.824, green: 0.973, blue: 0.012, alpha: 1.0)
        progressBar.layer.cornerRadius = 1.5
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressTrack.addSubview(progressBar)

        let initialProgressWidth = progressBar.widthAnchor.constraint(equalTo: progressTrack.widthAnchor, multiplier: 1.0)
        progressBarWidthConstraint = initialProgressWidth

        NSLayoutConstraint.activate([
            progressBar.leadingAnchor.constraint(equalTo: progressTrack.leadingAnchor),
            progressBar.topAnchor.constraint(equalTo: progressTrack.topAnchor),
            progressBar.bottomAnchor.constraint(equalTo: progressTrack.bottomAnchor),
            initialProgressWidth,
        ])

        // Vertical stack
        let stack = UIStackView(
            arrangedSubviews: [
                badgeContainer,
                titleLabel,
                pillView,
            ]
        )
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false

        cardView.addSubview(stack)
        cardView.addSubview(progressTrack)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardView.topAnchor.constraint(equalTo: topAnchor),
            cardView.bottomAnchor.constraint(equalTo: bottomAnchor),

            stack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: cardView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: cardView.trailingAnchor, constant: -20),
            stack.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),

            pillView.leadingAnchor.constraint(greaterThanOrEqualTo: cardView.leadingAnchor, constant: 24),
            pillView.trailingAnchor.constraint(lessThanOrEqualTo: cardView.trailingAnchor, constant: -24),

            progressTrack.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 20),
            progressTrack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 32),
            progressTrack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -32),
            progressTrack.heightAnchor.constraint(equalToConstant: 3),
            progressTrack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
        ])
    }

    func setState(_ state: State, dismissDuration: TimeInterval = 2.4) {
        switch state {
        case .saving:
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
            iconImageView.isHidden = true
            progressTrack.isHidden = true
            pillView.isHidden = true
            badgeContainer.backgroundColor = UIColor(red: 0.824, green: 0.973, blue: 0.012, alpha: 0.15)
            titleLabel.text = "Saving to LaterBox…"

        case .success(let subtitle, let kind):
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            iconImageView.isHidden = false
            progressTrack.isHidden = false

            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
            iconImageView.image = UIImage(systemName: "checkmark", withConfiguration: symbolConfig)
            iconImageView.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
            UIView.animate(
                withDuration: 0.45,
                delay: 0,
                usingSpringWithDamping: 0.65,
                initialSpringVelocity: 0.8,
                options: [.curveEaseOut],
                animations: {
                    self.iconImageView.transform = .identity
                }
            )

            badgeContainer.backgroundColor = UIColor(red: 0.824, green: 0.973, blue: 0.012, alpha: 0.28)
            titleLabel.text = "Saved to LaterBox"

            if let subtitle, !subtitle.isEmpty {
                pillView.isHidden = false
                subtitleLabel.text = subtitle

                let iconName: String
                switch kind {
                case "attachments":
                    iconName = "paperclip"
                case "url":
                    iconName = "link"
                default:
                    iconName = "text.alignleft"
                }
                let pillConfig = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
                pillIconView.image = UIImage(systemName: iconName, withConfiguration: pillConfig)
            } else {
                pillView.isHidden = true
            }

            // Animate progress bar countdown
            layoutIfNeeded()
            progressBarWidthConstraint?.isActive = false
            let zeroWidth = progressBar.widthAnchor.constraint(equalToConstant: 0)
            zeroWidth.isActive = true
            progressBarWidthConstraint = zeroWidth

            UIView.animate(
                withDuration: dismissDuration,
                delay: 0.1,
                options: [.curveLinear],
                animations: {
                    self.progressTrack.layoutIfNeeded()
                }
            )

        case .failure(let message):
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            iconImageView.isHidden = false
            progressTrack.isHidden = true

            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
            iconImageView.image = UIImage(systemName: "xmark", withConfiguration: symbolConfig)
            iconImageView.tintColor = .systemRed
            badgeContainer.backgroundColor = UIColor.systemRed.withAlphaComponent(0.15)
            titleLabel.text = "Couldn't save"

            pillView.isHidden = false
            subtitleLabel.text = message
            let pillConfig = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
            pillIconView.image = UIImage(systemName: "exclamationmark.triangle", withConfiguration: pillConfig)
        }
    }
}

