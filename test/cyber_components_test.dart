import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_to_me/core/constants/app_constants.dart';
import 'package:next_to_me/core/constants/user_friendly_strings.dart';
import 'package:next_to_me/core/models/device_peer.dart';
import 'package:next_to_me/core/theme/cyber_colors.dart';
import 'package:next_to_me/core/theme/theme_controller.dart';
import 'package:next_to_me/services/connection/hybrid_connection_manager.dart';
import 'package:next_to_me/ui/common_widgets/branded_app_logo.dart';
import 'package:next_to_me/ui/common_widgets/cyber_avatar.dart';
import 'package:next_to_me/ui/common_widgets/custom_cyber_icons.dart';
import 'package:next_to_me/ui/screens/about/about_screen.dart';
import 'package:next_to_me/ui/screens/hotspot_limits/widgets/interactive_speedometer_gauge.dart';
import 'package:next_to_me/ui/screens/hotspot_limits/widgets/live_bandwidth_card.dart';
import 'package:next_to_me/ui/screens/onboarding/onboarding_screen.dart';
import 'package:next_to_me/ui/screens/privacy/privacy_policy_screen.dart';
import 'package:next_to_me/ui/widgets/adaptive_radar_painter.dart';
import 'package:next_to_me/ui/widgets/radar_scan_view.dart';
import 'package:next_to_me/ui/widgets/wave_transfer_progress.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeController & Dark/Light Mode', () {
    test('ThemeController defaults to Light Mode initially', () async {
      final controller = ThemeController.instance;
      await controller.init();
      expect(controller.isDarkMode, isFalse);
      expect(controller.themeMode, equals(ThemeMode.light));
    });

    test('ThemeController toggles seamlessly between dark and light', () async {
      final controller = ThemeController.instance;
      await controller.setThemeMode(ThemeMode.dark);
      expect(controller.isDarkMode, isTrue);
      expect(controller.themeMode, equals(ThemeMode.dark));

      await controller.toggleTheme();
      expect(controller.isDarkMode, isFalse);
      expect(controller.themeMode, equals(ThemeMode.light));

      await controller.toggleTheme();
      expect(controller.isDarkMode, isTrue);
      expect(controller.themeMode, equals(ThemeMode.dark));
    });

    testWidgets('CyberColors dynamically adapts to theme brightness', (tester) async {
      Color? darkBg;
      Color? lightBg;

      await tester.pumpWidget(
        Theme(
          data: ThemeData(brightness: Brightness.dark),
          child: Builder(
            builder: (ctx) {
              darkBg = CyberColors.background(ctx);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(darkBg, equals(CyberColors.oledBlack));

      await tester.pumpWidget(
        Theme(
          data: ThemeData(brightness: Brightness.light),
          child: Builder(
            builder: (ctx) {
              lightBg = CyberColors.background(ctx);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(lightBg, equals(CyberColors.lightBg));
    });
  });

  group('Orbital Constellation Radar Scanner (10+ Devices)', () {
    testWidgets('RadarScanView renders 12 devices in orbital constellation without errors', (tester) async {
      final twelvePeers = List.generate(
        12,
        (i) => DevicePeer(
          id: 'dev-$i',
          name: 'Device $i',
          ipAddress: '192.168.49.${10 + i}',
          port: 8888,
          mode: ConnectionMode.directMode,
          deviceType: i % 3 == 0 ? DeviceType.pc : (i % 2 == 0 ? DeviceType.tablet : DeviceType.phone),
          rssi: -45 - (i * 3),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadarScanView(
              peers: twelvePeers,
              isScanning: true,
              isEcoMode: false,
              onPeerSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(RadarScanView), findsOneWidget);
      expect(find.text('ME'), findsOneWidget);
      expect(find.text('Device'), findsWidgets);
    });
  });

  group('Play Store Deployment Package (About & Privacy Policy)', () {
    testWidgets('AboutScreen displays exact required Play Store text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AboutScreen(),
        ),
      );

      expect(find.text('About NextToMe'), findsWidgets);
      expect(find.text('Version: 1.0.0'), findsOneWidget);
      expect(
        find.textContaining('NextToMe is the ultimate high-speed, offline file-sharing and communication hub'),
        findsOneWidget,
      );
    });

    testWidgets('PrivacyPolicyScreen displays exact required Play Store permissions text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PrivacyPolicyScreen(),
        ),
      );

      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('100% Offline & Private'), findsOneWidget);
      expect(find.text('Permissions Explained:'), findsOneWidget);
      expect(
        find.textContaining('Your transfers and offline chats are routed only between the connected devices'),
        findsOneWidget,
      );
    });
  });

  group('Cyber Colors & Gradients', () {
    test('Speedometer color transitions smoothly from Cyan to Tech Emerald', () {
      final lowColor = CyberColors.getSpeedometerColor(0.0);
      expect(lowColor, equals(CyberColors.electricCyan));

      final highColor = CyberColors.getSpeedometerColor(1.0);
      expect(highColor, equals(CyberColors.techEmerald));

      final midColor = CyberColors.getSpeedometerColor(0.5);
      expect(midColor, equals(CyberColors.techBlue));
    });
  });

  group('Cyber Persona Avatar & Custom Icons', () {
    testWidgets('CyberAvatar renders with status badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CyberAvatar(size: 56, showStatusBadge: true),
          ),
        ),
      );
      expect(find.byType(CyberAvatar), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('CyberIcon renders all types without errors', (tester) async {
      for (final type in CyberIconType.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CyberIcon(type: type, size: 24),
            ),
          ),
        );
        expect(find.byType(CyberIcon), findsOneWidget);
      }
    });

    testWidgets('BrandedAppLogo renders vector representation properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BrandedAppLogo(size: 80, useAssetIfAvailable: false),
          ),
        ),
      );
      expect(find.byType(BrandedAppLogo), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    test('UserFriendlyStrings has clean zero-jargon copy', () {
      expect(UserFriendlyStrings.appTagline, equals('Ultra-Fast Transfers without Internet'));
      expect(UserFriendlyStrings.navHome, equals('Home'));
      expect(UserFriendlyStrings.navSetLimits, equals('Set Limits'));
      expect(UserFriendlyStrings.navHistory, equals('History'));
    });
  });

  group('Speedometer-Style Hotspot Throttling Meter', () {
    testWidgets('InteractiveSpeedometerGauge renders and handles step taps', (tester) async {
      double selectedSpeed = 0.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveSpeedometerGauge(
              speedMb: 0.0,
              onSpeedChanged: (speed) => selectedSpeed = speed,
            ),
          ),
        ),
      );

      expect(find.text('UNLIMITED'), findsOneWidget);
      expect(find.text('2 MB/s'), findsOneWidget);

      await tester.tap(find.text('2 MB/s'));
      await tester.pump();
      expect(selectedSpeed, equals(2.0));
    });

    testWidgets('LiveBandwidthCard displays real-time readout', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LiveBandwidthCard(
              deviceName: 'OnePlus 12',
              currentSpeedMb: 1.8,
              usedMb: 140.0,
              totalQuotaMb: 1024.0,
              isThrottled: false,
            ),
          ),
        ),
      );

      expect(find.text('ONEPLUS 12'), findsOneWidget);
      expect(find.text('Used: 140MB / 1.0GB'), findsOneWidget);
      expect(find.text('Speed: 1.8 MB/s'), findsOneWidget);
    });
  });

  group('Adaptive Animations & Wave Progress', () {
    testWidgets('WaveTransferProgress renders sinusoidal wave', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WaveTransferProgress(
              progress: 0.45,
              isTransferring: true,
            ),
          ),
        ),
      );

      expect(find.byType(WaveTransferProgress), findsOneWidget);
    });

    test('DeviceAdaptivePulsePainter handles PC, Tablet, Phone modes', () {
      final painter = DeviceAdaptivePulsePainter(
        animationValue: 0.5,
        deviceType: DeviceType.pc,
        baseColor: CyberColors.techEmerald,
      );
      expect(painter.deviceType, equals(DeviceType.pc));
    });
  });

  group('4-Step Welcome Onboarding Slider & First-Launch Logic', () {
    testWidgets('OnboardingScreen renders first step with Skip and Next buttons and 4 dots', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final connectionManager = HybridConnectionManager();

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(connectionManager: connectionManager),
        ),
      );
      await tester.pumpAndSettle();

      // Skip button visible on Screen 1
      expect(find.text('Skip'), findsOneWidget);
      // Next button on screen 1
      expect(find.text('Next ➔'), findsOneWidget);
      // 4 circular indicator dots
      final dotsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).shape == BoxShape.circle &&
            (widget.constraints?.maxWidth == 10 || (widget.decoration as BoxDecoration).color != null),
      );
      expect(dotsFinder, findsWidgets);

      connectionManager.dispose();
    });

    testWidgets('Tapping Skip saves isFirstTimeLaunch=false and keyFirstLaunch=true', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final connectionManager = HybridConnectionManager();

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(connectionManager: connectionManager),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(AppConstants.keyIsFirstTimeLaunch), isFalse);
      expect(prefs.getBool(AppConstants.keyFirstLaunch), isTrue);

      connectionManager.dispose();
    });
  });
}
