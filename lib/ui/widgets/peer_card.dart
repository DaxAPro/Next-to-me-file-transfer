import 'package:flutter/material.dart';
import '../../core/models/device_peer.dart';
import '../../core/theme/cyber_colors.dart';
import '../common_widgets/custom_cyber_icons.dart';

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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CyberColors.darkSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CyberColors.borderOutline),
      ),
      child: Row(
        children: [
          // Device Avatar with CyberIcon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: CyberColors.oledBlack,
              shape: BoxShape.circle,
              border: Border.all(
                color: peer.isConnected ? CyberColors.techEmerald : CyberColors.electricCyan,
                width: 1.5,
              ),
            ),
            child: Center(
              child: CyberIcon(
                type: _getPeerCyberIcon(peer.deviceType),
                color: peer.isConnected ? CyberColors.techEmerald : CyberColors.electricCyan,
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
                        style: const TextStyle(
                          color: CyberColors.textPrimary,
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
                          color: CyberColors.electricCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: CyberColors.electricCyan.withValues(alpha: 0.3)),
                        ),
                        child: const Text(
                          '5GHz',
                          style: TextStyle(
                            color: CyberColors.electricCyan,
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
                      style: const TextStyle(
                        color: CyberColors.textSecondary,
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
            icon: const Icon(Icons.tune_rounded, color: CyberColors.textSecondary, size: 20),
            tooltip: 'Set Speed Limit',
            onPressed: onConfigureLimits,
          ),

          // Connect button
          ElevatedButton(
            onPressed: onConnect,
            style: ElevatedButton.styleFrom(
              backgroundColor: peer.isConnected ? CyberColors.techEmerald : CyberColors.electricCyan,
              foregroundColor: CyberColors.oledBlack,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: const Size(72, 34),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
