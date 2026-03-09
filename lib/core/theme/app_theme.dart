import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Dark Theme Colors ──
  static const Color darkBg = Color(0xFF0D0D0D); // Deep Dark Theme
  static const Color darkCard = Color(0xFF1A1A1A); // Secondary Dark
  static const Color darkPrimaryText = Color(0xFFFFFFFF); // Glowing White
  static const Color accentOrange = Color(0xFFFF6A00); // Bright Orange
  static const Color darkBorder = Color(0xFF2A2A2A); // Border
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
      textTheme: GoogleFonts.ibmPlexSansArabicTextTheme(ThemeData.dark().textTheme),
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
      textTheme: GoogleFonts.ibmPlexSansArabicTextTheme(ThemeData.light().textTheme),
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
