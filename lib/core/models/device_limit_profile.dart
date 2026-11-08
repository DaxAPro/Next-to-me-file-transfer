/// Granular Per-Device Speed Throttling & Quota Management
/// Enforced strictly at the Application Stream Level (Socket Pacing)
class DeviceLimitProfile {
  final int maxBytesPerSecond; // 0 = unlimited, otherwise in bytes/sec
  final int maxQuotaBytes;     // 0 = unlimited, otherwise in bytes
  int bytesUsed;

  DeviceLimitProfile({
    this.maxBytesPerSecond = 0,
    this.maxQuotaBytes = 0,
    this.bytesUsed = 0,
  });

  bool get isSpeedThrottled => maxBytesPerSecond > 0;
  bool get hasQuotaLimit => maxQuotaBytes > 0;
  bool get isQuotaExceeded => hasQuotaLimit && bytesUsed >= maxQuotaBytes;

  double get speedMbPerSec => maxBytesPerSecond / (1024 * 1024);
  double get quotaMb => maxQuotaBytes / (1024 * 1024);
  double get quotaGb => maxQuotaBytes / (1024 * 1024 * 1024);

  String get formattedSpeed {
    if (!isSpeedThrottled) return 'Unlimited';
    final mb = speedMbPerSec;
    return mb == mb.roundToDouble()
        ? '${mb.toInt()} MB/s'
        : '${mb.toStringAsFixed(1)} MB/s';
  }

  String get formattedQuota {
    if (!hasQuotaLimit) return 'Unlimited';
    if (quotaGb >= 1.0) {
      final gb = quotaGb;
      return gb == gb.roundToDouble()
          ? '${gb.toInt()} GB'
          : '${gb.toStringAsFixed(1)} GB';
    }
    return '${quotaMb.toInt()} MB';
  }

  String get formattedUsage {
    final mbUsed = (bytesUsed / (1024 * 1024)).toStringAsFixed(1);
    return '$mbUsed MB';
  }

  double get quotaProgress {
    if (!hasQuotaLimit || maxQuotaBytes <= 0) return 0.0;
    return (bytesUsed / maxQuotaBytes).clamp(0.0, 1.0);
  }

  DeviceLimitProfile copyWith({
    int? maxBytesPerSecond,
    int? maxQuotaBytes,
    int? bytesUsed,
  }) {
    return DeviceLimitProfile(
      maxBytesPerSecond: maxBytesPerSecond ?? this.maxBytesPerSecond,
      maxQuotaBytes: maxQuotaBytes ?? this.maxQuotaBytes,
      bytesUsed: bytesUsed ?? this.bytesUsed,
    );
  }
}
