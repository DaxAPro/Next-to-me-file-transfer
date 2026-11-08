import 'package:flutter/material.dart';
import '../../../core/models/device_peer.dart';
import '../../../core/theme/cyber_colors.dart';
import '../../../services/connection/hybrid_connection_manager.dart';
import '../../common_widgets/custom_cyber_icons.dart';
import '../../common_widgets/glass_background.dart';
import '../../common_widgets/glass_container.dart';
import 'device_limit_modal.dart';
import 'widgets/live_bandwidth_card.dart';

class HotspotLimitsScreen extends StatelessWidget {
  final HybridConnectionManager connectionManager;

  const HotspotLimitsScreen({super.key, required this.connectionManager});

  @override
  Widget build(BuildContext context) {
    final peers = connectionManager.discoveredPeers;

    return Scaffold(
      backgroundColor: CyberColors.background(context),
      appBar: AppBar(
        title: const Text('Set Limits'),
        backgroundColor: CyberColors.surface(context),
        elevation: 0,
      ),
      body: GlassBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Banner Notice
            GlassContainer(
              padding: const EdgeInsets.all(14),
              borderRadius: BorderRadius.circular(14),
              blur: 14,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                const CyberIcon(
                  type: CyberIconType.shield,
                  color: CyberColors.electricCyan,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Smooth Device Pacing',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: CyberColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Control transfer speed and data limits per device to keep your transfers running smoothly without overheating.',
                        style: TextStyle(
                          fontSize: 11,
                          color: CyberColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Real-Time Bandwidth Dashboard Card
          const LiveBandwidthCard(
            deviceName: 'Wi-Fi Direct Active Peer',
            currentSpeedMb: 1.8,
            usedMb: 140.0,
            totalQuotaMb: 1024.0,
            isThrottled: false,
          ),
          const SizedBox(height: 16),

          const Text(
            'CONNECTED PEER DEVICES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: CyberColors.electricCyan,
            ),
          ),
          const SizedBox(height: 8),

          if (peers.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CyberColors.darkSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CyberColors.borderOutline),
              ),
              child: const Text(
                'No peer devices currently discovered.\nStart scanning or connect via Direct Mode.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: CyberColors.textSecondary,
                ),
              ),
            )
          else
            ...peers.map((peer) => _buildPeerLimitTile(context, peer)),
        ],
      ),
    ),
    );
  }

  Widget _buildPeerLimitTile(BuildContext context, DevicePeer peer) {
    final limit = peer.limitProfile;

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(14),
      blur: 14,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: CyberColors.background(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CyberColors.border(context)),
                ),
                child: Center(
                  child: CyberIcon(
                    type: peer.deviceType == DeviceType.pc
                        ? CyberIconType.pc
                        : CyberIconType.phone,
                    size: 20,
                    color: peer.isConnected ? CyberColors.emeraldAccent(context) : CyberColors.primaryAccent(context),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      peer.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: CyberColors.text(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Max Speed: ${limit.formattedSpeed} • Quota: ${limit.formattedQuota}',
                      style: TextStyle(
                        fontSize: 11,
                        color: limit.isSpeedThrottled
                            ? CyberColors.warningAmber
                            : CyberColors.subtext(context),
                        fontWeight: limit.isSpeedThrottled ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _openLimitModal(context, peer),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CyberColors.primaryAccent(context),
                  foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(60, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('Configure', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                backgroundColor: CyberColors.oledBlack,
                valueColor: AlwaysStoppedAnimation<Color>(
                  limit.isQuotaExceeded ? CyberColors.dangerRed : CyberColors.techEmerald,
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
