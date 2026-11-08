import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/connection/hybrid_connection_manager.dart';
import '../home_screen.dart';

/// 4-Step Welcome Onboarding Screen Slider
/// Displayed ONLY on the very first launch of the application.
class OnboardingScreen extends StatefulWidget {
  final HybridConnectionManager connectionManager;

  const OnboardingScreen({super.key, required this.connectionManager});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Exact 4-step onboarding image assets in strict sequence
  static const List<String> _slides = [
    'assets/images/image_21.png', // Step 1: Welcome to NextToMe
    'assets/images/image_22.png', // Step 2: Set Speed & Data Limits
    'assets/images/image_27.png', // Step 3: 100% Private & Safe
    'assets/images/image_24.png', // Step 4: Offline Group Chat
  ];

  /// Saves first-time launch flags and navigates to the Radar dashboard.
  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsFirstTimeLaunch, false);
    await prefs.setBool(AppConstants.keyFirstLaunch, true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(connectionManager: widget.connectionManager),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const emeraldGreen = Color(0xFF10B981);
    const lightGrey = Color(0xFFE0E0E0);
    const pureWhite = Color(0xFFFFFFFF);

    return Scaffold(
      backgroundColor: pureWhite,
      body: Stack(
        children: [
          // 1. Swipeable ViewPager Slider for 9:16 Portrait Images
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return Container(
                color: pureWhite,
                width: double.infinity,
                height: double.infinity,
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
                        child: Image.asset(
                          _slides[index],
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.image_outlined, size: 64, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                    ),
                    // Reserve bottom space for the native overlay layer
                    const SizedBox(height: 130),
                  ],
                ),
              );
            },
          ),

          // 2. Top Overlay Layer: Skip Button (Visible on Screens 1, 2, 3)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_currentPage < 3)
                      TextButton(
                        onPressed: _finishOnboarding,
                        style: TextButton.styleFrom(
                          foregroundColor: emeraldGreen,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: emeraldGreen,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Bottom Overlay Layer: Indicator Dots & Action Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                color: pureWhite,
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 20, top: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Step Progress Indicator: 4 Circular Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        final isSelected = _currentPage == index;
                        return Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? emeraldGreen : lightGrey,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),

                    // Full-Width Flat Rounded Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentPage < 3) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _finishOnboarding();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: emeraldGreen,
                          foregroundColor: pureWhite,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _currentPage == 3 ? 'Get Started' : 'Next ➔',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: pureWhite,
                          ),
                        ),
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
