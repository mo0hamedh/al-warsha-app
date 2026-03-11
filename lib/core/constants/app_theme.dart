import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Dark Theme Colors ──
  // A calming deep night blue for better focus, inspired by premium meditation/Quran apps
  static const Color darkBg = Color(0xFF0F1520); // Deep Night Blue
  // Slightly elevated surface for cards, soft and less contrasting
  static const Color darkCard = Color(0xFF161F2C); // Soft Slate Blue
  // Elegant off-white for primary text (less harsh than pure white)
  static const Color darkPrimaryText = Color(0xFFEBEBF5); 
  // Premium muted gold for accents (replaces the harsh neon orange)
  static const Color accentOrange = Color(0xFFC5A87C); // Muted Gold / Sand
  // Extremely soft, almost invisible borders (if needed at all)
  static const Color darkBorder = Color(0xFF1E293B); 
  // Calming slate gray for secondary text
  static const Color darkTextSecondary = Color(0xFF8B9BB4); 

  // ── Light Theme Colors ──
  // Soft, warm paper-like white for minimal eye strain
  static const Color lightBg = Color(0xFFFAF9F6); // Off-White
  static const Color lightCard = Color(0xFFFFFFFF); // Pure White
  // Deep warm gray for text to keep it soft
  static const Color lightPrimaryText = Color(0xFF2D3748); 
  // Medium cool gray for secondary text
  static const Color lightTextSecondary = Color(0xFF718096); 

  // ── Dark Theme Data ──
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      // Minimalist, elegant modern Arabic typography
      textTheme: GoogleFonts.tajawalTextTheme(ThemeData.dark().textTheme),
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
      textTheme: GoogleFonts.tajawalTextTheme(ThemeData.light().textTheme),
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
