package com.example.laterbox.theme

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.graphics.Color

/**
 * Centralized LaterBox AppTheme (1:1 Parity with iOS AppTheme).
 * Change the master green, white, or black colors to effortlessly restyle the entire app.
 */
object AppTheme {
    // Master Dynamic Brand Colors
    var green: Color by mutableStateOf(Color(0xFFE6EDB0))       // Signature pastel green brand accent
    var white: Color by mutableStateOf(Color(0xFFFFFFFF))       // Master card surface & pure white
    var black: Color by mutableStateOf(Color(0xFF181818))       // Dark surface & primary text black
    var background: Color by mutableStateOf(Color(0xFFF7F5EE))  // Warm canvas background

    // Dynamic brand surfaces & accents derived from master colors
    val accent: Color get() = green
    val cardBackground: Color get() = white
    val darkSurface: Color get() = black
    val darkCard: Color get() = Color(0xFF222222)
    val darkBg: Color get() = Color(0xFF121212)
    val cardBorder: Color get() = black.copy(alpha = 0.06f)
    val darkCardBorder: Color get() = white.copy(alpha = 0.12f)

    // Dynamic typography colors derived from master colors
    val textPrimary: Color get() = black
    val textSecondary: Color get() = black.copy(alpha = 0.6f)
    val textTertiary: Color get() = black.copy(alpha = 0.4f)
    val textOnDark: Color get() = white
    val textOnDarkSecondary: Color get() = white.copy(alpha = 0.75f)

    // Dynamic status & semantic colors
    val statusSuccess: Color get() = green
    var amber: Color by mutableStateOf(Color(0xFFF59E0B))
    var indigo: Color by mutableStateOf(Color(0xFF6366F1))
    var emerald: Color by mutableStateOf(Color(0xFF10B981))
    var rose: Color by mutableStateOf(Color(0xFFF43F5E))
    var sky: Color by mutableStateOf(Color(0xFF0284C7))
}

// Backward-compatible delegates that dynamically link to AppTheme:
val LaterboxBg: Color get() = AppTheme.background
val LaterboxAccent: Color get() = AppTheme.green
val LaterboxDarkSurface: Color get() = AppTheme.black
val LaterboxDarkCard: Color get() = AppTheme.darkCard
val LaterboxDarkBg: Color get() = AppTheme.darkBg
val LaterboxCard: Color get() = AppTheme.white
val LaterboxBorder: Color get() = AppTheme.cardBorder
val LaterboxCardBorder: Color get() = AppTheme.cardBorder
val LaterboxDarkBorder: Color get() = AppTheme.darkCardBorder

// Text & Content Typography Colors
val LaterboxTextPrimary: Color get() = AppTheme.textPrimary
val LaterboxTextSecondary: Color get() = AppTheme.textSecondary
val LaterboxTextTertiary: Color get() = AppTheme.textTertiary
val LaterboxTextOnDark: Color get() = AppTheme.textOnDark
val LaterboxTextOnDarkSecondary: Color get() = AppTheme.textOnDarkSecondary

// Status & Semantic Colors
val LaterboxStatusSuccess: Color get() = AppTheme.statusSuccess
val LaterboxAmber: Color get() = AppTheme.amber
val LaterboxIndigo: Color get() = AppTheme.indigo
val LaterboxEmerald: Color get() = AppTheme.emerald
val LaterboxRose: Color get() = AppTheme.rose
val LaterboxSky: Color get() = AppTheme.sky
