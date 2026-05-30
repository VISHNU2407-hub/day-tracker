import 'package:flutter/material.dart';

/// Centralized color tokens for Habit Up's futuristic dark UI.
abstract final class AppColors {
  static const Color transparent = Colors.transparent;

  // Base dark surfaces.
  static const Color background = Color(0xFF080A12);
  static const Color surface = Color(0xFF101527);
  static const Color surfaceHigh = Color(0xFF161C33);
  static const Color surfaceHighest = Color(0xFF1E2642);

  // Neon accents.
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color neonBlue = Color(0xFF4D7CFF);
  static const Color neonGreen = Color(0xFF00F5A0);
  static const Color neonPink = Color(0xFFFF4FD8);

  // Utility colors.
  static const Color textPrimary = Color(0xFFF2F5FF);
  static const Color textSecondary = Color(0xFFB7C0DD);
  static const Color border = Color(0xFF283354);
  static const Color success = Color(0xFF21D19F);
  static const Color warning = Color(0xFFFFC857);
  static const Color error = Color(0xFFFF5D73);
}
