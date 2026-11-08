// laterbox-ios/laterbox-ios/Views/Components/LaterBoxVectorMark.swift
import SwiftUI

/// Transparent, resolution-independent recreation of the three faces of the LaterBox cube.
/// The paths come from the original 1024 x 1024 brand mark, cropped to its ink bounds.
/// No raster asset, background fill, mask image, or embedded font is required.
enum LaterBoxMarkAppearance {
    /// Dark ink for light surfaces.
    case light
    /// White ink for dark surfaces.
    case dark
    /// Automatically choose the ink based on the current color scheme.
    case automatic
}

/// Reusable mark; customize its size, ink, light/dark appearance and animation.
struct LaterBoxVectorMark: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var assembled = false
    @State private var lidFloating = false

    var size: CGFloat = 42
    var appearance: LaterBoxMarkAppearance = .automatic
    var ink: Color? = nil
    var animates: Bool = true
    /// Increment to replay the gentle assembly animation (e.g. when tapping the logo).
    var replayToken: Int = 0

    private var resolvedInk: Color {
        if let ink { return ink }
        switch appearance {
        case .light: return Color(hex: "171711")
        case .dark: return Color.white
        case .automatic: return colorScheme == .dark ? Color.white : Color(hex: "171711")
        }
    }

    private var showAssembled: Bool {
        !animates || reduceMotion || assembled
    }

    var body: some View {
        ZStack {
            LaterBoxMarkShape(part: .left)
                .fill(resolvedInk, style: FillStyle(eoFill: true))
                .offset(x: showAssembled ? 0 : -size * 0.075)
                .opacity(showAssembled ? 1 : 0)

            LaterBoxMarkShape(part: .right)
                .fill(resolvedInk, style: FillStyle(eoFill: true))
                .offset(x: showAssembled ? 0 : size * 0.075)
                .opacity(showAssembled ? 1 : 0)

            LaterBoxMarkShape(part: .lid)
                .fill(resolvedInk, style: FillStyle(eoFill: true))
                .offset(y: showAssembled ? (lidFloating ? -size * 0.018 : 0) : -size * 0.12)
                .opacity(showAssembled ? 1 : 0)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
        .task(id: replayToken) {
            await animateAssembly()
        }
    }

    @MainActor
    private func animateAssembly() async {
        guard animates && !reduceMotion else {
            assembled = true
            lidFloating = false
            return
        }

        assembled = false
        lidFloating = false
        await Task.yield()
        guard !Task.isCancelled else { return }
        withAnimation(.spring(response: 0.65, dampingFraction: 0.78)) {
            assembled = true
        }

        try? await Task.sleep(for: .milliseconds(800))
        guard !Task.isCancelled else { return }
        withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
            lidFloating = true
        }
    }
}

/// Draws the brand ink from bottom to top as a local startup stage completes.
/// Both copies use the same transparent vector paths; only the colored fill is masked.
struct LaterBoxLoadingMark: View {
    @Environment(\.colorScheme) private var colorScheme

    var size: CGFloat = 164
    var progress: Double
    /// Override either color for custom presentations, or use the system-adaptive defaults.
    var emptyInk: Color? = nil
    var filledInk: Color? = nil

    static func foreground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .white : .black
    }

    static func background(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .black : .white
    }

    /// Clamp startup stages so invalid/out-of-order values never escape the logo.
    static func normalizedProgress(_ progress: Double) -> Double {
        guard progress.isFinite else { return 0 }
        return min(1, max(0, progress))
    }

    private var fillHeight: CGFloat {
        size * CGFloat(Self.normalizedProgress(progress))
    }

    var body: some View {
        ZStack {
            LaterBoxVectorMark(
                size: size,
                ink: emptyInk ?? Self.foreground(for: colorScheme).opacity(0.16),
                animates: false
            )

            LaterBoxVectorMark(
                size: size,
                ink: filledInk ?? Self.foreground(for: colorScheme),
                animates: false
            )
                .mask {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        Rectangle()
                            .frame(height: fillHeight)
                    }
                    .frame(width: size, height: size)
                }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("LaterBox loading")
        .accessibilityValue("\(Int(Self.normalizedProgress(progress) * 100)) percent")
    }
}

/// The vector has exactly three independent ink pieces, allowing each face to animate.
/// All coordinates are relative to the cropped 603 x 656 artboard (original x=211, y=167).
struct LaterBoxMarkShape: Shape {
    enum Part {
        case lid
        case left
        case right
    }

    var part: Part

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch part {
        case .lid:
            polygon([
                (11, 157), (11, 160), (15, 165), (254, 295), (290, 313),
                (302, 312), (539, 187), (581, 164), (587, 159),
                (587, 155), (584, 151), (506, 107), (375, 36),
                (309, 2), (302, 0), (288, 3), (163, 69), (14, 153)
            ], into: &path)
            // Center of the cube lid: open, not painted white.
            polygon([
                (118, 157), (299, 63), (479, 157), (299, 262)
            ], into: &path)

        case .left:
            polygon([
                (0, 190), (0, 502), (2, 508), (11, 516), (263, 651),
                (275, 656), (274, 582), (73, 471), (67, 466), (67, 227)
            ], into: &path)

        case .right:
            polygon([
                (601, 185), (577, 199), (433, 274), (302, 337),
                (302, 650), (467, 571), (574, 523), (591, 514),
                (598, 508), (601, 502), (601, 406), (595, 393),
                (577, 380), (587, 371), (595, 360), (601, 343)
            ], into: &path)
            // Cut-out counters of the B. These also remain transparent.
            polygon([
                (543, 284), (542, 343), (539, 350), (528, 362),
                (508, 374), (441, 401), (370, 434), (367, 433),
                (367, 360), (369, 358), (466, 318), (537, 284)
            ], into: &path)
            polygon([
                (540, 432), (544, 440), (544, 469), (539, 480),
                (528, 491), (504, 504), (440, 531), (368, 566),
                (366, 565), (367, 487), (441, 453), (509, 426),
                (526, 424), (534, 427)
            ], into: &path)
        }

        let scale = min(rect.width / 603, rect.height / 656)
        let offsetX = rect.minX + (rect.width - 603 * scale) / 2
        let offsetY = rect.minY + (rect.height - 656 * scale) / 2
        return path.applying(CGAffineTransform(
            a: scale, b: 0, c: 0, d: scale, tx: offsetX, ty: offsetY
        ))
    }

    private func polygon(_ points: [(CGFloat, CGFloat)], into path: inout Path) {
        guard let first = points.first else { return }
        path.move(to: CGPoint(x: first.0, y: first.1))
        for (x, y) in points.dropFirst() {
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.closeSubpath()
    }
}

#Preview("Light ink · transparent") {
    LaterBoxVectorMark(size: 180, appearance: .light, animates: false)
        .padding(36)
        .background(Color(hex: "F7F5EE"))
}

#Preview("Dark ink · transparent") {
    LaterBoxVectorMark(size: 180, appearance: .dark, animates: false)
        .padding(36)
        .background(Color(hex: "171711"))
}
