import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_to_me/core/models/chat_message.dart';
import 'package:next_to_me/core/models/device_peer.dart';
import 'package:next_to_me/services/connection/hybrid_connection_manager.dart';
import 'package:next_to_me/services/storage/local_chat_storage.dart';
import 'package:next_to_me/ui/screens/chat/offline_group_chat_screen.dart';
import 'package:next_to_me/ui/screens/chat/widgets/active_members_modal.dart';
import 'package:next_to_me/ui/screens/chat/widgets/chat_message_bubble.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Offline Chat Local Storage & Auto-Cleanup', () {
    test(
      'LocalChatStorage saves, deletes, and clears messages locally',
      () async {
        final storage = LocalChatStorage.instance;
        final initial = await storage.loadMessages('me-1');
        expect(initial.isNotEmpty, isTrue);

        final msg = ChatMessage(
          id: 'msg-test-1',
          senderId: 'me-1',
          senderName: 'Me',
          content: 'Offline testing direct message',
          status: MessageDeliveryStatus.sent,
        );

        await storage.saveMessage(msg);
        var current = await storage.loadMessages('me-1');
        expect(current.any((m) => m.id == 'msg-test-1'), isTrue);

        // Test delete single message ("Delete for me")
        await storage.deleteMessage('msg-test-1');
        current = await storage.loadMessages('me-1');
        expect(current.any((m) => m.id == 'msg-test-1'), isFalse);

        // Test clear all
        await storage.clearAll();
        final cleared = await storage.loadMessages('me-1');
        expect(cleared.length, equals(1)); // Only default system message
      },
    );
  });

  group('WhatsApp-Style Chat Message Bubble & Delivery Checkmarks', () {
    testWidgets('Renders sent message in Emerald Green with checkmarks', (
      tester,
    ) async {
      final sentMsg = ChatMessage(
        id: 'sent-1',
        senderId: 'me-1',
        senderName: 'Me',
        content: 'Hello nearby friend!',
        isMe: true,
        status: MessageDeliveryStatus.delivered,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ChatMessageBubble(message: sentMsg)),
        ),
      );

      expect(find.text('Hello nearby friend!'), findsOneWidget);
      expect(
        find.text('✓✓'),
        findsOneWidget,
      ); // Two green/white ticks for delivered
    });

    testWidgets(
      'Renders received message with humanoid avatar and sender name',
      (tester) async {
        final receivedMsg = ChatMessage(
          id: 'rec-1',
          senderId: 'peer-2',
          senderName: 'Alice Phone',
          content: 'Got the offline video!',
          isMe: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ChatMessageBubble(message: receivedMsg)),
          ),
        );

        expect(find.text('Alice Phone'), findsOneWidget);
        expect(find.text('Got the offline video!'), findsOneWidget);
      },
    );
  });

  group('Group Roles & Active Members Modal', () {
    testWidgets(
      'ActiveMembersModal shows Host badge and Remove button for Admin',
      (tester) async {
        bool removed = false;
        final connectedPeer = DevicePeer(
          id: 'peer-guest',
          name: 'Guest Device',
          ipAddress: '192.168.49.55',
          port: 52520,
          mode: ConnectionMode.directMode,
          deviceType: DeviceType.phone,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ActiveMembersModal(
                localDeviceName: 'Host Admin Device',
                isHost: true,
                connectedPeers: [connectedPeer],
                onRemovePeer: (p) => removed = true,
              ),
            ),
          ),
        );

        expect(find.text('Active Members (2)'), findsOneWidget);
        expect(find.text('Who is in the group?'), findsOneWidget);
        expect(find.text('HOST'), findsOneWidget);
        expect(find.text('Guest Device'), findsOneWidget);
        expect(find.text('Remove'), findsOneWidget);
        expect(removed, isFalse);
      },
    );
  });

  group('OfflineGroupChatScreen Integration', () {
    testWidgets(
      'OfflineGroupChatScreen renders input bar and clipboard sync button',
      (tester) async {
        final cm = HybridConnectionManager();

        await tester.pumpWidget(
          MaterialApp(home: OfflineGroupChatScreen(connectionManager: cm)),
        );
        await tester.pump();
        expect(find.text('Offline Group Chat'), findsOneWidget);
        expect(find.byIcon(Icons.paste_rounded), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);

        cm.dispose();
      },
    );
  });
}
