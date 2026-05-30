import 'package:flutter/material.dart';
import 'package:habit_up/motion/motion.dart';
import 'package:habit_up/screens/goals/widgets/goal_progress_visualization.dart';
import 'package:habit_up/theme/app_colors.dart';

class SubGoalItemViewModel {
  const SubGoalItemViewModel({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.taskCount,
    required this.timeline,
    required this.isCompleted,
  });

  final String title;
  final String subtitle;
  final double progress;
  final int taskCount;
  final String timeline;
  final bool isCompleted;
}

class SubGoalItemCard extends StatelessWidget {
  const SubGoalItemCard({
    required this.item,
    required this.accent,
    required this.onTap,
    super.key,
  });

  final SubGoalItemViewModel item;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final progressPercent = (item.progress * 100).round();

    return ScalePress(
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.fromLTRB(11, 10, 10, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: accent.withValues(alpha: 0.17)),
          color: colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GoalCompletionDot(isComplete: item.isCompleted),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              item.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 8),
            GoalMiniProgressBars(
              values: <double>[item.progress],
              accent: accent,
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _Meta(
                    label: '$progressPercent%',
                    icon: Icons.show_chart_rounded,
                    accent: accent,
                  ),
                  const SizedBox(width: 5),
                  _Meta(
                    label: '${item.taskCount} tasks',
                    icon: Icons.task_alt_rounded,
                    accent: AppColors.neonBlue,
                  ),
                  const SizedBox(width: 5),
                  _Meta(
                    label: item.timeline,
                    icon: Icons.schedule_rounded,
                    accent: AppColors.warning,
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.icon, required this.accent});

  final String label;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: accent.withValues(alpha: 0.1),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: accent),
          const SizedBox(width: 3),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: accent,
              fontSize: 10.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
