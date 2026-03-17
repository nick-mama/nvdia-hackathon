import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visionaid/core/constants/app_constants.dart';
import 'package:visionaid/core/theme/app_theme.dart';
import 'package:visionaid/features/camera/camera_screen.dart';
import 'package:visionaid/features/tts/tts_service.dart';

/// Onboarding Screen - Audio-guided tutorial
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<OnboardingPage> _pages = [
    const OnboardingPage(
      title: 'Welcome to VisionAid',
      description: 'Your AI-powered accessibility companion. VisionAid helps you understand your surroundings, read text, and navigate safely.',
      icon: Icons.visibility,
      spokenText: 'Welcome to VisionAid. Your AI accessibility companion. Swipe right to continue.',
    ),
    const OnboardingPage(
      title: 'Gesture Controls',
      description: 'Double tap to describe your surroundings. Single tap to read text. Swipe up to change modes. Swipe down to repeat the last message.',
      icon: Icons.touch_app,
      spokenText: 'Double tap to describe surroundings. Single tap to read text. Swipe up to change modes. Swipe right to continue.',
    ),
    const OnboardingPage(
      title: 'Stay Safe',
      description: 'VisionAid will alert you to obstacles and hazards. Critical warnings will interrupt other audio. Always use caution in unfamiliar environments.',
      icon: Icons.shield,
      spokenText: 'VisionAid will alert you to hazards automatically. Swipe right to start.',
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    _initializeTtsAndSpeak();
  }
  
  Future<void> _initializeTtsAndSpeak() async {
    await ref.read(ttsServiceProvider).initialize();
    _speakCurrentPage();
  }
  
  void _speakCurrentPage() {
    ref.read(ttsServiceProvider).speak(
      _pages[_currentPage].spokenText,
      priority: AlertPriority.info,
    );
  }
  
  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      HapticFeedback.selectionClick();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }
  
  void _previousPage() {
    if (_currentPage > 0) {
      HapticFeedback.selectionClick();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  Future<void> _completeOnboarding() async {
    HapticFeedback.mediumImpact();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingCompleteKey, true);
    
    await ref.read(ttsServiceProvider).speak(
      'Setup complete. VisionAid is ready.',
      priority: AlertPriority.warning,
    );
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CameraScreen()),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: SafeArea(
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity != null) {
              if (details.primaryVelocity! < -500) {
                _nextPage();
              } else if (details.primaryVelocity! > 500) {
                _previousPage();
              }
            }
          },
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Semantics(
                  button: true,
                  label: 'Skip onboarding',
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'Skip',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.accessibilityTeal,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                    _speakCurrentPage();
                  },
                  itemBuilder: (context, index) => _OnboardingPageWidget(
                    page: _pages[index],
                  ),
                ),
              ),
              
              // Page indicators
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => Semantics(
                      label: 'Page ${index + 1} of ${_pages.length}${index == _currentPage ? ", current" : ""}',
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: index == _currentPage ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: index == _currentPage
                              ? AppColors.accessibilityTeal
                              : AppColors.accessibilityTeal.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Navigation buttons
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    if (_currentPage > 0)
                      Expanded(
                        child: Semantics(
                          button: true,
                          label: 'Go to previous page',
                          child: OutlinedButton(
                            onPressed: _previousPage,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.accessibilityTeal,
                              side: const BorderSide(color: AppColors.accessibilityTeal),
                              minimumSize: const Size(44, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Previous'),
                          ),
                        ),
                      ),
                    if (_currentPage > 0) const SizedBox(width: 16),
                    Expanded(
                      flex: _currentPage == 0 ? 1 : 1,
                      child: Semantics(
                        button: true,
                        label: _currentPage == _pages.length - 1
                            ? 'Complete setup and start using VisionAid'
                            : 'Go to next page',
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(44, 56),
                          ),
                          child: Text(
                            _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final String spokenText;
  
  const OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.spokenText,
  });
}

class _OnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;
  
  const _OnboardingPageWidget({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.accessibilityTeal.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accessibilityTeal,
                width: 3,
              ),
            ),
            child: Icon(
              page.icon,
              size: 56,
              color: AppColors.accessibilityTeal,
              semanticLabel: page.title,
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Title
          Semantics(
            header: true,
            child: Text(
              page.title,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Description
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white70,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
