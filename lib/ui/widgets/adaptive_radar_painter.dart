import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/models/device_peer.dart';

/// Device-Adaptive Sonar Harmonics Painter
/// Generates geometric pulse rings tailored to device type:
/// - PC / Laptop: Hexagonal faceted pulse waves
/// - Tablet: Rounded rectangle expansion waves
/// - Phone: Concentric circular sonar pings
class DeviceAdaptivePulsePainter extends CustomPainter {
  final double animationValue; // 0.0 to 1.0
  final DeviceType deviceType;
  final Color baseColor;

  DeviceAdaptivePulsePainter({
    required this.animationValue,
    required this.deviceType,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Calculate pulse alpha and expansion radius
    final currentRadius = maxRadius * animationValue;
    final alpha = (1.0 - animationValue).clamp(0.0, 1.0);

    final pulsePaint = Paint()
      ..color = baseColor.withValues(alpha: alpha * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    switch (deviceType) {
      case DeviceType.pc:
        _drawHexagon(canvas, center, currentRadius, pulsePaint);
        break;
      case DeviceType.tablet:
        _drawRoundedBox(canvas, center, currentRadius, pulsePaint);
        break;
      case DeviceType.phone:
      case DeviceType.unknown:
        canvas.drawCircle(center, currentRadius, pulsePaint);
        break;
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * math.pi / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawRoundedBox(Canvas canvas, Offset center, double radius, Paint paint) {
    final rect = Rect.fromCenter(center: center, width: radius * 1.8, height: radius * 1.8);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius * 0.3)), paint);
  }

  @override
  bool shouldRepaint(covariant DeviceAdaptivePulsePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.deviceType != deviceType ||
      oldDelegate.baseColor != baseColor;
}
