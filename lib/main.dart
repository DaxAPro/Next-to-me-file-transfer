import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/theme_controller.dart';
import 'services/connection/hybrid_connection_manager.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/onboarding/onboarding_screen.dart';
import 'ui/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize theme mode preference
  await ThemeController.instance.init();

  final prefs = await SharedPreferences.getInstance();
  // On app launch, check isFirstTimeLaunch (default: true)
  final isFirstTimeLaunch = prefs.getBool(AppConstants.keyIsFirstTimeLaunch) ??
      (prefs.getBool(AppConstants.keyFirstLaunch) != null
          ? !prefs.getBool(AppConstants.keyFirstLaunch)!
          : true);

  runApp(NextToMeApp(
    isFirstTimeLaunch: isFirstTimeLaunch,
    isFirstLaunchDone: !isFirstTimeLaunch,
  ));
}

class NextToMeApp extends StatefulWidget {
  final bool isFirstLaunchDone;
  final bool? isFirstTimeLaunch;

  const NextToMeApp({
    super.key,
    this.isFirstLaunchDone = true,
    this.isFirstTimeLaunch,
  });

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
    final showOnboarding = widget.isFirstTimeLaunch ?? !widget.isFirstLaunchDone;

    return ListenableBuilder(
      listenable: Listenable.merge([_connectionManager, ThemeController.instance]),
      builder: (context, child) {
        return MaterialApp(
          title: 'NextToMe',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeController.instance.themeMode,
          themeAnimationDuration: const Duration(milliseconds: 350),
          themeAnimationCurve: Curves.easeInOutCubic,
          home: showOnboarding
              ? OnboardingScreen(connectionManager: _connectionManager)
              : HomeScreen(connectionManager: _connectionManager),
        );
      },
    );
  }
}
