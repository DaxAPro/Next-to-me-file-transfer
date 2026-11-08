import 'package:flutter/material.dart';
import '../../core/models/transfer_models.dart';
import '../../core/theme/cyber_colors.dart';
import 'wave_transfer_progress.dart';

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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CyberColors.surface(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CyberColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Category icon, File Name, Speed Tag
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getCategoryColor(task.category).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
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
                      style: TextStyle(
                        color: CyberColors.text(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatBytes(task.bytesTransferred)} / ${_formatBytes(task.fileSize)} • ${task.category.name.toUpperCase()}',
                      style: TextStyle(
                        color: CyberColors.subtext(context),
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
                    color: CyberColors.techEmerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: CyberColors.techEmerald.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt, size: 14, color: CyberColors.techEmerald),
                      Text(
                        '$speedMb MB/s',
                        style: const TextStyle(
                          color: CyberColors.techEmerald,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else if (isCompleted)
                const Icon(Icons.check_circle, color: CyberColors.techEmerald, size: 22)
              else if (isPaused)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: CyberColors.warningAmber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'PAUSED',
                    style: TextStyle(
                      color: CyberColors.warningAmber,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Fluid Wave Progress Bar
          WaveTransferProgress(
            progress: task.progress,
            isTransferring: isTransferring,
            isCompleted: isCompleted,
            isPaused: isPaused,
          ),
          const SizedBox(height: 8),

          // Bottom Action Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${task.progressPercentage.toStringAsFixed(1)}% completed${task.estimatedSecondsRemaining > 0 ? " • ~${task.estimatedSecondsRemaining}s left" : ""}',
                style: const TextStyle(
                  color: CyberColors.textSecondary,
                  fontSize: 11,
                ),
              ),

              Row(
                children: [
                  if (task.checkStreamReady() && !isCompleted)
                    TextButton.icon(
                      onPressed: onStreamPlay,
                      icon: const Icon(Icons.play_circle_fill, color: CyberColors.electricCyan, size: 16),
                      label: const Text(
                        'Watch while downloading ▶',
                        style: TextStyle(color: CyberColors.electricCyan, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),

                  if (!isCompleted)
                    IconButton(
                      icon: Icon(
                        isPaused ? Icons.play_arrow : Icons.pause,
                        color: CyberColors.textPrimary,
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
                style: const TextStyle(color: CyberColors.dangerRed, fontSize: 11),
              ),
            ),
        ],
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

  IconData _getCategoryIcon(FileCategory category) {
    switch (category) {
      case FileCategory.videos:
        return Icons.movie_outlined;
      case FileCategory.music:
        return Icons.headphones_outlined;
      case FileCategory.images:
        return Icons.image_outlined;
      case FileCategory.documents:
        return Icons.description_outlined;
      case FileCategory.apks:
        return Icons.android_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _getCategoryColor(FileCategory category) {
    switch (category) {
      case FileCategory.videos:
        return CyberColors.dangerRed;
      case FileCategory.music:
        return CyberColors.electricCyan;
      case FileCategory.images:
        return CyberColors.cyberViolet;
      case FileCategory.documents:
        return CyberColors.warningAmber;
      case FileCategory.apks:
        return CyberColors.techEmerald;
      default:
        return CyberColors.textSecondary;
    }
  }
}
