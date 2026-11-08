import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/cyber_colors.dart';

/// Celebratory Transfer Success Dialog with Tick-Bounce and 2D Fireworks
class TransferSuccessDialog extends StatefulWidget {
  final String fileName;
  final String fileSize;
  final VoidCallback onDismiss;

  const TransferSuccessDialog({
    super.key,
    required this.fileName,
    required this.fileSize,
    required this.onDismiss,
  });

  @override
  State<TransferSuccessDialog> createState() => _TransferSuccessDialogState();
}

class _TransferSuccessDialogState extends State<TransferSuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Elastic bounce for checkmark
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.25).chain(CurveTween(curve: Curves.easeOutBack)), weight: 60),
      TweenSequenceItem(tween: Tween<double>(begin: 1.25, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 40),
    ]).animate(_animController);

    // Generate radial firework particles
    final random = math.Random();
    _particles = List.generate(24, (index) {
      final angle = (index * (360 / 24)) * math.pi / 180;
      final speed = 35.0 + random.nextDouble() * 45.0;
      final color = index % 2 == 0 ? CyberColors.techEmerald : CyberColors.electricCyan;
      return _Particle(angle: angle, speed: speed, color: color);
    });

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = CyberColors.surface(context);
    final borderColor = CyberColors.border(context);
    final textPrimary = CyberColors.text(context);
    final textSecondary = CyberColors.subtext(context);

    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Firework + Check Canvas
            SizedBox(
              width: 140,
              height: 140,
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _FireworksPainter(
                      progress: _animController.value,
                      particles: _particles,
                    ),
                    child: Center(
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: CyberColors.techEmerald,
                            shape: BoxShape.circle,
                            border: Border.all(color: surfaceColor, width: 3),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 34,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            const Text(
              'TRANSFER COMPLETE!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: CyberColors.techEmerald,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Saved to /Downloads/NextToMe • ${widget.fileSize}',
              style: TextStyle(
                fontSize: 11,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onDismiss();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CyberColors.techEmerald,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  final Color color;

  _Particle({required this.angle, required this.speed, required this.color});
}

class _FireworksPainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;

  _FireworksPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final alpha = (1.0 - progress).clamp(0.0, 1.0);

    for (final p in particles) {
      final distance = p.speed * progress;
      final x = center.dx + distance * math.cos(p.angle);
      final y = center.dy + distance * math.sin(p.angle);

      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 2.5 * alpha, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
