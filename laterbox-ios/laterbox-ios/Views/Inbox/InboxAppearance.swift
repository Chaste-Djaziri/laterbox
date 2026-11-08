// laterbox-ios/laterbox-ios/Views/Inbox/InboxAppearance.swift
import SwiftUI

/// Inbox-specific neutral palette: a truly white / black canvas with contrasting
/// controls and cards. This does not recolor the rest of the app's branded screens.
enum InboxAppearance {
    static func background(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .black : .white
    }

    static func surface(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "171717") : Color(hex: "F5F5F5")
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
