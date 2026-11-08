import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'cyber_colors.dart';

/// Reactive Theme Controller managing Dark and Light mode state and persistence
class ThemeController extends ChangeNotifier {
  static final ThemeController instance = ThemeController._internal();

  ThemeMode _themeMode = ThemeMode.dark;

  ThemeController._internal();

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Initialize theme mode from SharedPreferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(AppConstants.keyDarkMode) ?? true;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
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
    _themeMode = mode;
    _updateSystemOverlay();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyDarkMode, _themeMode == ThemeMode.dark);
  }

  void _updateSystemOverlay() {
    final isDark = _themeMode == ThemeMode.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark ? CyberColors.oledBlack : const Color(0xFFF6F8FA),
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }
}
