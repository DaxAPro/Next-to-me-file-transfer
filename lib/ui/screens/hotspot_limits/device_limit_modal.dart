import 'package:flutter/material.dart';
import '../../../core/models/device_peer.dart';
import '../../theme/app_theme.dart';

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
  late double _speedMb;   // 0 = unlimited, 1, 2, or slider (1-50)
  late double _quotaMb;   // 0 = unlimited, 250, 1024, or custom (100-10240)

  @override
  void initState() {
    super.initState();
    _speedMb = (widget.peer.speedLimitBytesPerSec / (1024 * 1024)).toDouble();
    _quotaMb = (widget.peer.dataLimitBytes / (1024 * 1024)).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Limits for ${widget.peer.name}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Application Stream-Level Socket Pacing',
                    style: TextStyle(fontSize: 11, color: AppTheme.cyan),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Speed Throttling Options
          const Text('Max Speed Throttling', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildChoiceChip('Unlimited', _speedMb == 0, () => setState(() => _speedMb = 0)),
              const SizedBox(width: 6),
              _buildChoiceChip('1 MB/s', _speedMb == 1.0, () => setState(() => _speedMb = 1.0)),
              const SizedBox(width: 6),
              _buildChoiceChip('2 MB/s', _speedMb == 2.0, () => setState(() => _speedMb = 2.0)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Custom:', style: TextStyle(fontSize: 11)),
              Expanded(
                child: Slider(
                  value: _speedMb.clamp(0.0, 50.0),
                  min: 0.0,
                  max: 50.0,
                  divisions: 50,
                  activeColor: AppTheme.cyan,
                  label: _speedMb == 0 ? 'Unlimited' : '${_speedMb.toInt()} MB/s',
                  onChanged: (val) => setState(() => _speedMb = val),
                ),
              ),
              Text(
                _speedMb == 0 ? 'Unlimited' : '${_speedMb.toInt()} MB/s',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cyan),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 2. Data Quota Limit
          const Text('Data Quota Limit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildChoiceChip('Unlimited', _quotaMb == 0, () => setState(() => _quotaMb = 0)),
              const SizedBox(width: 6),
              _buildChoiceChip('250 MB', _quotaMb == 250.0, () => setState(() => _quotaMb = 250.0)),
              const SizedBox(width: 6),
              _buildChoiceChip('1 GB', _quotaMb == 1024.0, () => setState(() => _quotaMb = 1024.0)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Custom:', style: TextStyle(fontSize: 11)),
              Expanded(
                child: Slider(
                  value: _quotaMb.clamp(0.0, 5120.0),
                  min: 0.0,
                  max: 5120.0,
                  divisions: 20,
                  activeColor: AppTheme.green,
                  label: _quotaMb == 0 ? 'Unlimited' : '${(_quotaMb / 1024).toStringAsFixed(1)} GB',
                  onChanged: (val) => setState(() => _quotaMb = val),
                ),
              ),
              Text(
                _quotaMb == 0 ? 'Unlimited' : '${(_quotaMb / 1024).toStringAsFixed(1)} GB',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.green),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final speedBytes = (_speedMb * 1024 * 1024).toInt();
                  final quotaBytes = (_quotaMb * 1024 * 1024).toInt();
                  widget.onSave(speedBytes, quotaBytes);
                  Navigator.pop(context);
                },
                child: const Text('Apply Limits'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.cyan : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? AppTheme.cyan : AppTheme.darkBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : null,
          ),
        ),
      ),
    );
  }
}
