import 'package:flutter/material.dart';

import '../../../core/theme/cyber_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String offlinePrivacyStatement =
      'NextToMe is a 100% offline application. We do not use cloud servers. '
      'Location, Bluetooth, and Wi-Fi permissions are used EXCLUSIVELY for '
      'local peer-to-peer device discovery (Wi-Fi Direct/BLE) and file '
      'transfers. No personal data, files, or chat logs are collected, '
      'transmitted, or shared with third parties.';

  @override
  Widget build(BuildContext context) {
    final textColor = CyberColors.text(context);
    final secondaryColor = CyberColors.subtext(context);

    return Scaffold(
      backgroundColor: CyberColors.background(context),
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: CyberColors.surface(context),
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: CyberColors.surface(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CyberColors.border(context)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: CyberColors.techEmerald,
                  size: 23,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    offlinePrivacyStatement,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.55,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _policySection(
            context,
            title: 'Local storage and deletion',
            content:
                'Chat history is stored in a local database on your device. '
                'Chat images are stored in the app’s private local storage. '
                'Use the chat controls to delete an individual message or '
                'clear the chat history and its saved images.',
          ),
          _policySection(
            context,
            title: 'Peer-to-peer sharing',
            content:
                'When you choose to send a message, image, or file, the '
                'selected content is sent directly to connected nearby '
                'devices over the local connection. NextToMe does not route '
                'content through a cloud service or share it with analytics '
                'or advertising providers.',
          ),
          _policySection(
            context,
            title: 'Device permissions',
            content:
                'Bluetooth and Wi-Fi access enable nearby discovery and '
                'local connections. Location permission may be required by '
                'some Android versions for nearby-device discovery; the app '
                'does not read or record your physical location. Camera and '
                'photo access are used only when you choose to take or select '
                'an image for a chat.',
          ),
          _policySection(
            context,
            title: 'Your choices',
            content:
                'You can deny optional permissions, stop sharing, delete '
                'messages, or clear locally stored chat history at any time. '
                'Disabling Wi-Fi or Bluetooth prevents nearby discovery and '
                'transfers until they are enabled again.',
          ),
          _policySection(
            context,
            title: 'Changes to this policy',
            content:
                'If this policy changes, the updated text will be published '
                'with a future version of the app.',
          ),
          const SizedBox(height: 8),
          Text(
            'NextToMe works without an internet connection.',
            style: TextStyle(fontSize: 12, height: 1.5, color: secondaryColor),
          ),
        ],
      ),
    );
  }

  Widget _policySection(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: CyberColors.techEmerald,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              color: CyberColors.text(context),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
