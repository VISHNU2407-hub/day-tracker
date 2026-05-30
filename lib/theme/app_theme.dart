import 'package:flutter/material.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/theme/app_text_styles.dart';

abstract final class AppTheme {
  // ── Dark Theme ──────────────────────────────────────────────────────────

  static ThemeData get dark {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.neonCyan,
      onPrimary: AppColors.background,
      primaryContainer: AppColors.neonBlue,
      onPrimaryContainer: AppColors.textPrimary,
      secondary: AppColors.neonGreen,
      onSecondary: AppColors.background,
      secondaryContainer: AppColors.surfaceHighest,
      onSecondaryContainer: AppColors.textPrimary,
      tertiary: AppColors.neonPink,
      onTertiary: AppColors.background,
      tertiaryContainer: AppColors.surfaceHighest,
      onTertiaryContainer: AppColors.textPrimary,
      error: AppColors.error,
      onError: AppColors.textPrimary,
      errorContainer: Color(0xFF4D1B26),
      onErrorContainer: AppColors.textPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceHighest,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: Color(0xFF202844),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: AppColors.textPrimary,
      onInverseSurface: AppColors.background,
      inversePrimary: AppColors.neonBlue,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppTextStyles.fontFamily,
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        labelLarge: AppTextStyles.labelLarge,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.neonCyan, width: 1.2),
        ),
      ),
      dividerColor: AppColors.border,
    );
  }

  // ── Light Theme ─────────────────────────────────────────────────────────

  static ThemeData get light {
    const lightBackground = Color(0xFFF4F6FC);
    const lightSurface = Color(0xFFFFFFFF);
    const lightSurfaceHigh = Color(0xFFF0F2F8);
    const lightTextPrimary = Color(0xFF1A1D2E);
    const lightTextSecondary = Color(0xFF6B728A);
    const lightBorder = Color(0xFFDEE2ED);

    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF00C2D4), // slightly deeper cyan for light bg
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF4D7CFF),
      onPrimaryContainer: Colors.white,
      secondary: Color(0xFF00D68F),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFE8F8F0),
      onSecondaryContainer: lightTextPrimary,
      tertiary: Color(0xFFE040C0),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFFDE8F8),
      onTertiaryContainer: lightTextPrimary,
      error: Color(0xFFE54560),
      onError: Colors.white,
      errorContainer: Color(0xFFFDE8EC),
      onErrorContainer: lightTextPrimary,
      surface: lightSurface,
      onSurface: lightTextPrimary,
      surfaceContainerHighest: lightSurfaceHigh,
      onSurfaceVariant: lightTextSecondary,
      outline: lightBorder,
      outlineVariant: Color(0xFFEFF1F6),
      shadow: Color(0x1A000000),
      scrim: Colors.black,
      inverseSurface: lightTextPrimary,
      onInverseSurface: lightSurface,
      inversePrimary: Color(0xFF00E5FF),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: lightBackground,
      fontFamily: AppTextStyles.fontFamily,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 40,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: lightTextPrimary,
          letterSpacing: 0.2,
        ),
        headlineMedium: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 1.3,
          color: lightTextPrimary,
          letterSpacing: 0.1,
        ),
        titleLarge: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: lightTextPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.35,
          color: lightTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: lightTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.45,
          color: lightTextSecondary,
        ),
        labelLarge: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: lightTextPrimary,
          letterSpacing: 0.2,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: lightBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurfaceHigh,
        hintStyle: const TextStyle(color: lightTextSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF00C2D4), width: 1.2),
        ),
      ),
      dividerColor: lightBorder,
    );
  }
}
