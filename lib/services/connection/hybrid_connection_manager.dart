import 'dart:async';

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
  final Map<String, Timer> _transferTimers = {};

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
    if (_activeMode == ConnectionMode.directMode) {
      _lanService.stopDiscovery();
      _handshakePhase = HandshakePhase.discoveringBle;
      _statusMessage = 'Scanning BLE 5GHz beacons (1-2s)...';
      notifyListeners();

      await _bleService.startScanning(localDeviceId: localDeviceId);
      await _bleService.startAdvertising(
        deviceName: localDeviceName,
        deviceId: localDeviceId,
        is5GHzCapable: true,
      );
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

      await Future.delayed(const Duration(milliseconds: 300));

      _handshakePhase = HandshakePhase.connectingWifiDirect;
      _statusMessage = 'Connecting to 5GHz Wi-Fi Channel (DIRECT-NM)...';
      notifyListeners();

      await _wifiDirectService.startServer(port: invitation.port);

      final connected = await _wifiDirectService.connectToHost(
        hostIp: targetIp,
        port: invitation.port,
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

  void enqueueTransfer({
    required String fileName,
    required int fileSize,
    required bool isIncoming,
    int resumeOffset = 0,
  }) {
    final task = TransferTask(
      id: 'task-${DateTime.now().millisecondsSinceEpoch}',
      fileName: fileName,
      fileSize: fileSize,
      bytesTransferred: resumeOffset,
      isIncoming: isIncoming,
      remotePeerId: _connectedPeer?.id,
      remotePeerName: _connectedPeer?.name,
    );

    _activeTransfers.insert(0, task);
    notifyListeners();

    _simulateHighSpeedTransfer(task, resumeOffset: resumeOffset);
  }

  void _cancelTransferTimer(String taskId) {
    final existingTimer = _transferTimers.remove(taskId);
    existingTimer?.cancel();
  }

  /// Green Code: Throttles UI refresh frequency to save battery during 40MB/s transfers
  void _simulateHighSpeedTransfer(
    TransferTask task, {
    int resumeOffset = 0,
  }) {
    _cancelTransferTimer(task.id);
    task.status = TransferStatus.transferring;
    task.bytesTransferred = resumeOffset;
    notifyListeners();

    // In Eco Mode, tick interval is 250ms (4 FPS); normal is 125ms (8 FPS)
    final tickMs = _isEcoMode ? 250 : 125;
    var currentBytes = resumeOffset;
    var lastUiNotify = DateTime.now().millisecondsSinceEpoch;

    final timer = Timer.periodic(Duration(milliseconds: tickMs), (timer) {
      if (task.status == TransferStatus.paused ||
          task.status == TransferStatus.canceled ||
          task.status == TransferStatus.completed ||
          task.status == TransferStatus.failed) {
        _cancelTransferTimer(task.id);
        return;
      }

      double targetBytesPerSec = 42.5 * 1024 * 1024;
      if (_hostLimitProfile.isSpeedThrottled) {
        targetBytesPerSec = _hostLimitProfile.maxBytesPerSecond.toDouble();
      }

      final bytesThisTick = (targetBytesPerSec * (tickMs / 1000.0)).round();

      if (_hostLimitProfile.hasQuotaLimit &&
          (currentBytes + bytesThisTick) >
              _hostLimitProfile.maxTotalQuotaBytes) {
        task.status = TransferStatus.failed;
        task.errorMessage =
            'Host data limit (${_hostLimitProfile.formattedQuotaLimit}) exceeded.';
        _cancelTransferTimer(task.id);
        notifyListeners();
        return;
      }

      currentBytes += bytesThisTick;
      if (currentBytes >= task.fileSize) {
        currentBytes = task.fileSize;
        task.status = TransferStatus.completed;
        task.finishedAt = DateTime.now();
        task.speedBytesPerSec = 0;
        _cancelTransferTimer(task.id);
        notifyListeners();
      } else {
        task.speedBytesPerSec = targetBytesPerSec;
        task.checkStreamReady();
      }

      task.bytesTransferred = currentBytes;

      // Green Code: Only call notifyListeners every 250ms (or 500ms in Eco Mode)
      final now = DateTime.now().millisecondsSinceEpoch;
      final uiNotifyThreshold = _isEcoMode ? 500 : 250;
      if (now - lastUiNotify >= uiNotifyThreshold) {
        lastUiNotify = now;
        notifyListeners();
      }
    });

    _transferTimers[task.id] = timer;
  }

  void pauseTransfer(String taskId) {
    final index = _activeTransfers.indexWhere((t) => t.id == taskId);
    if (index >= 0) {
      _cancelTransferTimer(taskId);
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
      _simulateHighSpeedTransfer(task, resumeOffset: task.bytesTransferred);
    }
  }

  @override
  void dispose() {
    for (final timer in _transferTimers.values) {
      timer.cancel();
    }
    _transferTimers.clear();
    _bleSub?.cancel();
    _lanSub?.cancel();
    _transferSub?.cancel();
    _bleService.dispose();
    _lanService.dispose();
    _wifiDirectService.dispose();
    super.dispose();
  }
}
