import 'package:flutter/material.dart';
import 'package:habit_up/theme/app_colors.dart';

class GoalsSectionHeader extends StatelessWidget {
  const GoalsSectionHeader({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary.withValues(alpha: 0.82),
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
