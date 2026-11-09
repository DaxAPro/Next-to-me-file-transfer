import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as mobile_sqlite;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

import '../../core/models/chat_message.dart';

/// Stores offline chat history in a local SQLite database.
class LocalChatStorage {
  static const String _legacyKey = 'offline_chat_history_v1';
  static const String _databaseName = 'nexttome_chat.db';
  static LocalChatStorage? _instance;

  Future<Database>? _databaseFuture;

  LocalChatStorage._();
  static LocalChatStorage get instance => _instance ??= LocalChatStorage._();

  Future<List<ChatMessage>> loadMessages(String myDeviceId) async {
    final db = await _database;
    await _migrateLegacyMessages(db);
    final rows = await db.query('messages', orderBy: 'timestamp ASC');

    if (rows.isEmpty) {
      return [
        ChatMessage(
          id: 'welcome-system-msg',
          senderId: 'sys',
          senderName: 'System',
          content:
              'Offline Wi-Fi Group Chat active. Messages route directly between connected peers without internet.',
          type: ChatMessageType.system,
          status: MessageDeliveryStatus.delivered,
        ),
      ];
    }

    return rows
        .map((row) => ChatMessage.fromJson(
              row,
              myDeviceId: myDeviceId,
            ))
        .toList();
  }

  Future<void> saveMessage(ChatMessage message) async {
    final db = await _database;
    await db.insert(
      'messages',
      _toDatabaseRow(message),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateDeliveryStatus(
    String messageId,
    MessageDeliveryStatus status,
  ) async {
    final db = await _database;
    await db.update(
      'messages',
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> deleteMessage(String messageId) async {
    final db = await _database;
    await db.delete('messages', where: 'id = ?', whereArgs: [messageId]);
  }

  Future<void> clearAll() async {
    final db = await _database;
    await db.delete('messages');
  }

  Future<Database> get _database => _databaseFuture ??= _openDatabase();

  Future<Database> _openDatabase() async {
    final factory = _databaseFactory;
    final databasePath = await factory.getDatabasesPath();
    return factory.openDatabase(
      path.join(databasePath, _databaseName),
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE messages (
              id TEXT PRIMARY KEY,
              senderId TEXT NOT NULL,
              senderName TEXT NOT NULL,
              content TEXT NOT NULL,
              type TEXT NOT NULL,
              timestamp INTEGER NOT NULL,
              mediaPath TEXT,
              status TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE metadata (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
        },
      ),
    );
  }

  DatabaseFactory get _databaseFactory {
    if (kIsWeb) {
      throw UnsupportedError('SQLite chat storage is not available on web.');
    }
    if (Platform.isAndroid || Platform.isIOS) {
      return mobile_sqlite.databaseFactory;
    }

    ffi.sqfliteFfiInit();
    return ffi.databaseFactoryFfi;
  }

  Future<void> _migrateLegacyMessages(Database db) async {
    final migrated = await db.query(
      'metadata',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [_legacyKey],
      limit: 1,
    );
    if (migrated.isNotEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final legacyItems = prefs.getStringList(_legacyKey) ?? const <String>[];
    final batch = db.batch();
    for (final item in legacyItems) {
      final message = ChatMessage.fromJson(
        jsonDecode(item) as Map<String, dynamic>,
        myDeviceId: '',
      );
      batch.insert(
        'messages',
        _toDatabaseRow(message),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    batch.insert('metadata', {'key': _legacyKey, 'value': 'done'});
    await batch.commit(noResult: true);
    if (legacyItems.isNotEmpty) {
      await prefs.remove(_legacyKey);
    }
  }

  Map<String, Object?> _toDatabaseRow(ChatMessage message) => {
        'id': message.id,
        'senderId': message.senderId,
        'senderName': message.senderName,
        'content': message.content,
        'type': message.type.name,
        'timestamp': message.timestamp.millisecondsSinceEpoch,
        'mediaPath': message.mediaPath,
        'status': message.status.name,
      };
}
