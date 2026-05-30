import 'package:flutter/material.dart';
import 'package:habit_up/models/task_model.dart';
import 'package:habit_up/screens/tasks/widgets/task_badge.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/theme/app_spacing.dart';
import 'package:habit_up/widgets/app_gaps.dart';

/// Compact, premium task tile for the calendar day agenda view.
///
/// Shows:
/// - Title with strikethrough when completed
/// - Difficulty badge, time badge, XP reward
/// - Overdue indicator
class CalendarTaskTile extends StatelessWidget {
  const CalendarTaskTile({
    required this.task,
    this.onTap,
    this.goalColor,
    super.key,
  });

  final TaskModel task;
  final VoidCallback? onTap;

  /// Optional goal accent colour for the status indicator dot.
  /// When provided, active tasks use this colour instead of the default
  /// neon cyan to visually propagate goal colour into the calendar.
  final Color? goalColor;

  bool get _isCompleted => task.isCompleted;
  bool get _isOverdue => !_isCompleted && task.status == TaskStatus.overdue;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final borderColor = _isCompleted
        ? AppColors.success.withValues(alpha: 0.35)
        : (_isOverdue
            ? AppColors.error.withValues(alpha: 0.4)
            : colorScheme.outline.withValues(alpha: 0.23));

    final bgColor = colorScheme.surface;

    final timeString = _formatTime(task.startTime ?? task.scheduledDate);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          color: bgColor,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status indicator dot (uses goal colour when available)
            Container(
              margin: const EdgeInsets.only(top: 3),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isCompleted
                    ? AppColors.success
                    : (_isOverdue
                        ? AppColors.error
                        : (goalColor ?? colorScheme.primary)),
              ),
            ),
            AppGaps.h12,
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _isCompleted
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onSurface,
                            decoration: _isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      ),
                      if (_isOverdue)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: colorScheme.error.withValues(alpha: 0.18),
                            border: Border.all(
                              color: colorScheme.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'Overdue',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.error,
                              fontWeight: FontWeight.w700,
                              fontSize: 9,
                            ),
                          ),
                        ),
                    ],
                  ),
                  AppGaps.v4,
                  // Description
                  if (task.description != null && task.description!.isNotEmpty)
                    Text(
                      task.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 6),
                  // Badge row
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      TaskBadge.difficulty(task.difficulty),
                      TaskBadge.time(timeString),
                      _XpBadge(xp: task.xpReward),
                      if (task.repeatType != TaskRepeatType.none)
                        TaskBadge.recurring(task.repeatType),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'No time';
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _XpBadge extends StatelessWidget {
  const _XpBadge({required this.xp});

  final int xp;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        gradient: LinearGradient(
          colors: <Color>[
            colorScheme.primary.withValues(alpha: 0.16),
            colorScheme.primary.withValues(alpha: 0.11),
          ],
        ),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 10, color: colorScheme.primary),
          const SizedBox(width: 3),
          Text(
            '$xp XP',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}
