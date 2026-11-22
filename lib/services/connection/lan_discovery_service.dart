import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../core/models/device_peer.dart';

/// LAN mDNS & UDP Multicast Discovery for Home Mode
/// Discovers PCs, laptops, and mobile phones on the same Wi-Fi router
class LanDiscoveryService {
  static const int discoveryPort = 52525;
  static const String multicastGroup = '239.255.255.250'; // SSDP/mDNS multicast

  RawDatagramSocket? _broadcastSocket;
  Timer? _announcementTimer;
  bool _isRunning = false;

  final StreamController<List<DevicePeer>> _lanPeersController =
      StreamController<List<DevicePeer>>.broadcast();
  final Map<String, DevicePeer> _peers = {};

  bool get isRunning => _isRunning;
  Stream<List<DevicePeer>> get lanPeersStream => _lanPeersController.stream;
  List<DevicePeer> get currentPeers => _peers.values.toList();

  /// Start listening and broadcasting on the local subnet
  Future<void> startDiscovery({
    required String localDeviceId,
    required String localDeviceName,
    required int transferPort,
  }) async {
    if (_isRunning) return;
    _isRunning = true;
    _peers.clear();
    _notifyPeers();

    try {
      _broadcastSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        discoveryPort,
        reuseAddress: true,
        reusePort: true,
      );
      _broadcastSocket?.broadcastEnabled = true;

      _broadcastSocket?.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _broadcastSocket?.receive();
          if (datagram != null) {
            _handleIncomingPacket(datagram, localDeviceId);
          }
        }
      });

      // Periodically announce presence to LAN every 3 seconds
      _announcementTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        _broadcastPresence(localDeviceId, localDeviceName, transferPort);
      });
      _broadcastPresence(localDeviceId, localDeviceName, transferPort);
    } catch (e) {
      // Discovery can be unavailable due to permissions or network policy.
      // An empty peer list is safer than reporting fictional devices.
      _isRunning = false;
      _announcementTimer?.cancel();
      _announcementTimer = null;
      _broadcastSocket?.close();
      _broadcastSocket = null;
    }
  }

  void _broadcastPresence(String id, String name, int port) {
    if (_broadcastSocket == null || !_isRunning) return;
    final payload = jsonEncode({
      'type': 'NEXT_TO_ME_ANNOUNCE',
      'id': id,
      'name': name,
      'port': port,
      'deviceType': 'phone',
      'os': Platform.operatingSystem,
    });
    final data = utf8.encode(payload);

    try {
      _broadcastSocket?.send(
        data,
        InternetAddress('255.255.255.255'),
        discoveryPort,
      );
    } catch (_) {}
  }

  void _handleIncomingPacket(Datagram datagram, String localDeviceId) {
    try {
      final msg = utf8.decode(datagram.data);
      final json = jsonDecode(msg) as Map<String, dynamic>;
      if (json['type'] == 'NEXT_TO_ME_ANNOUNCE' && json['id'] != localDeviceId) {
        final peer = DevicePeer.fromMdnsRecord(
          host: json['name'] ?? 'LAN Device',
          ip: datagram.address.address,
          port: json['port'] ?? 52520,
          txtRecords: {
            'id': json['id'] ?? '',
            'name': json['name'] ?? 'LAN Device',
            'type': json['deviceType'] ?? 'pc',
            'os': json['os'] ?? 'Unknown',
          },
        );
        _peers[peer.id] = peer;
        _notifyPeers();
      }
    } catch (_) {}
  }

  void stopDiscovery() {
    _isRunning = false;
    _announcementTimer?.cancel();
    _announcementTimer = null;
    _broadcastSocket?.close();
    _broadcastSocket = null;
  }

  void _notifyPeers() {
    if (!_lanPeersController.isClosed) {
      _lanPeersController.add(_peers.values.toList());
    }
  }

  void dispose() {
    stopDiscovery();
    _lanPeersController.close();
  }
}
