enum ChatMessageType {
  text,
  image,
  clipboard,
  system,
}

enum MessageDeliveryStatus {
  sent, // One grey tick
  delivered, // Two green ticks
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
  final MessageDeliveryStatus status;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.type = ChatMessageType.text,
    DateTime? timestamp,
    this.isMe = false,
    this.mediaPath,
    this.status = MessageDeliveryStatus.sent,
  }) : timestamp = timestamp ?? DateTime.now();

  String get formattedTime {
    final hour = timestamp.hour == 0
        ? 12
        : (timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour);
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final ampm = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? content,
    ChatMessageType? type,
    DateTime? timestamp,
    bool? isMe,
    String? mediaPath,
    MessageDeliveryStatus? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isMe: isMe ?? this.isMe,
      mediaPath: mediaPath ?? this.mediaPath,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'senderName': senderName,
    'content': content,
    'type': type.name,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'mediaPath': mediaPath,
    'status': status.name,
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
      status: MessageDeliveryStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageDeliveryStatus.delivered,
      ),
    );
  }
}
