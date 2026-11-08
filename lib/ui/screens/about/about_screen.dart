import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/cyber_colors.dart';
import '../../common_widgets/branded_app_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String aboutDescription =
      'NextToMe is the ultimate high-speed, offline file-sharing and communication hub. '
      'Built for professionals and everyday users alike, it transfers files at lightning speeds '
      'without using a single byte of internet data. Experience ultra-fast transfers, '
      'custom device speed limits, and secure off-grid group chats.';

  @override
  Widget build(BuildContext context) {
    final textPrimary = CyberColors.text(context);
    final surfaceColor = CyberColors.surface(context);
    final borderColor = CyberColors.border(context);
    final primaryAccent = CyberColors.primaryAccent(context);
    final emeraldAccent = CyberColors.emeraldAccent(context);

    return Scaffold(
      backgroundColor: CyberColors.background(context),
      appBar: AppBar(
        title: Text(
          'About NextToMe',
          style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: surfaceColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // App Logo (assets/logo.png) & Title
          Center(
            child: Column(
              children: [
                const BrandedAppLogo(size: 88),
                const SizedBox(height: 14),
                Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: emeraldAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: emeraldAccent.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'Version: 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: emeraldAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Official Play Store Description
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.stars_rounded, color: primaryAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'About NextToMe',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primaryAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  aboutDescription,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Features Summary Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Core Highlights',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: emeraldAccent,
                  ),
                ),
                const SizedBox(height: 10),
                _buildInfoRow(context, 'Internet Usage', '0 Bytes (100% Offline)'),
                _buildInfoRow(context, 'Transfer Speeds', 'Ultra-Fast Local P2P'),
                _buildInfoRow(context, 'Device Speed Control', 'Custom Per-Device Limit'),
                _buildInfoRow(context, 'Security', 'Private Direct Local Handoff'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String title, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: CyberColors.subtext(context))),
          Text(
            val,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: CyberColors.text(context),
            ),
          ),
        ],
      ),
    );
  }
}
