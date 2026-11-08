import 'package:flutter/material.dart';
import '../../core/theme/cyber_colors.dart';
import '../common_widgets/custom_cyber_icons.dart';

class PermissionDisclosureDialog extends StatelessWidget {
  final VoidCallback onAccepted;

  const PermissionDisclosureDialog({super.key, required this.onAccepted});

  @override
  Widget build(BuildContext context) {
    final surfaceColor = CyberColors.surface(context);
    final borderColor = CyberColors.border(context);
    final textPrimary = CyberColors.text(context);
    final textSecondary = CyberColors.subtext(context);
    final primaryAccent = CyberColors.primaryAccent(context);

    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
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
                    color: primaryAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: CyberIcon(type: CyberIconType.shield, color: primaryAccent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Prominent Permission Disclosure',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content
            Text(
              'NextToMe File Transfer requires access to Nearby Devices (BLE & Wi-Fi Direct) and Location in order to scan, discover, and establish high-speed 5GHz peer-to-peer file transfers with devices in your physical proximity.\n\n'
              '• Your physical location is NEVER recorded, tracked, or sent to any server.\n'
              '• All file transfers are 100% direct and offline.\n'
              '• Storage access is used exclusively to categorize and store files sent or received by you.',
              style: TextStyle(
                color: textSecondary,
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
                  backgroundColor: primaryAccent,
                  foregroundColor: Colors.white,
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
