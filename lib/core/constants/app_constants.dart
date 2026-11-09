/// Application Constants and Network Configurations
class AppConstants {
  static const String appName = 'NextToMe P2P ZERO-COPY';
  static const String appVersion = 'Version 1.0.0';
  static const String appBuild = '1.0.0+1';

  // Network Ports & Standards
  static const int defaultTransferPort = 52520;
  static const int defaultDiscoveryPort = 52525;
  static const int defaultWebServerPort = 8080;

  // Transfer Frame Magic Byte & Limits
  static const int magicByte = 0x5A;
  static const int defaultChunkSize = 64 * 1024; // 64 KB
  static const double streamReadyThreshold =
      0.05; // 5% download activates media preview

  // Preferences Keys
  static const String keyIsFirstTimeLaunch = 'isFirstTimeLaunch';
  static const String keyFirstLaunch = 'pref_first_launch_done';
  static const String keyHasSeenOnboarding = 'has_seen_onboarding';
  static const String keyEcoMode = 'pref_eco_mode';
  static const String keyDarkMode = 'pref_dark_mode';
  static const String keyPinEnabled = 'pref_pin_enabled';
  static const String keyPinCode = 'pref_pin_code';
  static const String keyOfflineChatEnabled = 'pref_offline_chat_enabled';
}
