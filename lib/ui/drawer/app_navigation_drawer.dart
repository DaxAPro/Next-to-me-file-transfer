import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/cyber_colors.dart';
import '../../services/connection/hybrid_connection_manager.dart';
import '../common_widgets/cyber_avatar.dart';
import '../common_widgets/custom_cyber_icons.dart';
import '../screens/about/about_screen.dart';
import '../screens/chat/offline_group_chat_screen.dart';
import '../screens/history/download_history_screen.dart';
import '../screens/hotspot_limits/hotspot_limits_screen.dart';
import '../screens/privacy/privacy_policy_screen.dart';
import '../screens/settings/settings_screen.dart';

enum DrawerItem {
  home,
  hotspotLimits,
  downloadHistory,
  offlineChat,
  settings,
  about,
  privacyPolicy,
}

class AppNavigationDrawer extends StatelessWidget {
  final HybridConnectionManager connectionManager;
  final DrawerItem currentItem;

  const AppNavigationDrawer({
    super.key,
    required this.connectionManager,
    this.currentItem = DrawerItem.home,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: CyberColors.oledBlack,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header: Persona Avatar & Device Status
            _buildDrawerHeader(),
            const Divider(color: CyberColors.borderOutline, height: 1),

            // Ordered Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                children: [
                  // 1. Home / File Share
                  _buildNavItem(
                    iconType: CyberIconType.wifiDirect,
                    title: 'Home / File Share',
                    isSelected: currentItem == DrawerItem.home,
                    onTap: () => Navigator.pop(context),
                  ),

                  // 2. Hotspot Limits
                  _buildNavItem(
                    iconType: CyberIconType.speedometer,
                    title: 'Hotspot Limits',
                    subtitle: connectionManager.hostLimitProfile.isSpeedThrottled
                        ? 'Throttled (${connectionManager.hostLimitProfile.formattedSpeedLimit})'
                        : 'Granular Controls',
                    isSelected: currentItem == DrawerItem.hotspotLimits,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HotspotLimitsScreen(connectionManager: connectionManager),
                        ),
                      );
                    },
                  ),

                  // 3. Download History
                  _buildNavItem(
                    iconType: CyberIconType.history,
                    title: 'Download History',
                    subtitle: '${connectionManager.activeTransfers.length} records',
                    isSelected: currentItem == DrawerItem.downloadHistory,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DownloadHistoryScreen(connectionManager: connectionManager),
                        ),
                      );
                    },
                  ),

                  // 4. Offline Chat
                  _buildNavItem(
                    iconType: CyberIconType.chat,
                    title: 'Offline Chat',
                    subtitle: 'Wi-Fi P2P Group',
                    isSelected: currentItem == DrawerItem.offlineChat,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OfflineGroupChatScreen(connectionManager: connectionManager),
                        ),
                      );
                    },
                  ),

                  // 5. Settings
                  _buildNavItem(
                    iconType: CyberIconType.eco,
                    title: 'Settings',
                    subtitle: 'Theme, Eco Mode & PIN',
                    isSelected: currentItem == DrawerItem.settings,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SettingsScreen(connectionManager: connectionManager),
                        ),
                      );
                    },
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: CyberColors.borderOutline, height: 1),
                  ),

                  // 6. About
                  _buildNavItem(
                    iconType: CyberIconType.phone,
                    title: 'About',
                    isSelected: currentItem == DrawerItem.about,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AboutScreen(),
                        ),
                      );
                    },
                  ),

                  // 7. Privacy Policy
                  _buildNavItem(
                    iconType: CyberIconType.shield,
                    title: 'Privacy Policy',
                    isSelected: currentItem == DrawerItem.privacyPolicy,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // 8. Footer: Version 1.0.0
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: CyberColors.borderOutline),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: CyberColors.textSecondary,
                    ),
                  ),
                  Text(
                    AppConstants.appVersion,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: CyberColors.electricCyan,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Distinct Flat 2D Digital Humanoid Persona Node
          const CyberAvatar(size: 46, showStatusBadge: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connectionManager.localDeviceName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: CyberColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: connectionManager.isConnected
                            ? CyberColors.techEmerald
                            : CyberColors.electricCyan,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      connectionManager.isConnected ? 'Connected' : 'Ready to share',
                      style: const TextStyle(
                        fontSize: 11,
                        color: CyberColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required CyberIconType iconType,
    required String title,
    String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final selectedBg = CyberColors.electricCyan.withValues(alpha: 0.12);
    final iconColor = isSelected ? CyberColors.electricCyan : CyberColors.textSecondary;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? selectedBg : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? CyberColors.electricCyan : Colors.transparent,
          width: 1,
        ),
      ),
      child: ListTile(
        dense: true,
        leading: CyberIcon(type: iconType, size: 20, color: iconColor),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? CyberColors.electricCyan : CyberColors.textPrimary,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: CyberColors.textSecondary,
                ),
              )
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
