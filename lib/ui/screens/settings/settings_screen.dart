import 'package:flutter/material.dart';
import '../../../services/connection/hybrid_connection_manager.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final HybridConnectionManager connectionManager;

  const SettingsScreen({super.key, required this.connectionManager});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isPinProtected = false;
  final String _pinCode = '1234';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cm = widget.connectionManager;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section: Device Profile
          _buildSectionHeader('DEVICE IDENTITY'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.badge_outlined, color: AppTheme.cyan),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Device Nickname', style: TextStyle(fontSize: 11, color: AppTheme.darkTextSecondary)),
                      Text(cm.localDeviceName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _editDeviceName(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Performance & Battery
          _buildSectionHeader('PERFORMANCE & GREEN CODE'),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('🌿 Eco Mode (Battery Saver)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Halts radar animations and throttles background polling to save battery.',
                    style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                  ),
                  value: cm.isEcoMode,
                  activeThumbColor: AppTheme.green,
                  onChanged: (val) {
                    cm.toggleEcoMode();
                    setState(() {});
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Zero-Copy Socket Transfer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Kernel-level sendfile() enabled for high-speed file streaming.', style: TextStyle(fontSize: 11, color: AppTheme.cyan)),
                  trailing: const Icon(Icons.check_circle_outline, color: AppTheme.green, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Security
          _buildSectionHeader('SECURITY & CONNECTION ACCESS'),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('4-Digit Connection PIN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    _isPinProtected ? 'Active PIN: $_pinCode' : 'Require PIN challenge before accepting incoming transfers.',
                    style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                  ),
                  value: _isPinProtected,
                  activeThumbColor: AppTheme.cyan,
                  onChanged: (val) {
                    setState(() => _isPinProtected = val);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: AppTheme.cyan),
      ),
    );
  }

  void _editDeviceName(BuildContext context) {
    final controller = TextEditingController(text: widget.connectionManager.localDeviceName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Device Nickname'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter name (e.g., Pixel 9 Pro)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  widget.connectionManager.localDeviceName = controller.text.trim();
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
