import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/cyber_colors.dart';

/// Speedometer-Inspired Circular Gauge for Socket Pacing & Speed Throttling
class InteractiveSpeedometerGauge extends StatefulWidget {
  final double speedMb; // 0 = unlimited, > 0 = speed in MB/s (max 50)
  final ValueChanged<double> onSpeedChanged;

  const InteractiveSpeedometerGauge({
    super.key,
    required this.speedMb,
    required this.onSpeedChanged,
  });

  @override
  State<InteractiveSpeedometerGauge> createState() => _InteractiveSpeedometerGaugeState();
}

class _InteractiveSpeedometerGaugeState extends State<InteractiveSpeedometerGauge> {
  static const double maxSpeed = 50.0;

  double get _ratio => widget.speedMb == 0 ? 1.0 : (widget.speedMb / maxSpeed).clamp(0.0, 1.0);

  void _handlePan(Offset localPos, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;

    // Angle in radians (-pi to pi)
    var angle = math.atan2(dy, dx);
    // Convert to degrees (0 to 360)
    var deg = angle * 180 / math.pi;
    if (deg < 0) deg += 360;

    // Active sweep is from 140° to 400° (which is 40°)
    // Sweep length = 260°
    double normalizedDeg;
    if (deg >= 140) {
      normalizedDeg = deg - 140;
    } else if (deg <= 40) {
      normalizedDeg = deg + 220;
    } else {
      // In dead bottom zone (40° to 140°)
      normalizedDeg = deg < 90 ? 260 : 0;
    }

    final ratio = (normalizedDeg / 260.0).clamp(0.0, 1.0);
    final newSpeed = (ratio * maxSpeed).roundToDouble();
    widget.onSpeedChanged(newSpeed == maxSpeed ? 0 : newSpeed);
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.speedMb == 0
        ? CyberColors.techEmerald
        : CyberColors.getSpeedometerColor(_ratio);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onPanUpdate: (details) {
            final box = context.findRenderObject() as RenderBox?;
            if (box != null) {
              _handlePan(box.globalToLocal(details.globalPosition), const Size(200, 180));
            }
          },
          onTapDown: (details) {
            _handlePan(details.localPosition, const Size(200, 180));
          },
          child: SizedBox(
            width: 200,
            height: 180,
            child: CustomPaint(
              painter: _SpeedometerDialPainter(
                ratio: _ratio,
                speedMb: widget.speedMb,
                activeColor: activeColor,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.speedMb == 0 ? 'MAX' : widget.speedMb.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          color: activeColor,
                        ),
                      ),
                      Text(
                        widget.speedMb == 0 ? 'UNLIMITED' : 'MB / SEC',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: CyberColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: CyberColors.darkSurface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: activeColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          widget.speedMb == 0
                              ? 'FULL SPEED'
                              : 'LIMIT: ${widget.speedMb.toStringAsFixed(0)} MB/S',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: activeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Step Preset Buttons
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStepButton('Unlimited', 0.0),
              const SizedBox(width: 6),
              _buildStepButton('1 MB/s', 1.0),
              const SizedBox(width: 6),
              _buildStepButton('2 MB/s', 2.0),
              const SizedBox(width: 6),
              _buildStepButton('5 MB/s', 5.0),
              const SizedBox(width: 6),
              _buildStepButton('10 MB/s', 10.0),
              const SizedBox(width: 6),
              _buildStepButton('25 MB/s', 25.0),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepButton(String label, double speed) {
    final isSelected = widget.speedMb == speed;
    return InkWell(
      onTap: () => widget.onSpeedChanged(speed),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? CyberColors.electricCyan : CyberColors.darkSurface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? CyberColors.electricCyan : CyberColors.borderOutline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? CyberColors.oledBlack : CyberColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _SpeedometerDialPainter extends CustomPainter {
  final double ratio;
  final double speedMb;
  final Color activeColor;

  _SpeedometerDialPainter({
    required this.ratio,
    required this.speedMb,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 10);
    final radius = size.width * 0.42;

    const startAngle = 140 * math.pi / 180;
    const sweepAngle = 260 * math.pi / 180;

    // Background track arc
    final trackPaint = Paint()
      ..color = CyberColors.borderOutline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, startAngle, sweepAngle, false, trackPaint);

    // Active speed progress arc
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    final currentSweep = sweepAngle * ratio;
    if (currentSweep > 0) {
      canvas.drawArc(rect, startAngle, currentSweep, false, activePaint);
    }

    // Tick marks around gauge
    const int tickCount = 13;
    final tickPaint = Paint()
      ..color = CyberColors.textMuted
      ..strokeWidth = 1.5;

    for (int i = 0; i < tickCount; i++) {
      final tickRatio = i / (tickCount - 1);
      final tickAngle = startAngle + (sweepAngle * tickRatio);
      final isMajor = i % 3 == 0;

      final innerR = radius - (isMajor ? 14 : 9);
      final outerR = radius - 4;

      final p1 = Offset(
        center.dx + innerR * math.cos(tickAngle),
        center.dy + innerR * math.sin(tickAngle),
      );
      final p2 = Offset(
        center.dx + outerR * math.cos(tickAngle),
        center.dy + outerR * math.sin(tickAngle),
      );

      tickPaint.color = tickRatio <= ratio ? activeColor : CyberColors.textMuted;
      canvas.drawLine(p1, p2, tickPaint);
    }

    // Pointer Indicator Needle Dot
    final needleAngle = startAngle + currentSweep;
    final needlePos = Offset(
      center.dx + radius * math.cos(needleAngle),
      center.dy + radius * math.sin(needleAngle),
    );

    final needlePaint = Paint()
      ..color = CyberColors.oledBlack
      ..style = PaintingStyle.fill;
    canvas.drawCircle(needlePos, 7, needlePaint);

    final needleDot = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(needlePos, 4.5, needleDot);
  }

  @override
  bool shouldRepaint(covariant _SpeedometerDialPainter oldDelegate) =>
      oldDelegate.ratio != ratio ||
      oldDelegate.speedMb != speedMb ||
      oldDelegate.activeColor != activeColor;
}
