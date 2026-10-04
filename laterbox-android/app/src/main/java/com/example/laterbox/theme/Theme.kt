package com.example.laterbox.theme

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val DarkColorScheme = darkColorScheme(
    primary = LaterboxAccent,
    onPrimary = LaterboxDarkSurface,
    primaryContainer = LaterboxDarkCard,
    onPrimaryContainer = Color.White,
    secondary = LaterboxIndigo,
    onSecondary = Color.White,
    background = LaterboxDarkBg,
    onBackground = Color.White,
    surface = LaterboxDarkSurface,
    onSurface = Color.White,
    surfaceVariant = LaterboxDarkCard,
    onSurfaceVariant = LaterboxTextOnDarkSecondary,
    outline = LaterboxDarkBorder
)

private val LightColorScheme = lightColorScheme(
    primary = LaterboxDarkSurface,
    onPrimary = Color.White,
    primaryContainer = LaterboxAccent,
    onPrimaryContainer = LaterboxDarkSurface,
    secondary = LaterboxIndigo,
    onSecondary = Color.White,
    background = LaterboxBg,
    onBackground = LaterboxTextPrimary,
    surface = LaterboxCard,
    onSurface = LaterboxTextPrimary,
    surfaceVariant = LaterboxBg,
    onSurfaceVariant = LaterboxTextSecondary,
    outline = LaterboxBorder
)

@Composable
fun LaterboxTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}
