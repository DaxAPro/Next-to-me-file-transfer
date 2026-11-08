import 'package:flutter/material.dart';
import '../../../core/theme/cyber_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../services/connection/hybrid_connection_manager.dart';
import '../../common_widgets/custom_cyber_icons.dart';
import '../../common_widgets/glass_background.dart';
import '../../common_widgets/glass_container.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: CyberColors.background(context),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: CyberColors.surface(context),
        elevation: 0,
      ),
      body: GlassBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Section: Appearance & Theme Mode
            _buildSectionHeader(context, 'APPEARANCE & THEME'),
            GlassContainer(
              borderRadius: BorderRadius.circular(12),
              blur: 16,
              child: SwitchListTile(
                secondary: Icon(
                  isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                  color: CyberColors.primaryAccent(context),
                ),
                title: Text(
                  'Dark Mode',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: CyberColors.text(context),
                  ),
                ),
                subtitle: Text(
                  isDark ? 'OLED Black Cyber Theme' : 'Clean Pearl White Theme',
                  style: TextStyle(fontSize: 11, color: CyberColors.subtext(context)),
                ),
                value: ThemeController.instance.isDarkMode,
                activeThumbColor: CyberColors.emeraldAccent(context),
                onChanged: (val) {
                  ThemeController.instance.toggleTheme();
                  setState(() {});
                },
              ),
            ),
            const SizedBox(height: 20),

            // Section: Device Profile
            _buildSectionHeader(context, 'DEVICE PROFILE'),
            GlassContainer(
              padding: const EdgeInsets.all(14),
              borderRadius: BorderRadius.circular(12),
              blur: 16,
              child: Row(
                children: [
                  CyberIcon(type: CyberIconType.phone, size: 22, color: CyberColors.primaryAccent(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Device Nickname', style: TextStyle(fontSize: 11, color: CyberColors.subtext(context))),
                        Text(
                          cm.localDeviceName,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: CyberColors.text(context)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_outlined, size: 20, color: CyberColors.subtext(context)),
                    onPressed: () => _editDeviceName(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section: Performance & Battery
            _buildSectionHeader(context, 'BATTERY & PERFORMANCE'),
            GlassContainer(
              borderRadius: BorderRadius.circular(12),
              blur: 16,
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      '🌿 Battery Saver',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: CyberColors.text(context)),
                    ),
                    subtitle: Text(
                      'Slows down radar scans to save phone battery.',
                      style: TextStyle(fontSize: 11, color: CyberColors.subtext(context)),
                    ),
                    value: cm.isEcoMode,
                    activeThumbColor: CyberColors.emeraldAccent(context),
                    onChanged: (val) {
                      cm.toggleEcoMode();
                      setState(() {});
                    },
                  ),
                  Divider(color: CyberColors.border(context), height: 1),
                  ListTile(
                    title: Text(
                      'Fast Direct File Sharing',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: CyberColors.text(context)),
                    ),
                    subtitle: Text(
                      'Transfers files smoothly without heating up your phone.',
                      style: TextStyle(fontSize: 11, color: CyberColors.primaryAccent(context)),
                    ),
                    trailing: Icon(Icons.check_circle_outline, color: CyberColors.emeraldAccent(context), size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section: Security
            _buildSectionHeader(context, 'SECURITY & CONNECTION ACCESS'),
            GlassContainer(
              borderRadius: BorderRadius.circular(12),
              blur: 16,
              child: SwitchListTile(
                title: Text(
                  '4-Digit PIN Verification',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: CyberColors.text(context)),
                ),
                subtitle: Text(
                  _isPinProtected ? 'Active (PIN: $_pinCode)' : 'Incoming transfers accept automatically',
                  style: TextStyle(fontSize: 11, color: CyberColors.subtext(context)),
                ),
                value: _isPinProtected,
                activeThumbColor: CyberColors.primaryAccent(context),
                onChanged: (val) {
                  setState(() => _isPinProtected = val);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: CyberColors.primaryAccent(context),
        ),
      ),
    );
  }

  void _editDeviceName(BuildContext context) {
    final controller = TextEditingController(text: widget.connectionManager.localDeviceName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberColors.surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: CyberColors.border(context)),
        ),
        title: Text('Rename Device', style: TextStyle(color: CyberColors.text(context), fontSize: 15)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: CyberColors.text(context)),
          decoration: InputDecoration(
            labelText: 'New Name',
            labelStyle: TextStyle(color: CyberColors.primaryAccent(context)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: CyberColors.primaryAccent(context))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: CyberColors.subtext(context))),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                widget.connectionManager.renameLocalDevice(controller.text.trim());
                setState(() {});
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberColors.primaryAccent(context),
              foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
