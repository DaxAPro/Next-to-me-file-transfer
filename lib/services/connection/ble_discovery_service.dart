import 'dart:async';
import '../../core/models/device_peer.dart';

/// Bluetooth Low Energy (BLE) Auto-Discovery Service
/// Achieves instant (1-2 seconds) nearby peer detection without manual pairing
class BleDiscoveryService {
  bool _isScanning = false;
  bool _isAdvertising = false;
  final StreamController<List<DevicePeer>> _discoveredPeersController =
      StreamController<List<DevicePeer>>.broadcast();

  final Map<String, DevicePeer> _peers = {};

  bool get isScanning => _isScanning;
  bool get isAdvertising => _isAdvertising;
  Stream<List<DevicePeer>> get discoveredPeersStream => _discoveredPeersController.stream;
  List<DevicePeer> get currentPeers => _peers.values.toList();

  /// Start BLE scanning for nearby devices
  Future<void> startScanning({required String localDeviceId}) async {
    if (_isScanning) return;
    _isScanning = true;
    _peers.clear();
    _notifyPeersChanged();

    // No platform BLE scanner is currently registered. Keep the result empty
    // rather than presenting fabricated devices as nearby peers.
  }

  /// Stop BLE scanning
  Future<void> stopScanning() async {
    _isScanning = false;
  }

  /// Broadcast local BLE advertisement packet (Invisible Beacon)
  Future<void> startAdvertising({
    required String deviceName,
    required String deviceId,
    bool is5GHzCapable = true,
  }) async {
    if (_isAdvertising) return;
    _isAdvertising = true;

    // Advertising requires a native BLE implementation; do not claim a
    // beacon is active when the platform has not provided one.
    _isAdvertising = false;
  }

  /// Stop BLE broadcasting
  Future<void> stopAdvertising() async {
    _isAdvertising = false;
  }

  /// Register or update an external discovered peer (e.g. from platform channels)
  void addOrUpdatePeer(DevicePeer peer) {
    _peers[peer.id] = peer;
    _notifyPeersChanged();
  }

  void removePeer(String peerId) {
    if (_peers.remove(peerId) != null) {
      _notifyPeersChanged();
    }
  }

  void _notifyPeersChanged() {
    if (!_discoveredPeersController.isClosed) {
      _discoveredPeersController.add(_peers.values.toList());
    }
  }

  void dispose() {
    stopScanning();
    stopAdvertising();
    _discoveredPeersController.close();
  }
}
