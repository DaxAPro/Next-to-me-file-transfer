import 'package:flutter/material.dart';
import '../../../../core/models/chat_message.dart';
import '../../../../core/theme/cyber_colors.dart';

/// Clean, modular chat bubble supporting Dark and Light themes.
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

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 280),
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
                    'Universal Clipboard',
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
    );
  }
}
