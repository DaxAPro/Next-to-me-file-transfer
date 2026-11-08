import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/user_friendly_strings.dart';
import '../../../core/theme/cyber_colors.dart';
import '../../common_widgets/branded_app_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textPrimary = CyberColors.text(context);
    final textSecondary = CyberColors.subtext(context);
    final surfaceColor = CyberColors.surface(context);
    final borderColor = CyberColors.border(context);
    final primaryAccent = CyberColors.primaryAccent(context);
    final emeraldAccent = CyberColors.emeraldAccent(context);

    return Scaffold(
      backgroundColor: CyberColors.background(context),
      appBar: AppBar(
        title: Text('About', style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: surfaceColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                // Branded App Logo (image_16.png)
                const BrandedAppLogo(size: 80),
                const SizedBox(height: 14),
                Text(
                  UserFriendlyStrings.appName,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                const SizedBox(height: 3),
                Text(
                  UserFriendlyStrings.appTagline,
                  style: TextStyle(fontSize: 12, color: primaryAccent, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  AppConstants.appVersion,
                  style: TextStyle(fontSize: 11, color: textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Key Benefits', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryAccent)),
                const SizedBox(height: 8),
                _buildTechRow(context, 'Internet Required', 'None (100% Offline)'),
                _buildTechRow(context, 'Connection Speed', 'Up to 50 MB/s'),
                _buildTechRow(context, 'Battery Protection', 'Smart Battery Saver Mode'),
                _buildTechRow(context, 'PC Connectivity', 'Connects in any PC Browser'),
                _buildTechRow(context, 'Save Location', 'Standard Downloads Folder'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('App Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: emeraldAccent)),
                const SizedBox(height: 8),
                _buildTechRow(context, 'Developer', 'DaxAPro'),
                _buildTechRow(context, 'GitHub', 'github.com/DaxAPro/Next-to-me-file-transfer'),
                _buildTechRow(context, 'License', 'Open Source (MIT)'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: CyberColors.subtext(context))),
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: CyberColors.text(context)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
