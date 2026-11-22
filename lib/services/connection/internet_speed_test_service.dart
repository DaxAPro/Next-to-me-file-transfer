import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

enum SpeedTestStage { ping, download, upload }

class SpeedTestProgress {
  final SpeedTestStage stage;
  final double value;

  const SpeedTestProgress({required this.stage, required this.value});
}

class SpeedTestResult {
  final double pingMilliseconds;
  final double downloadMbps;
  final double uploadMbps;

  const SpeedTestResult({
    required this.pingMilliseconds,
    required this.downloadMbps,
    required this.uploadMbps,
  });
}

class SpeedTestCancelledException implements Exception {
  const SpeedTestCancelledException();
}

class InternetSpeedTestService {
  static const int _downloadTestBytes = 20 * 1024 * 1024;
  static const int _uploadTestBytes = 8 * 1024 * 1024;
  static const int _chunkSize = 64 * 1024;
  static const Duration _requestTimeout = Duration(seconds: 30);

  HttpClient? _client;
  bool _isCancelled = false;

  Future<SpeedTestResult> run({
    required ValueChanged<SpeedTestProgress> onProgress,
  }) async {
    if (_client != null) {
      throw StateError('A speed test is already running.');
    }

    _isCancelled = false;
    final client = HttpClient()..connectionTimeout = _requestTimeout;
    _client = client;
    try {
      final ping = await _measurePing(client, onProgress);
      _ensureNotCancelled();
      final download = await _measureDownload(client, onProgress);
      _ensureNotCancelled();
      final upload = await _measureUpload(client, onProgress);
      return SpeedTestResult(
        pingMilliseconds: ping,
        downloadMbps: download,
        uploadMbps: upload,
      );
    } on SocketException catch (error) {
      if (_isCancelled) throw const SpeedTestCancelledException();
      throw StateError(
        'Could not reach the internet speed-test service. Check your connection. $error',
      );
    } on TimeoutException {
      if (_isCancelled) throw const SpeedTestCancelledException();
      throw StateError(
        'The speed test timed out. Try again on a stable network.',
      );
    } on HttpException {
      if (_isCancelled) throw const SpeedTestCancelledException();
      rethrow;
    } finally {
      client.close(force: true);
      _client = null;
    }
  }

  void cancel() {
    _isCancelled = true;
    _client?.close(force: true);
  }

  Future<double> _measurePing(
    HttpClient client,
    ValueChanged<SpeedTestProgress> onProgress,
  ) async {
    final samples = <double>[];
    for (var index = 0; index < 3; index++) {
      _ensureNotCancelled();
      final stopwatch = Stopwatch()..start();
      final request = await client
          .getUrl(
            Uri.https('speed.cloudflare.com', '/cdn-cgi/trace', {
              'probe': '${DateTime.now().microsecondsSinceEpoch}-$index',
            }),
          )
          .timeout(_requestTimeout);
      final response = await request.close().timeout(_requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await response.drain<void>();
        throw HttpException(
          'Ping request failed with HTTP ${response.statusCode}.',
        );
      }
      await response.drain<void>();
      stopwatch.stop();
      final latency = stopwatch.elapsedMicroseconds / 1000;
      samples.add(latency);
      onProgress(SpeedTestProgress(stage: SpeedTestStage.ping, value: latency));
    }
    samples.sort();
    return samples[samples.length ~/ 2];
  }

  Future<double> _measureDownload(
    HttpClient client,
    ValueChanged<SpeedTestProgress> onProgress,
  ) async {
    final request = await client
        .getUrl(
          Uri.https('speed.cloudflare.com', '/__down', {
            'bytes': '$_downloadTestBytes',
            'cache': '${DateTime.now().microsecondsSinceEpoch}',
          }),
        )
        .timeout(_requestTimeout);
    final response = await request.close().timeout(_requestTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      await response.drain<void>();
      throw HttpException(
        'Download test failed with HTTP ${response.statusCode}.',
      );
    }

    final stopwatch = Stopwatch()..start();
    var receivedBytes = 0;
    var lastUpdate = Duration.zero;
    await for (final chunk in response.timeout(_requestTimeout)) {
      _ensureNotCancelled();
      receivedBytes += chunk.length;
      if (stopwatch.elapsed - lastUpdate >= const Duration(milliseconds: 150)) {
        lastUpdate = stopwatch.elapsed;
        onProgress(
          SpeedTestProgress(
            stage: SpeedTestStage.download,
            value: _megabitsPerSecond(receivedBytes, stopwatch.elapsed),
          ),
        );
      }
    }
    stopwatch.stop();
    if (receivedBytes == 0) {
      throw const FormatException('The speed-test service returned no data.');
    }
    final speed = _megabitsPerSecond(receivedBytes, stopwatch.elapsed);
    onProgress(SpeedTestProgress(stage: SpeedTestStage.download, value: speed));
    return speed;
  }

  Future<double> _measureUpload(
    HttpClient client,
    ValueChanged<SpeedTestProgress> onProgress,
  ) async {
    final request = await client
        .postUrl(Uri.https('speed.cloudflare.com', '/__up'))
        .timeout(_requestTimeout);
    request.headers.contentType = ContentType.binary;
    request.contentLength = _uploadTestBytes;
    final chunk = Uint8List(_chunkSize);
    final stopwatch = Stopwatch()..start();
    var sentBytes = 0;
    var lastUpdate = Duration.zero;
    while (sentBytes < _uploadTestBytes) {
      _ensureNotCancelled();
      final length = (_uploadTestBytes - sentBytes).clamp(0, chunk.length);
      request.add(length == chunk.length ? chunk : chunk.sublist(0, length));
      sentBytes += length;
      if (stopwatch.elapsed - lastUpdate >= const Duration(milliseconds: 150)) {
        lastUpdate = stopwatch.elapsed;
        onProgress(
          SpeedTestProgress(
            stage: SpeedTestStage.upload,
            value: _megabitsPerSecond(sentBytes, stopwatch.elapsed),
          ),
        );
      }
      await Future<void>.delayed(Duration.zero);
    }
    final response = await request.close().timeout(_requestTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = await response
          .transform(const SystemEncoding().decoder)
          .join();
      throw HttpException(
        'Upload test failed with HTTP ${response.statusCode}: $body',
      );
    }
    await response.drain<void>();
    stopwatch.stop();
    final speed = _megabitsPerSecond(sentBytes, stopwatch.elapsed);
    onProgress(SpeedTestProgress(stage: SpeedTestStage.upload, value: speed));
    return speed;
  }

  double _megabitsPerSecond(int bytes, Duration elapsed) {
    final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    if (seconds <= 0) return 0;
    return bytes * 8 / seconds / 1000000;
  }

  void _ensureNotCancelled() {
    if (_isCancelled) throw const SpeedTestCancelledException();
  }
}
