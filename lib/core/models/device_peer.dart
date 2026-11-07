/// Represents the connection mode selected by the user
enum ConnectionMode {
  directMode, // Hybrid BLE (Discovery + Handshake) + Wi-Fi Direct 5GHz
  homeMode,   // LAN Sharing (mDNS Discovery + Router Sockets)
}

/// Device hardware platform category
enum DeviceType {
  phone,
  tablet,
  pc,
  unknown,
}

/// Discovered peer representation across BLE and LAN
class DevicePeer {
  final String id;
  final String name;
  final DeviceType deviceType;
  final String os;
  final int rssi; // Signal strength in dBm (-30 to -95)
  final String? ipAddress;
  final int port;
  final ConnectionMode mode;
  final bool supports5GHz;
  final bool supportsZeroCopy;
  final bool supportsUwb;
  bool isConnected;
  int speedLimitBytesPerSec; // 0 = unlimited
  int dataLimitBytes;        // 0 = unlimited
  int transferredBytes;

  DevicePeer({
    required this.id,
    required this.name,
    this.deviceType = DeviceType.phone,
    this.os = 'Android',
    this.rssi = -55,
    this.ipAddress,
    this.port = 52520,
    required this.mode,
    this.supports5GHz = true,
    this.supportsZeroCopy = true,
    this.supportsUwb = false,
    this.isConnected = false,
    this.speedLimitBytesPerSec = 0, // 0 = no throttle
    this.dataLimitBytes = 0,        // 0 = no quota limit
    this.transferredBytes = 0,
  });

  /// Factory from BLE advertising service data
  factory DevicePeer.fromBleAdvertisement({
    required String deviceId,
    required String name,
    required int rssi,
    Map<String, dynamic>? extraData,
  }) {
    final devTypeStr = extraData?['type']?.toString().toLowerCase() ?? 'phone';
    DeviceType devType = DeviceType.phone;
    if (devTypeStr.contains('pc') || devTypeStr.contains('desktop')) {
      devType = DeviceType.pc;
    } else if (devTypeStr.contains('tablet') || devTypeStr.contains('ipad')) {
      devType = DeviceType.tablet;
    }

    return DevicePeer(
      id: deviceId,
      name: name.isNotEmpty ? name : 'Nearby Device',
      deviceType: devType,
      os: extraData?['os']?.toString() ?? 'Android',
      rssi: rssi,
      ipAddress: extraData?['ip']?.toString(),
      port: extraData?['port'] != null ? int.tryParse(extraData!['port'].toString()) ?? 52520 : 52520,
      mode: ConnectionMode.directMode,
      supports5GHz: extraData?['5g'] == true || extraData?['5g'] == '1',
      supportsZeroCopy: extraData?['zc'] == true || extraData?['zc'] == '1',
      supportsUwb: extraData?['uwb'] == true,
    );
  }

  /// Factory from mDNS LAN record
  factory DevicePeer.fromMdnsRecord({
    required String host,
    required String ip,
    required int port,
    Map<String, String>? txtRecords,
  }) {
    final devTypeStr = txtRecords?['type']?.toLowerCase() ?? 'pc';
    DeviceType devType = DeviceType.pc;
    if (devTypeStr.contains('phone')) {
      devType = DeviceType.phone;
    } else if (devTypeStr.contains('tablet')) {
      devType = DeviceType.tablet;
    }

    return DevicePeer(
      id: txtRecords?['id'] ?? '$ip:$port',
      name: txtRecords?['name'] ?? host.replaceAll('.local', ''),
      deviceType: devType,
      os: txtRecords?['os'] ?? 'Windows',
      rssi: -45, // LAN typically strong
      ipAddress: ip,
      port: port,
      mode: ConnectionMode.homeMode,
      supports5GHz: true,
      supportsZeroCopy: true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'deviceType': deviceType.name,
    'os': os,
    'rssi': rssi,
    'ipAddress': ipAddress,
    'port': port,
    'mode': mode.name,
    'supports5GHz': supports5GHz,
    'supportsZeroCopy': supportsZeroCopy,
    'supportsUwb': supportsUwb,
    'isConnected': isConnected,
    'speedLimitBytesPerSec': speedLimitBytesPerSec,
    'dataLimitBytes': dataLimitBytes,
    'transferredBytes': transferredBytes,
  };
}
