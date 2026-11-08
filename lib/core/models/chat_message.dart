enum ChatMessageType {
  text,
  image,
  clipboard,
  system,
}

/// Offline P2P Group Chat Message
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final ChatMessageType type;
  final DateTime timestamp;
  final bool isMe;
  final String? mediaPath;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.type = ChatMessageType.text,
    DateTime? timestamp,
    this.isMe = false,
    this.mediaPath,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'senderName': senderName,
    'content': content,
    'type': type.name,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'mediaPath': mediaPath,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json, {required String myDeviceId}) {
    final sender = json['senderId']?.toString() ?? '';
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      senderId: sender,
      senderName: json['senderName']?.toString() ?? 'Nearby Peer',
      content: json['content']?.toString() ?? '',
      type: ChatMessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChatMessageType.text,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      isMe: sender == myDeviceId,
      mediaPath: json['mediaPath']?.toString(),
    );
  }
}
