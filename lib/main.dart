import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_constants.dart';
import 'services/connection/hybrid_connection_manager.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/onboarding/onboarding_screen.dart';
import 'ui/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure system navigation & status bar colors for flat aesthetics
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0B0E14),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  final isFirstLaunchDone = prefs.getBool(AppConstants.keyFirstLaunch) ?? false;

  runApp(NextToMeApp(isFirstLaunchDone: isFirstLaunchDone));
}

class NextToMeApp extends StatefulWidget {
  final bool isFirstLaunchDone;

  const NextToMeApp({super.key, this.isFirstLaunchDone = true});

  @override
  State<NextToMeApp> createState() => _NextToMeAppState();
}

class _NextToMeAppState extends State<NextToMeApp> {
  late final HybridConnectionManager _connectionManager;

  @override
  void initState() {
    super.initState();
    _connectionManager = HybridConnectionManager();
  }

  @override
  void dispose() {
    _connectionManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _connectionManager,
      builder: (context, child) {
        return MaterialApp(
          title: 'NextToMe',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark, // Default to Dark OLED
          home: widget.isFirstLaunchDone
              ? HomeScreen(connectionManager: _connectionManager)
              : OnboardingScreen(connectionManager: _connectionManager),
        );
      },
    );
  }
}
