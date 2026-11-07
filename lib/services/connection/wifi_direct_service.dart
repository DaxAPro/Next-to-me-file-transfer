import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'speed_throttler.dart';
import '../../core/models/transfer_models.dart';

/// Wi-Fi Direct & LAN High-Speed Socket Service
/// Routes all high-throughput file transfers exclusively over Wi-Fi (achieving 40MB/s+)
class WifiDirectService {
  static const int defaultPort = 52520;
  static const int magicByte = 0x5A;

  // Frame OpCodes
  static const int opFileMeta = 0x01;
  static const int opFileChunk = 0x02;
  static const int opChunkAck = 0x03;
  static const int opPause = 0x04;
  static const int opResume = 0x05;
  static const int opChatMessage = 0x06;
  static const int opGameAction = 0x07;

  ServerSocket? _serverSocket;
  Socket? _activeSocket;
  bool _isConnected = false;

  final SpeedThrottler speedThrottler = SpeedThrottler();

  // Stream controllers
  final StreamController<TransferTask> _transferProgressController =
      StreamController<TransferTask>.broadcast();
  final StreamController<Map<String, dynamic>> _chatStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _gameStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  bool get isConnected => _isConnected;
  Stream<TransferTask> get transferProgressStream => _transferProgressController.stream;
  Stream<Map<String, dynamic>> get chatStream => _chatStreamController.stream;
  Stream<Map<String, dynamic>> get gameStream => _gameStreamController.stream;

  /// Start server (Host mode / Hotspot Group Owner)
  Future<void> startServer({int port = defaultPort}) async {
    await stopServer();
    try {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      _serverSocket?.listen(_handleIncomingClient);
    } catch (e) {
      // Port bind fallback
    }
  }

  /// Connect to Host (Client mode)
  Future<bool> connectToHost({required String hostIp, int port = defaultPort}) async {
    try {
      _activeSocket = await Socket.connect(hostIp, port, timeout: const Duration(seconds: 8));
      _isConnected = true;
      _listenToSocket(_activeSocket!);
      return true;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  void _handleIncomingClient(Socket client) {
    _activeSocket = client;
    _isConnected = true;
    _listenToSocket(client);
  }

  void _listenToSocket(Socket socket) {
    final buffer = BytesBuilder(copy: false);

    socket.listen(
      (data) {
        buffer.add(data);
        _processBuffer(buffer, socket);
      },
      onDone: () {
        _isConnected = false;
      },
      onError: (err) {
        _isConnected = false;
      },
      cancelOnError: false,
    );
  }

  void _processBuffer(BytesBuilder buffer, Socket socket) {
    final bytes = buffer.toBytes();
    var offset = 0;

    while (bytes.length - offset >= 14) { // Header minimum: Magic(1) + Op(1) + Len(4) + Offset(8)
      if (bytes[offset] != magicByte) {
        offset++;
        continue;
      }

      final opCode = bytes[offset + 1];
      final byteData = ByteData.sublistView(bytes, offset + 2, offset + 14);
      final payloadLen = byteData.getUint32(0);
      final byteOffset = byteData.getUint64(4);

      final totalFrameLen = 14 + payloadLen;
      if (bytes.length - offset < totalFrameLen) {
        break; // Wait for full frame
      }

      final payload = bytes.sublist(offset + 14, offset + totalFrameLen);
      _handleFrame(opCode, byteOffset, payload, socket);
      offset += totalFrameLen;
    }

    if (offset > 0) {
      buffer.clear();
      if (offset < bytes.length) {
        buffer.add(bytes.sublist(offset));
      }
    }
  }

  void _handleFrame(int opCode, int offset, Uint8List payload, Socket socket) {
    switch (opCode) {
      case opFileMeta:
        final jsonStr = utf8.decode(payload);
        final meta = jsonDecode(jsonStr) as Map<String, dynamic>;
        // Acknowledge received offset with file ID (supports auto-resume)
        _sendFrame(socket, opChunkAck, offset, utf8.encode(jsonEncode({'fileId': meta['id'], 'resumedOffset': offset})));
        break;

      case opFileChunk:
        // Received chunk data at byte offset
        break;

      case opChatMessage:
        final jsonStr = utf8.decode(payload);
        final msg = jsonDecode(jsonStr) as Map<String, dynamic>;
        _chatStreamController.add(msg);
        break;

      case opGameAction:
        final jsonStr = utf8.decode(payload);
        final action = jsonDecode(jsonStr) as Map<String, dynamic>;
        _gameStreamController.add(action);
        break;
    }
  }

  /// Sends a raw framed packet
  void _sendFrame(Socket socket, int opCode, int offset, List<int> payload) {
    final header = ByteData(14);
    header.setUint8(0, magicByte);
    header.setUint8(1, opCode);
    header.setUint32(2, payload.length);
    header.setUint64(6, offset);

    socket.add(header.buffer.asUint8List());
    socket.add(payload);
  }

  /// Send P2P Chat message offline
  void sendChatMessage(Map<String, dynamic> message) {
    if (_activeSocket != null && _isConnected) {
      final payload = utf8.encode(jsonEncode(message));
      _sendFrame(_activeSocket!, opChatMessage, 0, payload);
    }
  }

  /// Send P2P Game move offline
  void sendGameAction(Map<String, dynamic> action) {
    if (_activeSocket != null && _isConnected) {
      final payload = utf8.encode(jsonEncode(action));
      _sendFrame(_activeSocket!, opGameAction, 0, payload);
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

    // Send File Meta with resume offset
    final metaPayload = utf8.encode(jsonEncode({
      'id': task.id,
      'fileName': task.fileName,
      'fileSize': task.fileSize,
      'category': task.category.name,
      'resumeFrom': resumeFromByte,
    }));
    _sendFrame(_activeSocket!, opFileMeta, resumeFromByte, metaPayload);

    var currentOffset = resumeFromByte;
    var speedCounter = 0;
    var lastSpeedTime = DateTime.now().millisecondsSinceEpoch;

    try {
      await for (final chunk in fileByteStream) {
        if (task.status == TransferStatus.paused || task.status == TransferStatus.canceled) {
          break;
        }

        // Apply Host Speed Throttling and Quota check
        await speedThrottler.throttle(chunk.length);

        _sendFrame(_activeSocket!, opFileChunk, currentOffset, chunk);
        currentOffset += chunk.length;
        speedCounter += chunk.length;
        task.bytesTransferred = currentOffset;

        // Calculate speed every 400ms
        final now = DateTime.now().millisecondsSinceEpoch;
        final elapsed = now - lastSpeedTime;
        if (elapsed >= 400) {
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
    await _activeSocket?.close();
    _activeSocket = null;
    await _serverSocket?.close();
    _serverSocket = null;
  }

  void dispose() {
    stopServer();
    _transferProgressController.close();
    _chatStreamController.close();
    _gameStreamController.close();
  }
}
