import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/user_friendly_strings.dart';
import '../../../core/theme/cyber_colors.dart';
import '../../common_widgets/branded_app_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberColors.oledBlack,
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: CyberColors.darkSurface,
        elevation: 0,
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
                const Text(
                  UserFriendlyStrings.appName,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CyberColors.textPrimary),
                ),
                const SizedBox(height: 3),
                const Text(
                  UserFriendlyStrings.appTagline,
                  style: TextStyle(fontSize: 12, color: CyberColors.electricCyan, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  AppConstants.appVersion,
                  style: TextStyle(fontSize: 11, color: CyberColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CyberColors.darkSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: CyberColors.borderOutline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Key Benefits', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: CyberColors.electricCyan)),
                const SizedBox(height: 8),
                _buildTechRow('Internet Required', 'None (100% Offline)'),
                _buildTechRow('Connection Speed', 'Up to 50 MB/s'),
                _buildTechRow('Battery Protection', 'Smart Battery Saver Mode'),
                _buildTechRow('PC Connectivity', 'Connects in any PC Browser'),
                _buildTechRow('Save Location', 'Standard Downloads Folder'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CyberColors.darkSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: CyberColors.borderOutline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('App Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: CyberColors.techEmerald)),
                const SizedBox(height: 8),
                _buildTechRow('Developer', 'DaxAPro'),
                _buildTechRow('GitHub', 'github.com/DaxAPro/Next-to-me-file-transfer'),
                _buildTechRow('License', 'Open Source (MIT)'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: CyberColors.textSecondary)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: CyberColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
