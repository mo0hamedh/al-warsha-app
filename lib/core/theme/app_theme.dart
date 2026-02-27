import 'package:flutter/material.dart';

class AppTheme {
  // ── Dark Neon Theme Colors ──
  static const Color darkBg = Color(0xFF121212); // Deep Dark Grey
  static const Color darkCard = Color(0xFF1E1E1E); // Secondary Dark
  static const Color darkPrimaryText = Color(0xFFFFFFFF); // Glowing White
  static const Color accentOrange = Color(0xFFFF6A00); // Bright Orange
  static const Color darkTextSecondary = Color(0xFFB3B3B3); // Light Grey

  // ── Light Theme Colors ──
  static const Color lightBg = Color(0xFFF5F5F5); // Very Light Grey/White
  static const Color lightCard = Color(0xFFFFFFFF); // Pure White
  static const Color lightPrimaryText = Color(0xFF121212); // Deep Dark Grey
  // We keep orange for accents in both themes
  static const Color lightTextSecondary = Color(0xFF666666); // Medium Grey

  // ── Dark Theme Data ──
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimaryText,
        secondary: accentOrange,
        surface: darkCard,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        iconTheme: IconThemeData(color: darkPrimaryText),
      ),
      useMaterial3: true,
    );
  }

  // ── Light Theme Data ──
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        primary: lightPrimaryText,
        secondary: accentOrange,
        surface: lightCard,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBg,
        elevation: 0,
        iconTheme: IconThemeData(color: lightPrimaryText),
      ),
      useMaterial3: true,
    );
  }
}
