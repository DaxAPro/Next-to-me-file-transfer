import 'package:flutter/material.dart';
import '../../../core/theme/cyber_colors.dart';
import '../../common_widgets/custom_cyber_icons.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textPrimary = CyberColors.text(context);
    final surfaceColor = CyberColors.surface(context);
    final primaryAccent = CyberColors.primaryAccent(context);
    final emeraldAccent = CyberColors.emeraldAccent(context);

    return Scaffold(
      backgroundColor: CyberColors.background(context),
      appBar: AppBar(
        title: Text('Privacy Policy', style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: surfaceColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildPolicyCard(
            context: context,
            icon: Icon(Icons.cloud_off_rounded, size: 20, color: primaryAccent),
            title: '100% Serverless & Offline',
            body: 'NextToMe does not upload files, chats, or personal information to any cloud server. All connections are direct device-to-device via Wi-Fi Direct, Local LAN, or BLE.',
          ),
          const SizedBox(height: 12),
          _buildPolicyCard(
            context: context,
            icon: Icon(Icons.location_off_rounded, size: 20, color: primaryAccent),
            title: 'Location & Nearby Devices Permission',
            body: 'Location access is required by Android OS strictly to detect nearby Wi-Fi Direct beacons and BLE signals. NextToMe NEVER tracks, records, or shares your geographic location.',
          ),
          const SizedBox(height: 12),
          _buildPolicyCard(
            context: context,
            icon: CyberIcon(type: CyberIconType.shield, size: 20, color: emeraldAccent),
            title: 'Storage & Zero-Tampering Policy',
            body: 'Storage permission is used solely to read files you choose to send and to write received files to public download folders. System directories are never touched.',
          ),
          const SizedBox(height: 12),
          _buildPolicyCard(
            context: context,
            icon: Icon(Icons.ad_units_outlined, size: 20, color: primaryAccent),
            title: 'Ad Transparency',
            body: 'Only non-intrusive bottom banner ads are displayed. Full-screen interstitial, pop-up, or blocking video ads are strictly prohibited to ensure an uninterrupted experience.',
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyCard({
    required BuildContext context,
    required Widget icon,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CyberColors.surface(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CyberColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              icon,
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: CyberColors.text(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: CyberColors.subtext(context),
            ),
          ),
        ],
      ),
    );
  }
}
