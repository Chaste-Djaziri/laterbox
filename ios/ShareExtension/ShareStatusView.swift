import UIKit

final class ShareStatusView: UIView {
    enum State {
        case promptWhen(
            previewTitle: String,
            previewSubtitle: String?,
            kind: String?,
            onConfirm: (Date?) -> Void,
            onCancel: () -> Void
        )
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

    // When Selector Container
    private let whenContainer = UIStackView()
    private let whenSectionLabel = UILabel()
    private let chipScrollView = UIScrollView()
    private let chipStack = UIStackView()
    private let selectedTimeLabel = UILabel()
    private let datePicker = UIDatePicker()
    private let actionButtonsStack = UIStackView()
    private let saveButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)

    // Progress
    private let progressTrack = UIView()
    private let progressBar = UIView()
    private var progressBarWidthConstraint: NSLayoutConstraint?

    // Selection state
    private var onConfirmCallback: ((Date?) -> Void)?
    private var onCancelCallback: (() -> Void)?
    private var selectedReturnDate: Date? = nil
    private var selectedPresetIndex = 0
    private var chipButtons: [UIButton] = []

    private let presets: [(label: String, calculate: () -> Date?, hint: String)] = [
        ("Inbox", { nil }, "Saves immediately to Inbox"),
        ("Later today", {
            let now = Date()
            var cal = Calendar.current
            cal.timeZone = .current
            let hour = cal.component(.hour, from: now)
            if hour < 18 {
                return cal.date(bySettingHour: 18, minute: 0, second: 0, of: now)
            } else {
                return cal.date(byAdding: .hour, value: 3, to: now)
            }
        }, "Returns today at 6:00 PM"),
        ("Tomorrow", {
            let now = Date()
            var cal = Calendar.current
            cal.timeZone = .current
            if let tomorrow = cal.date(byAdding: .day, value: 1, to: now) {
                return cal.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow)
            }
            return cal.date(byAdding: .day, value: 1, to: now)
        }, "Returns tomorrow morning at 9:00 AM"),
        ("Weekend", {
            let now = Date()
            var cal = Calendar.current
            cal.timeZone = .current
            let weekday = cal.component(.weekday, from: now)
            let daysUntilSat = (14 - weekday) % 7
            let days = daysUntilSat == 0 ? 7 : daysUntilSat
            if let sat = cal.date(byAdding: .day, value: days, to: now) {
                return cal.date(bySettingHour: 9, minute: 0, second: 0, of: sat)
            }
            return cal.date(byAdding: .day, value: 2, to: now)
        }, "Returns Saturday morning at 9:00 AM"),
        ("Someday", { nil }, "Saved to backlog without a return date"),
        ("Custom…", { nil }, "Choose custom return date and time")
    ]

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
                ? UIColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 0.98)
                : UIColor(red: 0.98, green: 0.976, blue: 0.96, alpha: 0.99)
        }
        cardView.layer.cornerRadius = 28
        if #available(iOS 13.0, *) {
            cardView.layer.cornerCurve = .continuous
        }
        cardView.layer.borderWidth = 1.0
        cardView.layer.borderColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(white: 0.25, alpha: 0.6)
                : UIColor(white: 0.85, alpha: 0.8)
        }.cgColor

        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.22
        cardView.layer.shadowRadius = 28
        cardView.layer.shadowOffset = CGSize(width: 0, height: 12)

        addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false

        // Badge Container
        badgeContainer.layer.cornerRadius = 24
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
            badgeContainer.widthAnchor.constraint(equalToConstant: 48),
            badgeContainer.heightAnchor.constraint(equalToConstant: 48),
            iconImageView.centerXAnchor.constraint(equalTo: badgeContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: badgeContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
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
                : UIColor(white: 0.92, alpha: 0.85)
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

        // When Container Configuration
        configureWhenSection()

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

        // Main Vertical Stack
        let mainStack = UIStackView(
            arrangedSubviews: [
                badgeContainer,
                titleLabel,
                pillView,
                whenContainer,
            ]
        )
        mainStack.axis = .vertical
        mainStack.alignment = .center
        mainStack.spacing = 14
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        cardView.addSubview(mainStack)
        cardView.addSubview(progressTrack)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardView.topAnchor.constraint(equalTo: topAnchor),
            cardView.bottomAnchor.constraint(equalTo: bottomAnchor),

            mainStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            mainStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 18),
            mainStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -18),

            pillView.leadingAnchor.constraint(greaterThanOrEqualTo: mainStack.leadingAnchor),
            pillView.trailingAnchor.constraint(lessThanOrEqualTo: mainStack.trailingAnchor),

            whenContainer.leadingAnchor.constraint(equalTo: mainStack.leadingAnchor),
            whenContainer.trailingAnchor.constraint(equalTo: mainStack.trailingAnchor),

            progressTrack.topAnchor.constraint(equalTo: mainStack.bottomAnchor, constant: 16),
            progressTrack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 32),
            progressTrack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -32),
            progressTrack.heightAnchor.constraint(equalToConstant: 3),
            progressTrack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
        ])
    }

    private func configureWhenSection() {
        whenContainer.axis = .vertical
        whenContainer.spacing = 10
        whenContainer.alignment = .fill
        whenContainer.translatesAutoresizingMaskIntoConstraints = false

        // Divider
        let divider = UIView()
        divider.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(white: 0.25, alpha: 0.4)
                : UIColor(white: 0.85, alpha: 0.6)
        }
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        whenContainer.addArrangedSubview(divider)

        // Section header
        whenSectionLabel.text = "CHOOSE WHEN"
        whenSectionLabel.font = .systemFont(ofSize: 11, weight: .bold)
        whenSectionLabel.textColor = .secondaryLabel
        whenSectionLabel.textAlignment = .left
        whenContainer.addArrangedSubview(whenSectionLabel)

        // Chip Scroll View
        chipScrollView.showsHorizontalScrollIndicator = false
        chipScrollView.translatesAutoresizingMaskIntoConstraints = false
        chipScrollView.heightAnchor.constraint(equalToConstant: 36).isActive = true

        chipStack.axis = .horizontal
        chipStack.spacing = 8
        chipStack.alignment = .center
        chipStack.translatesAutoresizingMaskIntoConstraints = false

        chipScrollView.addSubview(chipStack)
        NSLayoutConstraint.activate([
            chipStack.leadingAnchor.constraint(equalTo: chipScrollView.contentLayoutGuide.leadingAnchor),
            chipStack.trailingAnchor.constraint(equalTo: chipScrollView.contentLayoutGuide.trailingAnchor),
            chipStack.topAnchor.constraint(equalTo: chipScrollView.contentLayoutGuide.topAnchor),
            chipStack.bottomAnchor.constraint(equalTo: chipScrollView.contentLayoutGuide.bottomAnchor),
            chipStack.heightAnchor.constraint(equalTo: chipScrollView.heightAnchor),
        ])

        for (index, preset) in presets.enumerated() {
            let chip = UIButton(type: .custom)
            chip.setTitle(preset.label, for: .normal)
            chip.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .semibold)
            chip.contentEdgeInsets = UIEdgeInsets(top: 6, left: 13, bottom: 6, right: 13)
            chip.layer.cornerRadius = 14
            if #available(iOS 13.0, *) {
                chip.layer.cornerCurve = .continuous
            }
            chip.tag = index
            chip.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
            chipStack.addArrangedSubview(chip)
            chipButtons.append(chip)
        }
        whenContainer.addArrangedSubview(chipScrollView)

        // Selected Time Label
        selectedTimeLabel.font = .systemFont(ofSize: 12, weight: .medium)
        selectedTimeLabel.textColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.824, green: 0.973, blue: 0.012, alpha: 1.0)
                : UIColor(red: 0.15, green: 0.45, blue: 0.04, alpha: 1.0)
        }
        selectedTimeLabel.textAlignment = .left
        selectedTimeLabel.text = presets[0].hint
        whenContainer.addArrangedSubview(selectedTimeLabel)

        // Native DatePicker (hidden unless custom selected)
        if #available(iOS 14.0, *) {
            datePicker.preferredDatePickerStyle = .compact
        }
        datePicker.datePickerMode = .dateAndTime
        datePicker.minuteInterval = 5
        datePicker.minimumDate = Date()
        datePicker.isHidden = true
        datePicker.addTarget(self, action: #selector(datePickerChanged(_:)), for: .valueChanged)
        whenContainer.addArrangedSubview(datePicker)

        // Action Buttons
        actionButtonsStack.axis = .horizontal
        actionButtonsStack.spacing = 10
        actionButtonsStack.distribution = .fillProportionally
        actionButtonsStack.translatesAutoresizingMaskIntoConstraints = false

        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.secondaryLabel, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        saveButton.setTitle("Save to LaterBox", for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        saveButton.backgroundColor = UIColor(red: 0.824, green: 0.973, blue: 0.012, alpha: 1.0)
        saveButton.setTitleColor(UIColor(red: 0.09, green: 0.09, blue: 0.07, alpha: 1.0), for: .normal)
        saveButton.layer.cornerRadius = 15
        if #available(iOS 13.0, *) {
            saveButton.layer.cornerCurve = .continuous
        }
        saveButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 18, bottom: 10, right: 18)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        actionButtonsStack.addArrangedSubview(cancelButton)
        actionButtonsStack.addArrangedSubview(saveButton)
        whenContainer.addArrangedSubview(actionButtonsStack)

        updateChipStyles()
    }

    @objc private func chipTapped(_ sender: UIButton) {
        let index = sender.tag
        selectedPresetIndex = index
        let preset = presets[index]

        if preset.label == "Custom…" {
            datePicker.isHidden = false
            let chosen = datePicker.date
            selectedReturnDate = chosen
            selectedTimeLabel.text = "Returns on \(formatDate(chosen))"
        } else {
            datePicker.isHidden = true
            selectedReturnDate = preset.calculate()
            if let date = selectedReturnDate {
                selectedTimeLabel.text = "Returns on \(formatDate(date))"
            } else {
                selectedTimeLabel.text = preset.hint
            }
        }
        updateChipStyles()
    }

    @objc private func datePickerChanged(_ sender: UIDatePicker) {
        selectedReturnDate = sender.date
        selectedTimeLabel.text = "Returns on \(formatDate(sender.date))"
    }

    @objc private func saveTapped() {
        onConfirmCallback?(selectedReturnDate)
    }

    @objc private func cancelTapped() {
        onCancelCallback?()
    }

    private func updateChipStyles() {
        for (i, btn) in chipButtons.enumerated() {
            let isSelected = i == selectedPresetIndex
            if isSelected {
                btn.backgroundColor = UIColor(red: 0.824, green: 0.973, blue: 0.012, alpha: 1.0)
                btn.setTitleColor(UIColor(red: 0.09, green: 0.09, blue: 0.07, alpha: 1.0), for: .normal)
            } else {
                btn.backgroundColor = UIColor { trait in
                    trait.userInterfaceStyle == .dark
                        ? UIColor(white: 0.22, alpha: 0.5)
                        : UIColor(white: 0.90, alpha: 0.7)
                }
                btn.setTitleColor(.label, for: .normal)
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = .current
        formatter.dateFormat = "EEE, MMM d · h:mm a"
        return formatter.string(from: date)
    }

    func setState(_ state: State, dismissDuration: TimeInterval = 2.4) {
        switch state {
        case .promptWhen(let previewTitle, let previewSubtitle, let kind, let onConfirm, let onCancel):
            self.onConfirmCallback = onConfirm
            self.onCancelCallback = onCancel

            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            iconImageView.isHidden = false
            progressTrack.isHidden = true
            whenContainer.isHidden = false

            badgeContainer.backgroundColor = UIColor(red: 0.824, green: 0.973, blue: 0.012, alpha: 0.22)
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
            iconImageView.image = UIImage(systemName: "tray.and.arrow.down.fill", withConfiguration: symbolConfig)
            iconImageView.transform = .identity

            titleLabel.text = previewTitle

            if let subtitle = previewSubtitle, !subtitle.isEmpty {
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

            // Reset preset to Inbox by default
            selectedPresetIndex = 0
            selectedReturnDate = nil
            datePicker.isHidden = true
            selectedTimeLabel.text = presets[0].hint
            updateChipStyles()

        case .saving:
            whenContainer.isHidden = true
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
            iconImageView.isHidden = true
            progressTrack.isHidden = true
            pillView.isHidden = true
            badgeContainer.backgroundColor = UIColor(red: 0.824, green: 0.973, blue: 0.012, alpha: 0.15)
            titleLabel.text = "Saving to LaterBox…"

        case .success(let subtitle, let kind):
            whenContainer.isHidden = true
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            iconImageView.isHidden = false
            progressTrack.isHidden = false

            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
            iconImageView.image = UIImage(systemName: "checkmark", withConfiguration: symbolConfig)
            iconImageView.tintColor = UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(red: 0.824, green: 0.973, blue: 0.012, alpha: 1.0)
                    : UIColor(red: 0.20, green: 0.55, blue: 0.05, alpha: 1.0)
            }
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
            whenContainer.isHidden = true
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

