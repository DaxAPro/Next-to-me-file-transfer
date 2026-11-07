import 'package:flutter/material.dart';
import '../../core/models/device_peer.dart';
import '../../core/models/transfer_models.dart';
import '../../services/connection/hybrid_connection_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/radar_scan_view.dart';
import '../widgets/peer_card.dart';
import '../widgets/transfer_card.dart';
import '../widgets/speed_limit_dialog.dart';
import '../widgets/bottom_banner_ad.dart';
import '../widgets/permission_disclosure_dialog.dart';

class HomeScreen extends StatefulWidget {
  final HybridConnectionManager connectionManager;

  const HomeScreen({super.key, required this.connectionManager});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasAcceptedPermissions = false;

  @override
  void initState() {
    super.initState();
    // Auto start discovery
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionsAndStartScan();
    });
  }

  void _checkPermissionsAndStartScan() {
    if (!_hasAcceptedPermissions) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => PermissionDisclosureDialog(
          onAccepted: () {
            setState(() => _hasAcceptedPermissions = true);
            widget.connectionManager.startScanning();
          },
        ),
      );
    } else {
      widget.connectionManager.startScanning();
    }
  }

  void _showLimitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SpeedLimitDialog(
        currentProfile: widget.connectionManager.hostLimitProfile,
        onSave: (speedBytes, quotaBytes) {
          widget.connectionManager.updateHostLimits(
            maxBytesPerSecond: speedBytes,
            maxTotalQuotaBytes: quotaBytes,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Host limits updated: ${widget.connectionManager.hostLimitProfile.formattedSpeedLimit} • ${widget.connectionManager.hostLimitProfile.formattedQuotaLimit}',
              ),
              backgroundColor: AppTheme.cardDark,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  void _handlePeerTap(DevicePeer peer) async {
    final success = await widget.connectionManager.connectToPeer(peer);
    if (success && mounted) {
      _showQuickSendDialog(peer);
    }
  }

  void _showQuickSendDialog(DevicePeer peer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.send_rounded, color: AppTheme.primaryNeon),
                const SizedBox(width: 10),
                Text(
                  'Send File to ${peer.name}',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Select a sample file to test high-speed 5GHz transfer with chunking, zero-copy socket simulation, and stream-while-downloading:',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.movie, color: Colors.redAccent, size: 30),
              title: const Text('4K_Nature_Documentary.mp4 (450 MB)'),
              subtitle: const Text('Video • Supports Stream-While-Downloading at 5%'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textSecondary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: AppTheme.surfaceElevated,
              onTap: () {
                Navigator.pop(ctx);
                widget.connectionManager.enqueueTransfer(
                  fileName: '4K_Nature_Documentary.mp4',
                  fileSize: 450 * 1024 * 1024,
                  isIncoming: false,
                );
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.android, color: AppTheme.accentGreen, size: 30),
              title: const Text('ModernApp_v3.2.0.apk (85 MB)'),
              subtitle: const Text('Application • Auto-categorized to /NextToMe/APKs'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textSecondary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: AppTheme.surfaceElevated,
              onTap: () {
                Navigator.pop(ctx);
                widget.connectionManager.enqueueTransfer(
                  fileName: 'ModernApp_v3.2.0.apk',
                  fileSize: 85 * 1024 * 1024,
                  isIncoming: false,
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showStreamingPreviewDialog(TransferTask task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.play_circle_fill, color: AppTheme.primaryNeon),
            const SizedBox(width: 8),
            const Text('Stream While Downloading', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Playing: ${task.fileName}',
              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.4)),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.live_tv, size: 36, color: AppTheme.primaryNeon),
                    SizedBox(height: 6),
                    Text(
                      'HLS Direct Stream Active (0.05+ threshold met)',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close Player'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cm = widget.connectionManager;
    final isTransferring = cm.activeTransfers.any((t) => t.status == TransferStatus.transferring);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryNeon.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.offline_bolt, color: AppTheme.primaryNeon, size: 22),
            ),
            const SizedBox(width: 10),
            const Text('NextToMe'),
          ],
        ),
        actions: [
          // Host Limits Badge / Button
          IconButton(
            icon: Icon(
              Icons.tune,
              color: cm.hostLimitProfile.isSpeedThrottled ? AppTheme.accentAmber : AppTheme.textSecondary,
            ),
            tooltip: 'Host Speed & Quota Limits',
            onPressed: _showLimitDialog,
          ),

          // Rescan / Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textPrimary),
            tooltip: 'Rescan Nearby Devices',
            onPressed: cm.startScanning,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 20),
              children: [
                const SizedBox(height: 8),

                // Mode Selector Bar (Direct Mode vs Home Mode)
                _buildModeSelector(cm),

                // Status message indicator
                if (cm.statusMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Center(
                      child: Text(
                        cm.statusMessage!,
                        style: const TextStyle(color: AppTheme.primaryNeon, fontSize: 12),
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // Animated Radar Scanner View
                RadarScanView(
                  peers: cm.discoveredPeers,
                  isScanning: cm.handshakePhase == HandshakePhase.discoveringBle ||
                      cm.handshakePhase == HandshakePhase.idle,
                  onPeerSelected: _handlePeerTap,
                ),

                const SizedBox(height: 16),

                // Active Transfers Section
                if (cm.activeTransfers.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ACTIVE TRANSFERS',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.0,
                          ),
                        ),
                        if (cm.hostLimitProfile.isSpeedThrottled)
                          Text(
                            'Throttled: ${cm.hostLimitProfile.formattedSpeedLimit}',
                            style: const TextStyle(
                              color: AppTheme.accentAmber,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                  ...cm.activeTransfers.map((task) => TransferCard(
                        task: task,
                        onPause: () => cm.pauseTransfer(task.id),
                        onResume: () => cm.resumeTransfer(task.id),
                        onStreamPlay: () => _showStreamingPreviewDialog(task),
                      )),
                ],

                const SizedBox(height: 12),

                // Discovered Devices Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        cm.activeMode == ConnectionMode.directMode
                            ? 'NEARBY DEVICES (BLE 5GHz)'
                            : 'LAN DEVICES (ROUTER)',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        '${cm.discoveredPeers.length} found',
                        style: const TextStyle(
                          color: AppTheme.primaryNeon,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                if (cm.discoveredPeers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.radar, size: 40, color: AppTheme.textMuted.withOpacity(0.5)),
                          const SizedBox(height: 8),
                          const Text(
                            'Scanning for nearby devices...',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...cm.discoveredPeers.map((peer) => PeerCard(
                        peer: peer,
                        onConnect: () => _handlePeerTap(peer),
                        onConfigureLimits: _showLimitDialog,
                      )),
              ],
            ),
          ),

          // Pinned Smart Banner Ad adhering to Blueprint Section 6
          BottomBannerAdWidget(isTransferring: isTransferring),
        ],
      ),
    );
  }

  Widget _buildModeSelector(HybridConnectionManager cm) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          // Direct Mode
          Expanded(
            child: GestureDetector(
              onTap: () => cm.switchMode(ConnectionMode.directMode),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: cm.activeMode == ConnectionMode.directMode
                      ? AppTheme.primaryNeon
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bolt,
                      size: 16,
                      color: cm.activeMode == ConnectionMode.directMode
                          ? Colors.black
                          : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Direct Mode (BLE + Wi-Fi)',
                      style: TextStyle(
                        color: cm.activeMode == ConnectionMode.directMode
                            ? Colors.black
                            : AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Home Mode (LAN)
          Expanded(
            child: GestureDetector(
              onTap: () => cm.switchMode(ConnectionMode.homeMode),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: cm.activeMode == ConnectionMode.homeMode
                      ? AppTheme.secondaryAccent
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.router,
                      size: 16,
                      color: cm.activeMode == ConnectionMode.homeMode
                          ? Colors.white
                          : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Home Mode (LAN)',
                      style: TextStyle(
                        color: cm.activeMode == ConnectionMode.homeMode
                            ? Colors.white
                            : AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
