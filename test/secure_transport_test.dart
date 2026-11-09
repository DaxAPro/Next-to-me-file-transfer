import 'package:flutter_test/flutter_test.dart';
import 'package:next_to_me/services/connection/wifi_direct_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('chat frames use an AES-GCM protected X25519 session', () async {
    final host = WifiDirectService();
    final guest = WifiDirectService();

    await host.startServer(port: 0);
    final port = host.serverPort;
    expect(port, isNotNull);

    final received = host.chatStream.first.timeout(const Duration(seconds: 5));
    try {
      expect(
        await guest.connectToHost(hostIp: '127.0.0.1', port: port!),
        isTrue,
      );
      await guest.sendChatMessage({
        'id': 'secure-test',
        'content': 'offline encrypted message',
      });

      expect(
        await received,
        containsPair('content', 'offline encrypted message'),
      );
    } finally {
      await guest.stopServer();
      await host.stopServer();
      guest.dispose();
      host.dispose();
    }
  });
}
