import 'package:flutter/material.dart';
import '../../core/models/transfer_models.dart';
import '../theme/app_theme.dart';

class TransferCard extends StatelessWidget {
  final TransferTask task;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStreamPlay;

  const TransferCard({
    super.key,
    required this.task,
    required this.onPause,
    required this.onResume,
    required this.onStreamPlay,
  });

  @override
  Widget build(BuildContext context) {
    final speedMb = (task.speedBytesPerSec / (1024 * 1024)).toStringAsFixed(1);
    final isTransferring = task.status == TransferStatus.transferring;
    final isPaused = task.status == TransferStatus.paused;
    final isCompleted = task.status == TransferStatus.completed;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Category icon, File Name, Speed Tag
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(task.category).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getCategoryIcon(task.category),
                    color: _getCategoryColor(task.category),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.fileName,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatBytes(task.bytesTransferred)} / ${_formatBytes(task.fileSize)} • ${task.category.name.toUpperCase()}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // Live Speed Badge
                if (isTransferring)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.accentGreen.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt, size: 14, color: AppTheme.accentGreen),
                        Text(
                          '$speedMb MB/s',
                          style: const TextStyle(
                            color: AppTheme.accentGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isCompleted)
                  const Icon(Icons.check_circle, color: AppTheme.accentGreen, size: 22)
                else if (isPaused)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.accentAmber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'PAUSED',
                      style: TextStyle(
                        color: AppTheme.accentAmber,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: task.progress,
                minHeight: 6,
                backgroundColor: AppTheme.surfaceElevated,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted
                      ? AppTheme.accentGreen
                      : (isPaused ? AppTheme.accentAmber : AppTheme.primaryNeon),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Bottom Action Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${task.progressPercentage.toStringAsFixed(1)}% completed${task.estimatedSecondsRemaining > 0 ? " • ~${task.estimatedSecondsRemaining}s left" : ""}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),

                Row(
                  children: [
                    // Stream While Downloading Feature
                    if (task.checkStreamReady() && !isCompleted)
                      TextButton.icon(
                        onPressed: onStreamPlay,
                        icon: const Icon(Icons.play_circle_fill, color: AppTheme.primaryNeon, size: 16),
                        label: const Text(
                          'Stream Now (5%)',
                          style: TextStyle(color: AppTheme.primaryNeon, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),

                    // Pause / Resume
                    if (!isCompleted)
                      IconButton(
                        icon: Icon(
                          isPaused ? Icons.play_arrow : Icons.pause,
                          color: AppTheme.textPrimary,
                          size: 20,
                        ),
                        tooltip: isPaused ? 'Auto-Resume from exact byte' : 'Pause Transfer',
                        onPressed: isPaused ? onResume : onPause,
                      ),
                  ],
                ),
              ],
            ),
            if (task.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  task.errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '$bytes B';
  }

  Color _getCategoryColor(FileCategory cat) {
    switch (cat) {
      case FileCategory.videos:
        return Colors.redAccent;
      case FileCategory.music:
        return Colors.purpleAccent;
      case FileCategory.documents:
        return Colors.blueAccent;
      case FileCategory.apks:
        return AppTheme.accentGreen;
      case FileCategory.images:
        return Colors.tealAccent;
      case FileCategory.archives:
      case FileCategory.others:
        return AppTheme.primaryNeon;
    }
  }

  IconData _getCategoryIcon(FileCategory cat) {
    switch (cat) {
      case FileCategory.videos:
        return Icons.videocam;
      case FileCategory.music:
        return Icons.music_note;
      case FileCategory.documents:
        return Icons.description;
      case FileCategory.apks:
        return Icons.android;
      case FileCategory.images:
        return Icons.photo;
      case FileCategory.archives:
        return Icons.folder_zip;
      case FileCategory.others:
        return Icons.insert_drive_file;
    }
  }
}
