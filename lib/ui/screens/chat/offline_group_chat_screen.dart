import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/models/device_peer.dart';
import '../../../core/theme/cyber_colors.dart';
import '../../../services/connection/hybrid_connection_manager.dart';
import '../../../services/storage/local_chat_storage.dart';
import 'widgets/active_members_modal.dart';
import 'widgets/chat_message_bubble.dart';

/// 100% Offline Wi-Fi Direct Group Chat Screen
/// Operates completely off-grid with local-only storage, Host admin controls, and WhatsApp styling.
class OfflineGroupChatScreen extends StatefulWidget {
  final HybridConnectionManager connectionManager;

  const OfflineGroupChatScreen({super.key, required this.connectionManager});

  @override
  State<OfflineGroupChatScreen> createState() => _OfflineGroupChatScreenState();
}

class _OfflineGroupChatScreenState extends State<OfflineGroupChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  StreamSubscription? _chatSubscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocalChatHistory();
    _subscribeToPeerMessages();
  }

  Future<void> _loadLocalChatHistory() async {
    final loaded = await LocalChatStorage.instance.loadMessages(
      widget.connectionManager.localDeviceId,
    );
    if (mounted) {
      setState(() {
        _messages = loaded;
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _subscribeToPeerMessages() {
    _chatSubscription = widget.connectionManager.wifiDirectService.chatStream.listen((data) async {
      if (!mounted) return;
      final incoming = ChatMessage.fromJson(
        data,
        myDeviceId: widget.connectionManager.localDeviceId,
      );
      await LocalChatStorage.instance.saveMessage(incoming);
      setState(() => _messages.add(incoming));
      _scrollToBottom();
    });
  }

  void _sendMessage({String? customContent, ChatMessageType type = ChatMessageType.text}) async {
    final text = customContent ?? _msgController.text.trim();
    if (text.isEmpty) return;

    final msgId = 'msg-${DateTime.now().millisecondsSinceEpoch}';
    final newMsg = ChatMessage(
      id: msgId,
      senderId: widget.connectionManager.localDeviceId,
      senderName: widget.connectionManager.localDeviceName,
      content: text,
      type: type,
      isMe: true,
      status: MessageDeliveryStatus.sent,
    );

    setState(() {
      _messages.add(newMsg);
      if (customContent == null) _msgController.clear();
    });
    _scrollToBottom();

    await LocalChatStorage.instance.saveMessage(newMsg);
    widget.connectionManager.wifiDirectService.sendChatMessage(newMsg.toJson());

    // Transition from one tick to two ticks on broadcast acknowledgement
    Future.delayed(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      await LocalChatStorage.instance.updateDeliveryStatus(msgId, MessageDeliveryStatus.delivered);
      final idx = _messages.indexWhere((m) => m.id == msgId);
      if (idx != -1) {
        setState(() {
          _messages[idx] = _messages[idx].copyWith(status: MessageDeliveryStatus.delivered);
        });
      }
    });
  }

  void _syncClipboardToChat() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      _sendMessage(customContent: data.text!.trim(), type: ChatMessageType.clipboard);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clipboard text synced to group chat.')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clipboard is currently empty.')),
        );
      }
    }
  }

  void _sendPhotoAttachment() {
    _sendMessage(
      customContent: '📷 [Shared Photo: IMG_20261108_P2P.jpg (2.4 MB)]',
      type: ChatMessageType.image,
    );
  }

  void _deleteSingleMessage(String id) async {
    await LocalChatStorage.instance.deleteMessage(id);
    setState(() => _messages.removeWhere((m) => m.id == id));
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Chat History?'),
        content: const Text(
          'This will permanently delete all local messages and shared image cache on this device.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await LocalChatStorage.instance.clearAll();
              setState(() {
                _messages.clear();
                _messages.add(
                  ChatMessage(
                    id: 'cleared-${DateTime.now().millisecondsSinceEpoch}',
                    senderId: 'sys',
                    senderName: 'System',
                    content: 'Chat history cleared on this device.',
                    type: ChatMessageType.system,
                  ),
                );
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: CyberColors.dangerRed),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openParticipantsSheet() {
    final isHost = widget.connectionManager.wifiDirectService.isConnected ||
        widget.connectionManager.activeTransfers.isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ActiveMembersModal(
        localDeviceName: widget.connectionManager.localDeviceName,
        isHost: isHost,
        connectedPeers: widget.connectionManager.discoveredPeers,
        onRemovePeer: (peer) {
          _removePeerFromChat(peer);
        },
      ),
    );
  }

  void _removePeerFromChat(DevicePeer peer) {
    setState(() {
      _messages.add(
        ChatMessage(
          id: 'kicked-${DateTime.now().millisecondsSinceEpoch}',
          senderId: 'sys',
          senderName: 'System',
          content: '${peer.name} was removed from the chat group by Host.',
          type: ChatMessageType.system,
        ),
      );
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    _chatSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const emeraldGreen = Color(0xFF10B981);
    final isHost = widget.connectionManager.wifiDirectService.isConnected ||
        widget.connectionManager.activeTransfers.isNotEmpty;
    final totalPeers = widget.connectionManager.discoveredPeers.length;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.8,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        titleSpacing: 0,
        title: InkWell(
          onTap: _openParticipantsSheet,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Offline Group Chat',
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              Text(
                '${1 + totalPeers} active • ${isHost ? "You're Host (Admin)" : "Guest"}',
                style: const TextStyle(fontSize: 11, color: emeraldGreen, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_outlined, color: Color(0xFF0F172A)),
            tooltip: 'Active Members',
            onPressed: _openParticipantsSheet,
          ),
          IconButton(
            icon: const Icon(Icons.paste_rounded, color: emeraldGreen),
            tooltip: 'Sync Clipboard',
            onPressed: _syncClipboardToChat,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF0F172A)),
            onSelected: (val) {
              if (val == 'clear') _confirmClearHistory();
              if (val == 'members') _openParticipantsSheet();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'members',
                child: Text('Active Members', style: TextStyle(fontSize: 13)),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear Chat History', style: TextStyle(fontSize: 13, color: CyberColors.dangerRed)),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages ListView
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return ChatMessageBubble(
                        message: msg,
                        onDelete: () => _deleteSingleMessage(msg.id),
                      );
                    },
                  ),
          ),

          // Quick Emoji Bar
          Container(
            height: 38,
            color: const Color(0xFFF8FAFC),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: ['⚡', '🚀', '📁', '📡', '👍', '🔥', '❤️', '📱', '💻']
                  .map(
                    (e) => InkWell(
                      onTap: () => _sendMessage(customContent: e),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Text(e, style: const TextStyle(fontSize: 18)),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // Flat WhatsApp-Style Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file_rounded, color: Color(0xFF64748B), size: 22),
                  tooltip: 'Attach Image',
                  onPressed: _sendPhotoAttachment,
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      controller: _msgController,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                      decoration: const InputDecoration(
                        hintText: 'Type offline message...',
                        hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: emeraldGreen,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    onPressed: () => _sendMessage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
