import 'package:flutter/material.dart';
import '../../core/models/device_peer.dart';
import '../../core/models/transfer_models.dart';
import '../../services/connection/hybrid_connection_manager.dart';
import '../drawer/app_navigation_drawer.dart';
import '../theme/app_theme.dart';
import '../widgets/radar_scan_view.dart';
import '../widgets/peer_card.dart';
import '../widgets/transfer_card.dart';
import '../widgets/bottom_banner_ad.dart';
import '../widgets/permission_disclosure_dialog.dart';

class HomeScreen extends StatefulWidget {
  final HybridConnectionManager connectionManager;

  const HomeScreen({super.key, required this.connectionManager});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _hasAcceptedPermissions = false;

  @override
  void initState() {
    super.initState();
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

  void _handlePeerTap(DevicePeer peer) async {
    final success = await widget.connectionManager.connectToPeer(peer);
    if (success && mounted) {
      _showQuickSendDialog(peer);
    }
  }

  void _showQuickSendDialog(DevicePeer peer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.send_rounded, color: AppTheme.cyan),
                const SizedBox(width: 10),
                Text(
                  'Send File to ${peer.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Select a sample file to initiate high-speed 5GHz socket stream with stream-while-downloading:',
              style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.movie_outlined, color: AppTheme.red, size: 28),
              title: const Text('4K_Nature_Documentary.mp4 (450 MB)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: const Text('Supports 5% buffer streaming preview', style: TextStyle(fontSize: 11)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              tileColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
              onTap: () {
                Navigator.pop(ctx);
                widget.connectionManager.enqueueTransfer(
                  fileName: '4K_Nature_Documentary.mp4',
                  fileSize: 450 * 1024 * 1024,
                  isIncoming: false,
                );
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.android_outlined, color: AppTheme.green, size: 28),
              title: const Text('AppInstaller_v2.0.apk (85 MB)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: const Text('Auto-categorizes into /NextToMe/APKs', style: TextStyle(fontSize: 11)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              tileColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
              onTap: () {
                Navigator.pop(ctx);
                widget.connectionManager.enqueueTransfer(
                  fileName: 'AppInstaller_v2.0.apk',
                  fileSize: 85 * 1024 * 1024,
                  isIncoming: false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStreamingPreviewDialog(TransferTask task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.play_circle_fill, color: AppTheme.cyan),
            SizedBox(width: 8),
            Text('Stream Preview', style: TextStyle(fontSize: 15)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Playing: ${task.fileName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.cyan),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.live_tv, size: 32, color: AppTheme.cyan),
                    SizedBox(height: 6),
                    Text('Direct HLS Loopback Active (5% threshold met)', style: TextStyle(fontSize: 10, color: AppTheme.green)),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cm = widget.connectionManager;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTransferring = cm.activeTransfers.any((t) => t.status == TransferStatus.transferring);

    return Scaffold(
      key: _scaffoldKey,
      // Side Navigation Drawer
      drawer: AppNavigationDrawer(
        connectionManager: cm,
        currentItem: DrawerItem.home,
      ),
      appBar: AppBar(
        // Hamburger Menu (three lines top-left)
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          tooltip: 'Open Menu',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppTheme.cyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.bolt, color: AppTheme.cyan, size: 20),
            ),
            const SizedBox(width: 8),
            const Text('NextToMe'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Rescan Nearby',
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

                // Mode Selector Tabs (Direct vs Home)
                _buildModeSelector(cm, isDark),

                if (cm.statusMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Center(
                      child: Text(
                        cm.statusMessage!,
                        style: const TextStyle(color: AppTheme.cyan, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // Flat Radar Scanner
                RadarScanView(
                  peers: cm.discoveredPeers,
                  isScanning: cm.handshakePhase == HandshakePhase.discoveringBle ||
                      cm.handshakePhase == HandshakePhase.idle,
                  isEcoMode: cm.isEcoMode,
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
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: AppTheme.cyan),
                        ),
                        if (cm.hostLimitProfile.isSpeedThrottled)
                          Text(
                            'Throttled: ${cm.hostLimitProfile.formattedSpeedLimit}',
                            style: const TextStyle(color: AppTheme.amber, fontSize: 11, fontWeight: FontWeight.bold),
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
                            ? 'NEARBY DEVICES (5GHz)'
                            : 'LAN DEVICES (ROUTER)',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: AppTheme.cyan),
                      ),
                      Text(
                        '${cm.discoveredPeers.length} found',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                if (cm.discoveredPeers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Scanning for nearby devices...',
                        style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                      ),
                    ),
                  )
                else
                  ...cm.discoveredPeers.map((peer) => PeerCard(
                        peer: peer,
                        onConnect: () => _handlePeerTap(peer),
                        onConfigureLimits: () {},
                      )),
              ],
            ),
          ),

          // Pinned Bottom Banner Ad
          BottomBannerAdWidget(isTransferring: isTransferring),
        ],
      ),
    );
  }

  Widget _buildModeSelector(HybridConnectionManager cm, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => cm.switchMode(ConnectionMode.directMode),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: cm.activeMode == ConnectionMode.directMode ? AppTheme.cyan : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Direct (BLE + 5GHz)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: cm.activeMode == ConnectionMode.directMode ? Colors.black : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => cm.switchMode(ConnectionMode.homeMode),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: cm.activeMode == ConnectionMode.homeMode ? AppTheme.violet : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Home Mode (LAN)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: cm.activeMode == ConnectionMode.homeMode ? Colors.white : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
