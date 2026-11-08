import 'package:flutter/material.dart';
import '../../../core/theme/cyber_colors.dart';
import '../../../services/connection/hybrid_connection_manager.dart';
import '../../common_widgets/custom_cyber_icons.dart';

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
    final cm = widget.connectionManager;

    return Scaffold(
      backgroundColor: CyberColors.oledBlack,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: CyberColors.darkSurface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section: Device Profile
          _buildSectionHeader('DEVICE IDENTITY'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CyberColors.darkSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: CyberColors.borderOutline),
            ),
            child: Row(
              children: [
                const CyberIcon(type: CyberIconType.phone, size: 22, color: CyberColors.electricCyan),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Device Nickname', style: TextStyle(fontSize: 11, color: CyberColors.textSecondary)),
                      Text(cm.localDeviceName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: CyberColors.textPrimary)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: CyberColors.textSecondary),
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
              color: CyberColors.darkSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: CyberColors.borderOutline),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('🌿 Eco Mode (Battery Saver)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: CyberColors.textPrimary)),
                  subtitle: const Text(
                    'Halts radar animations and throttles background polling to save battery.',
                    style: TextStyle(fontSize: 11, color: CyberColors.textSecondary),
                  ),
                  value: cm.isEcoMode,
                  activeThumbColor: CyberColors.techEmerald,
                  onChanged: (val) {
                    cm.toggleEcoMode();
                    setState(() {});
                  },
                ),
                const Divider(color: CyberColors.borderOutline, height: 1),
                const ListTile(
                  title: Text('Zero-Copy Socket Transfer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: CyberColors.textPrimary)),
                  subtitle: Text('Kernel-level sendfile() enabled for high-speed file streaming.', style: TextStyle(fontSize: 11, color: CyberColors.electricCyan)),
                  trailing: Icon(Icons.check_circle_outline, color: CyberColors.techEmerald, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Security
          _buildSectionHeader('SECURITY & CONNECTION ACCESS'),
          Container(
            decoration: BoxDecoration(
              color: CyberColors.darkSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: CyberColors.borderOutline),
            ),
            child: SwitchListTile(
              title: const Text('4-Digit PIN Verification', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: CyberColors.textPrimary)),
              subtitle: Text(
                _isPinProtected ? 'Active (PIN: $_pinCode)' : 'Incoming transfers accept automatically',
                style: const TextStyle(fontSize: 11, color: CyberColors.textSecondary),
              ),
              value: _isPinProtected,
              activeThumbColor: CyberColors.electricCyan,
              onChanged: (val) {
                setState(() => _isPinProtected = val);
              },
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
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: CyberColors.electricCyan,
        ),
      ),
    );
  }

  void _editDeviceName(BuildContext context) {
    final controller = TextEditingController(text: widget.connectionManager.localDeviceName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberColors.oledBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: CyberColors.borderOutline),
        ),
        title: const Text('Rename Device', style: TextStyle(color: CyberColors.textPrimary, fontSize: 15)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: CyberColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'New Name',
            labelStyle: TextStyle(color: CyberColors.electricCyan),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: CyberColors.electricCyan)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: CyberColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                widget.connectionManager.renameLocalDevice(controller.text.trim());
                setState(() {});
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: CyberColors.electricCyan, foregroundColor: CyberColors.oledBlack),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
