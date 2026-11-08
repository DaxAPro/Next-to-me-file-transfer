import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/cyber_colors.dart';
import '../../common_widgets/cyber_avatar.dart';

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
                const CyberAvatar(size: 64, showStatusBadge: false),
                const SizedBox(height: 12),
                const Text(
                  AppConstants.appName,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CyberColors.textPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  AppConstants.appVersion,
                  style: TextStyle(fontSize: 12, color: CyberColors.electricCyan, fontWeight: FontWeight.bold),
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
                const Text('Architecture & Tech Stack', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: CyberColors.electricCyan)),
                const SizedBox(height: 8),
                _buildTechRow('UI Framework', 'Flutter (Android, iOS, PC)'),
                _buildTechRow('High-Speed Channel', '5GHz Wi-Fi Direct (40MB/s+)'),
                _buildTechRow('Auto-Discovery', 'Bluetooth Low Energy (BLE 1-sec)'),
                _buildTechRow('Green Code Engine', 'Zero-Copy Linux sendfile() C++'),
                _buildTechRow('PC Connectivity', 'Embedded Local Web Server (No App Needed)'),
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
                const Text('Developer Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: CyberColors.techEmerald)),
                const SizedBox(height: 8),
                _buildTechRow('Lead Engineer', 'DaxAPro'),
                _buildTechRow('Repository', 'github.com/DaxAPro/Next-to-me-file-transfer'),
                _buildTechRow('License', 'MIT Open Source'),
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
