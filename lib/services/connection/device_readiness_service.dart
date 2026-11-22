import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class DeviceHardwareStatus {
  final bool wifiEnabled;
  final bool bluetoothEnabled;

  const DeviceHardwareStatus({
    required this.wifiEnabled,
    required this.bluetoothEnabled,
  });

  bool get isReady => wifiEnabled && bluetoothEnabled;
}

class DeviceReadinessService {
  static const MethodChannel _channel = MethodChannel('nexttome/wifi_direct');

  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final statuses = await [
        Permission.bluetooth,
        Permission.locationWhenInUse,
      ].request();
      return statuses.length == 2 &&
          statuses.values.every((status) => status.isGranted);
    }
    if (!Platform.isAndroid) return true;

    final sdkVersion = await _channel.invokeMethod<int>('getAndroidSdkVersion');
    if (sdkVersion == null) {
      throw StateError('The Android version could not be checked.');
    }
    final permissions = <Permission>[
      if (sdkVersion >= 31) ...[
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
      ],
      Permission.locationWhenInUse,
      if (sdkVersion >= 33) Permission.nearbyWifiDevices,
    ];

    final statuses = await permissions.request();
    return statuses.length == permissions.length &&
        statuses.values.every((status) => status.isGranted);
  }

  Future<DeviceHardwareStatus> checkHardwareStatus() async {
    if (!Platform.isAndroid) {
      return const DeviceHardwareStatus(
        wifiEnabled: true,
        bluetoothEnabled: true,
      );
    }

    final status = await _channel.invokeMapMethod<String, dynamic>(
      'getHardwareStatus',
    );
    if (status == null ||
        status['wifiEnabled'] is! bool ||
        status['bluetoothEnabled'] is! bool) {
      throw StateError('The device connection status could not be checked.');
    }
    return DeviceHardwareStatus(
      wifiEnabled: status['wifiEnabled'] as bool,
      bluetoothEnabled: status['bluetoothEnabled'] as bool,
    );
  }

  Future<void> openWifiSettings() async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod<void>('openWifiSettings');
    }
  }

  Future<void> openBluetoothSettings() async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod<void>('openBluetoothSettings');
    }
  }
}
