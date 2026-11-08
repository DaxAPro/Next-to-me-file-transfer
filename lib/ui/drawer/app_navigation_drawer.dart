import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../services/connection/hybrid_connection_manager.dart';
import '../theme/app_theme.dart';
import '../screens/hotspot_limits/hotspot_limits_screen.dart';
import '../screens/history/download_history_screen.dart';
import '../screens/chat/offline_group_chat_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/about/about_screen.dart';
import '../screens/privacy/privacy_policy_screen.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header: Profile & Status
            _buildDrawerHeader(context, isDark),
            const Divider(),

            // Ordered Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                children: [
                  // 1. Home / File Share
                  _buildNavItem(
                    context,
                    icon: Icons.swap_horiz_rounded,
                    title: 'Home / File Share',
                    isSelected: currentItem == DrawerItem.home,
                    onTap: () {
                      Navigator.pop(context); // Close drawer, return to Home
                    },
                  ),

                  // 2. Hotspot Limits
                  _buildNavItem(
                    context,
                    icon: Icons.tune_rounded,
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
                    context,
                    icon: Icons.history_rounded,
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
                    context,
                    icon: Icons.chat_bubble_outline_rounded,
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
                    context,
                    icon: Icons.settings_outlined,
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
                    child: Divider(),
                  ),

                  // 6. About
                  _buildNavItem(
                    context,
                    icon: Icons.info_outline_rounded,
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
                    context,
                    icon: Icons.shield_outlined,
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
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                  Text(
                    AppConstants.appVersion,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.cyan,
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

  Widget _buildDrawerHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              ),
            ),
            child: const Icon(Icons.bolt, color: AppTheme.cyan, size: 26),
          ),
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
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: connectionManager.isConnected ? AppTheme.green : AppTheme.cyan,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      connectionManager.isConnected ? 'Connected' : 'Ready to share',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
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

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBg = isDark ? AppTheme.cyan.withValues(alpha: 0.12) : AppTheme.cyan.withValues(alpha: 0.15);
    final selectedBorder = isDark ? AppTheme.cyan : const Color(0xFF00838F);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? selectedBg : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? selectedBorder : Colors.transparent,
          width: 1,
        ),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          size: 20,
          color: isSelected
              ? (isDark ? AppTheme.cyan : const Color(0xFF00838F))
              : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? (isDark ? AppTheme.cyan : const Color(0xFF00838F))
                : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              )
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
