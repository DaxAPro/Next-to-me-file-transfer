import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildPolicyCard(
            context,
            icon: Icons.cloud_off_rounded,
            title: '100% Serverless & Offline',
            body: 'NextToMe does not upload files, chats, or personal information to any cloud server. All connections are direct device-to-device via Wi-Fi Direct, Local LAN, or BLE.',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildPolicyCard(
            context,
            icon: Icons.location_off_rounded,
            title: 'Location & Nearby Devices Permission',
            body: 'Location access is required by Android OS strictly to detect nearby Wi-Fi Direct beacons and BLE signals. NextToMe NEVER tracks, records, or shares your geographic location.',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildPolicyCard(
            context,
            icon: Icons.folder_shared_outlined,
            title: 'Storage Access',
            body: 'Storage permission is used solely to read files you choose to send and to write received files to public download folders. System directories are never touched.',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildPolicyCard(
            context,
            icon: Icons.ad_units_outlined,
            title: 'Ad Transparency',
            body: 'Only non-intrusive bottom banner ads are displayed. Full-screen interstitial, pop-up, or blocking video ads are strictly prohibited to ensure an uninterrupted experience.',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.cyan),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
