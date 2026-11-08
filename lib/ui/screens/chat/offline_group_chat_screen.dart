import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/theme/cyber_colors.dart';
import '../../../services/connection/hybrid_connection_manager.dart';
import '../../common_widgets/custom_cyber_icons.dart';

class OfflineGroupChatScreen extends StatefulWidget {
  final HybridConnectionManager connectionManager;

  const OfflineGroupChatScreen({super.key, required this.connectionManager});

  @override
  State<OfflineGroupChatScreen> createState() => _OfflineGroupChatScreenState();
}

class _OfflineGroupChatScreenState extends State<OfflineGroupChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isChatEnabled = true;

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        id: 'init-1',
        senderId: 'sys',
        senderName: 'System',
        content: 'Offline Wi-Fi Group Chat active. Messages route directly between connected peers without internet.',
        type: ChatMessageType.system,
      ),
    );

    widget.connectionManager.wifiDirectService.chatStream.listen((data) {
      if (!mounted || !_isChatEnabled) return;
      setState(() {
        _messages.add(
          ChatMessage.fromJson(data, myDeviceId: widget.connectionManager.localDeviceId),
        );
      });
    });
  }

  void _sendMessage({String? customContent, ChatMessageType type = ChatMessageType.text}) {
    final text = customContent ?? _msgController.text.trim();
    if (text.isEmpty) return;

    final msg = ChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      senderId: widget.connectionManager.localDeviceId,
      senderName: widget.connectionManager.localDeviceName,
      content: text,
      type: type,
      isMe: true,
    );

    setState(() {
      _messages.add(msg);
      if (customContent == null) _msgController.clear();
    });

    widget.connectionManager.wifiDirectService.sendChatMessage(msg.toJson());
  }

  void _syncClipboardToChat() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
      _sendMessage(customContent: clipboardData.text!, type: ChatMessageType.clipboard);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Universal Clipboard synced to group chat.')),
        );
      }
    }
  }

  void _sendImageAttachment() {
    _sendMessage(
      customContent: '📷 [Shared Photo: IMG_20261108_P2P.jpg (2.4 MB)]',
      type: ChatMessageType.image,
    );
  }

  void _clearConversation() {
    setState(() {
      _messages.clear();
      _messages.add(
        ChatMessage(
          id: 'cleared-${DateTime.now().millisecondsSinceEpoch}',
          senderId: 'sys',
          senderName: 'System',
          content: 'Chat cleared.',
          type: ChatMessageType.system,
        ),
      );
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberColors.oledBlack,
      appBar: AppBar(
        title: const Text('Offline Group Chat'),
        backgroundColor: CyberColors.darkSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.paste_rounded, color: CyberColors.electricCyan),
            tooltip: 'Paste & Sync Universal Clipboard',
            onPressed: _syncClipboardToChat,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: CyberColors.textPrimary),
            color: CyberColors.darkSurface,
            onSelected: (val) {
              if (val == 'clear') {
                _clearConversation();
              } else if (val == 'toggle') {
                setState(() => _isChatEnabled = !_isChatEnabled);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: const [
                    Icon(Icons.delete_sweep_outlined, size: 18, color: CyberColors.dangerRed),
                    SizedBox(width: 8),
                    Text('Clear Chat', style: TextStyle(color: CyberColors.textPrimary, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(
                      _isChatEnabled ? Icons.notifications_off_outlined : Icons.notifications_active_outlined,
                      size: 18,
                      color: CyberColors.electricCyan,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isChatEnabled ? 'Pause Chat' : 'Resume Chat',
                      style: const TextStyle(color: CyberColors.textPrimary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Peer status strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: CyberColors.darkSurface,
            child: Row(
              children: [
                const CyberIcon(type: CyberIconType.wifiDirect, size: 16, color: CyberColors.techEmerald),
                const SizedBox(width: 8),
                Text(
                  'Connected to ${widget.connectionManager.discoveredPeers.length} friend(s) nearby (No Internet)',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: CyberColors.textPrimary),
                ),
              ],
            ),
          ),
          const Divider(color: CyberColors.borderOutline, height: 1),

          // Messages List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                if (msg.type == ChatMessageType.system) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: CyberColors.darkSurface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: CyberColors.borderOutline),
                      ),
                      child: Text(
                        msg.content,
                        style: const TextStyle(fontSize: 11, color: CyberColors.electricCyan),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // Quick Emoji Bar
          Container(
            height: 38,
            color: CyberColors.darkSurface,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['⚡', '🚀', '📁', '📡', '👍', '🔥', '❤️', '📱', '💻']
                  .map(
                    (emoji) => InkWell(
                      onTap: _isChatEnabled ? () => _sendMessage(customContent: emoji) : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Text(emoji, style: const TextStyle(fontSize: 18)),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: CyberColors.darkSurface,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file_rounded, size: 20, color: CyberColors.textSecondary),
                  tooltip: 'Attach Image / File',
                  onPressed: _isChatEnabled ? _sendImageAttachment : null,
                ),
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    enabled: _isChatEnabled,
                    style: const TextStyle(fontSize: 13, color: CyberColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: _isChatEnabled ? 'Type offline message...' : 'Chat disabled',
                      hintStyle: const TextStyle(fontSize: 12, color: CyberColors.textMuted),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: CyberColors.oledBlack,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: CyberColors.borderOutline),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: CyberColors.electricCyan),
                  onPressed: _isChatEnabled ? () => _sendMessage() : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: msg.isMe ? const Color(0xFF003840) : CyberColors.darkSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: msg.type == ChatMessageType.clipboard
                ? CyberColors.electricCyan
                : CyberColors.borderOutline,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!msg.isMe)
              Text(
                msg.senderName,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: CyberColors.electricCyan),
              ),
            if (msg.type == ChatMessageType.clipboard)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.copy_rounded, size: 12, color: CyberColors.electricCyan),
                  SizedBox(width: 4),
                  Text('Universal Clipboard', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: CyberColors.electricCyan)),
                ],
              ),
            const SizedBox(height: 2),
            Text(msg.content, style: const TextStyle(fontSize: 13, color: CyberColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
