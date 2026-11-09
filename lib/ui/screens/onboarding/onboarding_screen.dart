import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/cyber_colors.dart';
import '../../../services/connection/hybrid_connection_manager.dart';
import '../home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final HybridConnectionManager connectionManager;

  const OnboardingScreen({super.key, required this.connectionManager});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const List<String> _slides = [
    'assets/images/image_21.png',
    'assets/images/image_22.png',
    'assets/images/image_27.png',
    'assets/images/image_24.png',
  ];

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isFinishing = false;

  Future<void> _finishOnboarding() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyHasSeenOnboarding, true);
    await prefs.setBool(AppConstants.keyIsFirstTimeLaunch, false);
    await prefs.setBool(AppConstants.keyFirstLaunch, true);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(connectionManager: widget.connectionManager),
      ),
    );
  }

  void _advancePage() {
    if (_currentPage == _slides.length - 1) {
      _finishOnboarding();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const darkSlate = Color(0xFF334155);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) => Image.asset(
              _slides[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const ColoredBox(
                color: CyberColors.lightBg,
                child: Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          if (_currentPage == 0)
            Center(
              child: Image.asset(
                'assets/logo.png',
                width: 160,
                height: 160,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: TextButton(
                  onPressed: _isFinishing ? null : _finishOnboarding,
                  style: TextButton.styleFrom(foregroundColor: darkSlate),
                  child: const Text('Skip'),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(_slides.length, (index) {
                        final isActive = index == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isActive ? 24 : 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: isActive
                                ? CyberColors.techEmeraldGreen
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                    ElevatedButton(
                      onPressed: _isFinishing ? null : _advancePage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CyberColors.techEmeraldGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentPage == _slides.length - 1
                            ? 'Get Started'
                            : 'Next ➔',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
