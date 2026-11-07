import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/models/device_peer.dart';
import '../theme/app_theme.dart';

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
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    // Green Code: Only run rotation animation if actively scanning and not in Eco Mode
    if (widget.isScanning && !widget.isEcoMode) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant RadarScanView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Green Code: Stop animation immediately when scanning stops or Eco Mode turns on
    if (widget.isScanning != oldWidget.isScanning || widget.isEcoMode != oldWidget.isEcoMode) {
      if (widget.isScanning && !widget.isEcoMode) {
        if (!_rotationController.isAnimating) {
          _rotationController.repeat();
        }
      } else {
        if (_rotationController.isAnimating) {
          _rotationController.stop();
        }
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
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

                // Rotating Radar Sweep Beam (Halted when not scanning to conserve GPU)
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

                // Center local device beacon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [AppTheme.primaryNeon, Color(0xFF0052CC)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryNeon.withValues(alpha: 0.5),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.wifi_tethering,
                    color: Colors.black,
                    size: 24,
                  ),
                ),

                // Discovered Peer Nodes placed radially based on RSSI
                ...widget.peers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final peer = entry.value;

                  // Compute angle around circle based on index
                  final angle = (index * (2 * pi / max(1, widget.peers.length))) - (pi / 2);
                  // Distance based on RSSI: -40 dBm is close (0.35 r), -90 dBm is far (0.85 r)
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
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: peer.isConnected
                                    ? AppTheme.accentGreen
                                    : AppTheme.cardDark,
                                border: Border.all(
                                  color: peer.isConnected
                                      ? AppTheme.accentGreen
                                      : AppTheme.primaryNeon,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (peer.isConnected
                                            ? AppTheme.accentGreen
                                            : AppTheme.primaryNeon)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _getPeerIcon(peer.deviceType),
                                size: 18,
                                color: peer.isConnected ? Colors.black : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                peer.name.split(' ').first,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
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

  IconData _getPeerIcon(DeviceType type) {
    switch (type) {
      case DeviceType.phone:
        return Icons.phone_android;
      case DeviceType.tablet:
        return Icons.tablet_android;
      case DeviceType.pc:
        return Icons.laptop;
      case DeviceType.unknown:
        return Icons.devices;
    }
  }
}

class _RadarGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    final ringPaint = Paint()
      ..color = AppTheme.cardBorder.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 4 Concentric Radar Rings
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, maxRadius * (i / 4.0), ringPaint);
    }

    // Crosshairs
    final linePaint = Paint()
      ..color = AppTheme.cardBorder.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), linePaint);
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RadarBeamPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final sweepGradient = SweepGradient(
      center: Alignment.center,
      startAngle: 0.0,
      endAngle: pi / 2,
      colors: [
        AppTheme.primaryNeon.withValues(alpha: 0.0),
        AppTheme.primaryNeon.withValues(alpha: 0.35),
      ],
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = sweepGradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawArc(rect, 0, pi / 2, true, paint);

    // Leading edge beam line
    final edgePaint = Paint()
      ..color = AppTheme.primaryNeon.withValues(alpha: 0.9)
      ..strokeWidth = 2.0;

    canvas.drawLine(
      center,
      Offset(center.dx + radius * cos(pi / 2), center.dy + radius * sin(pi / 2)),
      edgePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
