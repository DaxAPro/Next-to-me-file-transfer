import 'package:flutter/material.dart';
import '../../core/models/device_peer.dart';
import '../../core/theme/cyber_colors.dart';
import '../common_widgets/custom_cyber_icons.dart';
import '../common_widgets/glass_container.dart';

class PeerCard extends StatelessWidget {
  final DevicePeer peer;
  final VoidCallback onConnect;
  final VoidCallback onConfigureLimits;

  const PeerCard({
    super.key,
    required this.peer,
    required this.onConnect,
    required this.onConfigureLimits,
  });

  @override
  Widget build(BuildContext context) {
    final primaryAccent = CyberColors.primaryAccent(context);
    final emeraldAccent = CyberColors.emeraldAccent(context);
    final peerAccent = peer.isConnected ? emeraldAccent : primaryAccent;

    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(14),
      blur: 14,
      child: Row(
        children: [
          // Device Avatar with CyberIcon inside glass halo
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: peerAccent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: peerAccent,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: peerAccent.withValues(alpha: 0.20),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: CyberIcon(
                type: _getPeerCyberIcon(peer.deviceType),
                color: peerAccent,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Peer info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        peer.name,
                        style: TextStyle(
                          color: CyberColors.text(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (peer.supports5GHz)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: primaryAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: primaryAccent.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'Fast Link',
                          style: TextStyle(
                            color: primaryAccent,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${peer.os} • Nearby',
                      style: TextStyle(
                        color: CyberColors.subtext(context),
                        fontSize: 11,
                      ),
                    ),
                    if (peer.speedLimitBytesPerSec > 0) ...[
                      const SizedBox(width: 6),
                      const CyberIcon(type: CyberIconType.speedometer, size: 12, color: CyberColors.warningAmber),
                      const SizedBox(width: 3),
                      Text(
                        '${(peer.speedLimitBytesPerSec / (1024 * 1024)).toStringAsFixed(0)} MB/s',
                        style: const TextStyle(
                          color: CyberColors.warningAmber,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Limit Config Button
          IconButton(
            icon: Icon(Icons.tune_rounded, color: CyberColors.subtext(context), size: 20),
            tooltip: 'Set Speed Limit',
            onPressed: onConfigureLimits,
          ),

          // Connect button with glass sheen
          ElevatedButton(
            onPressed: onConnect,
            style: ElevatedButton.styleFrom(
              backgroundColor: peerAccent,
              foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: const Size(72, 34),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 2,
            ),
            child: Text(
              peer.isConnected ? 'Connected' : 'Send File',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  CyberIconType _getPeerCyberIcon(DeviceType type) {
    switch (type) {
      case DeviceType.phone:
        return CyberIconType.phone;
      case DeviceType.tablet:
        return CyberIconType.tablet;
      case DeviceType.pc:
        return CyberIconType.pc;
      case DeviceType.unknown:
        return CyberIconType.phone;
    }
  }
}
