import SwiftUI

/// Draws instructional callouts in SwiftUI over the original screenshots.
/// The bundled screenshots are never modified or redrawn.
struct ShortcutGuideScreenshotView: View {
    let stepNumber: Int
    let arrowStart: CGPoint  // Normalized 0...1, relative to the original screenshot
    let arrowTip: CGPoint
    var secondaryHighlights: [CGPoint] = []
    var targetArea: CGRect? = nil
    var showsTargetRing = true

    @State private var showingEnlarged = false

    var body: some View {
        Button {
            showingEnlarged = true
        } label: {
            annotatedScreenshot
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.10), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Screenshot \(stepNumber) of 9, annotated with an arrow. Tap to enlarge.")
        .accessibilityIdentifier("learn.shortcutGuide.image\(stepNumber)")
        .fullScreenCover(isPresented: $showingEnlarged) {
            NavigationStack {
                ZStack {
                    Color.black.ignoresSafeArea()
                    ScrollView {
                        annotatedScreenshot
                            .padding(.horizontal, 14)
                            .padding(.vertical, 16)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Close", systemImage: "xmark") {
                            showingEnlarged = false
                        }
                    }
                }
                .toolbarBackground(.visible, for: .navigationBar)
                .preferredColorScheme(.dark)
            }
        }
    }

    private var annotatedScreenshot: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ZStack {
                Image("ShortcutGuide\(stepNumber)")
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)

                if let targetArea {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .strokeBorder(Color(red: 0.95, green: 0.20, blue: 0.16), lineWidth: 2)
                        .frame(width: size.width * targetArea.width,
                               height: size.height * targetArea.height)
                        .position(x: size.width * targetArea.midX,
                                  y: size.height * targetArea.midY)
                        .shadow(color: .black.opacity(0.55), radius: 2)
                }

                // Short pointers never sweep across other actions or obscure labels.
                TutorialArrowShape(start: arrowStart, tip: arrowTip)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                    .shadow(color: .black.opacity(0.6), radius: 2, y: 1)

                TutorialArrowShape(start: arrowStart, tip: arrowTip)
                    .stroke(Color(red: 0.95, green: 0.20, blue: 0.16),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                ForEach(secondaryHighlights.indices, id: \.self) { index in
                    targetRing(in: size, at: secondaryHighlights[index], prominent: false)
                }
                if showsTargetRing {
                    targetRing(in: size, at: arrowTip, prominent: true)
                }
            }
            .frame(width: size.width, height: size.height)
            .clipped()
        }
        .aspectRatio(1320.0 / 2868.0, contentMode: .fit)
    }

    private func targetRing(in size: CGSize, at point: CGPoint, prominent: Bool) -> some View {
        Circle()
            .strokeBorder(.white, lineWidth: prominent ? 2 : 1.5)
            .overlay(Circle().strokeBorder(Color(red: 0.95, green: 0.20, blue: 0.16), lineWidth: 2))
            .frame(width: prominent ? 26 : 21, height: prominent ? 26 : 21)
            .position(x: size.width * point.x, y: size.height * point.y)
            .shadow(color: .black.opacity(0.5), radius: 3)
    }
}

private struct TutorialArrowShape: Shape {
    let start: CGPoint
    let tip: CGPoint

    func path(in rect: CGRect) -> Path {
        let a = CGPoint(x: rect.width * start.x, y: rect.height * start.y)
        let b = CGPoint(x: rect.width * tip.x, y: rect.height * tip.y)
        let dx = b.x - a.x
        let dy = b.y - a.y
        let length = max(hypot(dx, dy), 1)
        // Limit the arrow to a small pointer near its target even if the
        // normalized tail is far away in a tall screenshot.
        let shaft = min(length, rect.width * 0.14)
        let tail = CGPoint(x: b.x - dx / length * shaft,
                           y: b.y - dy / length * shaft)
        let bend = min(rect.width * 0.025, shaft * 0.10)
        let control = CGPoint(
            x: (tail.x + b.x) / 2 - (dy / length) * bend,
            y: (tail.y + b.y) / 2 + (dx / length) * bend
        )
        let angle = atan2(b.y - control.y, b.x - control.x)
        let head = min(rect.width * 0.035, 12.0)
        let spread: CGFloat = .pi / 5

        var path = Path()
        path.move(to: tail)
        path.addQuadCurve(to: b, control: control)
        path.move(to: CGPoint(
            x: b.x - head * cos(angle - spread),
            y: b.y - head * sin(angle - spread)
        ))
        path.addLine(to: b)
        path.addLine(to: CGPoint(
            x: b.x - head * cos(angle + spread),
            y: b.y - head * sin(angle + spread)
        ))
        return path
    }
}
