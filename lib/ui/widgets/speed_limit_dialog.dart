import 'package:flutter/material.dart';
import '../../core/models/transfer_models.dart';
import '../theme/app_theme.dart';

class SpeedLimitDialog extends StatefulWidget {
  final SpeedLimitProfile currentProfile;
  final Function(int speedLimitBytes, int quotaLimitBytes) onSave;

  const SpeedLimitDialog({
    super.key,
    required this.currentProfile,
    required this.onSave,
  });

  @override
  State<SpeedLimitDialog> createState() => _SpeedLimitDialogState();
}

class _SpeedLimitDialogState extends State<SpeedLimitDialog> {
  late int _selectedSpeedMb; // in MB/s (0 = unlimited)
  late int _selectedQuotaGb; // in GB (0 = unlimited)

  @override
  void initState() {
    super.initState();
    _selectedSpeedMb = (widget.currentProfile.maxBytesPerSecond / (1024 * 1024)).round();
    _selectedQuotaGb = (widget.currentProfile.maxTotalQuotaBytes / (1024 * 1024 * 1024)).round();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryNeon.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.speed, color: AppTheme.primaryNeon, size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Host Speed & Data Limits',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Control bandwidth throttling and maximum file quota for connected peer devices.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Speed Limit Options
            const Text(
              'Max Speed Throttling',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [0, 2, 5, 10, 20].map((speedMb) {
                final isSelected = _selectedSpeedMb == speedMb;
                return ChoiceChip(
                  label: Text(speedMb == 0 ? 'Unlimited' : '$speedMb MB/s'),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryNeon,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  backgroundColor: AppTheme.surfaceElevated,
                  onSelected: (val) {
                    setState(() => _selectedSpeedMb = speedMb);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Data Quota Options
            const Text(
              'Max Data Quota (Auto-Disconnects)',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [0, 1, 2, 5].map((quotaGb) {
                final isSelected = _selectedQuotaGb == quotaGb;
                return ChoiceChip(
                  label: Text(quotaGb == 0 ? 'Unlimited' : '$quotaGb GB'),
                  selected: isSelected,
                  selectedColor: AppTheme.accentGreen,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  backgroundColor: AppTheme.surfaceElevated,
                  onSelected: (val) {
                    setState(() => _selectedQuotaGb = quotaGb);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final speedBytes = _selectedSpeedMb * 1024 * 1024;
                    final quotaBytes = _selectedQuotaGb * 1024 * 1024 * 1024;
                    widget.onSave(speedBytes, quotaBytes);
                    Navigator.pop(context);
                  },
                  child: const Text('Apply Limits'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
