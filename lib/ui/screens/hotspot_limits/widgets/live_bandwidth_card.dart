import 'package:flutter/material.dart';
import '../../../../core/theme/cyber_colors.dart';
import '../../../common_widgets/custom_cyber_icons.dart';

/// Real-Time Bandwidth and Quota Feedback Card
class LiveBandwidthCard extends StatelessWidget {
  final String deviceName;
  final double currentSpeedMb;
  final double usedMb;
  final double totalQuotaMb; // 0 = unlimited
  final bool isThrottled;

  const LiveBandwidthCard({
    super.key,
    required this.deviceName,
    required this.currentSpeedMb,
    required this.usedMb,
    this.totalQuotaMb = 1024.0,
    this.isThrottled = false,
  });

  @override
  Widget build(BuildContext context) {
    final double quotaRatio = totalQuotaMb > 0
        ? (usedMb / totalQuotaMb).clamp(0.0, 1.0)
        : 0.15;

    final quotaColor = quotaRatio > 0.9
        ? CyberColors.dangerRed
        : quotaRatio > 0.7
            ? CyberColors.warningAmber
            : CyberColors.techEmerald;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CyberColors.darkSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CyberColors.borderOutline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CyberIcon(
                    type: CyberIconType.speedometer,
                    size: 16,
                    color: CyberColors.electricCyan,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    deviceName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: CyberColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isThrottled
                      ? CyberColors.warningAmber.withValues(alpha: 0.15)
                      : CyberColors.techEmerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isThrottled ? CyberColors.warningAmber : CyberColors.techEmerald,
                    width: 1,
                  ),
                ),
                child: Text(
                  isThrottled ? 'PACED' : 'OPTIMAL',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isThrottled ? CyberColors.warningAmber : CyberColors.techEmerald,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Dynamic Numeric Readout: "Used: 140MB / 1GB | Current Speed: 1.8 MB/s"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                totalQuotaMb > 0
                    ? 'Used: ${usedMb.toStringAsFixed(0)}MB / ${totalQuotaMb >= 1024 ? "${(totalQuotaMb / 1024).toStringAsFixed(1)}GB" : "${totalQuotaMb.toStringAsFixed(0)}MB"}'
                    : 'Used: ${usedMb.toStringAsFixed(0)}MB / Unlimited',
                style: const TextStyle(
                  fontSize: 11,
                  color: CyberColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Speed: ${currentSpeedMb.toStringAsFixed(1)} MB/s',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: CyberColors.electricCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: quotaRatio,
              minHeight: 5,
              backgroundColor: CyberColors.oledBlack,
              valueColor: AlwaysStoppedAnimation<Color>(quotaColor),
            ),
          ),
        ],
      ),
    );
  }
}
