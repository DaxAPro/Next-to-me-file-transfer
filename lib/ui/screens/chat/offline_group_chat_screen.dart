import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/chat_message.dart';
import '../../../services/connection/hybrid_connection_manager.dart';
import '../../theme/app_theme.dart';

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
    // Pre-populate system greeting
    _messages.add(
      ChatMessage(
        id: 'init-1',
        senderId: 'sys',
        senderName: 'System',
        content: 'Offline Wi-Fi Group Chat active. All messages route directly between connected devices without internet.',
        type: ChatMessageType.system,
      ),
    );

    // Listen to real incoming Wi-Fi frames
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

    // Send over socket channel to connected peers
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

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Group Chat'),
        actions: [
          // Clipboard Sync action
          IconButton(
            icon: const Icon(Icons.paste_rounded),
            tooltip: 'Paste & Sync Universal Clipboard',
            onPressed: _syncClipboardToChat,
          ),
          // Enable/disable toggle
          Switch(
            value: _isChatEnabled,
            activeThumbColor: AppTheme.cyan,
            onChanged: (val) {
              setState(() => _isChatEnabled = val);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Connected Peer Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            child: Row(
              children: [
                const Icon(Icons.wifi_tethering, size: 16, color: AppTheme.green),
                const SizedBox(width: 8),
                Text(
                  'Connected to ${widget.connectionManager.discoveredPeers.length} peer(s) via Wi-Fi',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(),

          // Chat Messages List
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
                        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                      ),
                      child: Text(msg.content, style: const TextStyle(fontSize: 11, color: AppTheme.cyan), textAlign: TextAlign.center),
                    ),
                  );
                }
                return _buildMessageBubble(msg, isDark);
              },
            ),
          ),

          // Message Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.content_paste_go, size: 20),
                  tooltip: 'Sync Clipboard',
                  onPressed: _syncClipboardToChat,
                ),
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    enabled: _isChatEnabled,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: _isChatEnabled ? 'Type offline message...' : 'Chat disabled',
                      hintStyle: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppTheme.cyan),
                  onPressed: _isChatEnabled ? () => _sendMessage() : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isDark) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: msg.isMe
              ? (isDark ? const Color(0xFF005662) : const Color(0xFFE0F7FA))
              : (isDark ? AppTheme.darkSurface : AppTheme.lightSurface),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: msg.type == ChatMessageType.clipboard ? AppTheme.cyan : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!msg.isMe)
              Text(
                msg.senderName,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.cyan),
              ),
            if (msg.type == ChatMessageType.clipboard)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.copy_rounded, size: 12, color: AppTheme.cyan),
                  SizedBox(width: 4),
                  Text('Universal Clipboard', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.cyan)),
                ],
              ),
            const SizedBox(height: 2),
            Text(msg.content, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
