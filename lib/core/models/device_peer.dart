import 'device_limit_profile.dart';

enum ConnectionMode {
  directMode, // Hybrid BLE + Wi-Fi Direct 5GHz
  homeMode,   // LAN Sharing (Router mDNS)
}

enum DeviceType {
  phone,
  tablet,
  pc,
  unknown,
}

/// Discovered peer representation across BLE, Wi-Fi Direct, and LAN
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
  DeviceLimitProfile limitProfile;

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
    DeviceLimitProfile? limitProfile,
    int speedLimitBytesPerSec = 0,
    int dataLimitBytes = 0,
    int transferredBytes = 0,
  }) : limitProfile = limitProfile ??
            DeviceLimitProfile(
              maxBytesPerSecond: speedLimitBytesPerSec,
              maxQuotaBytes: dataLimitBytes,
              bytesUsed: transferredBytes,
            );

  int get speedLimitBytesPerSec => limitProfile.maxBytesPerSecond;
  set speedLimitBytesPerSec(int val) {
    limitProfile = limitProfile.copyWith(maxBytesPerSecond: val);
  }

  int get dataLimitBytes => limitProfile.maxQuotaBytes;
  set dataLimitBytes(int val) {
    limitProfile = limitProfile.copyWith(maxQuotaBytes: val);
  }

  int get transferredBytes => limitProfile.bytesUsed;
  set transferredBytes(int val) {
    limitProfile = limitProfile.copyWith(bytesUsed: val);
  }

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
      rssi: -45,
      ipAddress: ip,
      port: port,
      mode: ConnectionMode.homeMode,
      supports5GHz: true,
      supportsZeroCopy: true,
    );
  }
}
