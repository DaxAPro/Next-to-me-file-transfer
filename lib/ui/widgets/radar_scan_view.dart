import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/models/device_peer.dart';
import '../../core/theme/cyber_colors.dart';
import '../common_widgets/cyber_avatar.dart';
import '../common_widgets/custom_cyber_icons.dart';
import 'adaptive_radar_painter.dart';

class RadarScanView extends StatefulWidget {
  final List<DevicePeer> peers;
  final bool isScanning;
  final bool isEcoMode;
  final Function(DevicePeer) onPeerSelected;

  const RadarScanView({
    super.key,
    required this.peers,
    required this.isScanning,
    this.isEcoMode = false,
    required this.onPeerSelected,
  });

  @override
  State<RadarScanView> createState() => _RadarScanViewState();
}

class _RadarScanViewState extends State<RadarScanView>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    if (widget.isScanning && !widget.isEcoMode) {
      _rotationController.repeat();
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant RadarScanView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning != oldWidget.isScanning || widget.isEcoMode != oldWidget.isEcoMode) {
      if (widget.isScanning && !widget.isEcoMode) {
        if (!_rotationController.isAnimating) _rotationController.repeat();
        if (!_pulseController.isAnimating) _pulseController.repeat();
      } else {
        if (_rotationController.isAnimating) _rotationController.stop();
        if (_pulseController.isAnimating) _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, 280.0);

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Concentric Sonar Rings
                CustomPaint(
                  size: Size(size, size),
                  painter: _RadarGridPainter(),
                ),

                // Rotating Radar Sweep Beam
                if (widget.isScanning && !widget.isEcoMode)
                  AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationController.value * 2 * pi,
                        child: CustomPaint(
                          size: Size(size, size),
                          painter: _RadarBeamPainter(),
                        ),
                      );
                    },
                  ),

                // Center local device identity node: Distinct Flat 2D Cyber Persona
                const CyberAvatar(size: 48, showStatusBadge: true),

                // Discovered Peer Nodes placed radially based on RSSI
                ...widget.peers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final peer = entry.value;

                  final angle = (index * (2 * pi / max(1, widget.peers.length))) - (pi / 2);
                  final normalizedDistance = ((peer.rssi.abs() - 40) / 55.0).clamp(0.35, 0.85);
                  final radius = (size / 2) * normalizedDistance;

                  final x = (size / 2) + radius * cos(angle) - 22;
                  final y = (size / 2) + radius * sin(angle) - 22;

                  return Positioned(
                    left: x,
                    top: y,
                    child: GestureDetector(
                      onTap: () => widget.onPeerSelected(peer),
                      child: Tooltip(
                        message: '${peer.name} (${peer.rssi} dBm)',
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Node with Adaptive Pulse Wave
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (peer.isConnected && !widget.isEcoMode)
                                    AnimatedBuilder(
                                      animation: _pulseController,
                                      builder: (context, child) {
                                        return CustomPaint(
                                          size: const Size(44, 44),
                                          painter: DeviceAdaptivePulsePainter(
                                            animationValue: _pulseController.value,
                                            deviceType: peer.deviceType,
                                            baseColor: CyberColors.techEmerald,
                                          ),
                                        );
                                      },
                                    ),
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: CyberColors.darkSurface,
                                      border: Border.all(
                                        color: peer.isConnected
                                            ? CyberColors.techEmerald
                                            : CyberColors.electricCyan,
                                        width: 1.8,
                                      ),
                                    ),
                                    child: Center(
                                      child: CyberIcon(
                                        type: _getPeerCyberIcon(peer.deviceType),
                                        size: 18,
                                        color: peer.isConnected
                                            ? CyberColors.techEmerald
                                            : CyberColors.electricCyan,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: CyberColors.oledBlack.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: CyberColors.borderOutline, width: 0.8),
                              ),
                              child: Text(
                                peer.name.split(' ').first,
                                style: const TextStyle(
                                  color: CyberColors.textPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  CyberIconType _getPeerCyberIcon(DeviceType type) {
    switch (type) {
      case DeviceType.pc:
        return CyberIconType.pc;
      case DeviceType.tablet:
        return CyberIconType.tablet;
      case DeviceType.phone:
      case DeviceType.unknown:
        return CyberIconType.phone;
    }
  }
}

class _RadarGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    final circlePaint = Paint()
      ..color = CyberColors.borderOutline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 3 concentric distance range rings
    canvas.drawCircle(center, maxRadius * 0.35, circlePaint);
    canvas.drawCircle(center, maxRadius * 0.65, circlePaint);
    canvas.drawCircle(center, maxRadius - 2, circlePaint);

    // Crosshairs
    final crosshairPaint = Paint()
      ..color = CyberColors.borderOutline.withValues(alpha: 0.5)
      ..strokeWidth = 0.8;

    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), crosshairPaint);
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), crosshairPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RadarBeamPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Flat Cyber sweep arc (45 degree sweep)
    final sweepGradient = SweepGradient(
      center: Alignment.center,
      startAngle: 0.0,
      endAngle: pi / 4,
      colors: [
        CyberColors.electricCyan.withValues(alpha: 0.0),
        CyberColors.electricCyan.withValues(alpha: 0.25),
      ],
    );

    final sweepPaint = Paint()
      ..shader = sweepGradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawArc(rect, 0, pi / 4, true, sweepPaint);

    // Leading edge bright ray
    final linePaint = Paint()
      ..color = CyberColors.electricCyan
      ..strokeWidth = 1.5;

    final edgeX = center.dx + radius * cos(pi / 4);
    final edgeY = center.dy + radius * sin(pi / 4);
    canvas.drawLine(center, Offset(edgeX, edgeY), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
