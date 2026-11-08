import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/theme/cyber_colors.dart';
import '../../../services/connection/hybrid_connection_manager.dart';
import '../../common_widgets/custom_cyber_icons.dart';
import 'widgets/chat_message_bubble.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = CyberColors.primaryAccent(context);
    final textPrimary = CyberColors.text(context);
    final surfaceColor = CyberColors.surface(context);
    final borderColor = CyberColors.border(context);

    return Scaffold(
      backgroundColor: CyberColors.background(context),
      appBar: AppBar(
        title: Text('Offline Group Chat', style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: surfaceColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        actions: [
          IconButton(
            icon: Icon(Icons.paste_rounded, color: primaryAccent),
            tooltip: 'Paste & Sync Universal Clipboard',
            onPressed: _syncClipboardToChat,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: textPrimary),
            color: surfaceColor,
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
                    Text('Clear Chat', style: TextStyle(color: CyberColors.dangerRed, fontSize: 13)),
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
                      color: primaryAccent,
                    ),
                    SizedBox(width: 8),
                    Text(
                      _isChatEnabled ? 'Pause Chat' : 'Resume Chat',
                      style: TextStyle(color: textPrimary, fontSize: 13),
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
            color: surfaceColor,
            child: Row(
              children: [
                const CyberIcon(type: CyberIconType.wifiDirect, size: 16, color: CyberColors.techEmerald),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Connected to ${widget.connectionManager.discoveredPeers.length} friend(s) nearby (No Internet)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: borderColor, height: 1),

          // Messages List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ChatMessageBubble(message: _messages[index]);
              },
            ),
          ),

          // Quick Emoji Bar
          Container(
            height: 38,
            color: surfaceColor,
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
            color: surfaceColor,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.attach_file_rounded, size: 20, color: CyberColors.subtext(context)),
                  tooltip: 'Attach Image / File',
                  onPressed: _isChatEnabled ? _sendImageAttachment : null,
                ),
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    enabled: _isChatEnabled,
                    style: TextStyle(fontSize: 13, color: textPrimary),
                    decoration: InputDecoration(
                      hintText: _isChatEnabled ? 'Type offline message...' : 'Chat disabled',
                      hintStyle: TextStyle(fontSize: 12, color: CyberColors.subtext(context)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: isDark ? CyberColors.oledBlack : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send_rounded, color: primaryAccent),
                  onPressed: _isChatEnabled ? () => _sendMessage() : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
