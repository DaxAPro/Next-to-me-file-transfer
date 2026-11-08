import 'package:flutter/material.dart';
import '../../core/constants/user_friendly_strings.dart';
import '../../core/models/device_peer.dart';
import '../../core/models/transfer_models.dart';
import '../../core/theme/cyber_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../services/connection/hybrid_connection_manager.dart';
import '../common_widgets/cyber_avatar.dart';
import '../common_widgets/custom_cyber_icons.dart';
import '../common_widgets/glass_background.dart';
import '../common_widgets/glass_container.dart';
import '../drawer/app_navigation_drawer.dart';
import '../screens/hotspot_limits/device_limit_modal.dart';
import '../widgets/bottom_banner_ad.dart';
import '../widgets/peer_card.dart';
import '../widgets/permission_disclosure_dialog.dart';
import '../widgets/radar_scan_view.dart';
import '../widgets/transfer_card.dart';
import '../widgets/transfer_success_dialog.dart';

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
    showModalBottomSheet(
      context: context,
      backgroundColor: CyberColors.surface(context),
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
                CyberIcon(type: CyberIconType.wifiDirect, color: CyberColors.primaryAccent(context), size: 22),
                const SizedBox(width: 10),
                Text(
                  'Send File to ${peer.name}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: CyberColors.text(context)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Select a sample file to send at ultra-fast speeds without internet:',
              style: TextStyle(fontSize: 12, color: CyberColors.subtext(context)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.movie_outlined, color: CyberColors.dangerRed, size: 26),
              title: Text('4K_Nature_Documentary.mp4 (450 MB)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: CyberColors.text(context))),
              subtitle: Text('Supports watching while downloading', style: TextStyle(fontSize: 11, color: CyberColors.subtext(context))),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              tileColor: CyberColors.background(context),
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
              leading: Icon(Icons.android_outlined, color: CyberColors.emeraldAccent(context), size: 26),
              title: Text('AppInstaller_v2.0.apk (85 MB)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: CyberColors.text(context))),
              subtitle: Text('Saved to your Downloads folder', style: TextStyle(fontSize: 11, color: CyberColors.subtext(context))),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              tileColor: CyberColors.background(context),
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
        backgroundColor: CyberColors.surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: CyberColors.border(context)),
        ),
        title: Row(
          children: [
            Icon(Icons.play_circle_fill, color: CyberColors.primaryAccent(context), size: 20),
            const SizedBox(width: 8),
            Text('Stream Preview', style: TextStyle(fontSize: 15, color: CyberColors.text(context))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Playing: ${task.fileName}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: CyberColors.text(context))),
            const SizedBox(height: 12),
            Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CyberColors.primaryAccent(context)),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.live_tv, size: 32, color: CyberColors.primaryAccent(context)),
                    const SizedBox(height: 6),
                    Text('Direct Playback Active (Threshold met)', style: TextStyle(fontSize: 10, color: CyberColors.emeraldAccent(context))),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberColors.primaryAccent(context),
              foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSuccessCelebration(TransferTask task) {
    showDialog(
      context: context,
      builder: (ctx) => TransferSuccessDialog(
        fileName: task.fileName,
        fileSize: '${(task.fileSize / (1024 * 1024)).toStringAsFixed(1)} MB',
        onDismiss: () {},
      ),
    );
  }

  void _openLimitModal(DevicePeer peer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DeviceLimitModal(
        peer: peer,
        onSave: (maxSpeedBytes, maxQuotaBytes) {
          peer.speedLimitBytesPerSec = maxSpeedBytes;
          peer.dataLimitBytes = maxQuotaBytes;
          widget.connectionManager.updateHostLimits(
            maxBytesPerSecond: maxSpeedBytes,
            maxTotalQuotaBytes: maxQuotaBytes,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cm = widget.connectionManager;
    final isTransferring = cm.activeTransfers.any((t) => t.status == TransferStatus.transferring);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: CyberColors.background(context),
      drawer: AppNavigationDrawer(
        connectionManager: cm,
        currentItem: DrawerItem.home,
      ),
      appBar: AppBar(
        backgroundColor: CyberColors.surface(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu_rounded, color: CyberColors.text(context)),
          tooltip: 'Open Menu',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          children: const [
            CyberAvatar(size: 26, showStatusBadge: false),
            SizedBox(width: 10),
            Text('NextToMe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          // Dark / Light Mode Instant Toggle
          IconButton(
            icon: Icon(
              ThemeController.instance.isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              color: CyberColors.primaryAccent(context),
            ),
            tooltip: ThemeController.instance.isDarkMode
                ? 'Switch to Light Mode'
                : 'Switch to Dark Mode',
            onPressed: () {
              ThemeController.instance.toggleTheme();
              setState(() {});
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: CyberColors.primaryAccent(context)),
            tooltip: 'Rescan Nearby',
            onPressed: cm.startScanning,
          ),
        ],
      ),
      body: GlassBackground(
        child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 20),
              children: [
                const SizedBox(height: 8),

                // Mode Selector Tabs (Direct vs Home)
                _buildModeSelector(cm),

                if (cm.statusMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Center(
                      child: Text(
                        cm.statusMessage!,
                        style: const TextStyle(color: CyberColors.electricCyan, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // Flat Radar Scanner with Adaptive Pulses and Cyber Persona
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
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: CyberColors.electricCyan),
                        ),
                        if (cm.hostLimitProfile.isSpeedThrottled)
                          Text(
                            'Throttled: ${cm.hostLimitProfile.formattedSpeedLimit}',
                            style: const TextStyle(color: CyberColors.warningAmber, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ),
                  ...cm.activeTransfers.map((task) => InkWell(
                        onTap: task.status == TransferStatus.completed
                            ? () => _showSuccessCelebration(task)
                            : null,
                        child: TransferCard(
                          task: task,
                          onPause: () => cm.pauseTransfer(task.id),
                          onResume: () => cm.resumeTransfer(task.id),
                          onStreamPlay: () => _showStreamingPreviewDialog(task),
                        ),
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
                        UserFriendlyStrings.sectionNearbyDevices,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: CyberColors.electricCyan),
                      ),
                      Text(
                        '${cm.discoveredPeers.length} found',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: CyberColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                if (cm.discoveredPeers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        UserFriendlyStrings.statusScanning,
                        style: TextStyle(fontSize: 12, color: CyberColors.textSecondary),
                      ),
                    ),
                  )
                else
                  ...cm.discoveredPeers.map((peer) => PeerCard(
                        peer: peer,
                        onConnect: () => _handlePeerTap(peer),
                        onConfigureLimits: () => _openLimitModal(peer),
                      )),
              ],
            ),
          ),

          // Pinned Bottom Banner Ad
          BottomBannerAdWidget(isTransferring: isTransferring),
        ],
      ),
    ),
    );
  }

  Widget _buildModeSelector(HybridConnectionManager cm) {
    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      borderRadius: BorderRadius.circular(12),
      blur: 16,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => cm.switchMode(ConnectionMode.directMode),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: cm.activeMode == ConnectionMode.directMode
                      ? CyberColors.primaryAccent(context)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    UserFriendlyStrings.modeNearby,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: cm.activeMode == ConnectionMode.directMode
                          ? (Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white)
                          : CyberColors.subtext(context),
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
                  color: cm.activeMode == ConnectionMode.homeMode
                      ? CyberColors.cyberViolet
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    UserFriendlyStrings.modeHomeWifi,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: cm.activeMode == ConnectionMode.homeMode
                          ? Colors.white
                          : CyberColors.subtext(context),
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
