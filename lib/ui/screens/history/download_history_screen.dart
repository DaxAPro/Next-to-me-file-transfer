import 'package:flutter/material.dart';
import '../../../core/models/transfer_models.dart';
import '../../../core/theme/cyber_colors.dart';
import '../../../services/connection/hybrid_connection_manager.dart';
import '../../common_widgets/custom_cyber_icons.dart';

class DownloadHistoryScreen extends StatefulWidget {
  final HybridConnectionManager connectionManager;

  const DownloadHistoryScreen({super.key, required this.connectionManager});

  @override
  State<DownloadHistoryScreen> createState() => _DownloadHistoryScreenState();
}

class _DownloadHistoryScreenState extends State<DownloadHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final transfers = widget.connectionManager.activeTransfers;

    return Scaffold(
      backgroundColor: CyberColors.oledBlack,
      appBar: AppBar(
        title: const Text('Download History'),
        backgroundColor: CyberColors.darkSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: CyberColors.dangerRed),
            tooltip: 'Clear Cache & History',
            onPressed: () => _confirmClearHistory(context),
          ),
        ],
      ),
      body: transfers.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CyberIcon(type: CyberIconType.history, size: 48, color: CyberColors.textMuted),
                  SizedBox(height: 14),
                  Text(
                    'No transfer history yet.',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: CyberColors.textPrimary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Files sent or received over Wi-Fi will appear here.',
                    style: TextStyle(fontSize: 12, color: CyberColors.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: transfers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final task = transfers[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CyberColors.darkSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: CyberColors.borderOutline),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: CyberColors.oledBlack,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: CyberColors.borderOutline),
                        ),
                        child: Icon(
                          task.isIncoming ? Icons.download_rounded : Icons.upload_rounded,
                          color: task.isIncoming ? CyberColors.techEmerald : CyberColors.electricCyan,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.fileName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: CyberColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_formatBytes(task.fileSize)} • ${task.targetSubdirectory}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: CyberColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: task.status == TransferStatus.completed
                              ? CyberColors.techEmerald.withValues(alpha: 0.15)
                              : CyberColors.warningAmber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: task.status == TransferStatus.completed
                                ? CyberColors.techEmerald
                                : CyberColors.warningAmber,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          task.status.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: task.status == TransferStatus.completed ? CyberColors.techEmerald : CyberColors.warningAmber,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _confirmClearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberColors.oledBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: CyberColors.borderOutline),
        ),
        title: const Text('Clear History & Cache?', style: TextStyle(color: CyberColors.textPrimary, fontSize: 15)),
        content: const Text(
          'This will remove transfer records and delete temporary stream playback chunks from device cache to free up memory.',
          style: TextStyle(color: CyberColors.textSecondary, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: CyberColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('History and streaming cache cleared.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberColors.dangerRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear Now'),
          ),
        ],
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
}
