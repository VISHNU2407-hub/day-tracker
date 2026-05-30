import 'package:flutter/material.dart';
import 'package:habit_up/screens/goals/widgets/goal_accent.dart';
import 'package:habit_up/screens/goals/widgets/goal_progress_ring.dart';
import 'package:habit_up/screens/goals/widgets/goal_progress_visualization.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/theme/app_spacing.dart';

class GoalProgressOverviewSection extends StatelessWidget {
  const GoalProgressOverviewSection({
    required this.progress,
    required this.accent,
    required this.activeStreak,
    required this.completedTasks,
    required this.insight,
    super.key,
  });

  final double progress;
  final GoalAccent accent;
  final int activeStreak;
  final int completedTasks;
  final String insight;

  Color get _accentColor {
    switch (accent) {
      case GoalAccent.purple:
        return const Color(0xFFB18BFF);
      case GoalAccent.green:
        return const Color(0xFF74DDBD);
      case GoalAccent.blue:
        return const Color(0xFF84B3FF);
      case GoalAccent.orange:
        return const Color(0xFFFFB089);
      case GoalAccent.cyan:
        return const Color(0xFF5FDDFF);
      case GoalAccent.pink:
        return const Color(0xFFFF8FDB);
      case GoalAccent.yellow:
        return const Color(0xFFFFD666);
      case GoalAccent.red:
        return const Color(0xFFFF7B89);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 13, AppSpacing.md, 13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _accentColor.withValues(alpha: 0.22)),
        color: colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GoalProgressRing(progress: progress, accent: _accentColor, size: 98),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mission Progress',
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(progress * 100).round()}% Complete',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      insight,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
                        height: 1.28,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _MetaMetric(label: 'Streak', value: '$activeStreak days', accent: AppColors.neonGreen),
              const SizedBox(width: AppSpacing.xs),
              _MetaMetric(
                label: 'Completed Tasks',
                value: '$completedTasks done',
                accent: AppColors.neonBlue,
              ),
            ],
          ),
          const SizedBox(height: 9),
          GoalMiniProgressBars(
            values: const <double>[0.55, 0.72, 0.66, 0.8, 0.63, 0.77, 0.7],
            accent: _accentColor,
          ),
        ],
      ),
    );
  }
}

class _MetaMetric extends StatelessWidget {
  const _MetaMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: accent.withValues(alpha: 0.08),
          border: Border.all(color: accent.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
