import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:cryptography/cryptography.dart';

import 'speed_throttler.dart';
import '../../core/models/device_peer.dart';
import '../../core/models/transfer_models.dart';

class LocalHotspotCredentials {
  final String ssid;
  final String password;

  const LocalHotspotCredentials({required this.ssid, required this.password});

  factory LocalHotspotCredentials.fromMap(Map<Object?, Object?> map) {
    final ssid = map['ssid'] as String?;
    final password = map['password'] as String?;
    if (ssid == null || password == null || ssid.isEmpty || password.isEmpty) {
      throw const FormatException(
        'Android did not return hotspot credentials.',
      );
    }
    return LocalHotspotCredentials(ssid: ssid, password: password);
  }
}

class _SecureSession {
  Future<KeyPair>? localKeyPair;
  bool helloSent = false;
  final Completer<SecretKey> keyReady = Completer<SecretKey>();
}

/// Wi-Fi Direct & LAN High-Speed Socket Service
/// Green Code: Optimized stream processing with minimal GC buffer reallocations
class WifiDirectService {
  static const int defaultPort = 52520;
  static const int magicByte = 0x5A;
  static const int maximumFramePayloadBytes = 16 * 1024 * 1024;
  static const int maximumChatPayloadBytes = 9 * 1024 * 1024;
  static const MethodChannel _hotspotChannel = MethodChannel(
    'nexttome/wifi_direct',
  );

  // Frame OpCodes
  static const int opFileMeta = 0x01;
  static const int opFileChunk = 0x02;
  static const int opChunkAck = 0x03;
  static const int opPause = 0x04;
  static const int opResume = 0x05;
  static const int opChatMessage = 0x06;
  static const int opGameAction = 0x07;
  static const int opSecureHello = 0x08;
  static const int opChatAcknowledgement = 0x09;
  static const int opPeerRemoved = 0x0A;
  static const int opPeerIdentity = 0x0B;

  static final X25519 _keyAgreement = X25519();
  static final Hkdf _keyDerivation = Hkdf(
    hmac: Hmac.sha256(),
    outputLength: 32,
  );
  static final AesGcm _aead = AesGcm.with256bits();

  ServerSocket? _serverSocket;
  Socket? _activeSocket;
  bool _isConnected = false;
  bool _isHost = false;
  final Map<Socket, _SecureSession> _secureSessions = {};
  final Map<Socket, Future<void>> _frameQueues = {};
  final Set<Socket> _serverClients = {};
  final Map<Socket, String> _peerIds = {};
  final Map<Socket, String> _peerNames = {};
  final Map<Socket, String> _peerAddresses = {};

  final SpeedThrottler speedThrottler = SpeedThrottler();

  // Stream controllers
  final StreamController<TransferTask> _transferProgressController =
      StreamController<TransferTask>.broadcast();
  final StreamController<Map<String, dynamic>> _chatStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _gameStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _chatDeliveryController =
      StreamController<String>.broadcast();
  final StreamController<List<DevicePeer>> _membersController =
      StreamController<List<DevicePeer>>.broadcast();

  String _localDeviceId = '';
  String _localDeviceName = 'My Device';

  bool get isConnected => _isConnected;
  bool get isHost => _isHost;
  bool get canSendChat => _isHost
      ? _serverClients.isNotEmpty
      : _isConnected && _activeSocket != null;
  int? get serverPort => _serverSocket?.port;
  Stream<TransferTask> get transferProgressStream =>
      _transferProgressController.stream;
  Stream<Map<String, dynamic>> get chatStream => _chatStreamController.stream;
  Stream<Map<String, dynamic>> get gameStream => _gameStreamController.stream;
  Stream<String> get chatDeliveryStream => _chatDeliveryController.stream;
  Stream<List<DevicePeer>> get membersStream => _membersController.stream;
  List<DevicePeer> get connectedPeers => _serverClients
      .map((socket) {
        final address = _peerAddresses[socket];
        return DevicePeer(
          id: _peerIds[socket] ?? 'peer-${address ?? socket.hashCode}',
          name: _peerNames[socket] ?? 'Nearby device',
          ipAddress: address,
          mode: ConnectionMode.directMode,
          isConnected: true,
        );
      })
      .toList(growable: false);

  void setLocalDeviceIdentity({
    required String deviceId,
    required String deviceName,
  }) {
    _localDeviceId = deviceId;
    _localDeviceName = deviceName;
  }

  Future<LocalHotspotCredentials> startLocalOnlyHotspot() async {
    final result = await _hotspotChannel.invokeMapMethod<Object?, Object?>(
      'startLocalOnlyHotspot',
    );
    if (result == null) {
      throw const FormatException(
        'Android did not return hotspot credentials.',
      );
    }
    return LocalHotspotCredentials.fromMap(result);
  }

  Future<LocalHotspotCredentials> regenerateLocalOnlyHotspotPassword() async {
    final result = await _hotspotChannel.invokeMapMethod<Object?, Object?>(
      'regenerateLocalOnlyHotspot',
    );
    if (result == null) {
      throw const FormatException(
        'Android did not return hotspot credentials.',
      );
    }
    return LocalHotspotCredentials.fromMap(result);
  }

  Future<void> stopLocalOnlyHotspot() async {
    await _hotspotChannel.invokeMethod<void>('stopLocalOnlyHotspot');
  }

  /// Start server (Host mode / Hotspot Group Owner)
  Future<void> startServer({int port = defaultPort}) async {
    await stopServer();
    try {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      _isHost = true;
      _serverSocket?.listen(_handleIncomingClient);
    } catch (error) {
      throw StateError('Could not start local transfer server: $error');
    }
  }

  /// Connect to Host (Client mode)
  Future<bool> connectToHost({
    required String hostIp,
    int port = defaultPort,
  }) async {
    try {
      _activeSocket = await Socket.connect(
        hostIp,
        port,
        timeout: const Duration(seconds: 8),
      );
      _isHost = false;
      _isConnected = true;
      _listenToSocket(_activeSocket!);
      await _establishSecureSession(_activeSocket!);
      await _sendPeerIdentity(_activeSocket!);
      return true;
    } catch (error) {
      _activeSocket?.destroy();
      _isHost = false;
      _isConnected = false;
      return false;
    }
  }

  void _handleIncomingClient(Socket client) {
    _serverClients.add(client);
    _peerAddresses[client] = client.remoteAddress.address;
    _isConnected = true;
    _publishConnectedPeers();
    _listenToSocket(client);
    unawaited(
      _establishSecureSession(client)
          .then((_) => _sendPeerIdentity(client))
          .catchError((Object error, StackTrace stackTrace) {
            _handleSocketFailure(client, error, stackTrace);
          }),
    );
  }

  void _listenToSocket(Socket socket) {
    final buffer = BytesBuilder(copy: false);

    socket.listen(
      (data) {
        buffer.add(data);
        _processBufferOptimized(buffer, socket);
      },
      onDone: () {
        _removeSocket(socket);
      },
      onError: (Object error, StackTrace stackTrace) {
        _handleSocketFailure(socket, error, stackTrace);
      },
      cancelOnError: false,
    );
  }

  /// Green Code: Process byte stream without redundant array duplications
  void _processBufferOptimized(BytesBuilder buffer, Socket socket) {
    final bytes = buffer.toBytes();
    var offset = 0;
    final totalLen = bytes.length;

    while (totalLen - offset >= 14) {
      if (bytes[offset] != magicByte) {
        offset++;
        continue;
      }

      final opCode = bytes[offset + 1];
      final byteData = ByteData.sublistView(bytes, offset + 2, offset + 14);
      final payloadLen = byteData.getUint32(0);
      final byteOffset = byteData.getUint64(4);

      if (payloadLen > maximumFramePayloadBytes) {
        _handleSocketFailure(
          socket,
          const FormatException('Received an oversized network message.'),
          StackTrace.current,
        );
        return;
      }

      final totalFrameLen = 14 + payloadLen;
      if (totalLen - offset < totalFrameLen) {
        break; // Frame is still partial, await next socket packet
      }

      final payload = Uint8List.sublistView(
        bytes,
        offset + 14,
        offset + totalFrameLen,
      );
      _queueFrame(socket, opCode, byteOffset, payload);
      offset += totalFrameLen;
    }

    if (offset > 0) {
      buffer.clear();
      if (offset < totalLen) {
        buffer.add(Uint8List.sublistView(bytes, offset, totalLen));
      }
    }
  }

  void _queueFrame(Socket socket, int opCode, int offset, Uint8List payload) {
    final previous = _frameQueues[socket] ?? Future<void>.value();
    _frameQueues[socket] = previous
        .then<void>((_) => _handleFrame(opCode, offset, payload, socket))
        .catchError((Object error, StackTrace stackTrace) {
          _handleSocketFailure(socket, error, stackTrace);
        });
  }

  Future<void> _handleFrame(
    int opCode,
    int offset,
    Uint8List payload,
    Socket socket,
  ) async {
    if (opCode == opSecureHello) {
      await _handleSecureHello(socket, payload);
      return;
    }

    final clearPayload = await _decryptFrame(socket, opCode, offset, payload);
    switch (opCode) {
      case opFileMeta:
        final jsonStr = utf8.decode(clearPayload);
        final meta = jsonDecode(jsonStr) as Map<String, dynamic>;
        await _sendSecureFrame(
          socket,
          opChunkAck,
          offset,
          utf8.encode(
            jsonEncode({'fileId': meta['id'], 'resumedOffset': offset}),
          ),
        );
        break;

      case opFileChunk:
        // Chunk received at offset
        break;

      case opChatMessage:
        final jsonStr = utf8.decode(clearPayload);
        final msg = jsonDecode(jsonStr) as Map<String, dynamic>;
        final senderId = msg['senderId']?.toString();
        final senderName = msg['senderName']?.toString();
        if (senderId != null && senderId.isNotEmpty) {
          _peerIds[socket] = senderId;
        }
        if (senderName != null && senderName.isNotEmpty) {
          _peerNames[socket] = senderName;
        }
        _publishConnectedPeers();
        _chatStreamController.add(msg);
        final messageId = msg['id']?.toString();
        if (_isHost && messageId != null) {
          for (final peerSocket in _serverClients) {
            if (identical(peerSocket, socket)) continue;
            await _sendSecureFrame(
              peerSocket,
              opChatMessage,
              0,
              utf8.encode(jsonStr),
            );
          }
        }
        if (messageId != null) {
          await _sendSecureFrame(
            socket,
            opChatAcknowledgement,
            0,
            utf8.encode(jsonEncode({'id': messageId})),
          );
        }
        break;

      case opChatAcknowledgement:
        final acknowledgement =
            jsonDecode(utf8.decode(clearPayload)) as Map<String, dynamic>;
        final messageId = acknowledgement['id']?.toString();
        if (messageId != null && !_chatDeliveryController.isClosed) {
          _chatDeliveryController.add(messageId);
        }
        break;

      case opPeerIdentity:
        final identity =
            jsonDecode(utf8.decode(clearPayload)) as Map<String, dynamic>;
        final peerId = identity['id']?.toString();
        final peerName = identity['name']?.toString();
        if (peerId != null && peerId.isNotEmpty) _peerIds[socket] = peerId;
        if (peerName != null && peerName.isNotEmpty) {
          _peerNames[socket] = peerName;
        }
        _publishConnectedPeers();
        break;

      case opPeerRemoved:
        _chatStreamController.add({
          'id': 'removed-${DateTime.now().millisecondsSinceEpoch}',
          'senderId': 'system',
          'senderName': 'System',
          'content': 'The host removed this device from the group.',
          'type': 'system',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'status': 'delivered',
        });
        socket.destroy();
        break;

      case opGameAction:
        final jsonStr = utf8.decode(clearPayload);
        final action = jsonDecode(jsonStr) as Map<String, dynamic>;
        _gameStreamController.add(action);
        break;
    }
  }

  Future<void> _establishSecureSession(Socket socket) async {
    final session = _secureSessions.putIfAbsent(socket, _SecureSession.new);
    final localKeyPair = await _localKeyPair(session);
    if (!session.helloSent) {
      session.helloSent = true;
      _sendFrame(socket, opSecureHello, 0, await _publicKeyBytes(localKeyPair));
    }

    await session.keyReady.future.timeout(const Duration(seconds: 10));
  }

  Future<void> _sendPeerIdentity(Socket socket) async {
    await _sendSecureFrame(
      socket,
      opPeerIdentity,
      0,
      utf8.encode(jsonEncode({'id': _localDeviceId, 'name': _localDeviceName})),
    );
  }

  Future<KeyPair> _localKeyPair(_SecureSession session) =>
      session.localKeyPair ??= _keyAgreement.newKeyPair();

  Future<List<int>> _publicKeyBytes(KeyPair keyPair) async {
    final publicKey = await keyPair.extractPublicKey();
    if (publicKey is! SimplePublicKey) {
      throw StateError('X25519 returned an unsupported public key type.');
    }
    return publicKey.bytes;
  }

  Future<void> _handleSecureHello(Socket socket, Uint8List remoteBytes) async {
    if (remoteBytes.length != 32) {
      throw const FormatException('Invalid secure-session public key.');
    }

    final session = _secureSessions.putIfAbsent(socket, _SecureSession.new);
    final localKeyPair = await _localKeyPair(session);
    if (!session.helloSent) {
      session.helloSent = true;
      _sendFrame(socket, opSecureHello, 0, await _publicKeyBytes(localKeyPair));
    }

    final sharedSecret = await _keyAgreement.sharedSecretKey(
      keyPair: localKeyPair,
      remotePublicKey: SimplePublicKey(remoteBytes, type: KeyPairType.x25519),
    );
    final sessionKey = await _keyDerivation.deriveKey(
      secretKey: sharedSecret,
      nonce: const <int>[],
      info: utf8.encode('NextToMe offline transport v1'),
    );
    if (!session.keyReady.isCompleted) {
      session.keyReady.complete(sessionKey);
    }
  }

  Future<void> _sendSecureFrame(
    Socket socket,
    int opCode,
    int offset,
    List<int> payload,
  ) async {
    final sessionKey = await _secureSessionKey(socket);
    final box = await _aead.encrypt(
      payload,
      secretKey: sessionKey,
      aad: _frameAad(opCode, offset),
    );
    _sendFrame(socket, opCode, offset, box.concatenation());
  }

  Future<Uint8List> _decryptFrame(
    Socket socket,
    int opCode,
    int offset,
    Uint8List payload,
  ) async {
    if (payload.length < 28) {
      throw const FormatException('Encrypted frame is incomplete.');
    }
    final sessionKey = await _secureSessionKey(socket);
    final clearPayload = await _aead.decrypt(
      SecretBox.fromConcatenation(payload, nonceLength: 12, macLength: 16),
      secretKey: sessionKey,
      aad: _frameAad(opCode, offset),
    );
    return Uint8List.fromList(clearPayload);
  }

  Future<SecretKey> _secureSessionKey(Socket socket) async {
    await _establishSecureSession(socket);
    return _secureSessions[socket]!.keyReady.future;
  }

  List<int> _frameAad(int opCode, int offset) => utf8.encode('$opCode:$offset');

  void _handleSocketFailure(
    Socket socket,
    Object error,
    StackTrace stackTrace,
  ) {
    _removeSocket(socket);
    socket.destroy();
    if (!_chatStreamController.isClosed) {
      _chatStreamController.addError(error, stackTrace);
    }
  }

  void _removeSocket(Socket socket) {
    _serverClients.remove(socket);
    _secureSessions.remove(socket);
    _frameQueues.remove(socket);
    _peerIds.remove(socket);
    _peerNames.remove(socket);
    _peerAddresses.remove(socket);
    if (identical(_activeSocket, socket)) _activeSocket = null;
    _isConnected = _activeSocket != null || _serverClients.isNotEmpty;
    _publishConnectedPeers();
  }

  void _publishConnectedPeers() {
    if (!_membersController.isClosed) {
      _membersController.add(connectedPeers);
    }
  }

  void _sendFrame(Socket socket, int opCode, int offset, List<int> payload) {
    final header = ByteData(14);
    header.setUint8(0, magicByte);
    header.setUint8(1, opCode);
    header.setUint32(2, payload.length);
    header.setUint64(6, offset);

    socket.add(header.buffer.asUint8List());
    socket.add(payload);
  }

  Future<void> sendChatMessage(Map<String, dynamic> message) async {
    if (!canSendChat) {
      throw StateError('Connect to a nearby device before sending a message.');
    }
    final payload = utf8.encode(jsonEncode(message));
    if (payload.length > maximumChatPayloadBytes) {
      throw const FormatException('The chat message is too large to send.');
    }
    if (_isHost) {
      for (final socket in _serverClients.toList(growable: false)) {
        await _sendSecureFrame(socket, opChatMessage, 0, payload);
      }
    } else {
      await _sendSecureFrame(_activeSocket!, opChatMessage, 0, payload);
    }
  }

  Future<void> removePeer(DevicePeer peer) async {
    if (!_isHost) {
      throw StateError('Only the network host can remove a group member.');
    }
    Socket? socket;
    for (final client in _serverClients) {
      if (_peerIds[client] == peer.id ||
          _peerNames[client] == peer.name ||
          (peer.ipAddress != null &&
              _peerAddresses[client] == peer.ipAddress)) {
        socket = client;
        break;
      }
    }
    if (socket == null) {
      throw StateError('${peer.name} is no longer connected.');
    }
    await _sendSecureFrame(socket, opPeerRemoved, 0, const <int>[]);
    await socket.flush();
    socket.destroy();
  }

  Future<void> sendGameAction(Map<String, dynamic> action) async {
    if (_activeSocket != null && _isConnected) {
      final payload = utf8.encode(jsonEncode(action));
      await _sendSecureFrame(_activeSocket!, opGameAction, 0, payload);
    }
  }

  /// Send file with chunking, throttling, and resumption
  Future<void> sendFile({
    required TransferTask task,
    required Stream<List<int>> fileByteStream,
    int resumeFromByte = 0,
  }) async {
    if (_activeSocket == null || !_isConnected) {
      task.status = TransferStatus.failed;
      task.errorMessage = 'Socket not connected';
      _transferProgressController.add(task);
      return;
    }

    task.status = TransferStatus.transferring;
    task.bytesTransferred = resumeFromByte;
    _transferProgressController.add(task);

    final metaPayload = utf8.encode(
      jsonEncode({
        'id': task.id,
        'fileName': task.fileName,
        'fileSize': task.fileSize,
        'category': task.category.name,
        'resumeFrom': resumeFromByte,
      }),
    );
    var currentOffset = resumeFromByte;
    var speedCounter = 0;
    var lastSpeedTime = DateTime.now().millisecondsSinceEpoch;

    try {
      await _sendSecureFrame(
        _activeSocket!,
        opFileMeta,
        resumeFromByte,
        metaPayload,
      );

      await for (final chunk in fileByteStream) {
        if (task.status == TransferStatus.paused ||
            task.status == TransferStatus.canceled) {
          break;
        }

        await speedThrottler.throttle(chunk.length);

        await _sendSecureFrame(
          _activeSocket!,
          opFileChunk,
          currentOffset,
          chunk,
        );
        currentOffset += chunk.length;
        speedCounter += chunk.length;
        task.bytesTransferred = currentOffset;

        final now = DateTime.now().millisecondsSinceEpoch;
        final elapsed = now - lastSpeedTime;
        // Green Code: Compute UI transfer update every 350ms to minimize UI thread re-rendering
        if (elapsed >= 350) {
          task.speedBytesPerSec = (speedCounter / (elapsed / 1000.0));
          speedCounter = 0;
          lastSpeedTime = now;
          task.checkStreamReady();
          _transferProgressController.add(task);
        }
      }

      if (task.bytesTransferred >= task.fileSize) {
        task.status = TransferStatus.completed;
        task.finishedAt = DateTime.now();
        task.speedBytesPerSec = 0;
      }
      _transferProgressController.add(task);
    } catch (e) {
      task.status = TransferStatus.failed;
      task.errorMessage = e.toString();
      _transferProgressController.add(task);
    }
  }

  Future<void> stopServer() async {
    _isConnected = false;
    _isHost = false;
    final sockets = <Socket>{..._serverClients};
    if (_activeSocket != null) sockets.add(_activeSocket!);
    for (final socket in sockets) {
      await socket.close();
    }
    _activeSocket = null;
    _serverClients.clear();
    await _serverSocket?.close();
    _serverSocket = null;
    _secureSessions.clear();
    _frameQueues.clear();
    _peerIds.clear();
    _peerNames.clear();
    _peerAddresses.clear();
    _publishConnectedPeers();
  }

  void dispose() {
    stopServer();
    _transferProgressController.close();
    _chatStreamController.close();
    _gameStreamController.close();
    _chatDeliveryController.close();
    _membersController.close();
  }
}
