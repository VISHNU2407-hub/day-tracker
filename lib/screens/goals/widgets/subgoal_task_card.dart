import 'package:flutter/material.dart';
import 'package:habit_up/motion/motion.dart';
import 'package:habit_up/screens/goals/widgets/subgoal_details_models.dart';
import 'package:habit_up/screens/goals/widgets/subgoal_priority_chip.dart';
import 'package:habit_up/screens/goals/widgets/subgoal_task_completion_indicator.dart';
import 'package:habit_up/screens/goals/widgets/subgoal_xp_chip.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/theme/app_spacing.dart';

class SubGoalTaskCard extends StatelessWidget {
  const SubGoalTaskCard({
    required this.task,
    this.onToggleComplete,
    this.onEditTask,
    this.onDeleteTask,
    super.key,
  });

  final SubGoalTaskItemViewModel task;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onEditTask;
  final VoidCallback? onDeleteTask;

  bool get _isCompleted => task.state == SubGoalTaskState.completed;
  bool get _isOverdue => task.state == SubGoalTaskState.overdue;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = _isCompleted
        ? AppColors.success.withValues(alpha: 0.45)
        : _isOverdue
            ? AppColors.error.withValues(alpha: 0.5)
            : colorScheme.outline.withValues(alpha: 0.3);

    return ScalePress(
      onTap: onToggleComplete ?? () {},
      child: Ink(
        padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 10, 4, AppSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          color: colorScheme.surface,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: SubGoalTaskCompletionIndicator(
                state: task.state,
                priority: task.priority,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall?.copyWith(
                            color: _isCompleted ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                            decoration: _isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      if (task.hasReminder)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.notifications_active_outlined,
                            size: 16,
                            color: AppColors.neonBlue,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      SubGoalPriorityChip(priority: task.priority),
                      _DueChip(dueLabel: task.dueLabel, isOverdue: _isOverdue),
                      SubGoalXpChip(xp: task.xpReward),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      minHeight: 5,
                      value: task.progress.clamp(0, 1),
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _isCompleted
                            ? AppColors.success
                            : _isOverdue
                                ? AppColors.error
                                : AppColors.neonBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 3-dot popup menu for edit/delete
            _TaskMenu(
              onEdit: onEditTask,
              onDelete: onDeleteTask,
            ),
          ],
        ),
      ),
    );
  }
}

/// 3-dot popup menu for edit/delete actions on a task card.
class _TaskMenu extends StatelessWidget {
  const _TaskMenu({
    this.onEdit,
    this.onDelete,
  });

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz_rounded, size: 18, color: colorScheme.onSurfaceVariant),
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit?.call();
          case 'delete':
            onDelete?.call();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit_rounded, color: colorScheme.primary, size: 18),
            title: Text('Edit', style: TextStyle(color: colorScheme.onSurface, fontSize: 13)),
            dense: true,
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete_rounded, color: colorScheme.error, size: 18),
            title: Text('Delete', style: TextStyle(color: colorScheme.error, fontSize: 13)),
            dense: true,
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}

class _DueChip extends StatelessWidget {
  const _DueChip({
    required this.dueLabel,
    required this.isOverdue,
  });

  final String dueLabel;
  final bool isOverdue;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final accent = isOverdue ? AppColors.error : colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: isOverdue ? AppColors.error.withValues(alpha: 0.14) : colorScheme.onSurfaceVariant.withValues(alpha: 0.08),
        border: Border.all(color: accent.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 11, color: accent),
          const SizedBox(width: 4),
          Text(
            dueLabel,
            style: textTheme.labelSmall?.copyWith(
              color: accent,
              fontSize: 10.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

