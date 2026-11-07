enum TransferStatus {
  idle,
  connecting,
  transferring,
  paused,
  completed,
  failed,
  canceled,
}

enum FileCategory {
  videos,
  music,
  documents,
  apks,
  images,
  archives,
  others,
}

/// Represents an active or completed file transfer
class TransferTask {
  final String id;
  final String fileName;
  final int fileSize;
  int bytesTransferred;
  double speedBytesPerSec;
  TransferStatus status;
  final String? localPath;
  final String? remotePeerId;
  final String? remotePeerName;
  final bool isIncoming;
  final FileCategory category;
  final DateTime startedAt;
  DateTime? finishedAt;
  String? errorMessage;

  /// Chunk streaming metadata
  final int chunkSize;
  final int totalChunks;
  int completedChunks;
  bool isStreamReady; // True once >= 5% contiguous data is received

  TransferTask({
    required this.id,
    required this.fileName,
    required this.fileSize,
    this.bytesTransferred = 0,
    this.speedBytesPerSec = 0.0,
    this.status = TransferStatus.idle,
    this.localPath,
    this.remotePeerId,
    this.remotePeerName,
    this.isIncoming = false,
    FileCategory? category,
    DateTime? startedAt,
    this.chunkSize = 64 * 1024, // 64 KB chunks
    this.completedChunks = 0,
    this.isStreamReady = false,
    this.errorMessage,
  })  : category = category ?? categorizeFileName(fileName),
        startedAt = startedAt ?? DateTime.now(),
        totalChunks = (fileSize / (64 * 1024)).ceil().clamp(1, 1000000000);

  double get progress => fileSize == 0 ? 0.0 : (bytesTransferred / fileSize).clamp(0.0, 1.0);

  double get progressPercentage => progress * 100.0;

  /// Smart streaming threshold: first 5% of file enables streaming (HLS/Direct media playback)
  bool checkStreamReady() {
    if (isStreamReady) return true;
    if (category == FileCategory.videos || category == FileCategory.music) {
      if (progress >= 0.05) {
        isStreamReady = true;
        return true;
      }
    }
    return false;
  }

  /// Calculates estimated remaining time in seconds
  int get estimatedSecondsRemaining {
    if (speedBytesPerSec <= 0 || status != TransferStatus.transferring) return 0;
    final remainingBytes = fileSize - bytesTransferred;
    if (remainingBytes <= 0) return 0;
    return (remainingBytes / speedBytesPerSec).round();
  }

  static FileCategory categorizeFileName(String name) {
    final ext = name.split('.').last.toLowerCase();
    if (['mp4', 'mkv', 'avi', 'mov', 'webm', 'flv'].contains(ext)) {
      return FileCategory.videos;
    } else if (['mp3', 'flac', 'wav', 'aac', 'ogg', 'm4a'].contains(ext)) {
      return FileCategory.music;
    } else if (['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'].contains(ext)) {
      return FileCategory.documents;
    } else if (['apk', 'xapk', 'apkm'].contains(ext)) {
      return FileCategory.apks;
    } else if (['jpg', 'jpeg', 'png', 'webp', 'gif', 'svg'].contains(ext)) {
      return FileCategory.images;
    } else if (['zip', 'rar', '7z', 'tar', 'gz'].contains(ext)) {
      return FileCategory.archives;
    }
    return FileCategory.others;
  }

  /// Target subfolder path according to Smart File Organization
  String get targetSubdirectory {
    switch (category) {
      case FileCategory.videos:
        return 'NextToMe/Videos';
      case FileCategory.music:
        return 'NextToMe/Music';
      case FileCategory.documents:
        return 'NextToMe/Documents';
      case FileCategory.apks:
        return 'NextToMe/APKs';
      case FileCategory.images:
        return 'NextToMe/Images';
      case FileCategory.archives:
      case FileCategory.others:
        return 'NextToMe/Downloads';
    }
  }

  Map<String, dynamic> toSnapshot() => {
    'id': id,
    'fileName': fileName,
    'fileSize': fileSize,
    'bytesTransferred': bytesTransferred,
    'completedChunks': completedChunks,
    'isIncoming': isIncoming,
    'localPath': localPath,
    'category': category.name,
    'remotePeerId': remotePeerId,
  };
}

/// Host speed throttling & quota configuration
class SpeedLimitProfile {
  final int maxBytesPerSecond; // e.g. 5 * 1024 * 1024 = 5MB/s
  final int maxTotalQuotaBytes; // e.g. 1024 * 1024 * 1024 = 1GB

  const SpeedLimitProfile({
    this.maxBytesPerSecond = 0, // 0 = unlimited
    this.maxTotalQuotaBytes = 0, // 0 = unlimited
  });

  bool get isSpeedThrottled => maxBytesPerSecond > 0;
  bool get hasQuotaLimit => maxTotalQuotaBytes > 0;

  String get formattedSpeedLimit {
    if (!isSpeedThrottled) return 'Unlimited';
    final mb = maxBytesPerSecond / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB/s';
  }

  String get formattedQuotaLimit {
    if (!hasQuotaLimit) return 'Unlimited';
    final gb = maxTotalQuotaBytes / (1024 * 1024 * 1024);
    if (gb >= 1.0) {
      return '${gb.toStringAsFixed(1)} GB';
    }
    final mb = maxTotalQuotaBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(0)} MB';
  }
}
