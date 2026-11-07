import 'package:flutter/material.dart';
import '../../core/models/device_peer.dart';
import '../theme/app_theme.dart';

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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Device Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: peer.isConnected
                    ? AppTheme.accentGreen.withValues(alpha: 0.15)
                    : AppTheme.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(
                  color: peer.isConnected ? AppTheme.accentGreen : AppTheme.cardBorder,
                  width: 1.5,
                ),
              ),
              child: Icon(
                _getPeerIcon(peer.deviceType),
                color: peer.isConnected ? AppTheme.accentGreen : AppTheme.primaryNeon,
                size: 24,
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
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (peer.supports5GHz)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryNeon.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '5GHz',
                            style: TextStyle(
                              color: AppTheme.primaryNeon,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (peer.supportsZeroCopy) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Zero-Copy',
                            style: TextStyle(
                              color: Color(0xFFB388FF),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${peer.os} • ${peer.rssi} dBm',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      if (peer.speedLimitBytesPerSec > 0) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.speed, size: 12, color: AppTheme.accentAmber),
                        const SizedBox(width: 2),
                        Text(
                          '${(peer.speedLimitBytesPerSec / (1024 * 1024)).toStringAsFixed(0)}MB/s',
                          style: const TextStyle(
                            color: AppTheme.accentAmber,
                            fontSize: 11,
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
              icon: const Icon(Icons.tune, color: AppTheme.textSecondary, size: 20),
              tooltip: 'Speed & Data Limits',
              onPressed: onConfigureLimits,
            ),

            // Connect button
            ElevatedButton(
              onPressed: onConnect,
              style: ElevatedButton.styleFrom(
                backgroundColor: peer.isConnected ? AppTheme.accentGreen : AppTheme.primaryNeon,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: const Size(80, 36),
              ),
              child: Text(
                peer.isConnected ? 'Connected' : 'Send',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPeerIcon(DeviceType type) {
    switch (type) {
      case DeviceType.phone:
        return Icons.smartphone;
      case DeviceType.tablet:
        return Icons.tablet_mac;
      case DeviceType.pc:
        return Icons.computer;
      case DeviceType.unknown:
        return Icons.devices;
    }
  }
}
