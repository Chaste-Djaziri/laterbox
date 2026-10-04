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
    // Official LaterBox Theme Colors routed through AppTheme
    public static var lbBackground: Color { AppTheme.background }
    public static var lbGreenTheme: Color { AppTheme.accent }

    public static var lbAmber: Color { AppTheme.amber }
    public static let lbAmberLight = Color(red: 251/255, green: 191/255, blue: 36/255)
    public static let lbAmberDark = Color(red: 217/255, green: 119/255, blue: 6/255)
    public static var lbEmerald: Color { AppTheme.accent }
    public static let lbEmeraldLight = Color(red: 240/255, green: 245/255, blue: 200/255)
    public static var lbDarkBackground: Color { AppTheme.darkSurface }
    public static var lbCardBackground: Color { AppTheme.cardBackground }
    
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
                    .fill(colorScheme == .dark ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color.white))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        colorScheme == .dark
                            ? Color.white.opacity(borderOpacity)
                            : Color.black.opacity(0.06),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.04),
                radius: 10,
                x: 0,
                y: 4
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
                    .fill(isSelected ? AnyShapeStyle(Color.lbGreenTheme) : AnyShapeStyle(Color.white))
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(
                        isSelected
                            ? Color.black.opacity(0.12)
                            : Color.black.opacity(0.07),
                        lineWidth: 1
                    )
            )
            .foregroundColor(isSelected ? .black : Color.black.opacity(0.7))
            .shadow(
                color: isSelected ? Color.lbGreenTheme.opacity(0.4) : Color.clear,
                radius: 4,
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
            Color.lbBackground
                .ignoresSafeArea()

            if colorScheme == .dark {
                // Amber Orb
                Circle()
                    .fill(Color.lbAmber.opacity(0.18))
                    .frame(width: 320, height: 320)
                    .blur(radius: 80)
                    .offset(x: -120, y: -220)

                // Contrast Orb
                Circle()
                    .fill(Color(red: 99/255, green: 102/255, blue: 241/255).opacity(0.14))
                    .frame(width: 300, height: 300)
                    .blur(radius: 90)
                    .offset(x: 140, y: 120)
            } else {
                // Subtle pastel green theme (#E6EDB0) ambient illumination
                Circle()
                    .fill(Color.lbGreenTheme.opacity(0.35))
                    .frame(width: 320, height: 320)
                    .blur(radius: 100)
                    .offset(x: -120, y: -220)

                Circle()
                    .fill(Color.lbGreenTheme.opacity(0.20))
                    .frame(width: 300, height: 300)
                    .blur(radius: 90)
                    .offset(x: 140, y: 180)
            }
        }
        .allowsHitTesting(false)
    }
}
