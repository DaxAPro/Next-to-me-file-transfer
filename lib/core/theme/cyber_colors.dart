import 'package:flutter/material.dart';

/// Cyber-Material Brand Colors & Speedometer Gradients
class CyberColors {
  // Dark Palette (Deep Obsidian #121212 & Slate Surfaces)
  static const Color oledBlack = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color borderOutline = Color(0xFF2C2C2C);
  static const Color cardSubtle = Color(0xFF242424);

  // Light Palette (Pure White #FFFFFF & Crisp Slate Surfaces)
  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF8FAFC);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF1E2638);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Speedometer & Status Accents
  static const Color electricCyan = Color(0xFF00E5FF); // Low / Idle Speed
  static const Color techBlue = Color(0xFF00B0FF); // Mid-low Speed
  static const Color techEmerald = Color(0xFF10B981); // Tech Emerald Green
  static const Color techEmeraldGreen = techEmerald;
  static const Color warningAmber = Color(0xFFFFB300); // Throttled
  static const Color dangerRed = Color(0xFFFF5252); // Quota Exceeded
  static const Color cyberViolet = Color(0xFF7C4DFF); // LAN Mode

  // Text Hierarchy
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted = Color(0xFF5A6675);

  // Dynamic Theme-Aware Color Resolvers
  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? oledBlack : lightBg;

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? darkSurface
      : lightSurface;

  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? borderOutline
      : lightBorder;

  static Color text(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? textPrimary
      : lightTextPrimary;

  static Color subtext(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? textSecondary
      : lightTextSecondary;

  static Color primaryAccent(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? electricCyan
      : const Color(0xFF0097A7);

  static Color emeraldAccent(BuildContext context) => techEmerald;

  /// Smoothly interpolates color from Cyan to Tech Emerald Green across 0.0 -> 1.0 ratio
  static Color getSpeedometerColor(double ratio) {
    final clamped = ratio.clamp(0.0, 1.0);
    if (clamped < 0.5) {
      return Color.lerp(electricCyan, techBlue, clamped * 2) ?? electricCyan;
    } else {
      return Color.lerp(techBlue, techEmerald, (clamped - 0.5) * 2) ??
          techEmerald;
    }
  }
}
