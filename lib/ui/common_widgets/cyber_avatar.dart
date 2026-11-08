import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/cyber_colors.dart';

/// Distinct Flat 2D Digital Humanoid "ME" Avatar Node (image_13.png)
/// Features:
/// - Borderless 2D digital humanoid silhouette bust
/// - Bluetooth glyph on the left
/// - Wi-Fi waves on the upper-right / lower-right
/// - Tech Emerald Green and Electric Cyan curving boundaries
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
          ClipOval(
            child: Image.asset(
              'assets/images/user icon.png',
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => CustomPaint(
                size: Size(size, size),
                painter: _CyberAvatarPainter(
                  borderColor: borderColor,
                ),
              ),
            ),
          ),
          if (showStatusBadge)
            Positioned(
              right: 1,
              bottom: 1,
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

    // Dark surface background
    final bgPaint = Paint()
      ..color = CyberColors.darkSurface
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 1.5, bgPaint);

    // Curving boundary ring (Tech Emerald to Electric Cyan split)
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

    final rect = Rect.fromCircle(center: center, radius: radius - 2.5);
    canvas.drawArc(rect, -math.pi * 0.15, math.pi * 0.85, false, ringPaintCyan);
    canvas.drawArc(rect, math.pi * 0.85, math.pi * 0.85, false, ringPaintGreen);

    // Bluetooth glyph on the left
    final btPaint = Paint()
      ..color = CyberColors.techBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final bx = center.dx - radius * 0.62;
    final by = center.dy;
    final bH = radius * 0.22;
    final btPath = Path()
      ..moveTo(bx, by - bH)
      ..lineTo(bx, by + bH)
      ..lineTo(bx + bH * 0.5, by + bH * 0.5)
      ..lineTo(bx - bH * 0.4, by - bH * 0.4)
      ..moveTo(bx - bH * 0.4, by + bH * 0.4)
      ..lineTo(bx + bH * 0.5, by - bH * 0.5)
      ..lineTo(bx, by);
    canvas.drawPath(btPath, btPaint);

    // Wi-Fi signal waves on the upper-right / right side
    final wifiCenter = Offset(center.dx + radius * 0.55, center.dy);
    final wifiPaint = Paint()
      ..color = CyberColors.electricCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(wifiCenter, 1.4, Paint()..color = CyberColors.electricCyan..style = PaintingStyle.fill);
    canvas.drawArc(Rect.fromCircle(center: wifiCenter, radius: radius * 0.14), -math.pi * 0.6, math.pi * 0.6, false, wifiPaint);
    canvas.drawArc(Rect.fromCircle(center: wifiCenter, radius: radius * 0.24), -math.pi * 0.6, math.pi * 0.6, false, wifiPaint);

    // Digital Humanoid Bust Silhouette (Center)
    // Head circle
    final headRadius = size.width * 0.14;
    final headCenter = Offset(center.dx, center.dy - size.height * 0.12);
    final headPaint = Paint()
      ..color = CyberColors.electricCyan
      ..style = PaintingStyle.fill;
    canvas.drawCircle(headCenter, headRadius, headPaint);

    // Humanoid Shoulders / Curved Torso
    final torsoPaint = Paint()
      ..color = CyberColors.techEmerald
      ..style = PaintingStyle.fill;

    final torsoPath = Path();
    final shoulderTopY = center.dy + size.height * 0.08;
    final torsoBottomY = size.height - 6;
    final torsoWidth = size.width * 0.32;

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

    // Connection bridge
    final bridgePaint = Paint()
      ..color = CyberColors.oledBlack
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(center.dx, headCenter.dy + headRadius),
      Offset(center.dx, shoulderTopY + 2),
      bridgePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CyberAvatarPainter oldDelegate) =>
      oldDelegate.borderColor != borderColor;
}
