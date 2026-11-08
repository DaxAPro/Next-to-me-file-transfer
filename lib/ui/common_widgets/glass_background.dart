import 'package:flutter/material.dart';
import '../../core/theme/cyber_colors.dart';

/// Ambient Cyber-Glassmesh background providing luminous gradients for frosted glass cards.
class GlassBackground extends StatelessWidget {
  final Widget child;

  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Base solid background
        Container(
          color: CyberColors.background(context),
        ),

        // Ambient Luminous Mesh 1 (Top-Right Cyan Glow)
        Positioned(
          top: -60,
          right: -60,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  CyberColors.primaryAccent(context).withValues(alpha: isDark ? 0.16 : 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Ambient Luminous Mesh 2 (Center-Left Emerald Glow)
        Positioned(
          top: 240,
          left: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  CyberColors.emeraldAccent(context).withValues(alpha: isDark ? 0.14 : 0.07),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Foreground content
        child,
      ],
    );
  }
}
