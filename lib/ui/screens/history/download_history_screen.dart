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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = CyberColors.text(context);
    final textSecondary = CyberColors.subtext(context);
    final surfaceColor = CyberColors.surface(context);
    final borderColor = CyberColors.border(context);

    return Scaffold(
      backgroundColor: CyberColors.background(context),
      appBar: AppBar(
        title: Text(
          'Download History',
          style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: surfaceColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
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
                children: [
                  const CyberIcon(type: CyberIconType.history, size: 48, color: CyberColors.textMuted),
                  const SizedBox(height: 14),
                  Text(
                    'No transfer history yet.',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Files sent or received over Wi-Fi will appear here.',
                    style: TextStyle(fontSize: 12, color: textSecondary),
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
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? CyberColors.oledBlack : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: Icon(
                          task.isIncoming ? Icons.download_rounded : Icons.upload_rounded,
                          color: task.isIncoming ? CyberColors.techEmerald : CyberColors.primaryAccent(context),
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
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_formatBytes(task.fileSize)} • ${task.targetSubdirectory}',
                              style: TextStyle(
                                fontSize: 11,
                                color: textSecondary,
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
    final surfaceColor = CyberColors.surface(context);
    final borderColor = CyberColors.border(context);
    final textPrimary = CyberColors.text(context);
    final textSecondary = CyberColors.subtext(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor),
        ),
        title: Text('Clear History & Cache?', style: TextStyle(color: textPrimary, fontSize: 15)),
        content: Text(
          'This will remove transfer records and delete temporary stream playback chunks from device cache to free up memory.',
          style: TextStyle(color: textSecondary, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: textSecondary)),
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
