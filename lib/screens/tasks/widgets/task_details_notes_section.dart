import 'package:flutter/material.dart';
import 'package:habit_up/screens/tasks/widgets/task_details_surface.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/theme/app_spacing.dart';

class TaskDetailsNotesSection extends StatelessWidget {
  const TaskDetailsNotesSection({
    required this.notes,
    super.key,
  });

  final String notes;

  @override
  Widget build(BuildContext context) {
    final hasNotes = notes.trim().isNotEmpty;
    final textTheme = Theme.of(context).textTheme;

    return TaskDetailsSurface(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
          collapsedIconColor: AppColors.textSecondary,
          iconColor: AppColors.neonCyan,
          title: Text(
            'Execution Notes',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            hasNotes ? 'Task instructions and productivity insights' : 'No notes available yet',
            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          children: [
            if (hasNotes)
              Text(
                notes,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.92),
                  height: 1.45,
                ),
              )
            else
              _NoteFallback(textTheme: textTheme),
          ],
        ),
      ),
    );
  }
}

class _NoteFallback extends StatelessWidget {
  const _NoteFallback({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.notes_rounded, size: 16, color: AppColors.neonBlue),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Capture a short execution brief to reduce context switching later.',
            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
