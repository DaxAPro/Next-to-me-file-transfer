import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/cyber_colors.dart';
import '../../../services/connection/hybrid_connection_manager.dart';
import '../home_screen.dart';

class LocalProfileSetupScreen extends StatefulWidget {
  final HybridConnectionManager connectionManager;

  const LocalProfileSetupScreen({super.key, required this.connectionManager});

  @override
  State<LocalProfileSetupScreen> createState() =>
      _LocalProfileSetupScreenState();
}

class _LocalProfileSetupScreenState extends State<LocalProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    setState(() => _isSaving = true);
    final name = _nameController.text.trim();
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(AppConstants.keyDisplayName, name);
      widget.connectionManager.renameLocalDevice(name);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) =>
              HomeScreen(connectionManager: widget.connectionManager),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save your profile: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = CyberColors.text(context);
    return Scaffold(
      backgroundColor: CyberColors.background(context),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 56,
                      color: CyberColors.techEmerald,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Set up your local profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nearby devices will see this name when you connect or chat.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: CyberColors.subtext(context),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _nameController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 32,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _saveProfile(),
                      decoration: const InputDecoration(
                        labelText: 'Display name',
                        hintText: 'Your name',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (value) {
                        final name = value?.trim() ?? '';
                        if (name.isEmpty) return 'Enter a display name.';
                        if (name.runes.length > 32) {
                          return 'Use 32 characters or fewer.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: FilledButton.styleFrom(
                        backgroundColor: CyberColors.techEmerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Continue'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
