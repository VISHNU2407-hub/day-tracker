import 'package:flutter/material.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/theme/app_spacing.dart';

class GoalEmptyState extends StatelessWidget {
  const GoalEmptyState({
    required this.onAddSubGoal,
    super.key,
  });

  final VoidCallback onAddSubGoal;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 14, AppSpacing.md, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colorScheme.outline),
        color: colorScheme.surface,
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x555E7DF5)),
              color: const Color(0x262A49C5),
            ),
            child: const Icon(Icons.track_changes_rounded, color: AppColors.neonCyan),
          ),
          const SizedBox(height: 9),
          Text(
            'No Sub Goals Yet',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Create your first sub goal to break this mission into focused execution steps.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 9),
          OutlinedButton.icon(
            onPressed: onAddSubGoal,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Add First Sub Goal'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
              side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
