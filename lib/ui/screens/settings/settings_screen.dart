import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/cyber_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../services/connection/hybrid_connection_manager.dart';
import '../../../services/connection/wifi_direct_service.dart';
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
  LocalHotspotCredentials? _hotspotCredentials;
  bool _isHotspotBusy = false;
  bool _showHotspotPassword = false;

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
                value: isDark,
                activeThumbColor: CyberColors.emeraldAccent(context),
                onChanged: _setDarkMode,
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionHeader(context, 'LOCAL HOTSPOT'),
            GlassContainer(
              padding: const EdgeInsets.all(14),
              borderRadius: BorderRadius.circular(12),
              blur: 16,
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(
                      Icons.wifi_tethering_rounded,
                      color: CyberColors.primaryAccent(context),
                    ),
                    title: Text(
                      'Local-only hotspot',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: CyberColors.text(context),
                      ),
                    ),
                    subtitle: Text(
                      'Create a nearby network without internet access.',
                      style: TextStyle(
                        fontSize: 11,
                        color: CyberColors.subtext(context),
                      ),
                    ),
                    value: _hotspotCredentials != null,
                    activeThumbColor: CyberColors.emeraldAccent(context),
                    onChanged: _isHotspotBusy
                        ? null
                        : (enabled) => enabled
                            ? _startHotspot()
                            : _stopHotspot(),
                  ),
                  if (_isHotspotBusy)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    ),
                  if (_hotspotCredentials case final credentials?) ...[
                    Divider(color: CyberColors.border(context), height: 20),
                    _buildCredentialRow(context, 'Network name', credentials.ssid),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCredentialRow(
                            context,
                            'Password',
                            _showHotspotPassword
                                ? credentials.password
                                : '•' * credentials.password.length,
                          ),
                        ),
                        IconButton(
                          tooltip: _showHotspotPassword
                              ? 'Hide password'
                              : 'Show password',
                          onPressed: () => setState(
                            () => _showHotspotPassword = !_showHotspotPassword,
                          ),
                          icon: Icon(
                            _showHotspotPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Copy hotspot password',
                          onPressed: () => Clipboard.setData(
                            ClipboardData(text: credentials.password),
                          ),
                          icon: const Icon(Icons.copy_outlined),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _isHotspotBusy ? null : _regenerateHotspot,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Change password'),
                      ),
                    ),
                    Text(
                      'Changing the password restarts the hotspot; connected guests must reconnect.',
                      style: TextStyle(
                        fontSize: 11,
                        color: CyberColors.subtext(context),
                      ),
                    ),
                  ],
                ],
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

  Widget _buildCredentialRow(
    BuildContext context,
    String label,
    String value,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: CyberColors.subtext(context)),
        ),
        const SizedBox(height: 2),
        SelectableText(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: CyberColors.text(context),
          ),
        ),
      ],
    );
  }

  Future<void> _startHotspot() async {
    setState(() => _isHotspotBusy = true);
    try {
      final service = widget.connectionManager.wifiDirectService;
      final credentials = await service.startLocalOnlyHotspot();
      try {
        await service.startServer();
      } catch (_) {
        await service.stopLocalOnlyHotspot();
        rethrow;
      }
      if (mounted) {
        setState(() {
          _hotspotCredentials = credentials;
          _showHotspotPassword = false;
        });
      }
    } catch (error) {
      _showHotspotError(error);
    } finally {
      if (mounted) setState(() => _isHotspotBusy = false);
    }
  }

  Future<void> _regenerateHotspot() async {
    setState(() => _isHotspotBusy = true);
    try {
      final credentials = await widget.connectionManager.wifiDirectService
          .regenerateLocalOnlyHotspotPassword();
      if (mounted) {
        setState(() {
          _hotspotCredentials = credentials;
          _showHotspotPassword = false;
        });
      }
    } catch (error) {
      _showHotspotError(error);
    } finally {
      if (mounted) setState(() => _isHotspotBusy = false);
    }
  }

  Future<void> _stopHotspot() async {
    setState(() => _isHotspotBusy = true);
    try {
      final service = widget.connectionManager.wifiDirectService;
      try {
        await service.stopLocalOnlyHotspot();
      } finally {
        await service.stopServer();
      }
      if (mounted) {
        setState(() {
          _hotspotCredentials = null;
          _showHotspotPassword = false;
        });
      }
    } catch (error) {
      _showHotspotError(error);
    } finally {
      if (mounted) setState(() => _isHotspotBusy = false);
    }
  }

  void _showHotspotError(Object error) {
    if (!mounted) return;
    final message = error is MissingPluginException
        ? 'Local hotspot controls are available on Android. On other devices, use the system Wi-Fi hotspot settings.'
        : 'Could not update the local hotspot: $error';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _setDarkMode(bool enabled) async {
    try {
      await ThemeController.instance.setThemeMode(
        enabled ? ThemeMode.dark : ThemeMode.light,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save theme preference: $error')),
      );
    }
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
