import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/connection/hybrid_connection_manager.dart';
import 'ui/screens/home_screen.dart';
import 'ui/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure system navigation bar & status bar colors for OLED Dark aesthetic
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0B0E14),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const NextToMeApp());
}

class NextToMeApp extends StatefulWidget {
  const NextToMeApp({super.key});

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
          title: 'NextToMe P2P',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: HomeScreen(connectionManager: _connectionManager),
        );
      },
    );
  }
}
