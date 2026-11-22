import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/cyber_colors.dart';
import '../../../services/connection/hybrid_connection_manager.dart';
import '../../../services/connection/local_web_server_service.dart';

class LocalWebPortalScreen extends StatefulWidget {
  final HybridConnectionManager connectionManager;

  const LocalWebPortalScreen({super.key, required this.connectionManager});

  @override
  State<LocalWebPortalScreen> createState() => _LocalWebPortalScreenState();
}

class _LocalWebPortalScreenState extends State<LocalWebPortalScreen> {
  final LocalWebServerService _server = LocalWebServerService.instance;
  Timer? _clientCountTimer;
  bool _isBusy = false;
  int _clientCount = 0;

  @override
  void initState() {
    super.initState();
    _clientCount = _server.connectedBrowserCount;
    _clientCountTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_server.connectedBrowserCount != _clientCount && mounted) {
        setState(() => _clientCount = _server.connectedBrowserCount);
      }
    });
  }

  @override
  void dispose() {
    _clientCountTimer?.cancel();
    super.dispose();
  }

  Future<void> _startServer() async {
    setState(() => _isBusy = true);
    try {
      final wifiService = widget.connectionManager.wifiDirectService;
      await _server.start(
        onPortalChatMessage: (message) async {
          if (wifiService.canSendChat) {
            await wifiService.sendChatMessage(message);
          }
        },
      );
      if (mounted) setState(() => _clientCount = _server.connectedBrowserCount);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start the local portal: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _stopServer() async {
    setState(() => _isBusy = true);
    try {
      await _server.stop();
      if (mounted) setState(() => _clientCount = 0);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not stop the local portal: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _copyUrl(String url) async {
    try {
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Portal link copied.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not copy the portal link: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _server.accessUrl;
    final running = _server.isRunning;
    return Scaffold(
      backgroundColor: CyberColors.background(context),
      appBar: AppBar(
        title: const Text('PC Web Portal'),
        backgroundColor: CyberColors.surface(context),
        foregroundColor: CyberColors.text(context),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: CyberColors.surface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CyberColors.border(context)),
            ),
            child: Column(
              children: [
                Icon(
                  running ? Icons.wifi_tethering_rounded : Icons.wifi_outlined,
                  size: 42,
                  color: CyberColors.techEmerald,
                ),
                const SizedBox(height: 12),
                Text(
                  running ? 'Portal is ready' : 'Share files from a computer',
                  style: TextStyle(
                    color: CyberColors.text(context),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  running
                      ? '$_clientCount browser connection${_clientCount == 1 ? '' : 's'} active'
                      : 'Start a secure local web portal for file transfer and group chat.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CyberColors.subtext(context),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isBusy
                        ? null
                        : running
                        ? _stopServer
                        : _startServer,
                    icon: Icon(
                      running ? Icons.stop_circle_outlined : Icons.play_arrow,
                    ),
                    label: Text(running ? 'Stop portal' : 'Start portal'),
                    style: FilledButton.styleFrom(
                      backgroundColor: running
                          ? CyberColors.dangerRed
                          : CyberColors.techEmerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                if (_isBusy) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(color: CyberColors.techEmerald),
                ],
              ],
            ),
          ),
          if (running && url != null) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: CyberColors.surface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: CyberColors.border(context)),
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: url,
                    size: 220,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF10241A),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF10241A),
                    ),
                    semanticsLabel: 'QR code for the NextToMe local web portal',
                  ),
                  const SizedBox(height: 14),
                  SelectableText(
                    url,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: CyberColors.text(context),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _copyUrl(url),
                    icon: const Icon(Icons.copy_outlined, size: 18),
                    label: const Text('Copy portal link'),
                  ),
                ],
              ),
            ),
          ],
          if (running && url == null) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: CyberColors.warningAmber),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'The server is running, but no private IPv4 address is available to create a shareable link. Connect to Wi-Fi or enable the local hotspot and try again.',
                style: TextStyle(fontSize: 12, height: 1.5),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CyberColors.surface(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CyberColors.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Before you connect',
                  style: TextStyle(
                    color: CyberColors.text(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Connect the computer to the same Wi-Fi network or this phone’s local hotspot, then scan the QR code. The access link contains a private session token; share it only with people you trust. Files and chat stay on the local network.',
                  style: TextStyle(
                    color: CyberColors.subtext(context),
                    fontSize: 12,
                    height: 1.55,
                  ),
                ),
                if (_server.mdnsError case final error?) ...[
                  const SizedBox(height: 10),
                  Text(
                    '$error Use the displayed network address if available.',
                    style: const TextStyle(
                      color: CyberColors.warningAmber,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'The portal accepts uploads up to 2 GB and supports real-time group chat.',
                  style: TextStyle(
                    color: CyberColors.subtext(context),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
