import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/models/chat_message.dart';
import '../../../../core/theme/cyber_colors.dart';
import '../../../common_widgets/cyber_avatar.dart';

/// WhatsApp-style offline chat bubble with Emerald Green (#10B981) sent bubbles,
/// light grey received bubbles, delivery checkmarks, and long-press "Delete for me".
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onDelete;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final receivedColor =
        isDark ? CyberColors.darkSurface : const Color(0xFFF1F5F9);
    final receivedTextColor = CyberColors.text(context);

    // System status banner
    if (message.type == ChatMessageType.system) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: receivedColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CyberColors.border(context)),
          ),
          child: Text(
            message.content,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: receivedTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    const emeraldGreen = Color(0xFF10B981);
    final isMe = message.isMe;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Received message: Digital humanoid avatar on left (assets/user_icon.png)
          if (!isMe) ...[
            const CyberAvatar(size: 28, showStatusBadge: false),
            const SizedBox(width: 8),
          ],

          // Chat Bubble with long-press "Delete for me" menu
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showBubbleContextMenu(context),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 280),
                padding: const EdgeInsets.only(top: 8, left: 12, right: 12, bottom: 6),
                decoration: BoxDecoration(
                  color: isMe ? emeraldGreen : receivedColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(14),
                    topRight: const Radius.circular(14),
                    bottomLeft: Radius.circular(isMe ? 14 : 2),
                    bottomRight: Radius.circular(isMe ? 2 : 14),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sender name on received group messages
                    if (!isMe) ...[
                      Text(
                        message.senderName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: CyberColors.primaryAccent(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],

                    // Image Attachment preview
                    if (message.type == ChatMessageType.image) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 140,
                          width: double.infinity,
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.2)
                              : CyberColors.border(context),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.image_rounded, size: 48, color: CyberColors.subtext(context)),
                              ),
                              Positioned(
                                bottom: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Offline Photo (2.4 MB)',
                                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],

                    // Universal Clipboard badge
                    if (message.type == ChatMessageType.clipboard) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.25)
                              : CyberColors.border(context),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.copy_rounded, size: 10, color: isMe ? Colors.white : receivedTextColor),
                            const SizedBox(width: 4),
                            Text(
                              'Synced Clipboard',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: isMe ? Colors.white : receivedTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Message text content
                    Text(
                      message.content,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isMe ? Colors.white : receivedTextColor,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Timestamp and Delivery Ticks
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          message.formattedTime,
                          style: TextStyle(
                            fontSize: 9.5,
                            color: isMe ? Colors.white.withValues(alpha: 0.8) : CyberColors.subtext(context),
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          _buildDeliveryTicks(message.status),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Delivery checkmarks: One grey tick (sent), Two green ticks (received by peers)
  Widget _buildDeliveryTicks(MessageDeliveryStatus status) {
    if (status == MessageDeliveryStatus.sent) {
      return const Text(
        '✓',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE0E0E0)),
      );
    }
    // Delivered: Two ticks (white on green bubble)
    return const Text(
      '✓✓',
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }

  void _showBubbleContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy_rounded, color: Color(0xFF0F172A)),
                title: const Text('Copy Text', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.content));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Message copied to clipboard.')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: CyberColors.dangerRed),
                title: const Text('Delete for me', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CyberColors.dangerRed)),
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete?.call();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
