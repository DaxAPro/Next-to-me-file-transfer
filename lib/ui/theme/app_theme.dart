import 'package:flutter/material.dart';

class AppTheme {
  // Brand Neon & Cyber Accents
  static const Color primaryNeon = Color(0xFF00E5FF);       // Electric Cyan
  static const Color secondaryAccent = Color(0xFF7C4DFF);    // Deep Violet
  static const Color accentGreen = Color(0xFF00E676);        // High Speed Green
  static const Color accentAmber = Color(0xFFFFB300);        // Throttled / Warning Amber

  // Dark OLED Palette
  static const Color bgDark = Color(0xFF0B0E14);             // Deep OLED Background
  static const Color cardDark = Color(0xFF131B2A);           // Glassmorphic Surface
  static const Color cardBorder = Color(0xFF1F2E47);         // Subtle Border Glow
  static const Color surfaceElevated = Color(0xFF1A2338);

  // Text Colors
  static const Color textPrimary = Color(0xFFF0F6FC);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted = Color(0xFF586069);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: primaryNeon,
      colorScheme: const ColorScheme.dark(
        primary: primaryNeon,
        secondary: secondaryAccent,
        surface: cardDark,
        error: Color(0xFFFF5252),
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNeon,
          foregroundColor: Colors.black,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }
}
