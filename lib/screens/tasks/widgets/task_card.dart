import 'package:flutter/material.dart';
import 'package:habit_up/models/task_model.dart';
import 'package:habit_up/screens/tasks/widgets/task_badge.dart';
import 'package:habit_up/screens/tasks/widgets/xp_reward_chip.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/widgets/app_gaps.dart';

enum TaskPriority { normal, high }

class TodayTaskViewModel {
  const TodayTaskViewModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.difficulty,
    required this.startTime,
    required this.xp,
    required this.priority,
    required this.hasReminder,
    required this.isCompleted,
  });

  final String id;
  final String title;
  final String subtitle;
  final TaskDifficulty difficulty;
  final String startTime;
  final int xp;
  final TaskPriority priority;
  final bool hasReminder;
  final bool isCompleted;

  factory TodayTaskViewModel.fromTaskModel(TaskModel model) {
    final time = model.startTime ?? model.scheduledDate;
    final timeString = time != null
        ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
        : 'No time';
    return TodayTaskViewModel(
      id: model.id,
      title: model.title,
      subtitle: model.description ?? '',
      difficulty: model.difficulty,
      startTime: timeString,
      xp: model.xpReward,
      priority: model.difficulty == TaskDifficulty.hard
          ? TaskPriority.high
          : TaskPriority.normal,
      hasReminder: model.reminderTime != null,
      isCompleted: model.isCompleted,
    );
  }
}

/// Compact horizontal task row with 3-dot popup menu.
class TaskCard extends StatelessWidget {
  const TaskCard({
    required this.task,
    this.onToggle,
    this.onEdit,
    this.onDelete,
    this.onPushBackToGoal,
    super.key,
  });

  final TodayTaskViewModel task;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onPushBackToGoal;

  IconData _taskIcon(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return Icons.bolt_rounded;
      case TaskDifficulty.medium:
        return Icons.tune_rounded;
      case TaskDifficulty.hard:
        return Icons.local_fire_department_rounded;
    }
  }

  Color _iconColor(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return AppColors.neonGreen;
      case TaskDifficulty.medium:
        return AppColors.neonBlue;
      case TaskDifficulty.hard:
        return const Color(0xFFFF8B78);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: task.priority == TaskPriority.high
              ? const Color(0x5CFF8B78)
              : colorScheme.outline.withValues(alpha: 0.3),
        ),
        color: colorScheme.surface,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Left: task icon ──
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _iconColor(task.difficulty).withValues(alpha: 0.12),
              border: Border.all(
                color: _iconColor(task.difficulty).withValues(alpha: 0.25),
              ),
            ),
            child: Icon(
              _taskIcon(task.difficulty),
              size: 14,
              color: _iconColor(task.difficulty),
            ),
          ),
          AppGaps.h8,
          // ── Center: title + time • category ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: task.isCompleted
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onSurface,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                    if (task.hasReminder)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.notifications_active_outlined,
                          color: AppColors.neonBlue,
                          size: 12,
                        ),
                      ),
                  ],
                ),
                AppGaps.v2,
                Text(
                  '${task.startTime}${task.subtitle.isNotEmpty ? ' • ${task.subtitle}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          AppGaps.h8,
          // ── Right: badges + 3-dot menu ──
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TaskBadge.difficulty(task.difficulty),
              AppGaps.h4,
              XpRewardChip(xp: task.xp),
              AppGaps.h2,
              // 3-dot popup menu
              _TaskMenu(
                isCompleted: task.isCompleted,
                onToggle: onToggle,
                onEdit: onEdit,
                onDelete: onDelete,
                onPushBackToGoal: onPushBackToGoal,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 3-dot popup menu replacing visible edit/delete buttons.
class _TaskMenu extends StatelessWidget {
  const _TaskMenu({
    required this.isCompleted,
    this.onToggle,
    this.onEdit,
    this.onDelete,
    this.onPushBackToGoal,
  });

  final bool isCompleted;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onPushBackToGoal;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz_rounded, size: 18, color: colorScheme.onSurfaceVariant),
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (value) {
        switch (value) {
          case 'toggle':
            onToggle?.call();
          case 'edit':
            onEdit?.call();
          case 'delete':
            onDelete?.call();
          case 'pushback':
            onPushBackToGoal?.call();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'toggle',
          child: ListTile(
            leading: Icon(
              isCompleted ? Icons.undo_rounded : Icons.check_circle_outline_rounded,
              color: isCompleted ? AppColors.warning : AppColors.neonGreen,
              size: 18,
            ),
            title: Text(
              isCompleted ? 'Undo' : 'Complete',
              style: TextStyle(
                color: isCompleted ? AppColors.warning : AppColors.neonGreen,
                fontSize: 13,
              ),
            ),
            dense: true,
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
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
        if (onPushBackToGoal != null)
          PopupMenuItem(
            value: 'pushback',
            child: ListTile(
              leading: Icon(Icons.unfold_less_rounded, color: AppColors.warning, size: 18),
              title: Text('Push Back to Goal', style: TextStyle(color: AppColors.warning, fontSize: 13)),
              dense: true,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
      ],
    );
  }
}
