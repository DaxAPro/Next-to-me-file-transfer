import 'package:flutter/material.dart';

/// Cyber-Material Brand Colors & Speedometer Gradients
class CyberColors {
  // Primary Spectrum
  static const Color oledBlack = Color(0xFF080B10);
  static const Color darkSurface = Color(0xFF101622);
  static const Color borderOutline = Color(0xFF1C2638);
  static const Color cardSubtle = Color(0xFF151D2C);

  // Speedometer & Status Accents
  static const Color electricCyan = Color(0xFF00E5FF);       // Low / Idle Speed
  static const Color techBlue = Color(0xFF00B0FF);           // Mid-low Speed
  static const Color techEmerald = Color(0xFF00E676);        // High / Optimal Speed
  static const Color warningAmber = Color(0xFFFFB300);       // Throttled
  static const Color dangerRed = Color(0xFFFF5252);          // Quota Exceeded
  static const Color cyberViolet = Color(0xFF7C4DFF);        // LAN Mode

  // Text Hierarchy
  static const Color textPrimary = Color(0xFFF0F4F8);
  static const Color textSecondary = Color(0xFF8B98A5);
  static const Color textMuted = Color(0xFF5A6675);

  /// Smoothly interpolates color from Cyan to Tech Emerald Green across 0.0 -> 1.0 ratio
  static Color getSpeedometerColor(double ratio) {
    final clamped = ratio.clamp(0.0, 1.0);
    if (clamped < 0.5) {
      return Color.lerp(electricCyan, techBlue, clamped * 2) ?? electricCyan;
    } else {
      return Color.lerp(techBlue, techEmerald, (clamped - 0.5) * 2) ?? techEmerald;
    }
  }
}
