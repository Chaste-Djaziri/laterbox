import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const ink = Color(0xFF171711);
  static const paper = Color(0xFFF7F5EE);
  static const surface = Color(0xFFFFFFFF);
  static const accent = Color(0xFFE7FF57);
  static const muted = Color(0xFF6C6B63);
  static const outline = Color(0xFFE4E0D5);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: accent, surface: paper)
        .copyWith(
          primary: ink,
          onPrimary: surface,
          secondary: accent,
          onSecondary: ink,
          onSurface: ink,
          outline: outline,
          onSurfaceVariant: muted,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: paper,
      appBarTheme: const AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.all(18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ink, width: 2),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ink,
        foregroundColor: surface,
        elevation: 0,
        shape: CircleBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: surface,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
