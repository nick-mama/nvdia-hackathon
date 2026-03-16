import 'package:flutter/material.dart';

/// VisionAid Brand Colors from PRD
class AppColors {
  // Primary
  static const Color deepNavy = Color(0xFF1A3A5C);
  
  // Accent
  static const Color accessibilityTeal = Color(0xFF00A896);
  
  // Highlight
  static const Color warmAmber = Color(0xFFF4A261);
  
  // Backgrounds
  static const Color softMint = Color(0xFFEAF6F4);
  static const Color lightGray = Color(0xFFF5F5F5);
  
  // Text
  static const Color charcoal = Color(0xFF333333);
  static const Color white = Color(0xFFFFFFFF);
  
  // Semantic colors for alerts
  static const Color danger = Color(0xFFE63946);
  static const Color warning = Color(0xFFF4A261);
  static const Color success = Color(0xFF2A9D8F);
}

/// VisionAid Typography following PRD specs
class AppTypography {
  static const String fontFamilyPrimary = 'Nunito';
  static const String fontFamilySecondary = 'NunitoSans';
  
  static TextTheme get textTheme => const TextTheme(
    // App Title / Logo - Nunito ExtraBold 32sp+
    displayLarge: TextStyle(
      fontFamily: fontFamilyPrimary,
      fontSize: 32,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
    ),
    
    // Screen Headings - Nunito Bold 22-28sp
    headlineLarge: TextStyle(
      fontFamily: fontFamilyPrimary,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.25,
    ),
    headlineMedium: TextStyle(
      fontFamily: fontFamilyPrimary,
      fontSize: 24,
      fontWeight: FontWeight.w700,
    ),
    headlineSmall: TextStyle(
      fontFamily: fontFamilyPrimary,
      fontSize: 22,
      fontWeight: FontWeight.w700,
    ),
    
    // Body / Descriptions - Nunito Sans Regular 16-18sp
    bodyLarge: TextStyle(
      fontFamily: fontFamilySecondary,
      fontSize: 18,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamilySecondary,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    
    // Captions / Labels - Nunito Sans Medium 14sp
    labelLarge: TextStyle(
      fontFamily: fontFamilySecondary,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    labelMedium: TextStyle(
      fontFamily: fontFamilySecondary,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    
    // Spoken Output UI - Nunito Sans SemiBold 18-20sp
    titleLarge: TextStyle(
      fontFamily: fontFamilySecondary,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    titleMedium: TextStyle(
      fontFamily: fontFamilySecondary,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
  );
}

/// Main App Theme
class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.deepNavy,
      secondary: AppColors.accessibilityTeal,
      tertiary: AppColors.warmAmber,
      surface: AppColors.lightGray,
      onPrimary: AppColors.white,
      onSecondary: AppColors.white,
      onSurface: AppColors.charcoal,
      error: AppColors.danger,
    ),
    scaffoldBackgroundColor: AppColors.lightGray,
    textTheme: AppTypography.textTheme.apply(
      bodyColor: AppColors.charcoal,
      displayColor: AppColors.deepNavy,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.deepNavy,
      foregroundColor: AppColors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accessibilityTeal,
        foregroundColor: AppColors.white,
        minimumSize: const Size(44, 44), // WCAG touch target
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontFamily: AppTypography.fontFamilySecondary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    cardTheme: CardTheme(
      color: AppColors.softMint,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
  
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accessibilityTeal,
      secondary: AppColors.accessibilityTeal,
      tertiary: AppColors.warmAmber,
      surface: AppColors.deepNavy,
      onPrimary: AppColors.white,
      onSecondary: AppColors.white,
      onSurface: AppColors.white,
      error: AppColors.danger,
    ),
    scaffoldBackgroundColor: AppColors.deepNavy,
    textTheme: AppTypography.textTheme.apply(
      bodyColor: AppColors.white,
      displayColor: AppColors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.deepNavy,
      foregroundColor: AppColors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accessibilityTeal,
        foregroundColor: AppColors.white,
        minimumSize: const Size(44, 44), // WCAG touch target
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontFamily: AppTypography.fontFamilySecondary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    cardTheme: CardTheme(
      color: AppColors.deepNavy.withOpacity(0.8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.accessibilityTeal.withOpacity(0.3),
          width: 1,
        ),
      ),
    ),
  );
}
