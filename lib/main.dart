import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visionaid/core/theme/app_theme.dart';
import 'package:visionaid/features/onboarding/onboarding_screen.dart';
import 'package:visionaid/features/camera/camera_screen.dart';
import 'package:visionaid/core/providers/app_state_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock orientation to portrait for accessibility
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style for accessibility
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.deepNavy,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(
    const ProviderScope(
      child: VisionAidApp(),
    ),
  );
}

class VisionAidApp extends ConsumerWidget {
  const VisionAidApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasCompletedOnboarding = ref.watch(hasCompletedOnboardingProvider);
    
    return MaterialApp(
      title: 'VisionAid',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // High contrast by default
      home: hasCompletedOnboarding.when(
        data: (completed) => completed 
            ? const CameraScreen() 
            : const OnboardingScreen(),
        loading: () => const SplashScreen(),
        error: (_, __) => const OnboardingScreen(),
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App icon placeholder
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.accessibilityTeal,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.visibility,
                size: 60,
                color: Colors.white,
                semanticLabel: 'VisionAid Logo',
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'VisionAid',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
              semanticsLabel: 'VisionAid - Loading',
            ),
            const SizedBox(height: 8),
            Text(
              'Your AI Eyes',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.accessibilityTeal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
