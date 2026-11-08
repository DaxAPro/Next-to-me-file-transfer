import 'package:flutter/material.dart';
import '../../core/theme/cyber_colors.dart';

/// Distinct Flat 2D Material Cyber Vector Icons
class CyberIcon extends StatelessWidget {
  final CyberIconType type;
  final double size;
  final Color? color;

  const CyberIcon({
    super.key,
    required this.type,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CyberIconPainter(
        type: type,
        color: color ?? CyberColors.electricCyan,
      ),
    );
  }
}

enum CyberIconType {
  phone,
  tablet,
  pc,
  speedometer,
  wifiDirect,
  chat,
  history,
  shield,
  eco,
}

class _CyberIconPainter extends CustomPainter {
  final CyberIconType type;
  final Color color;

  _CyberIconPainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (type) {
      case CyberIconType.phone:
        _drawPhone(canvas, size, strokePaint, fillPaint);
        break;
      case CyberIconType.tablet:
        _drawTablet(canvas, size, strokePaint, fillPaint);
        break;
      case CyberIconType.pc:
        _drawPc(canvas, size, strokePaint);
        break;
      case CyberIconType.speedometer:
        _drawSpeedometer(canvas, size, strokePaint, fillPaint);
        break;
      case CyberIconType.wifiDirect:
        _drawWifiDirect(canvas, size, strokePaint, fillPaint);
        break;
      case CyberIconType.chat:
        _drawChat(canvas, size, strokePaint, fillPaint);
        break;
      case CyberIconType.history:
        _drawHistory(canvas, size, strokePaint);
        break;
      case CyberIconType.shield:
        _drawShield(canvas, size, strokePaint, fillPaint);
        break;
      case CyberIconType.eco:
        _drawEco(canvas, size, strokePaint, fillPaint);
        break;
    }
  }

  void _drawPhone(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.22, size.height * 0.08, size.width * 0.56, size.height * 0.84),
      const Radius.circular(5),
    );
    canvas.drawRRect(rrect, stroke);
    // Home dot / notch
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.82), 1.6, fill);
    // Screen top speaker line
    canvas.drawLine(
      Offset(size.width * 0.42, size.height * 0.16),
      Offset(size.width * 0.58, size.height * 0.16),
      stroke..strokeWidth = 1.2,
    );
  }

  void _drawTablet(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.12, size.height * 0.1, size.width * 0.76, size.height * 0.8),
      const Radius.circular(6),
    );
    canvas.drawRRect(rrect, stroke);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.82), 1.8, fill);
  }

  void _drawPc(Canvas canvas, Size size, Paint stroke) {
    // Laptop screen
    final screen = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.15, size.height * 0.15, size.width * 0.7, size.height * 0.52),
      const Radius.circular(3),
    );
    canvas.drawRRect(screen, stroke);
    // Base stand
    final basePath = Path()
      ..moveTo(size.width * 0.08, size.height * 0.78)
      ..lineTo(size.width * 0.92, size.height * 0.78)
      ..lineTo(size.width * 0.85, size.height * 0.84)
      ..lineTo(size.width * 0.15, size.height * 0.84)
      ..close();
    canvas.drawPath(basePath, stroke);
  }

  void _drawSpeedometer(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final center = Offset(size.width * 0.5, size.height * 0.56);
    final radius = size.width * 0.38;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 220 degree arc
    canvas.drawArc(rect, 2.6, 4.4, false, stroke);
    // Center pivot
    canvas.drawCircle(center, 2.5, fill);
    // Needle pointing upper right
    canvas.drawLine(center, Offset(center.dx + radius * 0.6, center.dy - radius * 0.5), stroke);
  }

  void _drawWifiDirect(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final center = Offset(size.width * 0.5, size.height * 0.75);
    canvas.drawCircle(center, 2.0, fill);
    canvas.drawArc(Rect.fromCircle(center: center, radius: size.width * 0.22), 3.9, 1.6, false, stroke);
    canvas.drawArc(Rect.fromCircle(center: center, radius: size.width * 0.42), 3.9, 1.6, false, stroke);
  }

  void _drawChat(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.2)
      ..lineTo(size.width * 0.85, size.height * 0.2)
      ..quadraticBezierTo(size.width * 0.9, size.height * 0.2, size.width * 0.9, size.height * 0.26)
      ..lineTo(size.width * 0.9, size.height * 0.64)
      ..quadraticBezierTo(size.width * 0.9, size.height * 0.7, size.width * 0.85, size.height * 0.7)
      ..lineTo(size.width * 0.45, size.height * 0.7)
      ..lineTo(size.width * 0.25, size.height * 0.88)
      ..lineTo(size.width * 0.25, size.height * 0.7)
      ..lineTo(size.width * 0.15, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.1, size.height * 0.7, size.width * 0.1, size.height * 0.64)
      ..lineTo(size.width * 0.1, size.height * 0.26)
      ..quadraticBezierTo(size.width * 0.1, size.height * 0.2, size.width * 0.15, size.height * 0.2)
      ..close();
    canvas.drawPath(path, stroke);
  }

  void _drawHistory(Canvas canvas, Size size, Paint stroke) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final radius = size.width * 0.38;
    canvas.drawCircle(center, radius, stroke);
    // Clock hands
    canvas.drawLine(center, Offset(center.dx, center.dy - radius * 0.6), stroke);
    canvas.drawLine(center, Offset(center.dx + radius * 0.45, center.dy), stroke);
  }

  void _drawShield(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.12)
      ..lineTo(size.width * 0.85, size.height * 0.26)
      ..lineTo(size.width * 0.85, size.height * 0.56)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.82, size.width * 0.5, size.height * 0.9)
      ..quadraticBezierTo(size.width * 0.15, size.height * 0.82, size.width * 0.15, size.height * 0.56)
      ..lineTo(size.width * 0.15, size.height * 0.26)
      ..close();
    canvas.drawPath(path, stroke);
  }

  void _drawEco(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.2, size.height * 0.25, size.width * 0.8, size.height * 0.2)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.75, size.width * 0.2, size.height * 0.8);
    canvas.drawPath(path, stroke);
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.8),
      Offset(size.width * 0.65, size.height * 0.35),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _CyberIconPainter oldDelegate) =>
      oldDelegate.type != type || oldDelegate.color != color;
}
