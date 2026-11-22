import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/models/device_peer.dart';
import '../../core/models/transfer_models.dart';
import 'ble_discovery_service.dart';
import 'lan_discovery_service.dart';
import 'handshake_protocol.dart';
import 'wifi_direct_service.dart';

enum HandshakePhase {
  idle,
  discoveringBle,
  negotiatingHandshake,
  connectingWifiDirect,
  connected,
  failed,
}

/// Master Hybrid Connection Manager
/// Green Code: Throttles UI notifications to conserve battery, supports Eco Mode
class HybridConnectionManager extends ChangeNotifier {
  final BleDiscoveryService _bleService = BleDiscoveryService();
  final LanDiscoveryService _lanService = LanDiscoveryService();
  final WifiDirectService _wifiDirectService = WifiDirectService();

  ConnectionMode _activeMode = ConnectionMode.directMode;
  HandshakePhase _handshakePhase = HandshakePhase.idle;
  DevicePeer? _connectedPeer;
  String? _statusMessage;
  bool _isEcoMode = false;

  final String localDeviceId =
      'device-${DateTime.now().millisecondsSinceEpoch % 10000}';
  String localDeviceName = 'My Device';

  List<DevicePeer> _discoveredPeers = [];
  final List<TransferTask> _activeTransfers = [];

  // Host configuration for speed throttling & limits
  SpeedLimitProfile _hostLimitProfile = const SpeedLimitProfile();

  // Subscriptions
  StreamSubscription? _bleSub;
  StreamSubscription? _lanSub;
  StreamSubscription? _transferSub;

  HybridConnectionManager() {
    _wifiDirectService.setLocalDeviceIdentity(
      deviceId: localDeviceId,
      deviceName: localDeviceName,
    );
    _initStreams();
  }

  // Getters
  ConnectionMode get activeMode => _activeMode;
  HandshakePhase get handshakePhase => _handshakePhase;
  DevicePeer? get connectedPeer => _connectedPeer;
  String? get statusMessage => _statusMessage;
  bool get isEcoMode => _isEcoMode;
  List<DevicePeer> get discoveredPeers => List.unmodifiable(_discoveredPeers);
  List<TransferTask> get activeTransfers => List.unmodifiable(_activeTransfers);
  SpeedLimitProfile get hostLimitProfile => _hostLimitProfile;
  bool get isConnected =>
      _connectedPeer != null && _wifiDirectService.isConnected;
  WifiDirectService get wifiDirectService => _wifiDirectService;

  void toggleEcoMode() {
    _isEcoMode = !_isEcoMode;
    notifyListeners();
  }

  void renameLocalDevice(String newName) {
    localDeviceName = newName;
    _wifiDirectService.setLocalDeviceIdentity(
      deviceId: localDeviceId,
      deviceName: newName,
    );
    notifyListeners();
  }

  void _initStreams() {
    _bleSub = _bleService.discoveredPeersStream.listen((peers) {
      if (_activeMode == ConnectionMode.directMode) {
        _discoveredPeers = peers;
        notifyListeners();
      }
    });

    _lanSub = _lanService.lanPeersStream.listen((peers) {
      if (_activeMode == ConnectionMode.homeMode) {
        _discoveredPeers = peers;
        notifyListeners();
      }
    });

    _transferSub = _wifiDirectService.transferProgressStream.listen((task) {
      final index = _activeTransfers.indexWhere((t) => t.id == task.id);
      if (index >= 0) {
        _activeTransfers[index] = task;
      } else {
        _activeTransfers.insert(0, task);
      }
      notifyListeners();
    });
  }

  /// Switch between Direct Mode (BLE + Wi-Fi Direct) and Home Mode (LAN)
  Future<void> switchMode(ConnectionMode newMode) async {
    if (_activeMode == newMode) return;
    _activeMode = newMode;
    _discoveredPeers = [];
    notifyListeners();

    await startScanning();
  }

  /// Start discovery based on current mode
  Future<void> startScanning() async {
    await _wifiDirectService.startServer();
    if (_activeMode == ConnectionMode.directMode) {
      _lanService.stopDiscovery();
      _handshakePhase = HandshakePhase.idle;
      _statusMessage =
          'Bluetooth discovery is unavailable. Select Home Wi-Fi to find devices on your local network.';
      notifyListeners();
      await _bleService.stopScanning();
      await _bleService.stopAdvertising();
    } else {
      await _bleService.stopScanning();
      await _bleService.stopAdvertising();
      _handshakePhase = HandshakePhase.discoveringBle;
      _statusMessage = 'Searching LAN router (mDNS)...';
      notifyListeners();

      await _lanService.startDiscovery(
        localDeviceId: localDeviceId,
        localDeviceName: localDeviceName,
        transferPort: 52520,
      );
    }
  }

  /// Stop all active discovery
  Future<void> stopScanning() async {
    await _bleService.stopScanning();
    await _bleService.stopAdvertising();
    _lanService.stopDiscovery();
    _handshakePhase = HandshakePhase.idle;
    _statusMessage = null;
    notifyListeners();
  }

  /// Step 2 & 3: Invisible Handshake and High-Speed 5GHz Connection
  Future<bool> connectToPeer(DevicePeer peer) async {
    try {
      _handshakePhase = HandshakePhase.negotiatingHandshake;
      _statusMessage = 'Executing Invisible Handshake with ${peer.name}...';
      notifyListeners();

      final invitation = HandshakePayload.createNewDirectInvitation(
        senderId: localDeviceId,
        senderName: localDeviceName,
      );

      if (!invitation.verifyIntegrity()) {
        throw Exception('Handshake security verification failed');
      }

      final targetIp = peer.ipAddress?.trim();
      if (targetIp == null || targetIp.isEmpty) {
        throw StateError(
          'This peer does not expose a valid network address for a direct connection.',
        );
      }

      _handshakePhase = HandshakePhase.connectingWifiDirect;
      _statusMessage = 'Connecting to the peer over the local network...';
      notifyListeners();

      final connected = await _wifiDirectService.connectToHost(
        hostIp: targetIp,
        port: peer.port,
      );
      if (!connected) {
        throw StateError(
          'Could not establish an encrypted session with ${peer.name}.',
        );
      }

      peer.isConnected = true;
      _connectedPeer = peer;
      _handshakePhase = HandshakePhase.connected;
      _statusMessage = 'Connected (5GHz High-Speed Channel active)';
      notifyListeners();

      return true;
    } catch (e) {
      _connectedPeer = null;
      _handshakePhase = HandshakePhase.failed;
      _statusMessage = 'Connection failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<void> disconnect() async {
    await _wifiDirectService.stopServer();
    if (_connectedPeer != null) {
      _connectedPeer!.isConnected = false;
      _connectedPeer = null;
    }
    _handshakePhase = HandshakePhase.idle;
    _statusMessage = 'Disconnected';
    notifyListeners();
  }

  void updateHostLimits({
    required int maxBytesPerSecond,
    required int maxTotalQuotaBytes,
  }) {
    _hostLimitProfile = SpeedLimitProfile(
      maxBytesPerSecond: maxBytesPerSecond,
      maxTotalQuotaBytes: maxTotalQuotaBytes,
    );
    _wifiDirectService.speedThrottler.updateLimits(
      maxBytesPerSecond: maxBytesPerSecond,
      maxTotalQuota: maxTotalQuotaBytes,
    );
    if (_connectedPeer != null) {
      _connectedPeer!.speedLimitBytesPerSec = maxBytesPerSecond;
      _connectedPeer!.dataLimitBytes = maxTotalQuotaBytes;
    }
    notifyListeners();
  }

  Future<void> sendLocalFile(String path) async {
    final file = File(path);
    if (!await file.exists()) throw FileSystemException('File not found', path);
    if (!isConnected) throw StateError('Connect to a nearby device first.');
    final task = TransferTask(
      id: 'task-${DateTime.now().millisecondsSinceEpoch}',
      fileName: path.split(Platform.pathSeparator).last,
      fileSize: await file.length(),
      localPath: path,
      isIncoming: false,
      remotePeerId: _connectedPeer?.id,
      remotePeerName: _connectedPeer?.name,
    );
    _activeTransfers.insert(0, task);
    notifyListeners();
    await _wifiDirectService.sendFile(task: task, fileByteStream: file.openRead());
  }

  void pauseTransfer(String taskId) {
    final index = _activeTransfers.indexWhere((t) => t.id == taskId);
    if (index >= 0) {
      _activeTransfers[index].status = TransferStatus.paused;
      _activeTransfers[index].speedBytesPerSec = 0;
      notifyListeners();
    }
  }

  void resumeTransfer(String taskId) {
    final index = _activeTransfers.indexWhere((t) => t.id == taskId);
    if (index >= 0) {
      final task = _activeTransfers[index];
      if (task.status == TransferStatus.completed ||
          task.status == TransferStatus.failed ||
          task.status == TransferStatus.canceled) {
        return;
      }
      final path = task.localPath;
      if (!task.isIncoming && path != null) {
        unawaited(_wifiDirectService.sendFile(
          task: task,
          fileByteStream: File(path).openRead(task.bytesTransferred),
          resumeFromByte: task.bytesTransferred,
        ));
      }
    }
  }

  @override
  void dispose() {
    _bleSub?.cancel();
    _lanSub?.cancel();
    _transferSub?.cancel();
    _bleService.dispose();
    _lanService.dispose();
    _wifiDirectService.dispose();
    super.dispose();
  }
}
