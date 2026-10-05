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
        }.background(.black).buttonStyle(.plain).colorScheme(.dark)
    }
}
