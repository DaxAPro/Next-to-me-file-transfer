import 'package:flutter/material.dart';
import '../../../core/models/device_peer.dart';
import '../../../core/theme/cyber_colors.dart';
import 'widgets/interactive_speedometer_gauge.dart';

/// Modal for Configuring Per-Device Speed Limit & Quota
class DeviceLimitModal extends StatefulWidget {
  final DevicePeer peer;
  final Function(int maxSpeedBytes, int maxQuotaBytes) onSave;

  const DeviceLimitModal({
    super.key,
    required this.peer,
    required this.onSave,
  });

  @override
  State<DeviceLimitModal> createState() => _DeviceLimitModalState();
}

class _DeviceLimitModalState extends State<DeviceLimitModal> {
  late double _speedMb; // 0 = unlimited, 1-50
  late double _quotaMb; // 0 = unlimited, 250, 1024, etc.

  @override
  void initState() {
    super.initState();
    _speedMb = (widget.peer.speedLimitBytesPerSec / (1024 * 1024)).toDouble();
    _quotaMb = (widget.peer.dataLimitBytes / (1024 * 1024)).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: CyberColors.oledBlack,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: CyberColors.borderOutline),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Drag handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: CyberColors.borderOutline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SPEED & QUOTA LIMITS',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: CyberColors.electricCyan,
                      ),
                    ),
                    Text(
                      widget.peer.name,
                      style: const TextStyle(
                        fontSize: 11,
                        color: CyberColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: CyberColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: CyberColors.borderOutline, height: 24),

            // 1. Dynamic Speedometer Gauge
            InteractiveSpeedometerGauge(
              speedMb: _speedMb,
              onSpeedChanged: (speed) {
                setState(() => _speedMb = speed);
              },
            ),

            const SizedBox(height: 20),
            const Divider(color: CyberColors.borderOutline, height: 1),
            const SizedBox(height: 16),

            // 2. Data Quota Limit
            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                'DATA QUOTA LIMIT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: CyberColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildQuotaChip('Unlimited', 0.0),
                const SizedBox(width: 8),
                _buildQuotaChip('250 MB', 250.0),
                const SizedBox(width: 8),
                _buildQuotaChip('1 GB', 1024.0),
                const SizedBox(width: 8),
                _buildQuotaChip('5 GB', 5120.0),
              ],
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CyberColors.textSecondary,
                      side: const BorderSide(color: CyberColors.borderOutline),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final speedBytes = (_speedMb * 1024 * 1024).toInt();
                      final quotaBytes = (_quotaMb * 1024 * 1024).toInt();
                      widget.onSave(speedBytes, quotaBytes);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CyberColors.electricCyan,
                      foregroundColor: CyberColors.oledBlack,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Apply Limits',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotaChip(String label, double quotaVal) {
    final isSelected = _quotaMb == quotaVal;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _quotaMb = quotaVal),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? CyberColors.techEmerald : CyberColors.darkSurface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? CyberColors.techEmerald : CyberColors.borderOutline,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? CyberColors.oledBlack : CyberColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
