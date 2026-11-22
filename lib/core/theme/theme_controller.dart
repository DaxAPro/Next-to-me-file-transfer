import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'cyber_colors.dart';

/// Reactive Theme Controller managing Dark and Light mode state and persistence
class ThemeController extends ChangeNotifier {
  static final ThemeController instance = ThemeController._internal();

  ThemeMode _themeMode = ThemeMode.light;

  ThemeController._internal();

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Initialize theme mode from SharedPreferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.keyThemeMode);
    _themeMode = switch (saved) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      'light' => ThemeMode.light,
      _ => (prefs.getBool(AppConstants.keyDarkMode) ?? false)
          ? ThemeMode.dark
          : ThemeMode.light,
    };
    _updateSystemOverlay();
    notifyListeners();
  }

  /// Toggle between Dark and Light mode
  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  /// Explicitly set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.keyThemeMode,
      switch (mode) {
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
        ThemeMode.light => 'light',
      },
    );
    await prefs.setBool(AppConstants.keyDarkMode, mode == ThemeMode.dark);

    _themeMode = mode;
    _updateSystemOverlay();
    notifyListeners();
  }

  void _updateSystemOverlay() {
    final isDark = _themeMode == ThemeMode.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark ? CyberColors.oledBlack : CyberColors.lightBg,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }
}
