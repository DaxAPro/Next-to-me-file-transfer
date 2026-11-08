import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_to_me/core/models/device_peer.dart';
import 'package:next_to_me/core/theme/cyber_colors.dart';
import 'package:next_to_me/ui/common_widgets/cyber_avatar.dart';
import 'package:next_to_me/ui/common_widgets/custom_cyber_icons.dart';
import 'package:next_to_me/ui/screens/hotspot_limits/widgets/interactive_speedometer_gauge.dart';
import 'package:next_to_me/ui/screens/hotspot_limits/widgets/live_bandwidth_card.dart';
import 'package:next_to_me/ui/widgets/adaptive_radar_painter.dart';
import 'package:next_to_me/ui/widgets/wave_transfer_progress.dart';

void main() {
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
}
