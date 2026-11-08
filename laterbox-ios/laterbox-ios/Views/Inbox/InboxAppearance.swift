// laterbox-ios/laterbox-ios/Views/Inbox/InboxAppearance.swift
import SwiftUI

/// Inbox-specific neutral palette: clean white in Light Mode and soft
/// graphite charcoal in Dark Mode with contrasting controls and cards.
enum InboxAppearance {
    static func background(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "1B1D20") : .white
    }

    static func surface(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "25282B") : Color(hex: "F5F5F5")
    }

    static func textPrimary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .white : .black
    }

    static func textSecondary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.68) : Color.black.opacity(0.60)
    }

    static func border(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.11) : Color.black.opacity(0.07)
    }

    static func inactiveStar(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.44) : Color.black.opacity(0.28)
    }
}

/// A restrained, static graphite grain for the Inbox and its fixed header.
/// Drawing two compound paths makes the texture inexpensive to render;
/// positions are seeded, not randomized per redraw, so nothing flickers.
struct InboxGrainBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [
                        Color(hex: "222427"),
                        InboxAppearance.background(for: .dark),
                        Color(hex: "17191B")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Canvas(opaque: false, rendersAsynchronously: true) { context, size in
                    guard size.width > 0, size.height > 0 else { return }

                    var highlights = Path()
                    var shadows = Path()
                    let count = min(9_000, Int(size.width * size.height / 62))

                    for index in 0..<count {
                        let seed = UInt64(index)
                        let x = Self.noise(seed &* 3 &+ 11) * size.width
                        let y = Self.noise(seed &* 3 &+ 12) * size.height
                        let diameter = 0.6 + Self.noise(seed &* 3 &+ 13) * 0.8
                        let speck = CGRect(x: x, y: y, width: diameter, height: diameter)

                        if index.isMultiple(of: 2) {
                            highlights.addRect(speck)
                        } else {
                            shadows.addRect(speck)
                        }
                    }

                    context.fill(highlights, with: .color(.white.opacity(0.075)))
                    context.fill(shadows, with: .color(.black.opacity(0.16)))
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            } else {
                Color.white
            }
        }
    }

    /// Stable hash-based noise in [0, 1], independent of scrolling/time.
    static func noise(_ value: UInt64) -> CGFloat {
        var seed = value &+ 0x9E3779B97F4A7C15
        seed = (seed ^ (seed >> 30)) &* 0xBF58476D1CE4E5B9
        seed = (seed ^ (seed >> 27)) &* 0x94D049BB133111EB
        seed = seed ^ (seed >> 31)
        return CGFloat(seed & 0xFFFF) / 65_535
    }
}
