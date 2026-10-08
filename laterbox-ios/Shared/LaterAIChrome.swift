import SwiftUI

/// Shared chrome prevents the host and share extension from drifting visually.
enum LaterAIStyle {
    static let accent = Color(red: 230.0 / 255, green: 237.0 / 255, blue: 176.0 / 255)
    static let field = Color(red: 31.0 / 255, green: 31.0 / 255, blue: 33.0 / 255)
}
struct LaterAIHeader: View {
    var canReset: Bool
    var close: () -> Void
    var reset: () -> Void
    var body: some View {
        VStack(spacing: 10) {
            Capsule().fill(Color.white.opacity(0.3)).frame(width: 38, height: 4.5).padding(.top, 6)
            HStack {
                Button(action: close) { icon("chevron.down", enabled: true) }.accessibilityLabel("Close Later AI")
                Spacer()
                HStack(spacing: 7) {
                    Image(systemName: "sparkles").font(.system(size: 15, weight: .semibold)).foregroundStyle(LaterAIStyle.accent)
                    Text("Later AI").font(.system(size: 17, weight: .bold)).foregroundStyle(.white)
                    Text("PREVIEW").font(.system(size: 9, weight: .bold)).foregroundStyle(.black)
                        .padding(.horizontal, 5).padding(.vertical, 2).background(LaterAIStyle.accent, in: Capsule())
                }
                Spacer()
                Button(action: reset) { icon("square.and.pencil", enabled: canReset) }.disabled(!canReset).accessibilityLabel("New chat")
            }.padding(.horizontal, 18).padding(.bottom, 8)
            Divider().background(Color.white.opacity(0.08))
        }.buttonStyle(.plain)
    }
    private func icon(_ name: String, enabled: Bool) -> some View {
        Image(systemName: name).font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.white.opacity(enabled ? 1 : 0.3))
            .frame(width: 36, height: 36).background(Color.white.opacity(0.12), in: Circle())
    }
}
struct LaterAIComposer: View {
    @Binding var text: String
    var thinking: Bool
    var attach: () -> Void
    var send: () -> Void
    var body: some View {
        let hasText = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 10) {
                Button(action: attach) {
                    Image(systemName: "plus").font(.system(size: 17, weight: .semibold)).foregroundStyle(.white)
                        .frame(width: 36, height: 36).background(Color.white.opacity(0.12), in: Circle())
                }.accessibilityLabel("Guided capture")
                HStack(alignment: .bottom, spacing: 8) {
                    TextField("", text: $text, prompt: Text("Message Later AI...").foregroundColor(Color.white.opacity(0.60)), axis: .vertical)
                        .font(.system(size: 15)).foregroundStyle(.white).tint(LaterAIStyle.accent).lineLimit(1...5)
                        .padding(.vertical, 8).padding(.leading, 4)
                    Button(action: send) {
                        Image(systemName: "arrow.up").font(.system(size: hasText ? 14 : 16, weight: hasText ? .bold : .medium))
                            .foregroundStyle(hasText ? .black : Color.white.opacity(0.75)).frame(width: 32, height: 32)
                            .background(hasText ? LaterAIStyle.accent : .clear, in: Circle())
                    }.disabled(!hasText || thinking).padding(.bottom, 2).accessibilityLabel("Send message")
                }.padding(.horizontal, 12).padding(.vertical, 4)
                    .background(LaterAIStyle.field, in: RoundedRectangle(cornerRadius: 24))
                    .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
            }.padding(.horizontal, 16).padding(.top, 8)
            Text("Later AI can make mistakes. Verify important info.").font(.system(size: 11)).foregroundStyle(Color.white.opacity(0.35)).padding(.bottom, 6)
        }.background(.black).buttonStyle(.plain).environment(\.colorScheme, .light)
    }
}

struct LaterAIChatRow: View {
    var text: String
    var isUser: Bool
    var timestamp: Date?
    var body: some View {
        if isUser {
            HStack {
                Spacer(minLength: 48)
                Text(text).font(.system(size: 15)).foregroundStyle(.white)
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(Color(red: 39.0/255, green: 39.0/255, blue: 41.0/255), in: RoundedRectangle(cornerRadius: 18))
            }
        } else {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles").font(.system(size: 13, weight: .semibold)).foregroundStyle(LaterAIStyle.accent)
                    .frame(width: 30, height: 30).background(Color(white: 28.0/255), in: Circle())
                VStack(alignment: .leading, spacing: 6) {
                    Text(text).font(.system(size: 15)).foregroundStyle(.white).lineSpacing(4)
                    if let timestamp {
                        Text(timestamp.formatted(date: .omitted, time: .shortened)).font(.system(size: 11)).foregroundStyle(Color.white.opacity(0.35))
                    }
                }
                Spacer(minLength: 32)
            }
        }
    }
}
struct LaterAIThinkingIndicator: View {
    var thinking: Bool
    var statusText: String = "Later AI is writing..."
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color(white: 28.0/255))
                    .frame(width: 32, height: 32)
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LaterAIStyle.accent)
            }
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    ForEach(0..<3) { i in
                        Circle().fill(LaterAIStyle.accent).frame(width: 5.5, height: 5.5)
                            .scaleEffect(thinking ? 1 : 0.4)
                            .opacity(thinking ? 1 : 0.4)
                            .animation(.easeInOut(duration: 0.55).repeatForever().delay(Double(i) * 0.18), value: thinking)
                    }
                }
                Text(statusText).font(.system(size: 13, weight: .medium)).foregroundColor(Color.white.opacity(0.7))
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Color(white: 24.0/255), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
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
    var title: String? = nil
    var options: [LaterAIOptionItem]
    var onManualType: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                if let title, !title.isEmpty {
                    Text(title)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.65))
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                Spacer()
                Button(action: onManualType) {
                    HStack(spacing: 4) {
                        Image(systemName: "keyboard")
                            .font(.system(size: 11))
                        Text("Type instead")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(Color.white.opacity(0.55))
                }
                .buttonStyle(.plain)
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
                                        .foregroundColor(opt.isPrimary ? .black : LaterAIStyle.accent)
                                }
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(opt.title)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(opt.isPrimary ? .black : .white)
                                    if let sub = opt.subtitle {
                                        Text(sub)
                                            .font(.system(size: 10))
                                            .foregroundColor(opt.isPrimary ? Color.black.opacity(0.7) : Color.white.opacity(0.6))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(opt.isPrimary ? AnyShapeStyle(LaterAIStyle.accent) : AnyShapeStyle(Color(white: 24.0/255)))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(opt.isPrimary ? Color.black.opacity(0.12) : Color.white.opacity(0.12), lineWidth: 1)
                            )
                            .shadow(color: opt.isPrimary ? LaterAIStyle.accent.opacity(0.3) : Color.clear, radius: 8, y: 3)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }

            Text("Later AI can make mistakes. Verify important info.")
                .font(.system(size: 11))
                .foregroundColor(Color.white.opacity(0.35))
                .padding(.bottom, 6)
        }
        .padding(.top, 8)
        .background(Color.black)
        .environment(\.colorScheme, .light)
    }
}
