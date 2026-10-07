package com.example.laterbox.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

@Composable
fun LaterboxTheme(
    content: @Composable () -> Unit
) {
    val colorScheme = lightColorScheme(
        primary = LaterboxDarkSurface,
        onPrimary = AppTheme.white,
        primaryContainer = LaterboxAccent,
        onPrimaryContainer = LaterboxDarkSurface,
        secondary = LaterboxIndigo,
        onSecondary = AppTheme.white,
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

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}
