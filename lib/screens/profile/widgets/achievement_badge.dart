import 'package:flutter/material.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/theme/app_text_styles.dart';

/// A glowing achievement badge for the profile's rewards preview.
class AchievementBadge extends StatelessWidget {
  const AchievementBadge({
    required this.icon,
    required this.label,
    this.isUnlocked = true,
    this.color = AppColors.neonCyan,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool isUnlocked;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final opacity = isUnlocked ? 1.0 : 0.3;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isUnlocked
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      color,
                      color.withValues(alpha: 0.6),
                    ],
                  )
                : null,
            color: isUnlocked ? null : const Color(0xFF1E2740),
            border: Border.all(
              color: isUnlocked
                  ? color.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.08),
              width: isUnlocked ? 1.5 : 1,
            ),
            boxShadow: isUnlocked
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Opacity(
            opacity: opacity,
            child: Icon(icon, size: 20, color: Colors.white),
          ),
        ),
        const SizedBox(height: 3),
        SizedBox(
          width: 48,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 8,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: isUnlocked ? 0.7 : 0.3),
              letterSpacing: 0.1,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
