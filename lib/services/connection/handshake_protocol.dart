import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Cryptographic handshake payload exchanged invisibly over BLE
class HandshakePayload {
  final String senderId;
  final String senderName;
  final String wifiSsid;
  final String wifiPassword;
  final String ipAddress;
  final int port;
  final bool is5GHzBand;
  final int channel; // 5GHz channel: e.g. 36, 40, 44, 48, 149
  final bool supportsZeroCopy;
  final String sessionSecret;
  final String signature;
  final int timestamp;

  HandshakePayload({
    required this.senderId,
    required this.senderName,
    required this.wifiSsid,
    required this.wifiPassword,
    required this.ipAddress,
    required this.port,
    this.is5GHzBand = true,
    this.channel = 149,
    this.supportsZeroCopy = true,
    required this.sessionSecret,
    required this.signature,
    required this.timestamp,
  });

  /// Generate a secure 5GHz Wi-Fi Direct invitation packet
  static HandshakePayload createNewDirectInvitation({
    required String senderId,
    required String senderName,
    String? preferredIp,
    int preferredPort = 52520,
  }) {
    final rand = Random.secure();
    final randomSuffix = List.generate(4, (_) => rand.nextInt(36).toRadixString(36)).join().toUpperCase();
    final ssid = 'DIRECT-NM-$randomSuffix';
    final password = _generateSecurePassphrase(rand);
    final sessionKey = _generateSecureToken(rand, 16);
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final dataToSign = '$senderId|$ssid|$password|$timestamp';
    final signature = hmacSha256(dataToSign, sessionKey);

    return HandshakePayload(
      senderId: senderId,
      senderName: senderName,
      wifiSsid: ssid,
      wifiPassword: password,
      ipAddress: preferredIp ?? '192.168.49.1', // Standard Wi-Fi Direct GO IP
      port: preferredPort,
      is5GHzBand: true,
      channel: 149, // 5.745 GHz band for high-speed interference-free throughput
      supportsZeroCopy: true,
      sessionSecret: sessionKey,
      signature: signature,
      timestamp: timestamp,
    );
  }

  /// Verifies payload integrity and freshness (valid within 60s)
  bool verifyIntegrity() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if ((now - timestamp).abs() > 60000) {
      return false; // Replay attack protection
    }
    final dataToSign = '$senderId|$wifiSsid|$wifiPassword|$timestamp';
    final expectedSig = hmacSha256(dataToSign, sessionSecret);
    return expectedSig == signature;
  }

  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'senderName': senderName,
    'wifiSsid': wifiSsid,
    'wifiPassword': wifiPassword,
    'ipAddress': ipAddress,
    'port': port,
    'is5GHzBand': is5GHzBand,
    'channel': channel,
    'supportsZeroCopy': supportsZeroCopy,
    'sessionSecret': sessionSecret,
    'signature': signature,
    'timestamp': timestamp,
  };

  String serialize() => jsonEncode(toMap());

  factory HandshakePayload.fromSerialized(String rawJson) {
    final map = jsonDecode(rawJson) as Map<String, dynamic>;
    return HandshakePayload(
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      wifiSsid: map['wifiSsid'] ?? '',
      wifiPassword: map['wifiPassword'] ?? '',
      ipAddress: map['ipAddress'] ?? '192.168.49.1',
      port: map['port'] ?? 52520,
      is5GHzBand: map['is5GHzBand'] ?? true,
      channel: map['channel'] ?? 149,
      supportsZeroCopy: map['supportsZeroCopy'] ?? true,
      sessionSecret: map['sessionSecret'] ?? '',
      signature: map['signature'] ?? '',
      timestamp: map['timestamp'] ?? 0,
    );
  }

  static String hmacSha256(String data, String key) {
    final hmac = Hmac(sha256, utf8.encode(key));
    return hmac.convert(utf8.encode(data)).toString();
  }

  static String _generateSecurePassphrase(Random rand) {
    const chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(12, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  static String _generateSecureToken(Random rand, int length) {
    return List.generate(length, (_) => rand.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }
}
