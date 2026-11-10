import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/chat_message.dart';
import '../../../core/models/device_peer.dart';
import '../../../core/theme/cyber_colors.dart';
import '../../../services/connection/hybrid_connection_manager.dart';
import '../../../services/storage/local_chat_storage.dart';
import 'widgets/active_members_modal.dart';
import 'widgets/chat_message_bubble.dart';

class OfflineGroupChatScreen extends StatefulWidget {
  final HybridConnectionManager connectionManager;

  const OfflineGroupChatScreen({super.key, required this.connectionManager});

  @override
  State<OfflineGroupChatScreen> createState() => _OfflineGroupChatScreenState();
}

class _OfflineGroupChatScreenState extends State<OfflineGroupChatScreen> {
  static const int _maximumImageBytes = 6 * 1024 * 1024;
  static const Color _emerald = Color(0xFF10B981);

  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final LocalChatStorage _storage = LocalChatStorage.instance;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  List<ChatMessage> _messages = [];
  List<DevicePeer> _connectedPeers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _connectedPeers = widget.connectionManager.wifiDirectService.connectedPeers;
    _loadLocalChatHistory();
    _subscribeToPeerMessages();
    _subscribeToDeliveryUpdates();
    _subscribeToMembers();
  }

  Future<void> _loadLocalChatHistory() async {
    try {
      final loaded = await _storage.loadMessages(
        widget.connectionManager.localDeviceId,
      );
      if (!mounted) return;
      setState(() {
        _messages = loaded;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Could not load local chat history: $error');
    }
  }

  void _subscribeToPeerMessages() {
    _subscriptions.add(
      widget.connectionManager.wifiDirectService.chatStream.listen(
        (data) async {
          try {
            final incomingData = Map<String, dynamic>.from(data);
            final encodedImage = incomingData.remove('mediaData')?.toString();
            if (encodedImage != null) {
              if (encodedImage.length > (_maximumImageBytes * 4 ~/ 3) + 4) {
                throw const FormatException('The shared image is too large.');
              }
              final imageBytes = base64Decode(encodedImage);
              if (imageBytes.length > _maximumImageBytes) {
                throw const FormatException('The shared image is too large.');
              }
              incomingData['mediaPath'] = await _storage.saveImageBytes(
                bytes: imageBytes,
                messageId: incomingData['id'].toString(),
                fileName: incomingData['content']?.toString() ?? 'image.jpg',
              );
            }
            final incoming = ChatMessage.fromJson(
              incomingData,
              myDeviceId: widget.connectionManager.localDeviceId,
            );
            await _storage.saveMessage(incoming);
            if (!mounted) return;
            setState(() => _messages.add(incoming));
            _scrollToBottom();
          } catch (error) {
            if (mounted) {
              _showMessage('Could not save the received message: $error');
            }
          }
        },
        onError: (Object error) {
          if (mounted) _showMessage('Chat connection was interrupted: $error');
        },
      ),
    );
  }

  void _subscribeToDeliveryUpdates() {
    _subscriptions.add(
      widget.connectionManager.wifiDirectService.chatDeliveryStream.listen((
        messageId,
      ) async {
        await _storage.updateDeliveryStatus(
          messageId,
          MessageDeliveryStatus.delivered,
        );
        if (!mounted) return;
        final index = _messages.indexWhere(
          (message) => message.id == messageId,
        );
        if (index == -1) return;
        setState(() {
          _messages[index] = _messages[index].copyWith(
            status: MessageDeliveryStatus.delivered,
          );
        });
      }),
    );
  }

  void _subscribeToMembers() {
    _subscriptions.add(
      widget.connectionManager.wifiDirectService.membersStream.listen((peers) {
        if (mounted) setState(() => _connectedPeers = peers);
      }),
    );
  }

  List<DevicePeer> get _activePeers {
    final peersById = <String, DevicePeer>{
      for (final peer in _connectedPeers) peer.id: peer,
      for (final peer in widget.connectionManager.discoveredPeers)
        if (peer.isConnected) peer.id: peer,
    };
    final activeConnection = widget.connectionManager.connectedPeer;
    if (activeConnection != null && activeConnection.isConnected) {
      peersById[activeConnection.id] = activeConnection;
    }
    return peersById.values.toList(growable: false);
  }

  Future<void> _sendMessage({
    String? customContent,
    ChatMessageType type = ChatMessageType.text,
    String? mediaPath,
    Uint8List? mediaBytes,
    String? messageId,
  }) async {
    final text = customContent ?? _msgController.text.trim();
    if (text.isEmpty && type != ChatMessageType.image) return;
    if (!widget.connectionManager.wifiDirectService.canSendChat) {
      if (mediaPath != null) await _storage.deleteImageFile(mediaPath);
      _showMessage('Connect to a nearby device before sending a message.');
      return;
    }

    final id =
        messageId ??
        'msg-${widget.connectionManager.localDeviceId}-${DateTime.now().microsecondsSinceEpoch}';
    final message = ChatMessage(
      id: id,
      senderId: widget.connectionManager.localDeviceId,
      senderName: widget.connectionManager.localDeviceName,
      content: text,
      type: type,
      isMe: true,
      mediaPath: mediaPath,
      status: MessageDeliveryStatus.sent,
    );
    final outgoingData = message.toJson();
    if (mediaBytes != null) {
      outgoingData['mediaData'] = base64Encode(mediaBytes);
    }

    try {
      await _storage.saveMessage(message);
    } catch (error) {
      if (mediaPath != null) await _storage.deleteImageFile(mediaPath);
      if (mounted) _showMessage('Could not save the message locally: $error');
      return;
    }

    if (mounted) {
      setState(() => _messages.add(message));
      _scrollToBottom();
    }
    try {
      await widget.connectionManager.wifiDirectService.sendChatMessage(
        outgoingData,
      );
      if (mounted && customContent == null) {
        setState(_msgController.clear);
      }
    } catch (error) {
      await _storage.deleteMessage(id);
      if (mounted) {
        setState(() => _messages.removeWhere((item) => item.id == id));
        _showMessage('Message could not be sent: $error');
      }
    }
  }

  Future<void> _syncClipboardToChat() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim();
      if (text == null || text.isEmpty) {
        _showMessage('There is no copied text to share.');
        return;
      }
      await _sendMessage(customContent: text, type: ChatMessageType.clipboard);
    } catch (error) {
      if (mounted) _showMessage('Could not read the clipboard: $error');
    }
  }

  Future<void> _chooseImageSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: _emerald,
              ),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: _emerald),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    String? savedPath;
    String? messageId;
    try {
      final photo = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
      if (photo == null) return;

      final imageBytes = await photo.readAsBytes();
      if (imageBytes.length > _maximumImageBytes) {
        _showMessage('Choose an image smaller than 6 MB.');
        return;
      }
      final id =
          'image-${widget.connectionManager.localDeviceId}-${DateTime.now().microsecondsSinceEpoch}';
      messageId = id;
      savedPath = await _storage.saveImageBytes(
        bytes: imageBytes,
        messageId: id,
        fileName: photo.name,
      );
      await _sendMessage(
        customContent: photo.name,
        type: ChatMessageType.image,
        mediaPath: savedPath,
        mediaBytes: imageBytes,
        messageId: id,
      );
    } catch (error) {
      if (savedPath != null && messageId != null) {
        await _storage.deleteImageFile(savedPath);
      }
      if (mounted) _showMessage('Could not attach the selected image: $error');
    }
  }

  Future<void> _deleteSingleMessage(String id) async {
    try {
      await _storage.deleteMessage(id);
      if (mounted) {
        setState(() => _messages.removeWhere((message) => message.id == id));
      }
    } catch (error) {
      if (mounted) _showMessage('Could not delete the message: $error');
    }
  }

  void _confirmClearHistory() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear chat history?'),
        content: const Text(
          'This permanently deletes messages and shared images stored on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await _storage.clearAll();
                if (!mounted) return;
                setState(() {
                  _messages = [
                    ChatMessage(
                      id: 'cleared-${DateTime.now().millisecondsSinceEpoch}',
                      senderId: 'system',
                      senderName: 'System',
                      content: 'Chat history cleared on this device.',
                      type: ChatMessageType.system,
                    ),
                  ];
                });
              } catch (error) {
                if (mounted) {
                  _showMessage('Could not clear chat history: $error');
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: CyberColors.dangerRed,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _openParticipantsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ActiveMembersModal(
        localDeviceName: widget.connectionManager.localDeviceName,
        isHost: widget.connectionManager.wifiDirectService.isHost,
        connectedPeers: _activePeers,
        onRemovePeer: (peer) => unawaited(_removePeerFromChat(peer)),
      ),
    );
  }

  Future<void> _removePeerFromChat(DevicePeer peer) async {
    try {
      await widget.connectionManager.wifiDirectService.removePeer(peer);
      final notice = ChatMessage(
        id: 'removed-${DateTime.now().microsecondsSinceEpoch}',
        senderId: 'system',
        senderName: 'System',
        content: '${peer.name} was removed from the group.',
        type: ChatMessageType.system,
      );
      await _storage.saveMessage(notice);
      if (!mounted) return;
      setState(() => _messages.add(notice));
      _scrollToBottom();
    } catch (error) {
      if (mounted) _showMessage('Could not remove ${peer.name}: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalMembers = 1 + _activePeers.length;
    final isHost = widget.connectionManager.wifiDirectService.isHost;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0.5,
        titleSpacing: 0,
        title: InkWell(
          onTap: _openParticipantsSheet,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Offline Group Chat',
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
              ),
              Text(
                '$totalMembers active · ${isHost ? 'Host' : 'Guest'}',
                style: const TextStyle(
                  fontSize: 11,
                  color: _emerald,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_outlined),
            tooltip: 'Active members',
            onPressed: _openParticipantsSheet,
          ),
          IconButton(
            icon: const Icon(Icons.content_paste_rounded, color: _emerald),
            tooltip: 'Share copied text',
            onPressed: _syncClipboardToChat,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') _confirmClearHistory();
              if (value == 'members') _openParticipantsSheet();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'members', child: Text('Active members')),
              PopupMenuItem(value: 'clear', child: Text('Clear chat history')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _emerald),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return ChatMessageBubble(
                        message: message,
                        onDelete: () => _deleteSingleMessage(message.id),
                      );
                    },
                  ),
          ),
          Container(
            height: 42,
            color: Colors.white,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: ['Hello', 'On my way', 'Thanks']
                  .map(
                    (suggestion) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ActionChip(
                        avatar: const Icon(
                          Icons.quickreply_outlined,
                          size: 15,
                          color: _emerald,
                        ),
                        label: Text(suggestion),
                        onPressed: () =>
                            _sendMessage(customContent: suggestion),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.attach_file_rounded,
                    color: Color(0xFF64748B),
                  ),
                  tooltip: 'Attach a photo',
                  onPressed: _chooseImageSource,
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      controller: _msgController,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(fontSize: 13),
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
                  backgroundColor: _emerald,
                  child: IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
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
