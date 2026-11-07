import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Pinned Smart Banner Ad widget adhering strictly to Blueprint Section 6:
/// - Pinned strictly to bottom edge of screen
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
        // Pause timer when idle
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
    return Container(
      width: double.infinity,
      height: 52,
      decoration: const BoxDecoration(
        color: Color(0xFF0F1522),
        border: Border(
          top: BorderSide(color: AppTheme.cardBorder, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: const Text(
              'Ad',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _adCampaigns[_adImpressionIndex],
                key: ValueKey<int>(_adImpressionIndex),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const Icon(
            Icons.verified_user_outlined,
            size: 16,
            color: AppTheme.textMuted,
          ),
        ],
      ),
    );
  }
}
