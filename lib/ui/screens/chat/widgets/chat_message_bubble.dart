import 'package:flutter/material.dart';
import '../../../../core/models/chat_message.dart';
import '../../../../core/theme/cyber_colors.dart';
import '../../../common_widgets/cyber_avatar.dart';

/// Clean, modular chat bubble supporting Dark and Light themes with user avatar.
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.type == ChatMessageType.system) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: CyberColors.surface(context),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: CyberColors.border(context)),
          ),
          child: Text(
            message.content,
            style: TextStyle(
              fontSize: 11,
              color: CyberColors.primaryAccent(context),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = CyberColors.primaryAccent(context);
    final isMe = message.isMe;

    final bubbleBg = isMe
        ? (isDark ? const Color(0xFF003840) : const Color(0xFFE0F7FA))
        : CyberColors.surface(context);

    final borderColor = message.type == ChatMessageType.clipboard
        ? primaryAccent
        : isMe
            ? (isDark ? const Color(0xFF005b66) : const Color(0xFF80DEEA))
            : CyberColors.border(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Peer avatar on left
          if (!isMe) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CyberColors.surface(context),
                border: Border.all(color: CyberColors.border(context), width: 1.2),
              ),
              child: Center(
                child: Text(
                  message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: primaryAccent,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Bubble container
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              constraints: const BoxConstraints(maxWidth: 260),
              decoration: BoxDecoration(
                color: bubbleBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: primaryAccent,
                      ),
                    ),
                  if (message.type == ChatMessageType.clipboard) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy_rounded, size: 12, color: primaryAccent),
                        const SizedBox(width: 4),
                        Text(
                          'Shared Link',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: primaryAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 13,
                      color: CyberColors.text(context),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // "ME" avatar on right using assets/user_icon.png
          if (isMe) ...[
            const SizedBox(width: 8),
            const CyberAvatar(size: 28, showStatusBadge: false),
          ],
        ],
      ),
    );
  }
}
