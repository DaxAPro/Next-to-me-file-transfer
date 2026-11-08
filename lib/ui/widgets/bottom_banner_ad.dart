import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/cyber_colors.dart';
import '../common_widgets/glass_container.dart';

/// Pinned Smart Banner Ad widget adhering strictly to Blueprint Section 6:
/// - Frosted glass dock pinned strictly to bottom edge of screen
/// - Auto-refreshes every 50 seconds during file transfers
/// - Green Code: Idles and pauses timer when no transfer is active to save battery
class BottomBannerAdWidget extends StatefulWidget {
  final bool isTransferring;

  const BottomBannerAdWidget({
    super.key,
    required this.isTransferring,
  });

  @override
  State<BottomBannerAdWidget> createState() => _BottomBannerAdWidgetState();
}

class _BottomBannerAdWidgetState extends State<BottomBannerAdWidget> {
  Timer? _refreshTimer;
  int _adImpressionIndex = 0;

  final List<String> _adCampaigns = [
    'Secure 5GHz P2P File Transfer • Zero-Copy Speed',
    'Next-Gen Offline Sharing • Up to 80MB/s',
    'No Internet Required • Privacy-First Transfers',
  ];

  @override
  void initState() {
    super.initState();
    _startAutoRefreshTimer();
  }

  @override
  void didUpdateWidget(covariant BottomBannerAdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Green Code: Only touch timer if the transfer active state actually changed
    if (widget.isTransferring != oldWidget.isTransferring) {
      if (widget.isTransferring) {
        _startAutoRefreshTimer();
      } else {
        _refreshTimer?.cancel();
        _refreshTimer = null;
      }
    }
  }

  void _startAutoRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 50), (timer) {
      if (mounted) {
        setState(() {
          _adImpressionIndex = (_adImpressionIndex + 1) % _adCampaigns.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = CyberColors.border(context);
    final textPrimary = CyberColors.text(context);
    final textSecondary = CyberColors.subtext(context);

    return GlassContainer(
      width: double.infinity,
      height: 52,
      borderRadius: BorderRadius.zero,
      blur: 16,
      border: Border(
        top: BorderSide(color: borderColor, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // "AD" Indicator Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              'AD',
              style: TextStyle(
                color: textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Sponsored text
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                _adCampaigns[_adImpressionIndex],
                key: ValueKey<int>(_adImpressionIndex),
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Green Code status indicator
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isTransferring ? CyberColors.techEmerald : CyberColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

