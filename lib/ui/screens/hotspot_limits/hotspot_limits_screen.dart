import 'package:flutter/material.dart';
import '../../../core/models/device_peer.dart';
import '../../../services/connection/hybrid_connection_manager.dart';
import '../../theme/app_theme.dart';
import 'device_limit_modal.dart';

class HotspotLimitsScreen extends StatelessWidget {
  final HybridConnectionManager connectionManager;

  const HotspotLimitsScreen({super.key, required this.connectionManager});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final peers = connectionManager.discoveredPeers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotspot Limits'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner Notice
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_outlined, color: AppTheme.cyan, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Application Stream-Level Pacing',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Throttles socket transmission byte-rates and enforces transfer quotas per connected device without touching OS-level hotspot settings.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'CONNECTED PEER DEVICES',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: AppTheme.cyan),
          ),
          const SizedBox(height: 8),

          if (peers.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Text(
                'No peer devices currently discovered.\nStart scanning or connect via Direct Mode.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
            )
          else
            ...peers.map((peer) => _buildPeerLimitTile(context, peer, isDark)),
        ],
      ),
    );
  }

  Widget _buildPeerLimitTile(BuildContext context, DevicePeer peer, bool isDark) {
    final limit = peer.limitProfile;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                ),
                child: Icon(
                  peer.deviceType == DeviceType.pc ? Icons.laptop_mac : Icons.smartphone,
                  size: 20,
                  color: peer.isConnected ? AppTheme.green : AppTheme.cyan,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      peer.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Max Speed: ${limit.formattedSpeed} • Quota: ${limit.formattedQuota}',
                      style: TextStyle(
                        fontSize: 11,
                        color: limit.isSpeedThrottled ? AppTheme.amber : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                        fontWeight: limit.isSpeedThrottled ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _openLimitModal(context, peer),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(60, 32),
                ),
                child: const Text('Configure', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          if (limit.hasQuotaLimit) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: limit.quotaProgress,
                minHeight: 4,
                backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
                valueColor: AlwaysStoppedAnimation<Color>(
                  limit.isQuotaExceeded ? AppTheme.red : AppTheme.green,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openLimitModal(BuildContext context, DevicePeer peer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DeviceLimitModal(
        peer: peer,
        onSave: (maxSpeedBytes, maxQuotaBytes) {
          peer.speedLimitBytesPerSec = maxSpeedBytes;
          peer.dataLimitBytes = maxQuotaBytes;
          connectionManager.updateHostLimits(
            maxBytesPerSecond: maxSpeedBytes,
            maxTotalQuotaBytes: maxQuotaBytes,
          );
        },
      ),
    );
  }
}
