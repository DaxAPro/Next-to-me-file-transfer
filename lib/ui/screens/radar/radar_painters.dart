import 'dart:math';
import 'package:flutter/material.dart';

/// 1. Subtle Graph-Paper Grid Painter across the entire radar background
class GraphPaperGridPainter extends CustomPainter {
  final Color gridColor;
  final double gridSpacing;

  const GraphPaperGridPainter({
    required this.gridColor,
    this.gridSpacing = 28.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.65
      ..style = PaintingStyle.stroke;

    // Draw vertical grid lines
    for (double x = 0; x <= size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }

    // Draw horizontal grid lines
    for (double y = 0; y <= size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant GraphPaperGridPainter oldDelegate) =>
      oldDelegate.gridColor != gridColor || oldDelegate.gridSpacing != gridSpacing;
}

/// 2. Outward-Expanding Circular Ripples (Sonar Effect) from center node
class SonarPulsePainter extends CustomPainter {
  final double animationValue;
  final Color emeraldColor;
  final Color cyanColor;
  final double maxRadius;

  const SonarPulsePainter({
    required this.animationValue,
    required this.emeraldColor,
    required this.cyanColor,
    required this.maxRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Render 3 staggered expanding ripples
    for (int i = 0; i < 3; i++) {
      final waveProgress = (animationValue + (i * 0.33)) % 1.0;
      final currentRadius = waveProgress * maxRadius;
      final opacity = (1.0 - waveProgress) * 0.55;

      // Alternate wave color between Emerald Green and Cyan
      final waveColor = i % 2 == 0 ? emeraldColor : cyanColor;

      final glowPaint = Paint()
        ..color = waveColor.withValues(alpha: (opacity * 0.42).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
      final wavePaint = Paint()
        ..color = waveColor.withValues(alpha: opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;

      canvas.drawCircle(center, currentRadius, glowPaint);
      canvas.drawCircle(center, currentRadius, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant SonarPulsePainter oldDelegate) => true;
}

/// 3. Dynamic Dashed Connection Lines connecting ME to each discovered device
class DynamicConnectionLinesPainter extends CustomPainter {
  final Offset center;
  final List<Offset> devicePositions;
  final List<Color> lineColors;

  const DynamicConnectionLinesPainter({
    required this.center,
    required this.devicePositions,
    required this.lineColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < devicePositions.length; i++) {
      final target = devicePositions[i];
      final color = i < lineColors.length ? lineColors[i] : const Color(0xFF00E5FF);

      final dx = target.dx - center.dx;
      final dy = target.dy - center.dy;
      final distance = sqrt(dx * dx + dy * dy);
      if (distance <= 56) continue;

      final direction = Offset(dx / distance, dy / distance);
      final start = center + direction * 34;
      final end = target - direction * 24;
      final curveOffset = Offset(-direction.dy, direction.dx) * min(distance * 0.035, 18);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(
          (start.dx + end.dx) / 2 + curveOffset.dx,
          (start.dy + end.dy) / 2 + curveOffset.dy,
          end.dx,
          end.dy,
        );

      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.18)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      glowPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      final linePaint = Paint()
        ..color = color.withValues(alpha: 0.48)
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant DynamicConnectionLinesPainter oldDelegate) => true;
}
