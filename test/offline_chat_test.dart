import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_to_me/core/models/chat_message.dart';
import 'package:next_to_me/core/models/device_peer.dart';
import 'package:next_to_me/services/connection/hybrid_connection_manager.dart';
import 'package:next_to_me/services/connection/wifi_direct_service.dart';
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

        final imagePath = await storage.saveImageBytes(
          bytes: [1, 2, 3],
          messageId: 'message-image-test',
          fileName: 'photo.jpg',
        );
        await storage.saveMessage(
          ChatMessage(
            id: 'message-image-test',
            senderId: 'me-1',
            senderName: 'Me',
            content: 'photo.jpg',
            type: ChatMessageType.image,
            mediaPath: imagePath,
          ),
        );
        expect(await File(imagePath).exists(), isTrue);
        await storage.deleteMessage('message-image-test');
        expect(await File(imagePath).exists(), isFalse);

        final orphanImagePath = await storage.saveImageBytes(
          bytes: [4, 5, 6],
          messageId: 'orphan-image-test',
          fileName: 'orphan.jpg',
        );

        // Test clear all
        await storage.clearAll();
        expect(await File(orphanImagePath).exists(), isFalse);
        final cleared = await storage.loadMessages('me-1');
        expect(cleared.length, equals(1)); // Only default system message
      },
    );
  });

  group('WhatsApp-Style Chat Message Bubble & Delivery Checkmarks', () {
    test('Image wire data never exposes its device-local file path', () {
      final message = ChatMessage(
        id: 'image-1',
        senderId: 'me-1',
        senderName: 'Me',
        content: 'photo.jpg',
        type: ChatMessageType.image,
        mediaPath: r'C:\private\offline_chat_images\image-1.jpg',
        mediaData: 'encoded-image-data',
      );

      final wireMessage = message.toJson();
      expect(wireMessage.containsKey('mediaPath'), isFalse);
      expect(wireMessage['mediaData'], equals('encoded-image-data'));

      final received = ChatMessage.fromJson(wireMessage, myDeviceId: 'peer-1');
      expect(received.mediaPath, isNull);
      expect(received.mediaData, equals('encoded-image-data'));
    });

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
        expect(find.text('GUEST'), findsOneWidget);
        expect(find.text('Guest Device'), findsOneWidget);
        expect(find.text('Remove'), findsOneWidget);
        expect(removed, isFalse);
      },
    );
  });

  group('Local peer chat transport', () {
    test(
      'Relays chat, confirms delivery, identifies peers and removes a member',
      () async {
        final host = WifiDirectService()
          ..setLocalDeviceIdentity(
            deviceId: 'host-1',
            deviceName: 'Host Device',
          );
        final guest = WifiDirectService()
          ..setLocalDeviceIdentity(
            deviceId: 'guest-1',
            deviceName: 'Guest Device',
          );
        final secondGuest = WifiDirectService()
          ..setLocalDeviceIdentity(
            deviceId: 'guest-2',
            deviceName: 'Second Guest',
          );

        try {
          await host.startServer(port: 0);
          final guestMember = host.membersStream
              .firstWhere(
                (peers) => peers.any((peer) => peer.name == 'Guest Device'),
              )
              .timeout(const Duration(seconds: 10));
          final secondGuestMember = host.membersStream
              .firstWhere(
                (peers) => peers.any((peer) => peer.name == 'Second Guest'),
              )
              .timeout(const Duration(seconds: 10));
          expect(
            await guest.connectToHost(
              hostIp: '127.0.0.1',
              port: host.serverPort!,
            ),
            isTrue,
          );
          expect((await guestMember).single.name, equals('Guest Device'));
          expect(
            await secondGuest.connectToHost(
              hostIp: '127.0.0.1',
              port: host.serverPort!,
            ),
            isTrue,
          );
          expect((await secondGuestMember).length, equals(2));

          final hostReceived = host.chatStream
              .firstWhere((message) => message['id'] == 'guest-message')
              .timeout(const Duration(seconds: 10));
          final relayedToSecondGuest = secondGuest.chatStream
              .firstWhere((message) => message['id'] == 'guest-message')
              .timeout(const Duration(seconds: 10));
          final guestAcknowledged = guest.chatDeliveryStream
              .firstWhere((id) => id == 'guest-message')
              .timeout(const Duration(seconds: 10));
          await guest.sendChatMessage({
            'id': 'guest-message',
            'senderId': 'guest-1',
            'senderName': 'Guest Device',
            'content': 'Hello from the guest',
            'type': 'text',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'status': 'sent',
          });
          expect(
            (await hostReceived)['content'],
            equals('Hello from the guest'),
          );
          expect(
            (await relayedToSecondGuest)['content'],
            equals('Hello from the guest'),
          );
          expect(await guestAcknowledged, equals('guest-message'));

          final guestReceived = guest.chatStream
              .firstWhere((message) => message['id'] == 'host-message')
              .timeout(const Duration(seconds: 10));
          final secondGuestReceived = secondGuest.chatStream
              .firstWhere((message) => message['id'] == 'host-message')
              .timeout(const Duration(seconds: 10));
          final hostAcknowledged = host.chatDeliveryStream
              .firstWhere((id) => id == 'host-message')
              .timeout(const Duration(seconds: 10));
          await host.sendChatMessage({
            'id': 'host-message',
            'senderId': 'host-1',
            'senderName': 'Host Device',
            'content': 'Hello from the host',
            'type': 'text',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'status': 'sent',
          });
          expect(
            (await guestReceived)['content'],
            equals('Hello from the host'),
          );
          expect(
            (await secondGuestReceived)['content'],
            equals('Hello from the host'),
          );
          expect(await hostAcknowledged, equals('host-message'));

          final removalNotice = guest.chatStream
              .firstWhere((message) => message['type'] == 'system')
              .timeout(const Duration(seconds: 10));
          final guestToRemove = host.connectedPeers.firstWhere(
            (peer) => peer.name == 'Guest Device',
          );
          await host.removePeer(guestToRemove);
          expect(
            (await removalNotice)['content'],
            contains('removed this device'),
          );
          expect(host.connectedPeers.single.name, equals('Second Guest'));
        } finally {
          await host.stopServer();
          await guest.stopServer();
          await secondGuest.stopServer();
          host.dispose();
          guest.dispose();
          secondGuest.dispose();
        }
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
