package com.example.laterbox.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

// Default LaterBox Warm Light Color Scheme (1:1 with iOS AppTheme)
private val LightColorScheme = lightColorScheme(
    primary = LaterboxDarkSurface,
    onPrimary = Color.White,
    primaryContainer = LaterboxAccent,
    onPrimaryContainer = LaterboxDarkSurface,
    secondary = LaterboxIndigo,
    onSecondary = Color.White,
    secondaryContainer = LaterboxAccent,
    onSecondaryContainer = LaterboxDarkSurface,
    background = LaterboxBg,
    onBackground = LaterboxTextPrimary,
    surface = LaterboxCard,
    onSurface = LaterboxTextPrimary,
    surfaceVariant = LaterboxBg,
    onSurfaceVariant = LaterboxTextSecondary,
    outline = LaterboxBorder,
    outlineVariant = LaterboxCardBorder
)

@Composable
fun LaterboxTheme(
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colorScheme = LightColorScheme,
        typography = Typography,
        content = content
    )
}
