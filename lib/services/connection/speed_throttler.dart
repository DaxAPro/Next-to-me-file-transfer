import 'dart:async';

/// Token-bucket speed throttler and quota tracker for host transfers
class SpeedThrottler {
  int maxBytesPerSecond; // 0 = unlimited
  int maxTotalQuota;     // 0 = unlimited
  int _totalBytesProcessed = 0;
  
  int _tokensInBucket;
  int _lastRefillTimestamp;

  SpeedThrottler({
    this.maxBytesPerSecond = 0,
    this.maxTotalQuota = 0,
  })  : _tokensInBucket = maxBytesPerSecond > 0 ? maxBytesPerSecond : 100 * 1024 * 1024,
        _lastRefillTimestamp = DateTime.now().millisecondsSinceEpoch;

  int get totalBytesProcessed => _totalBytesProcessed;

  void updateLimits({int? maxBytesPerSecond, int? maxTotalQuota}) {
    if (maxBytesPerSecond != null) {
      this.maxBytesPerSecond = maxBytesPerSecond;
      _tokensInBucket = maxBytesPerSecond > 0 ? maxBytesPerSecond : 100 * 1024 * 1024;
    }
    if (maxTotalQuota != null) {
      this.maxTotalQuota = maxTotalQuota;
    }
  }

  /// Check if quota has been exceeded
  bool isQuotaExceeded() {
    if (maxTotalQuota > 0 && _totalBytesProcessed >= maxTotalQuota) {
      return true;
    }
    return false;
  }

  /// Throttles chunk flow to maintain specified byte-rate
  Future<void> throttle(int byteCount) async {
    _totalBytesProcessed += byteCount;

    if (isQuotaExceeded()) {
      throw QuotaExceededException(
        'Host data transfer limit of ${_formatBytes(maxTotalQuota)} exceeded.',
      );
    }

    if (maxBytesPerSecond <= 0) return; // Unlimited speed

    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsedMs = now - _lastRefillTimestamp;

    // Refill tokens based on elapsed time
    if (elapsedMs > 0) {
      final refill = ((elapsedMs / 1000.0) * maxBytesPerSecond).round();
      _tokensInBucket = (_tokensInBucket + refill).clamp(0, maxBytesPerSecond);
      _lastRefillTimestamp = now;
    }

    // If bucket doesn't have enough tokens, sleep until replenished
    if (_tokensInBucket < byteCount) {
      final deficit = byteCount - _tokensInBucket;
      final waitMs = ((deficit / maxBytesPerSecond) * 1000).ceil();
      await Future.delayed(Duration(milliseconds: waitMs.clamp(1, 1000)));
      _tokensInBucket = 0;
      _lastRefillTimestamp = DateTime.now().millisecondsSinceEpoch;
    } else {
      _tokensInBucket -= byteCount;
    }
  }

  static String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class QuotaExceededException implements Exception {
  final String message;
  QuotaExceededException(this.message);

  @override
  String toString() => message;
}
