import 'package:flutter/material.dart';
import '../../../core/theme/cyber_colors.dart';
import '../../common_widgets/glass_background.dart';
import '../../common_widgets/glass_container.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textPrimary = CyberColors.text(context);
    final textSecondary = CyberColors.subtext(context);
    final surfaceColor = CyberColors.surface(context);
    final primaryAccent = CyberColors.primaryAccent(context);
    final emeraldAccent = CyberColors.emeraldAccent(context);

    return Scaffold(
      backgroundColor: CyberColors.background(context),
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
          style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: surfaceColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: GlassBackground(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          children: [
            // Banner Card: 100% Offline & Private
            GlassContainer(
              padding: const EdgeInsets.all(18),
              borderRadius: BorderRadius.circular(14),
              blur: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: emeraldAccent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.shield_rounded, color: emeraldAccent, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '100% Offline & Private',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: emeraldAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'NextToMe is designed with strict privacy principles. We do NOT collect, store, or transmit your personal data, files, or chat history to any external servers.',
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

            // Permissions Explained Card
            GlassContainer(
              padding: const EdgeInsets.all(18),
              borderRadius: BorderRadius.circular(14),
              blur: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified_user_outlined, color: primaryAccent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Permissions Explained:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primaryAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildPermissionItem(
                    context,
                    title: 'Location',
                    description:
                        'Required by Android strictly to discover nearby Wi-Fi devices. We do not track your physical location.',
                  ),
                  const SizedBox(height: 12),
                  _buildPermissionItem(
                    context,
                    title: 'Wi-Fi & Bluetooth',
                    description:
                        'Used exclusively to establish high-speed, secure local peer-to-peer connections.',
                  ),
                  const SizedBox(height: 12),
                  _buildPermissionItem(
                    context,
                    title: 'Storage',
                    description:
                        'Required to save the files you receive directly to your device\'s local memory.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Local Network Guarantee Card
            GlassContainer(
              padding: const EdgeInsets.all(18),
              borderRadius: BorderRadius.circular(14),
              blur: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.cloud_off_rounded, color: primaryAccent, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your transfers and offline chats are routed only between the connected devices on your local network. No internet connection is used, and no tracking analytics are embedded.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: textSecondary,
                      ),
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

  Widget _buildPermissionItem(
    BuildContext context, {
    required String title,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• $title',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: CyberColors.text(context),
          ),
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            description,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: CyberColors.subtext(context),
            ),
          ),
        ),
      ],
    );
  }
}
