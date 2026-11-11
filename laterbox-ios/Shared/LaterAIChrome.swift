import SwiftUI

/// Shared chrome prevents the host and share extension from drifting visually.
/// Dynamically adapts to both Light and Dark mode using LaterBox's warm canvas
/// background (#F7F5EE), clean surface cards, and signature pastel lime accent (#E6EDB0).
enum LaterAIStyle {
    static let accent = Color(red: 230.0 / 255, green: 237.0 / 255, blue: 176.0 / 255)
    static let brandGreen = Color(red: 107.0 / 255, green: 137.0 / 255, blue: 81.0 / 255)

    static func canvas(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 27.0 / 255, green: 29.0 / 255, blue: 32.0 / 255)
            : Color(red: 247.0 / 255, green: 245.0 / 255, blue: 238.0 / 255)
    }

    static func surface(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 37.0 / 255, green: 40.0 / 255, blue: 43.0 / 255)
            : Color.white
    }

    static func textPrimary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .white : Color(red: 23.0 / 255, green: 23.0 / 255, blue: 17.0 / 255)
    }

    static func textSecondary(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.68)
            : Color(red: 104.0 / 255, green: 117.0 / 255, blue: 95.0 / 255)
    }

    static func border(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.12)
            : Color.black.opacity(0.08)
    }

    static func fieldBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 31.0 / 255, green: 31.0 / 255, blue: 33.0 / 255)
            : Color(red: 238.0 / 255, green: 237.0 / 255, blue: 230.0 / 255)
    }
}

struct LaterAIHeader: View {
    @Environment(\.colorScheme) private var colorScheme
    var title: String = "Save to LaterBox"
    var canReset: Bool
    var close: () -> Void
    var reset: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Capsule()
                .fill(LaterAIStyle.textSecondary(for: colorScheme).opacity(0.35))
                .frame(width: 38, height: 4.5)
                .padding(.top, 6)
            HStack {
                Button(action: close) {
                    icon("chevron.down", enabled: true)
                }
                .accessibilityLabel("Close")

                Spacer()

                HStack(spacing: 7) {
                    Image(systemName: "tray.and.arrow.down.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(LaterAIStyle.brandGreen)
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(LaterAIStyle.textPrimary(for: colorScheme))
                }

                Spacer()

                Button(action: reset) {
                    icon("arrow.counterclockwise", enabled: canReset)
                }
                .disabled(!canReset)
                .accessibilityLabel("Reset")
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 8)

            Divider().background(LaterAIStyle.border(for: colorScheme))
        }
        .buttonStyle(.plain)
    }

    private func icon(_ name: String, enabled: Bool) -> some View {
        Image(systemName: name)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(LaterAIStyle.textPrimary(for: colorScheme).opacity(enabled ? 1 : 0.3))
            .frame(width: 36, height: 36)
            .background(LaterAIStyle.surface(for: colorScheme), in: Circle())
            .overlay(Circle().strokeBorder(LaterAIStyle.border(for: colorScheme), lineWidth: 1))
    }
}

struct LaterAIComposer: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var text: String
    var thinking: Bool
    var attach: () -> Void
    var send: () -> Void

    var body: some View {
        let hasText = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 10) {
                Button(action: attach) {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(LaterAIStyle.textPrimary(for: colorScheme))
                        .frame(width: 36, height: 36)
                        .background(LaterAIStyle.surface(for: colorScheme), in: Circle())
                        .overlay(Circle().strokeBorder(LaterAIStyle.border(for: colorScheme), lineWidth: 1))
                }
                .accessibilityLabel("Guided capture")

                HStack(alignment: .bottom, spacing: 8) {
                    TextField("", text: $text, prompt: Text("Message Later AI...").foregroundColor(LaterAIStyle.textSecondary(for: colorScheme)), axis: .vertical)
                        .font(.system(size: 15))
                        .foregroundStyle(LaterAIStyle.textPrimary(for: colorScheme))
                        .tint(LaterAIStyle.brandGreen)
                        .lineLimit(1...5)
                        .padding(.vertical, 8)
                        .padding(.leading, 4)

                    Button(action: send) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: hasText ? 14 : 16, weight: hasText ? .bold : .medium))
                            .foregroundStyle(hasText ? Color(red: 23.0 / 255, green: 23.0 / 255, blue: 17.0 / 255) : LaterAIStyle.textSecondary(for: colorScheme))
                            .frame(width: 32, height: 32)
                            .background(hasText ? LaterAIStyle.accent : .clear, in: Circle())
                    }
                    .disabled(!hasText || thinking)
                    .padding(.bottom, 2)
                    .accessibilityLabel("Send message")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(LaterAIStyle.fieldBackground(for: colorScheme), in: RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(LaterAIStyle.border(for: colorScheme), lineWidth: 1))
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(LaterAIStyle.canvas(for: colorScheme))
        .buttonStyle(.plain)
    }
}

struct LaterAIChatRow: View {
    @Environment(\.colorScheme) private var colorScheme
    var text: String
    var isUser: Bool
    var timestamp: Date?
    var iconName: String = "tray.and.arrow.down.fill"

    var body: some View {
        if isUser {
            HStack {
                Spacer(minLength: 48)
                Text(text)
                    .font(.system(size: 15))
                    .foregroundStyle(colorScheme == .dark ? .white : Color(red: 23.0 / 255, green: 23.0 / 255, blue: 17.0 / 255))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        colorScheme == .dark
                            ? Color(red: 39.0 / 255, green: 39.0 / 255, blue: 41.0 / 255)
                            : Color(red: 230.0 / 255, green: 237.0 / 255, blue: 176.0 / 255).opacity(0.45),
                        in: RoundedRectangle(cornerRadius: 18)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(LaterAIStyle.border(for: colorScheme), lineWidth: 1)
                    )
            }
        } else {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: iconName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(LaterAIStyle.brandGreen)
                    .frame(width: 30, height: 30)
                    .background(LaterAIStyle.surface(for: colorScheme), in: Circle())
                    .overlay(Circle().strokeBorder(LaterAIStyle.border(for: colorScheme), lineWidth: 1))

                VStack(alignment: .leading, spacing: 6) {
                    Text(text)
                        .font(.system(size: 15))
                        .foregroundStyle(LaterAIStyle.textPrimary(for: colorScheme))
                        .lineSpacing(4)
                    if let timestamp {
                        Text(timestamp.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 11))
                            .foregroundStyle(LaterAIStyle.textSecondary(for: colorScheme))
                    }
                }
                Spacer(minLength: 32)
            }
        }
    }
}

struct LaterAIThinkingIndicator: View {
    @Environment(\.colorScheme) private var colorScheme
    var thinking: Bool
    var statusText: String = "Preparing draft..."

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                Circle()
                    .fill(LaterAIStyle.surface(for: colorScheme))
                    .frame(width: 32, height: 32)
                Image(systemName: "tray.and.arrow.down.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(LaterAIStyle.brandGreen)
            }
            .overlay(Circle().strokeBorder(LaterAIStyle.border(for: colorScheme), lineWidth: 1))

            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(LaterAIStyle.brandGreen)
                            .frame(width: 5.5, height: 5.5)
                            .scaleEffect(thinking ? 1 : 0.4)
                            .opacity(thinking ? 1 : 0.4)
                            .animation(.easeInOut(duration: 0.55).repeatForever().delay(Double(i) * 0.18), value: thinking)
                    }
                }
                Text(statusText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(LaterAIStyle.textSecondary(for: colorScheme))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(LaterAIStyle.surface(for: colorScheme), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(LaterAIStyle.border(for: colorScheme), lineWidth: 1))

            Spacer()
        }
    }
}

public struct LaterAIOptionItem: Identifiable, Equatable {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let icon: String?
    public let isPrimary: Bool
    public let action: () -> Void

    public init(
        id: String = UUID().uuidString,
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        isPrimary: Bool = false,
        action: @escaping () -> Void
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.isPrimary = isPrimary
        self.action = action
    }

    public static func == (lhs: LaterAIOptionItem, rhs: LaterAIOptionItem) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title && lhs.subtitle == rhs.subtitle && lhs.icon == rhs.icon && lhs.isPrimary == rhs.isPrimary
    }
}

struct LaterAIOptionsDock: View {
    @Environment(\.colorScheme) private var colorScheme
    var title: String? = nil
    var options: [LaterAIOptionItem]
    var onManualType: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                if let title, !title.isEmpty {
                    Text(title)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(LaterAIStyle.textSecondary(for: colorScheme))
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                Spacer()
                if let onManualType {
                    Button(action: onManualType) {
                        HStack(spacing: 4) {
                            Image(systemName: "keyboard")
                                .font(.system(size: 11))
                            Text("Type instead")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(LaterAIStyle.textSecondary(for: colorScheme))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options) { opt in
                        Button(action: {
                            opt.action()
                        }) {
                            HStack(spacing: 8) {
                                if let icon = opt.icon {
                                    Image(systemName: icon)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(opt.isPrimary ? Color(red: 23.0 / 255, green: 23.0 / 255, blue: 17.0 / 255) : LaterAIStyle.brandGreen)
                                }
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(opt.title)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(opt.isPrimary ? Color(red: 23.0 / 255, green: 23.0 / 255, blue: 17.0 / 255) : LaterAIStyle.textPrimary(for: colorScheme))
                                    if let sub = opt.subtitle {
                                        Text(sub)
                                            .font(.system(size: 10))
                                            .foregroundColor(opt.isPrimary ? Color(red: 23.0 / 255, green: 23.0 / 255, blue: 17.0 / 255).opacity(0.7) : LaterAIStyle.textSecondary(for: colorScheme))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(opt.isPrimary ? AnyShapeStyle(LaterAIStyle.accent) : AnyShapeStyle(LaterAIStyle.surface(for: colorScheme)))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(opt.isPrimary ? Color.black.opacity(0.12) : LaterAIStyle.border(for: colorScheme), lineWidth: 1)
                            )
                            .shadow(color: opt.isPrimary ? LaterAIStyle.accent.opacity(0.3) : Color.black.opacity(colorScheme == .dark ? 0.25 : 0.05), radius: 6, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
            .accessibilityIdentifier("capture.options")
        }
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(LaterAIStyle.canvas(for: colorScheme))
    }
}
