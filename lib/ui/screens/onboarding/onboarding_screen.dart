import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/user_friendly_strings.dart';
import '../../../core/theme/cyber_colors.dart';
import '../../../services/connection/hybrid_connection_manager.dart';
import '../../common_widgets/branded_app_logo.dart';
import '../../common_widgets/custom_cyber_icons.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final HybridConnectionManager connectionManager;

  const OnboardingScreen({super.key, required this.connectionManager});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'useLogo': true,
      'title': UserFriendlyStrings.appTagline,
      'desc': 'Share videos, photos, and files in seconds with nearby phones & PCs. No internet or data needed.',
      'color': CyberColors.techEmerald,
    },
    {
      'useLogo': false,
      'iconType': CyberIconType.speedometer,
      'title': 'Set Speed & Data Limits',
      'desc': 'Control transfer speed per device with an interactive speed dial to keep your phone smooth and cool.',
      'color': CyberColors.electricCyan,
    },
    {
      'useLogo': false,
      'iconType': CyberIconType.chat,
      'title': 'Chat & Share Links Offline',
      'desc': 'Chat with connected friends, send emojis, and sync copied links without any internet connection.',
      'color': CyberColors.cyberViolet,
    },
  ];

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberColors.oledBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _finishOnboarding,
            child: const Text('Skip', style: TextStyle(color: CyberColors.electricCyan, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  final isLogo = slide['useLogo'] == true;
                  final color = slide['color'] as Color;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isLogo)
                          const BrandedAppLogo(size: 96)
                        else
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: CyberColors.darkSurface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: color, width: 2),
                            ),
                            child: Center(
                              child: CyberIcon(
                                type: slide['iconType'] as CyberIconType,
                                size: 44,
                                color: color,
                              ),
                            ),
                          ),
                        const SizedBox(height: 32),
                        Text(
                          slide['title'] as String,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: CyberColors.textPrimary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide['desc'] as String,
                          style: const TextStyle(fontSize: 13, height: 1.45, color: CyberColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Pagination Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => Container(
                  width: _currentPage == index ? 22 : 8,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _currentPage == index ? CyberColors.electricCyan : CyberColors.borderOutline,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Action Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _slides.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _finishOnboarding();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CyberColors.electricCyan,
                    foregroundColor: CyberColors.oledBlack,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
