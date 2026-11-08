import 'package:flutter/material.dart';
import '../../core/theme/cyber_colors.dart';
import '../common_widgets/custom_cyber_icons.dart';

class PermissionDisclosureDialog extends StatelessWidget {
  final VoidCallback onAccepted;

  const PermissionDisclosureDialog({super.key, required this.onAccepted});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CyberColors.oledBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: CyberColors.borderOutline),
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
                    color: CyberColors.electricCyan.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const CyberIcon(type: CyberIconType.shield, color: CyberColors.electricCyan, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Prominent Permission Disclosure',
                    style: TextStyle(
                      color: CyberColors.textPrimary,
                      fontSize: 15,
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
                color: CyberColors.textSecondary,
                fontSize: 12,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),

            // Agree & Continue button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onAccepted();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CyberColors.electricCyan,
                  foregroundColor: CyberColors.oledBlack,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Accept & Continue',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
