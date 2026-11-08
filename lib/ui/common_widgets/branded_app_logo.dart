import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/cyber_colors.dart';

/// Custom Branded App Logo matching image_16.png
/// Displays two split curved arrows:
/// - Top-right: Tech Emerald Green arrow with Wi-Fi signal arcs
/// - Bottom-left: Electric Cyan/Blue arrow with Bluetooth icon
/// - Center: Sharp turquoise lightning bolt
class BrandedAppLogo extends StatelessWidget {
  final double size;
  final bool useAssetIfAvailable;

  const BrandedAppLogo({
    super.key,
    this.size = 96.0,
    this.useAssetIfAvailable = true,
  });

  @override
  Widget build(BuildContext context) {
    if (useAssetIfAvailable) {
      return Image.asset(
        'assets/logo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildVectorLogo(context),
      );
    }
    return _buildVectorLogo(context);
  }

  Widget _buildVectorLogo(BuildContext context) {
    final surfaceColor = CyberColors.surface(context);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BrandedLogoPainter(backgroundColor: surfaceColor),
        size: Size(size, size),
      ),
    );
  }
}

class _BrandedLogoPainter extends CustomPainter {
  final Color backgroundColor;

  _BrandedLogoPainter({this.backgroundColor = CyberColors.oledBlack});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Circular backdrop
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 2, bgPaint);

    final strokeWidth = size.width * 0.085;

    // 1. Top-Right Green Arc Arrow (Tech Emerald)
    final greenPaint = Paint()
      ..color = CyberColors.techEmerald
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final arcRect = Rect.fromCircle(center: center, radius: radius * 0.76);
    canvas.drawArc(arcRect, -math.pi * 0.9, math.pi * 0.85, false, greenPaint);

    // Green Arrowhead at upper right
    final greenHead = Path();
    final gx = center.dx + radius * 0.76 * math.cos(-math.pi * 0.05);
    final gy = center.dy + radius * 0.76 * math.sin(-math.pi * 0.05);
    greenHead.moveTo(gx - 4, gy - 12);
    greenHead.lineTo(gx + 12, gy);
    greenHead.lineTo(gx - 4, gy + 12);
    greenHead.close();
    canvas.drawPath(greenHead, Paint()..color = CyberColors.techEmerald..style = PaintingStyle.fill);

    // Wi-Fi arcs inside top-left quadrant
    final wifiCenter = Offset(center.dx - radius * 0.32, center.dy - radius * 0.28);
    final wifiPaint = Paint()
      ..color = CyberColors.electricCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(wifiCenter, 2.2, Paint()..color = CyberColors.electricCyan..style = PaintingStyle.fill);
    canvas.drawArc(Rect.fromCircle(center: wifiCenter, radius: radius * 0.16), -math.pi * 0.8, math.pi * 0.6, false, wifiPaint);
    canvas.drawArc(Rect.fromCircle(center: wifiCenter, radius: radius * 0.28), -math.pi * 0.8, math.pi * 0.6, false, wifiPaint);

    // 2. Bottom-Left Blue/Cyan Arc Arrow (Electric Cyan)
    final cyanPaint = Paint()
      ..color = CyberColors.electricCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(arcRect, math.pi * 0.1, math.pi * 0.85, false, cyanPaint);

    // Cyan Arrowhead at lower left
    final cyanHead = Path();
    final cx = center.dx + radius * 0.76 * math.cos(math.pi * 0.95);
    final cy = center.dy + radius * 0.76 * math.sin(math.pi * 0.95);
    cyanHead.moveTo(cx + 4, cy - 12);
    cyanHead.lineTo(cx - 12, cy);
    cyanHead.lineTo(cx + 4, cy + 12);
    cyanHead.close();
    canvas.drawPath(cyanHead, Paint()..color = CyberColors.electricCyan..style = PaintingStyle.fill);

    // Bluetooth glyph in lower right quadrant
    final btPaint = Paint()
      ..color = CyberColors.techBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final bx = center.dx + radius * 0.34;
    final by = center.dy + radius * 0.32;
    final bH = radius * 0.24;
    final btPath = Path()
      ..moveTo(bx, by - bH)
      ..lineTo(bx, by + bH)
      ..lineTo(bx + bH * 0.5, by + bH * 0.5)
      ..lineTo(bx - bH * 0.4, by - bH * 0.4)
      ..moveTo(bx - bH * 0.4, by + bH * 0.4)
      ..lineTo(bx + bH * 0.5, by - bH * 0.5)
      ..lineTo(bx, by);
    canvas.drawPath(btPath, btPaint);

    // 3. Sharp Turquoise Lightning Bolt in Center
    final boltPaint = Paint()
      ..color = CyberColors.electricCyan
      ..style = PaintingStyle.fill;

    final bolt = Path()
      ..moveTo(center.dx + 2, center.dy - radius * 0.24)
      ..lineTo(center.dx - radius * 0.14, center.dy + 1)
      ..lineTo(center.dx - 1, center.dy + 1)
      ..lineTo(center.dx - 2, center.dy + radius * 0.24)
      ..lineTo(center.dx + radius * 0.14, center.dy - 1)
      ..lineTo(center.dx + 1, center.dy - 1)
      ..close();
    canvas.drawPath(bolt, boltPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
