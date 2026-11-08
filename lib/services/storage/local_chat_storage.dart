import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/chat_message.dart';

/// 100% Offline Local Chat Storage Service
/// Saves chat history strictly on the local device without any cloud servers.
class LocalChatStorage {
  static const String _keyChatHistory = 'offline_chat_history_v1';
  static LocalChatStorage? _instance;

  LocalChatStorage._();
  static LocalChatStorage get instance => _instance ??= LocalChatStorage._();

  /// Loads all local messages from disk storage
  Future<List<ChatMessage>> loadMessages(String myDeviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getStringList(_keyChatHistory);

    if (rawData == null || rawData.isEmpty) {
      return [
        ChatMessage(
          id: 'welcome-system-msg',
          senderId: 'sys',
          senderName: 'System',
          content: 'Offline Wi-Fi Group Chat active. Messages route directly between connected peers without internet.',
          type: ChatMessageType.system,
          status: MessageDeliveryStatus.delivered,
        ),
      ];
    }

    try {
      return rawData
          .map((item) => ChatMessage.fromJson(
                jsonDecode(item) as Map<String, dynamic>,
                myDeviceId: myDeviceId,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Appends a new message to the local storage
  Future<void> saveMessage(ChatMessage message) async {
    final prefs = await SharedPreferences.getInstance();
    final currentList = prefs.getStringList(_keyChatHistory) ?? [];
    currentList.add(jsonEncode(message.toJson()));
    await prefs.setStringList(_keyChatHistory, currentList);
  }

  /// Updates delivery status of an existing message (e.g. from sent to delivered)
  Future<void> updateDeliveryStatus(String messageId, MessageDeliveryStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    final currentList = prefs.getStringList(_keyChatHistory) ?? [];
    bool updated = false;

    final newList = currentList.map((item) {
      final json = jsonDecode(item) as Map<String, dynamic>;
      if (json['id'] == messageId) {
        json['status'] = status.name;
        updated = true;
      }
      return jsonEncode(json);
    }).toList();

    if (updated) {
      await prefs.setStringList(_keyChatHistory, newList);
    }
  }

  /// "Delete for me": Deletes an individual message from local storage
  Future<void> deleteMessage(String messageId) async {
    final prefs = await SharedPreferences.getInstance();
    final currentList = prefs.getStringList(_keyChatHistory) ?? [];

    final updatedList = currentList.where((item) {
      try {
        final json = jsonDecode(item) as Map<String, dynamic>;
        return json['id'] != messageId;
      } catch (_) {
        return true;
      }
    }).toList();

    await prefs.setStringList(_keyChatHistory, updatedList);
  }

  /// "Clear Chat History": Permanently purges all chat records from local memory
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyChatHistory);
  }
}
