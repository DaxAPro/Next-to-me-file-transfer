import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/cyber_colors.dart';

/// Distinct Flat 2D Digital Humanoid Persona Node
/// Combines Tech Emerald Green and Electric Cyan curving boundaries.
class CyberAvatar extends StatelessWidget {
  final double size;
  final bool isScanning;
  final bool showStatusBadge;
  final Color? borderColor;

  const CyberAvatar({
    super.key,
    this.size = 56.0,
    this.isScanning = false,
    this.showStatusBadge = true,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _CyberAvatarPainter(
              borderColor: borderColor,
            ),
          ),
          if (showStatusBadge)
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: size * 0.22,
                height: size * 0.22,
                decoration: BoxDecoration(
                  color: CyberColors.techEmerald,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: CyberColors.oledBlack,
                    width: 2.0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CyberAvatarPainter extends CustomPainter {
  final Color? borderColor;

  _CyberAvatarPainter({this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Dark surface disc background
    final bgPaint = Paint()
      ..color = CyberColors.darkSurface
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 2, bgPaint);

    // Curving boundary ring (Emerald Green to Electric Cyan split)
    final ringPaintCyan = Paint()
      ..color = borderColor ?? CyberColors.electricCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final ringPaintGreen = Paint()
      ..color = borderColor ?? CyberColors.techEmerald
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius - 3);
    // Upper right cyan arc (30° to 190°)
    canvas.drawArc(rect, -math.pi * 0.15, math.pi * 0.9, false, ringPaintCyan);
    // Lower left emerald arc (210° to 370°)
    canvas.drawArc(rect, math.pi * 0.85, math.pi * 0.9, false, ringPaintGreen);

    // Humanoid Digital Node Silhouette
    // Head circle
    final headRadius = size.width * 0.16;
    final headCenter = Offset(center.dx, center.dy - size.height * 0.12);
    final nodePaint = Paint()
      ..color = CyberColors.electricCyan
      ..style = PaintingStyle.fill;
    canvas.drawCircle(headCenter, headRadius, nodePaint);

    // Humanoid Shoulders / Curved Torso
    final torsoPaint = Paint()
      ..color = CyberColors.techEmerald
      ..style = PaintingStyle.fill;

    final torsoPath = Path();
    final shoulderTopY = center.dy + size.height * 0.08;
    final torsoBottomY = size.height - 7;
    final torsoWidth = size.width * 0.36;

    torsoPath.moveTo(center.dx - torsoWidth, torsoBottomY);
    torsoPath.quadraticBezierTo(
      center.dx - torsoWidth * 0.85,
      shoulderTopY,
      center.dx,
      shoulderTopY,
    );
    torsoPath.quadraticBezierTo(
      center.dx + torsoWidth * 0.85,
      shoulderTopY,
      center.dx + torsoWidth,
      torsoBottomY,
    );
    torsoPath.close();
    canvas.drawPath(torsoPath, torsoPaint);

    // Neural Bridge Line connecting Head and Torso
    final bridgePaint = Paint()
      ..color = CyberColors.oledBlack
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(center.dx, headCenter.dy + headRadius),
      Offset(center.dx, shoulderTopY + 3),
      bridgePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CyberAvatarPainter oldDelegate) =>
      oldDelegate.borderColor != borderColor;
}
