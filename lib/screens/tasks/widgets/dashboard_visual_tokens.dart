import 'package:flutter/material.dart';
import 'package:habit_up/theme/app_spacing.dart';

abstract final class DashboardVisualTokens {
  static const double cardRadius = 22;
  static const double avatarSize = 44;
  static const double ringStroke = 7;
  static const double ringSmallSize = 66;
  static const double ringLargeSize = 124;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.xl,
    vertical: AppSpacing.lg,
  );

  static const EdgeInsets cardPadding = EdgeInsets.all(AppSpacing.md);

  static const LinearGradient headerGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0x1A00E5FF),
      Color(0x1200F5A0),
      Color(0x08080A12),
    ],
  );

  static const Color mutedText = Color(0xFF9AA0B2);

  static BoxDecoration panelDecoration({
    required Color borderColor,
    required Color glowColor,
    required ColorScheme colorScheme,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(cardRadius),
      border: Border.all(color: borderColor),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          colorScheme.surface.withValues(alpha: 0.95),
          colorScheme.surface.withValues(alpha: 0.85),
          colorScheme.surface.withValues(alpha: 0.75),
        ],
      ),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: glowColor.withValues(alpha: 0.12),
          blurRadius: 18,
          spreadRadius: -7,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: colorScheme.shadow.withValues(alpha: 0.16),
          blurRadius: 14,
          spreadRadius: -8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
