import 'package:flutter/material.dart';
import 'package:habit_up/theme/app_spacing.dart';

class SubGoalTasksEmptyState extends StatelessWidget {
  const SubGoalTasksEmptyState({
    required this.onCreateFirstTask,
    super.key,
  });

  final VoidCallback onCreateFirstTask;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        color: colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  border: Border.all(color: colorScheme.primary.withValues(alpha: 0.23)),
                ),
                child: Icon(Icons.rocket_launch_rounded, size: 15, color: colorScheme.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'No tasks yet',
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Start with one high-impact action to build execution momentum today.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: onCreateFirstTask,
            style: TextButton.styleFrom(
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
              side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.35)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            ),
            icon: Icon(Icons.add_rounded, size: 16, color: colorScheme.primary),
            label: Text(
              'Create first task',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

