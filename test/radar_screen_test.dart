import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_to_me/core/models/device_peer.dart';
import 'package:next_to_me/ui/common_widgets/cyber_avatar.dart';
import 'package:next_to_me/ui/screens/radar/home_radar_screen.dart';
import 'package:next_to_me/ui/screens/radar/radar_device_node.dart';
import 'package:next_to_me/ui/screens/radar/radar_painters.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockPeers = List.generate(
    12,
    (i) => DevicePeer(
      id: 'peer-$i',
      name: 'Galaxy S2$i',
      ipAddress: '192.168.49.${20 + i}',
      port: 52520,
      mode: ConnectionMode.directMode,
      deviceType: i % 3 == 0
          ? DeviceType.pc
          : (i % 2 == 0 ? DeviceType.tablet : DeviceType.phone),
      rssi: -55 - (i * 3),
    ),
  );

  group('Discovering Peers Radar Animation (HomeRadarScreen)', () {
    testWidgets(
      'HomeRadarScreen renders grid, sonar pulses, center node, and 12+ orbital peers',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HomeRadarScreen(peers: mockPeers, isScanning: true),
            ),
          ),
        );

        // Verify Center Node ME badge
        expect(find.text('ME'), findsOneWidget);
        expect(find.byType(CyberAvatar), findsOneWidget);

        final radarCanvas = find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint && widget.painter is GraphPaperGridPainter,
        );
        final radarBox = tester.renderObject<RenderBox>(radarCanvas);
        final avatarBox = tester.renderObject<RenderBox>(
          find.byType(CyberAvatar),
        );
        final radarCenter = radarBox.localToGlobal(
          radarBox.size.center(Offset.zero),
        );
        final avatarCenter = avatarBox.localToGlobal(
          avatarBox.size.center(Offset.zero),
        );
        expect((radarCenter - avatarCenter).distance, lessThan(1));

        // Verify Discovery Header
        expect(find.text('Discovering Peers (12 found)'), findsOneWidget);

        // Verify presence of CustomPainters
        expect(find.byType(CustomPaint), findsWidgets);

        // Verify that device names and RSSI signal strings are rendered
        expect(find.text('Galaxy S20'), findsOneWidget);
        expect(find.text('(-55dBm)'), findsOneWidget);

        // Verify multiple radar nodes rendered
        expect(find.byType(RadarDeviceNode), findsNWidgets(12));

        // Advance time slightly to test orbital drift and sonar animations without exceptions
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 1000));
      },
    );

    testWidgets(
      'RadarDeviceNode renders elastic bounce and triggers tap callback',
      (tester) async {
        bool tapped = false;
        final testPeer = DevicePeer(
          id: 'test-1',
          name: 'Pixel 8 Pro',
          ipAddress: '192.168.49.50',
          port: 52520,
          mode: ConnectionMode.directMode,
          deviceType: DeviceType.phone,
          rssi: -62,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: RadarDeviceNode(
                  peer: testPeer,
                  onTap: () => tapped = true,
                ),
              ),
            ),
          ),
        );

        expect(find.text('Pixel 8 Pro'), findsOneWidget);
        expect(find.text('(-62dBm)'), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 750));
        await tester.tap(find.byType(RadarDeviceNode));
        await tester.pump();
        expect(tapped, isTrue);
      },
    );

    test('Radar CustomPainters repaint behavior is properly controlled', () {
      final grid1 = GraphPaperGridPainter(gridColor: Colors.grey);
      final grid2 = GraphPaperGridPainter(gridColor: Colors.grey);
      final grid3 = GraphPaperGridPainter(gridColor: Colors.white);

      expect(grid1.shouldRepaint(grid2), isFalse);
      expect(grid1.shouldRepaint(grid3), isTrue);

      final sonar = SonarPulsePainter(
        animationValue: 0.5,
        emeraldColor: Colors.green,
        cyanColor: Colors.cyan,
        maxRadius: 150,
      );
      expect(sonar.shouldRepaint(sonar), isTrue);
    });
  });
}
