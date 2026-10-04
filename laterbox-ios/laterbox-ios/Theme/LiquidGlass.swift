//
//  LiquidGlass.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Brand Colors & Palette
extension Color {
    // Official LaterBox Theme Colors (#F7F5EE background & #E6EDB0 green theme)
    public static let lbBackground = Color(red: 247/255, green: 245/255, blue: 238/255) // #F7F5EE
    public static let lbGreenTheme = Color(red: 230/255, green: 237/255, blue: 176/255) // #E6EDB0

    public static let lbAmber = Color(red: 245/255, green: 158/255, blue: 11/255) // #F59E0B
    public static let lbAmberLight = Color(red: 251/255, green: 191/255, blue: 36/255) // #FBBF24
    public static let lbAmberDark = Color(red: 217/255, green: 119/255, blue: 6/255) // #D97706
    public static let lbEmerald = Color(red: 230/255, green: 237/255, blue: 176/255) // #E6EDB0 primary green theme
    public static let lbEmeraldLight = Color(red: 240/255, green: 245/255, blue: 200/255)
    public static let lbDarkBackground = Color(red: 22/255, green: 22/255, blue: 20/255)
    public static let lbCardBackground = Color(red: 255/255, green: 255/255, blue: 255/255)
    
    public static func dynamicBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? lbDarkBackground : lbBackground
    }
}

// MARK: - Haptic Feedback
public enum LBHaptic {
    public static func light() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
    public static func medium() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }
    public static func heavy() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        #endif
    }
    public static func success() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
    public static func warning() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        #endif
    }
    public static func error() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        #endif
    }
}

// MARK: - Liquid Glass View Modifiers
public struct LiquidGlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat
    var borderOpacity: Double
    var isInteractive: Bool
    @Environment(\.colorScheme) private var colorScheme

    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? borderOpacity : borderOpacity * 1.5),
                                Color.white.opacity(0.04),
                                Color.lbAmber.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: colorScheme == .dark
                    ? Color.black.opacity(0.35)
                    : Color.black.opacity(0.06),
                radius: 12,
                x: 0,
                y: 6
            )
    }
}

public struct LiquidGlassPillModifier: ViewModifier {
    var isSelected: Bool
    @Environment(\.colorScheme) private var colorScheme

    public func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(Color.lbAmber) : AnyShapeStyle(.ultraThinMaterial))
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(
                        isSelected
                            ? Color.white.opacity(0.3)
                            : Color.white.opacity(colorScheme == .dark ? 0.15 : 0.4),
                        lineWidth: 1
                    )
            )
            .foregroundColor(isSelected ? .black : .primary)
            .shadow(
                color: isSelected ? Color.lbAmber.opacity(0.3) : Color.clear,
                radius: 6,
                y: 2
            )
    }
}

extension View {
    public func liquidGlass(cornerRadius: CGFloat = 16, borderOpacity: Double = 0.22) -> some View {
        self.modifier(LiquidGlassCardModifier(cornerRadius: cornerRadius, borderOpacity: borderOpacity, isInteractive: false))
    }

    public func liquidGlassCard(cornerRadius: CGFloat = 20, borderOpacity: Double = 0.22, isInteractive: Bool = false) -> some View {
        self.modifier(LiquidGlassCardModifier(cornerRadius: cornerRadius, borderOpacity: borderOpacity, isInteractive: isInteractive))
    }

    public func liquidGlassPill(isSelected: Bool = false) -> some View {
        self.modifier(LiquidGlassPillModifier(isSelected: isSelected))
    }
}

// MARK: - Ambient Liquid Glass Mesh Background
public struct LiquidGlassBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    public var body: some View {
        ZStack {
            Color.dynamicBackground(for: colorScheme)
                .ignoresSafeArea()

            if colorScheme == .dark {
                // Amber Orb
                Circle()
                    .fill(Color.lbAmber.opacity(0.18))
                    .frame(width: 320, height: 320)
                    .blur(radius: 80)
                    .offset(x: -120, y: -220)

                // Purple/Indigo Contrast Orb
                Circle()
                    .fill(Color(red: 99/255, green: 102/255, blue: 241/255).opacity(0.14))
                    .frame(width: 300, height: 300)
                    .blur(radius: 90)
                    .offset(x: 140, y: 120)

                // Teal Accent Orb
                Circle()
                    .fill(Color(red: 20/255, green: 184/255, blue: 166/255).opacity(0.10))
                    .frame(width: 260, height: 260)
                    .blur(radius: 80)
                    .offset(x: -80, y: 340)
            } else {
                // Light mode subtle warmth
                Circle()
                    .fill(Color.lbAmber.opacity(0.12))
                    .frame(width: 340, height: 340)
                    .blur(radius: 90)
                    .offset(x: -100, y: -200)

                Circle()
                    .fill(Color(red: 99/255, green: 102/255, blue: 241/255).opacity(0.08))
                    .frame(width: 300, height: 300)
                    .blur(radius: 90)
                    .offset(x: 130, y: 150)
            }
        }
        .allowsHitTesting(false)
    }
}
