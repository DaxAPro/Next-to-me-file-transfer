import 'package:flutter/material.dart';

import '../../../core/theme/cyber_colors.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberColors.background(context),
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
        backgroundColor: CyberColors.surface(context),
        foregroundColor: CyberColors.text(context),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _section(
            context,
            'Using NextToMe',
            'NextToMe provides local peer-to-peer file transfers and '
                'communication over a Wi-Fi, Wi-Fi Direct, or hotspot network. '
                'You are responsible for choosing the devices and content you '
                'share and for obtaining any permissions needed to share that content.',
          ),
          _section(
            context,
            'Local transfers and chat',
            'Transfer and chat features are intended to work between nearby '
                'devices on a local network without a cloud server. Chat history '
                'and received chat images may be stored locally on this device '
                'until you delete them. Keep your hotspot credentials private '
                'and stop the hotspot when you are finished.',
          ),
          _section(
            context,
            'Web sharing portal',
            'When you start the local web portal, people with access to the '
                'same network and the portal link can upload or download files '
                'and use its chat. Share the link only with people you trust. '
                'Uploaded portal files are kept in app-local storage until you '
                'delete them or remove the app.',
          ),
          _section(
            context,
            'Internet speed test',
            'The optional Global Internet Speed Test requires an active internet '
                'connection and sends generated test data to its measurement '
                'service. It does not include your shared files or chat messages. '
                'Results vary with the network and measurement server.',
          ),
          _section(
            context,
            'Acceptable use',
            'Use NextToMe only to share content you are authorized to distribute. '
                'Do not use the app to violate another person’s rights or any '
                'applicable law. You are responsible for securing your devices '
                'and reviewing transferred files.',
          ),
          _section(
            context,
            'Availability and changes',
            'Local connectivity depends on device hardware, operating system '
                'permissions, and network configuration. Features may not be '
                'available on every device. These terms may be updated with '
                'future app releases.',
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: CyberColors.techEmerald,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            content,
            style: TextStyle(
              color: CyberColors.text(context),
              fontSize: 13,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
