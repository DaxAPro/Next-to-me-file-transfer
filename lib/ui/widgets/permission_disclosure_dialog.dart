import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PermissionDisclosureDialog extends StatelessWidget {
  final VoidCallback onAccepted;

  const PermissionDisclosureDialog({super.key, required this.onAccepted});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryNeon.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.security, color: AppTheme.primaryNeon, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Prominent Permission Disclosure',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content
            const Text(
              'NextToMe File Transfer requires access to Nearby Devices (BLE & Wi-Fi Direct) and Location in order to scan, discover, and establish high-speed 5GHz peer-to-peer file transfers with devices in your physical proximity.\n\n'
              '• Your physical location is NEVER recorded, tracked, or sent to any server.\n'
              '• All file transfers are 100% direct and offline.\n'
              '• Storage access is used exclusively to categorize and store files sent or received by you.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onAccepted();
                  },
                  child: const Text('I Understand & Agree'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
