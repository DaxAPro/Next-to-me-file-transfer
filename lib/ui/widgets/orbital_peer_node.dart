import 'package:flutter/material.dart';
import '../../core/models/device_peer.dart';
import '../../core/theme/cyber_colors.dart';
import '../common_widgets/custom_cyber_icons.dart';
import 'adaptive_radar_painter.dart';

/// Floating peer node with pop-in bounce animation and clean mini-card
class OrbitalPeerNode extends StatefulWidget {
  final DevicePeer peer;
  final double crowdScale;
  final bool isEcoMode;
  final double pulseValue;
  final VoidCallback onTap;

  const OrbitalPeerNode({
    super.key,
    required this.peer,
    required this.crowdScale,
    required this.isEcoMode,
    required this.pulseValue,
    required this.onTap,
  });

  @override
  State<OrbitalPeerNode> createState() => _OrbitalPeerNodeState();
}

class _OrbitalPeerNodeState extends State<OrbitalPeerNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _popController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _popController,
      curve: Curves.elasticOut,
    );
    _popController.forward();
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = CyberColors.primaryAccent(context);
    final borderColor = CyberColors.border(context);
    final surfaceColor = CyberColors.surface(context);
    final textPrimary = CyberColors.text(context);
    final peer = widget.peer;
    final peerAccent = peer.isConnected ? CyberColors.techEmerald : primaryAccent;

    // Mini-card dimensions scaled according to crowd density
    final nodeSize = 36.0 * widget.crowdScale;
    final iconSize = 16.0 * widget.crowdScale;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Transform.scale(
        scale: widget.crowdScale,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Device circular node with adaptive pulse wave
              SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (peer.isConnected && !widget.isEcoMode)
                      CustomPaint(
                        size: const Size(44, 44),
                        painter: DeviceAdaptivePulsePainter(
                          animationValue: widget.pulseValue,
                          deviceType: peer.deviceType,
                          baseColor: CyberColors.techEmerald,
                        ),
                      ),
                    Container(
                      width: nodeSize,
                      height: nodeSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: surfaceColor,
                        border: Border.all(color: peerAccent, width: 1.8),
                        boxShadow: [
                          BoxShadow(
                            color: peerAccent.withValues(alpha: isDark ? 0.25 : 0.15),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: CyberIcon(
                          type: _getPeerCyberIcon(peer.deviceType),
                          size: iconSize,
                          color: peerAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),

              // Floating Mini-Card with device name & signal strength
              Container(
                constraints: const BoxConstraints(maxWidth: 76),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: surfaceColor.withValues(alpha: isDark ? 0.90 : 0.96),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: borderColor, width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      peer.name.split(' ').first,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: peerAccent,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${peer.rssi} dBm',
                          style: TextStyle(
                            color: CyberColors.subtext(context),
                            fontSize: 7.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
