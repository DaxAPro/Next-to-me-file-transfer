import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/cyber_colors.dart';

/// Sinusoidal Fluid Wave Transfer Progress Indicator
class WaveTransferProgress extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final bool isTransferring;
  final bool isCompleted;
  final bool isPaused;

  const WaveTransferProgress({
    super.key,
    required this.progress,
    required this.isTransferring,
    this.isCompleted = false,
    this.isPaused = false,
  });

  @override
  State<WaveTransferProgress> createState() => _WaveTransferProgressState();
}

class _WaveTransferProgressState extends State<WaveTransferProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.isTransferring && !widget.isPaused && !widget.isCompleted) {
      _waveController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant WaveTransferProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTransferring && !widget.isPaused && !widget.isCompleted) {
      if (!_waveController.isAnimating) _waveController.repeat();
    } else {
      if (_waveController.isAnimating) _waveController.stop();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waveColor = widget.isCompleted
        ? CyberColors.techEmerald
        : widget.isPaused
            ? CyberColors.warningAmber
            : CyberColors.electricCyan;

    return Container(
      height: 10,
      decoration: BoxDecoration(
        color: CyberColors.darkSurface,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: CyberColors.borderOutline, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: AnimatedBuilder(
          animation: _waveController,
          builder: (context, child) {
            return CustomPaint(
              painter: _WaveProgressPainter(
                progress: widget.progress.clamp(0.0, 1.0),
                wavePhase: _waveController.value * 2 * math.pi,
                waveColor: waveColor,
                isTransferring: widget.isTransferring && !widget.isPaused && !widget.isCompleted,
              ),
              size: const Size(double.infinity, 10),
            );
          },
        ),
      ),
    );
  }
}

class _WaveProgressPainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final Color waveColor;
  final bool isTransferring;

  _WaveProgressPainter({
    required this.progress,
    required this.wavePhase,
    required this.waveColor,
    required this.isTransferring,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final fillWidth = size.width * progress;
    final paint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;

    if (!isTransferring || progress >= 0.99) {
      // Flat solid progress when paused or completed
      canvas.drawRect(Rect.fromLTWH(0, 0, fillWidth, size.height), paint);
      return;
    }

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, 0);

    // Wave crest at leading edge
    const waveAmplitude = 1.8;
    const waveFreq = 0.05;

    for (double x = 0; x <= fillWidth; x += 2.0) {
      final y = math.sin((x * waveFreq) + wavePhase) * waveAmplitude + (size.height * 0.3);
      path.lineTo(x, y.clamp(0.0, size.height));
    }

    path.lineTo(fillWidth, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Leading crest bright tip
    final tipPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(fillWidth, 0),
      Offset(fillWidth, size.height),
      tipPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WaveProgressPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.wavePhase != wavePhase ||
      oldDelegate.waveColor != waveColor ||
      oldDelegate.isTransferring != isTransferring;
}
