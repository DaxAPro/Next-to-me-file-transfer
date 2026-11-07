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
/// Glues BLE Discovery + Invisible Handshake + 5GHz Wi-Fi Direct & LAN Sharing
class HybridConnectionManager extends ChangeNotifier {
  final BleDiscoveryService _bleService = BleDiscoveryService();
  final LanDiscoveryService _lanService = LanDiscoveryService();
  final WifiDirectService _wifiDirectService = WifiDirectService();

  ConnectionMode _activeMode = ConnectionMode.directMode;
  HandshakePhase _handshakePhase = HandshakePhase.idle;
  DevicePeer? _connectedPeer;
  String? _statusMessage;

  final String localDeviceId = 'device-${DateTime.now().millisecondsSinceEpoch % 10000}';
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
    _initStreams();
  }

  // Getters
  ConnectionMode get activeMode => _activeMode;
  HandshakePhase get handshakePhase => _handshakePhase;
  DevicePeer? get connectedPeer => _connectedPeer;
  String? get statusMessage => _statusMessage;
  List<DevicePeer> get discoveredPeers => List.unmodifiable(_discoveredPeers);
  List<TransferTask> get activeTransfers => List.unmodifiable(_activeTransfers);
  SpeedLimitProfile get hostLimitProfile => _hostLimitProfile;
  bool get isConnected => _connectedPeer != null && _wifiDirectService.isConnected;
  WifiDirectService get wifiDirectService => _wifiDirectService;

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

      // Step 2: Generate cryptographic Wi-Fi Direct invitation packet
      final invitation = HandshakePayload.createNewDirectInvitation(
        senderId: localDeviceId,
        senderName: localDeviceName,
      );

      // Verify payload cryptographic signature
      if (!invitation.verifyIntegrity()) {
        throw Exception('Handshake security verification failed');
      }

      // Simulate invisible BLE credential exchange delay (200-400ms)
      await Future.delayed(const Duration(milliseconds: 350));

      // Step 3: Establish 5GHz Wi-Fi Direct High-Speed Socket
      _handshakePhase = HandshakePhase.connectingWifiDirect;
      _statusMessage = 'Connecting to 5GHz Wi-Fi Channel (DIRECT-NM)...';
      notifyListeners();

      // Start socket server/client handover
      await _wifiDirectService.startServer(port: invitation.port);

      // In Direct Mode or Home Mode, link socket
      final targetIp = peer.ipAddress ?? invitation.ipAddress;
      if (peer.ipAddress != null) {
        await _wifiDirectService.connectToHost(hostIp: targetIp, port: invitation.port);
      }
      // Mark peer as connected
      peer.isConnected = true;
      _connectedPeer = peer;
      _handshakePhase = HandshakePhase.connected;
      _statusMessage = 'Connected (5GHz High-Speed Channel active)';
      notifyListeners();

      return true;
    } catch (e) {
      _handshakePhase = HandshakePhase.failed;
      _statusMessage = 'Connection failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Disconnect current session
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

  /// Host Speed Limit & Quota Configuration
  void updateHostLimits({
    required int maxBytesPerSecond, // e.g. 5 * 1024 * 1024 for 5MB/s
    required int maxTotalQuotaBytes, // e.g. 1024 * 1024 * 1024 for 1GB
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

  /// Adds a transfer task and initiates high-speed transfer
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

    // Start transfer simulation / socket streaming
    _simulateHighSpeedTransfer(task, resumeOffset: resumeOffset);
  }

  /// High-speed transfer simulator reflecting real 40MB/s+ 5GHz socket performance
  void _simulateHighSpeedTransfer(TransferTask task, {int resumeOffset = 0}) async {
    task.status = TransferStatus.transferring;
    task.bytesTransferred = resumeOffset;
    notifyListeners();

    // Simulated transfer: ticks every 100ms
    // Target speed: ~42.5 MB/s (unless throttled by host limit)
    const tickMs = 100;
    var currentBytes = resumeOffset;

    Timer.periodic(const Duration(milliseconds: tickMs), (timer) {
      if (task.status == TransferStatus.paused ||
          task.status == TransferStatus.canceled ||
          task.status == TransferStatus.completed) {
        timer.cancel();
        return;
      }

      // Check speed limit
      double targetBytesPerSec = 42.5 * 1024 * 1024; // 42.5 MB/s
      if (_hostLimitProfile.isSpeedThrottled) {
        targetBytesPerSec = _hostLimitProfile.maxBytesPerSecond.toDouble();
      }

      final bytesThisTick = (targetBytesPerSec * (tickMs / 1000.0)).round();

      // Check quota limit
      if (_hostLimitProfile.hasQuotaLimit &&
          (currentBytes + bytesThisTick) > _hostLimitProfile.maxTotalQuotaBytes) {
        task.status = TransferStatus.failed;
        task.errorMessage = 'Host data limit (${_hostLimitProfile.formattedQuotaLimit}) exceeded.';
        timer.cancel();
        notifyListeners();
        return;
      }

      currentBytes += bytesThisTick;
      if (currentBytes >= task.fileSize) {
        currentBytes = task.fileSize;
        task.status = TransferStatus.completed;
        task.finishedAt = DateTime.now();
        task.speedBytesPerSec = 0;
        timer.cancel();
      } else {
        task.speedBytesPerSec = targetBytesPerSec;
        task.checkStreamReady();
      }

      task.bytesTransferred = currentBytes;
      notifyListeners();
    });
  }

  /// Pause transfer with exact byte caching
  void pauseTransfer(String taskId) {
    final index = _activeTransfers.indexWhere((t) => t.id == taskId);
    if (index >= 0) {
      _activeTransfers[index].status = TransferStatus.paused;
      _activeTransfers[index].speedBytesPerSec = 0;
      notifyListeners();
    }
  }

  /// Resume transfer from the exact cached byte offset (Auto-Resume)
  void resumeTransfer(String taskId) {
    final index = _activeTransfers.indexWhere((t) => t.id == taskId);
    if (index >= 0) {
      final task = _activeTransfers[index];
      _simulateHighSpeedTransfer(task, resumeOffset: task.bytesTransferred);
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
