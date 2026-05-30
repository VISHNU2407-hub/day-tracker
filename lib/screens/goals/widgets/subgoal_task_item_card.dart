import 'package:flutter/material.dart';
import 'package:habit_up/screens/goals/widgets/goal_progress_visualization.dart';
import 'package:habit_up/theme/app_colors.dart';

class SubGoalTaskItemViewModel {
  const SubGoalTaskItemViewModel({
    required this.title,
    required this.note,
    required this.timeline,
    required this.isComplete,
  });

  final String title;
  final String note;
  final String timeline;
  final bool isComplete;
}

class SubGoalTaskItemCard extends StatelessWidget {
  const SubGoalTaskItemCard({
    required this.item,
    required this.accent,
    required this.onTap,
    super.key,
  });

  final SubGoalTaskItemViewModel item;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.fromLTRB(11, 10, 10, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.15)),
          color: colorScheme.surface,
        ),
        child: Row(
          children: [
            GoalCompletionDot(isComplete: item.isComplete),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: AppColors.neonBlue.withValues(alpha: 0.2)),
                color: AppColors.neonBlue.withValues(alpha: 0.08),
              ),
              child: Text(
                item.timeline,
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.neonBlue,
                  fontSize: 10.1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
