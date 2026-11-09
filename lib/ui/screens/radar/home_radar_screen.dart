import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/models/device_peer.dart';
import '../../../core/theme/cyber_colors.dart';
import '../../common_widgets/branded_app_logo.dart';
import 'radar_device_node.dart';
import 'radar_painters.dart';

/// "Discovering Peers" Radar Animation Screen
/// High-performance 60fps trigonometric orbital constellation layout.
class HomeRadarScreen extends StatefulWidget {
  final List<DevicePeer> peers;
  final bool isScanning;
  final Function(DevicePeer)? onPeerSelected;

  const HomeRadarScreen({
    super.key,
    required this.peers,
    this.isScanning = true,
    this.onPeerSelected,
  });

  @override
  State<HomeRadarScreen> createState() => _HomeRadarScreenState();
}

class _HomeRadarScreenState extends State<HomeRadarScreen>
    with TickerProviderStateMixin {
  // Continuous Sonar Ripple Animation Controller
  late final AnimationController _sonarController;

  // Very slow continuous Orbital Drift Rotation Controller
  late final AnimationController _orbitalDriftController;

  @override
  void initState() {
    super.initState();
    _sonarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _orbitalDriftController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 32000),
    );

    if (widget.isScanning) {
      _sonarController.repeat();
      _orbitalDriftController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant HomeRadarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning != oldWidget.isScanning) {
      if (widget.isScanning) {
        _sonarController.repeat();
        _orbitalDriftController.repeat();
      } else {
        _sonarController.stop();
        _orbitalDriftController.stop();
      }
    }
  }

  @override
  void dispose() {
    _sonarController.dispose();
    _orbitalDriftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gridLineColor = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.35)
        : const Color(0xFFCBD5E1).withValues(alpha: 0.50);

    const emeraldGreen = Color(0xFF10B981);
    const electricCyan = Color(0xFF00E5FF);

    return Scaffold(
      backgroundColor: CyberColors.background(context),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
          final maxRadius = min(constraints.maxWidth, constraints.maxHeight) * 0.44;

          // 3 Concentric orbital tracks: Inner (36%), Middle (64%), Outer (92%)
          final orbitRadii = [maxRadius * 0.36, maxRadius * 0.64, maxRadius * 0.92];

          // Distribute peers into 2 or 3 concentric orbits
          final List<List<DevicePeer>> orbits = [[], [], []];
          for (int i = 0; i < widget.peers.length; i++) {
            final track = _assignOrbitIndex(i, widget.peers.length);
            orbits[track].add(widget.peers[i]);
          }

          return AnimatedBuilder(
            animation: Listenable.merge([_sonarController, _orbitalDriftController]),
            builder: (context, child) {
              final driftAngle = _orbitalDriftController.value * 2 * pi;

              // Compute dynamic positions of all peers on their orbits
              final List<Offset> peerPositions = [];
              final List<Color> peerLineColors = [];
              final List<Widget> peerWidgets = [];

              for (int track = 0; track < 3; track++) {
                final trackPeers = orbits[track];
                if (trackPeers.isEmpty) continue;

                final radius = orbitRadii[track];
                final trackDrift = (track == 0)
                    ? driftAngle * 0.15
                    : (track == 1)
                        ? -driftAngle * 0.10
                        : driftAngle * 0.06;

                final step = (2 * pi) / trackPeers.length;

                for (int slot = 0; slot < trackPeers.length; slot++) {
                  final peer = trackPeers[slot];
                  final angle = (slot * step) - (pi / 2) + trackDrift;

                  final posX = center.dx + radius * cos(angle);
                  final posY = center.dy + radius * sin(angle);

                  final posOffset = Offset(posX, posY);
                  peerPositions.add(posOffset);

                  final isStrong = peer.isConnected || peer.rssi >= -65;
                  peerLineColors.add(isStrong ? emeraldGreen : electricCyan);

                  // Centered device node with 86px width
                  peerWidgets.add(
                    Positioned(
                      left: posX - 43,
                      top: posY - 22,
                      child: RadarDeviceNode(
                        peer: peer,
                        onTap: () => widget.onPeerSelected?.call(peer),
                      ),
                    ),
                  );
                }
              }

              return Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Subtle Graph-Paper Grid Background across entire screen
                  CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: GraphPaperGridPainter(gridColor: gridLineColor),
                  ),

                  // 2. Outward-Expanding Circular Ripples (Sonar Pulse) from center
                  CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: SonarPulsePainter(
                      animationValue: _sonarController.value,
                      emeraldColor: emeraldGreen,
                      cyanColor: electricCyan,
                      maxRadius: maxRadius,
                    ),
                  ),

                  // 3. Dynamic Dashed Connection Lines connecting ME to each device
                  CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: DynamicConnectionLinesPainter(
                      center: center,
                      devicePositions: peerPositions,
                      lineColors: peerLineColors,
                    ),
                  ),

                  // 4. Keep the app logo's center aligned with the radar origin.
                  Positioned(
                    left: center.dx - 36,
                    top: center.dy - 29,
                    child: _buildCenterUserNode(emeraldGreen, electricCyan),
                  ),

                  // 5. Orbital Constellation Devices (Animated bouncy nodes)
                  ...peerWidgets,

                  // 6. Header discovery status badge
                  Positioned(
                    top: 16,
                    left: 20,
                    right: 20,
                    child: SafeArea(
                      child: _buildHeaderBadge(context, emeraldGreen),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCenterUserNode(Color emeraldColor, Color cyanColor) {
    return SizedBox(
      width: 72,
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 7,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: cyanColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: cyanColor.withValues(alpha: 0.42),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: emeraldColor.withValues(alpha: 0.24),
                    blurRadius: 22,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Center(
                child: BrandedAppLogo(size: 54, useAssetIfAvailable: false),
              ),
            ),
          ),
          Positioned(
            top: 63,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                decoration: BoxDecoration(
                  color: emeraldColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: emeraldColor, width: 1),
                ),
                child: Text(
                  'ME',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: emeraldColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge(BuildContext context, Color emeraldColor) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black.withValues(alpha: 0.60)
              : Colors.white.withValues(alpha: 0.80),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: emeraldColor.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: emeraldColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Discovering Peers (${widget.peers.length} found)',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: CyberColors.text(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _assignOrbitIndex(int index, int total) {
    if (total <= 3) return 1; // All on Middle Orbit
    if (total <= 6) return (index % 2 == 0) ? 0 : 1; // Inner and Middle
    return index % 3; // Distribute across 3 concentric rings
  }
}
