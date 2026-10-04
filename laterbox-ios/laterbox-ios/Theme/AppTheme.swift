//
//  AppTheme.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import SwiftUI

// MARK: - Centralized LaterBox Theme
/// Change these simple master variables to easily restyle the entire app from one place.
public enum AppTheme {
    // Primary Brand Surfaces & Accents
    public static var background: Color = Color(hex: "F7F5EE")       // Main warm canvas background (#F7F5EE)
    public static var accent: Color = Color(hex: "E6EDB0")           // Signature pastel green brand accent (#E6EDB0)
    public static var darkSurface: Color = Color(hex: "181818")      // Primary dark button / dark card background
    public static var cardBackground: Color = Color.white            // Default card background
    public static var cardBorder: Color = Color.black.opacity(0.06)  // Light card border
    public static var darkCardBorder: Color = Color.white.opacity(0.12)// Dark card border

    // Text & Content Typography Colors
    public static var textPrimary: Color = Color.black               // Headings, titles, prominent text
    public static var textSecondary: Color = Color.black.opacity(0.6)// Subtitles, secondary descriptions
    public static var textTertiary: Color = Color.black.opacity(0.4) // Subtle metadata, timestamps
    public static var textOnDark: Color = Color.white                // Text on dark buttons / cards
    public static var textOnDarkSecondary: Color = Color.white.opacity(0.75) // Secondary text on dark cards

    // Status Colors
    public static var statusSuccess: Color = Color(hex: "E6EDB0")    // Synced / success state
    public static var amber: Color = Color(hex: "F59E0B")            // Starred / highlight amber
    public static var indigo: Color = Color(hex: "6366F1")           // Contrast indigo
}

// MARK: - Hex Color Initializer
extension Color {
    public init(hex: String) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleanHex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
