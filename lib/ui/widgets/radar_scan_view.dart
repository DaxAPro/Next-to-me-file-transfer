import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/models/device_peer.dart';
import '../../core/theme/cyber_colors.dart';
import '../common_widgets/cyber_avatar.dart';
import 'orbital_peer_node.dart';

/// Advanced Orbital Constellation Radar Scanner (Handles 10+ Devices Gracefully)
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

class _RadarScanViewState extends State<RadarScanView> with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _rippleController;
  late final AnimationController _orbitalController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _orbitalController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16000),
    );

    if (widget.isScanning && !widget.isEcoMode) {
      _rotationController.repeat();
      _rippleController.repeat();
      _orbitalController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant RadarScanView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning != oldWidget.isScanning || widget.isEcoMode != oldWidget.isEcoMode) {
      if (widget.isScanning && !widget.isEcoMode) {
        if (!_rotationController.isAnimating) _rotationController.repeat();
        if (!_rippleController.isAnimating) _rippleController.repeat();
        if (!_orbitalController.isAnimating) _orbitalController.repeat();
      } else {
        if (_rotationController.isAnimating) _rotationController.stop();
        if (_rippleController.isAnimating) _rippleController.stop();
        if (_orbitalController.isAnimating) _orbitalController.stop();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _rippleController.dispose();
    _orbitalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = CyberColors.border(context);
    final primaryAccent = CyberColors.primaryAccent(context);
    final emeraldAccent = CyberColors.emeraldAccent(context);

    final crowdScale = widget.peers.length >= 10
        ? 0.74
        : widget.peers.length >= 6
            ? 0.85
            : 1.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, 300.0);
        final maxRadius = size / 2;

        // Orbital Track radii: Inner (0.38), Middle (0.62), Outer (0.86)
        final trackRadii = [maxRadius * 0.38, maxRadius * 0.62, maxRadius * 0.86];

        // Group peers into orbits to avoid overlapping
        final Map<int, List<DevicePeer>> orbitGroups = {0: [], 1: [], 2: []};
        for (int i = 0; i < widget.peers.length; i++) {
          final track = _assignOrbitTrack(i, widget.peers.length);
          orbitGroups[track]!.add(widget.peers[i]);
        }

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Orbital Constellation Grid Rings
                CustomPaint(
                  size: Size(size, size),
                  painter: _RadarGridPainter(
                    gridColor: borderColor,
                    trackRadii: trackRadii,
                  ),
                ),

                // 2. Smooth Outward-Rippling Sonar Pulses
                if (widget.isScanning && !widget.isEcoMode)
                  AnimatedBuilder(
                    animation: _rippleController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: Size(size, size),
                        painter: _SonarRipplesPainter(
                          animationValue: _rippleController.value,
                          rippleColor: primaryAccent,
                        ),
                      );
                    },
                  ),

                // 3. Rotating Radar Sweep Beam
                if (widget.isScanning && !widget.isEcoMode)
                  AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationController.value * 2 * pi,
                        child: CustomPaint(
                          size: Size(size, size),
                          painter: _RadarBeamPainter(beamColor: primaryAccent),
                        ),
                      );
                    },
                  ),

                // 4. Center "ME" User Node (assets/user_icon.png)
                _buildCenterUserNode(primaryAccent, emeraldAccent),

                // 5. Orbital Constellation Peer Nodes (No overlap for 10+ devices)
                AnimatedBuilder(
                  animation: _orbitalController,
                  builder: (context, child) {
                    final orbitalTime = _orbitalController.value * 2 * pi;
                    return Stack(
                      children: [
                        for (int track = 0; track < 3; track++)
                          ..._buildTrackPeers(
                            orbitGroups[track]!,
                            track,
                            trackRadii[track],
                            size,
                            orbitalTime,
                            crowdScale,
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCenterUserNode(Color primaryAccent, Color emeraldAccent) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CyberAvatar(size: 46, showStatusBadge: true),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: emeraldAccent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: emeraldAccent, width: 0.8),
          ),
          child: Text(
            'ME',
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
              color: emeraldAccent,
            ),
          ),
        ),
      ],
    );
  }

  int _assignOrbitTrack(int index, int total) {
    if (total <= 3) return 1; // Middle
    if (total <= 6) return (index % 2 == 0) ? 0 : 1; // Inner and Middle
    // 7 to 10+ devices distributed across 3 distinct concentric rings
    return index % 3;
  }

  List<Widget> _buildTrackPeers(
    List<DevicePeer> peers,
    int track,
    double radius,
    double size,
    double orbitalTime,
    double crowdScale,
  ) {
    if (peers.isEmpty) return [];

    // Slow orbital rotation per ring (different speeds & directions prevent clustering)
    final trackRotation = (track == 0)
        ? orbitalTime * 0.12
        : (track == 1)
            ? -orbitalTime * 0.08
            : orbitalTime * 0.05;

    final center = size / 2;

    return peers.asMap().entries.map((entry) {
      final slotIndex = entry.key;
      final peer = entry.value;

      final angleStep = (2 * pi) / max(1, peers.length);
      final angle = (slotIndex * angleStep) - (pi / 2) + trackRotation;

      final x = center + radius * cos(angle) - 22;
      final y = center + radius * sin(angle) - 22;

      return Positioned(
        left: x,
        top: y,
        child: OrbitalPeerNode(
          peer: peer,
          crowdScale: crowdScale,
          isEcoMode: widget.isEcoMode,
          pulseValue: _rippleController.value,
          onTap: () => widget.onPeerSelected(peer),
        ),
      );
    }).toList();
  }
}

class _RadarGridPainter extends CustomPainter {
  final Color gridColor;
  final List<double> trackRadii;

  _RadarGridPainter({required this.gridColor, required this.trackRadii});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final circlePaint = Paint()
      ..color = gridColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final r in trackRadii) {
      canvas.drawCircle(center, r, circlePaint);
    }

    final crosshairPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.35)
      ..strokeWidth = 0.8;

    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), crosshairPaint);
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), crosshairPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarGridPainter oldDelegate) =>
      oldDelegate.gridColor != gridColor;
}

class _SonarRipplesPainter extends CustomPainter {
  final double animationValue;
  final Color rippleColor;

  _SonarRipplesPainter({required this.animationValue, required this.rippleColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final waveProgress = (animationValue + (i * 0.33)) % 1.0;
      final currentRadius = waveProgress * maxRadius;
      final alpha = (1.0 - waveProgress) * 0.40;

      final paint = Paint()
        ..color = rippleColor.withValues(alpha: alpha.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(center, currentRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SonarRipplesPainter oldDelegate) => true;
}

class _RadarBeamPainter extends CustomPainter {
  final Color beamColor;
  _RadarBeamPainter({required this.beamColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final sweepGradient = SweepGradient(
      center: Alignment.center,
      startAngle: 0.0,
      endAngle: pi / 4,
      colors: [
        beamColor.withValues(alpha: 0.0),
        beamColor.withValues(alpha: 0.22),
      ],
    );

    final sweepPaint = Paint()
      ..shader = sweepGradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawArc(rect, 0, pi / 4, true, sweepPaint);

    final linePaint = Paint()
      ..color = beamColor
      ..strokeWidth = 1.4;

    final edgeX = center.dx + radius * cos(pi / 4);
    final edgeY = center.dy + radius * sin(pi / 4);
    canvas.drawLine(center, Offset(edgeX, edgeY), linePaint);
  }

  @override
  bool shouldRepaint(covariant _RadarBeamPainter oldDelegate) =>
      oldDelegate.beamColor != beamColor;
}
