import 'package:flutter/material.dart';

import '../../../../core/theme/cyber_colors.dart';
import '../../../../services/connection/internet_speed_test_service.dart';
import '../hotspot_limits/widgets/interactive_speedometer_gauge.dart';

class GlobalSpeedTestScreen extends StatefulWidget {
  const GlobalSpeedTestScreen({super.key});

  @override
  State<GlobalSpeedTestScreen> createState() => _GlobalSpeedTestScreenState();
}

class _GlobalSpeedTestScreenState extends State<GlobalSpeedTestScreen> {
  final InternetSpeedTestService _speedTestService = InternetSpeedTestService();
  bool _isRunning = false;
  SpeedTestStage? _stage;
  double _liveDownload = 0;
  double _liveUpload = 0;
  double? _ping;
  SpeedTestResult? _result;
  String? _error;

  Future<void> _runTest() async {
    setState(() {
      _isRunning = true;
      _stage = SpeedTestStage.ping;
      _liveDownload = 0;
      _liveUpload = 0;
      _ping = null;
      _result = null;
      _error = null;
    });
    try {
      final result = await _speedTestService.run(
        onProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _stage = progress.stage;
            switch (progress.stage) {
              case SpeedTestStage.ping:
                _ping = progress.value;
              case SpeedTestStage.download:
                _liveDownload = progress.value;
              case SpeedTestStage.upload:
                _liveUpload = progress.value;
            }
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _liveDownload = result.downloadMbps;
        _liveUpload = result.uploadMbps;
        _ping = result.pingMilliseconds;
        _stage = null;
      });
    } on SpeedTestCancelledException {
      if (mounted) setState(() => _stage = null);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _stage = null;
        });
      }
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
  }

  void _cancelTest() {
    _speedTestService.cancel();
  }

  @override
  void dispose() {
    _speedTestService.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shownSpeed = _stage == SpeedTestStage.upload
        ? _liveUpload
        : _liveDownload;
    const maximumSpeed = 1000.0;
    final ratio = (shownSpeed / maximumSpeed).clamp(0.0, 1.0);
    final accent = CyberColors.getSpeedometerColor(ratio);

    return Scaffold(
      backgroundColor: CyberColors.background(context),
      appBar: AppBar(
        title: const Text('Global Internet Speed Test'),
        backgroundColor: CyberColors.surface(context),
        foregroundColor: CyberColors.text(context),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
              decoration: BoxDecoration(
                color: CyberColors.surface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: CyberColors.border(context)),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 230,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(280, 220),
                          painter: SpeedometerPainter(
                            ratio: ratio,
                            speedMb: shownSpeed,
                            activeColor: accent,
                            trackColor: CyberColors.border(context),
                            tickColor: CyberColors.subtext(context),
                            needleColor: CyberColors.background(context),
                          ),
                        ),
                        Positioned(
                          top: 112,
                          child: Column(
                            children: [
                              Text(
                                shownSpeed.toStringAsFixed(1),
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Mbps ${_stage == SpeedTestStage.upload ? 'UPLOAD' : 'DOWNLOAD'}',
                                style: TextStyle(
                                  color: CyberColors.subtext(context),
                                  fontSize: 10,
                                  letterSpacing: 1.1,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _resultMetric(
                          context,
                          icon: Icons.download_rounded,
                          label: 'Download',
                          value: _result?.downloadMbps ?? _liveDownload,
                          unit: 'Mbps',
                        ),
                      ),
                      Expanded(
                        child: _resultMetric(
                          context,
                          icon: Icons.upload_rounded,
                          label: 'Upload',
                          value: _result?.uploadMbps ?? _liveUpload,
                          unit: 'Mbps',
                        ),
                      ),
                      Expanded(
                        child: _resultMetric(
                          context,
                          icon: Icons.network_ping_rounded,
                          label: 'Ping',
                          value: _result?.pingMilliseconds ?? _ping,
                          unit: 'ms',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (_stage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        switch (_stage!) {
                          SpeedTestStage.ping => 'Measuring network latency',
                          SpeedTestStage.download => 'Measuring download speed',
                          SpeedTestStage.upload => 'Measuring upload speed',
                        },
                        style: TextStyle(
                          color: CyberColors.subtext(context),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isRunning ? _cancelTest : _runTest,
                      icon: Icon(
                        _isRunning
                            ? Icons.stop_circle_outlined
                            : Icons.speed_rounded,
                      ),
                      label: Text(_isRunning ? 'Cancel test' : 'Start test'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _isRunning
                            ? CyberColors.dangerRed
                            : CyberColors.techEmerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  if (_error case final error?) ...[
                    const SizedBox(height: 12),
                    Text(
                      error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: CyberColors.dangerRed,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This test requires internet access. Generated test data is sent to Cloudflare’s speed-test service; no shared files or chat messages are included. Ping is measured as HTTPS round-trip latency.',
              style: TextStyle(
                color: CyberColors.subtext(context),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultMetric(
    BuildContext context, {
    required IconData icon,
    required String label,
    required double? value,
    required String unit,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: CyberColors.techEmerald),
        const SizedBox(height: 5),
        Text(
          value == null ? '--' : value.toStringAsFixed(1),
          style: TextStyle(
            color: CyberColors.text(context),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '$label ($unit)',
          style: TextStyle(color: CyberColors.subtext(context), fontSize: 10),
        ),
      ],
    );
  }
}
