import 'package:flutter/material.dart';
import '../../../core/models/device_peer.dart';
import '../../common_widgets/custom_cyber_icons.dart';

/// Animated radar peer node with elastic bounce entry, glowing aura, and device label.
class RadarDeviceNode extends StatefulWidget {
  final DevicePeer peer;
  final VoidCallback onTap;

  const RadarDeviceNode({
    super.key,
    required this.peer,
    required this.onTap,
  });

  @override
  State<RadarDeviceNode> createState() => _RadarDeviceNodeState();
}

class _RadarDeviceNodeState extends State<RadarDeviceNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _popController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Pop-in bounce with satisfying elasticOut curve
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
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
    final peer = widget.peer;

    // Green (#10B981) for strong signal / connected, Blue (#00E5FF) for good signal
    final isStrong = peer.isConnected || peer.rssi >= -65;
    final auraColor = isStrong ? const Color(0xFF10B981) : const Color(0xFF00E5FF);
    final surfaceColor = isDark ? const Color(0xFF101622) : const Color(0xFFFFFFFF);
    final textPrimary = isDark ? const Color(0xFFF0F4F8) : const Color(0xFF1F2328);
    final textSecondary = isDark ? const Color(0xFF8B98A5) : const Color(0xFF656D76);

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          width: 86,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular device icon with glowing aura border
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: surfaceColor,
                  border: Border.all(color: auraColor, width: 2.0),
                  boxShadow: [
                    BoxShadow(
                      color: auraColor.withValues(alpha: 0.38),
                      blurRadius: 10,
                      spreadRadius: 1.5,
                    ),
                  ],
                ),
                child: Center(
                  child: CyberIcon(
                    type: _getDeviceIcon(peer.deviceType),
                    size: 20,
                    color: auraColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // Small text label: Name and Signal Strength
              Text(
                peer.name,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              Text(
                '(${peer.rssi}dBm)',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  CyberIconType _getDeviceIcon(DeviceType type) {
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
