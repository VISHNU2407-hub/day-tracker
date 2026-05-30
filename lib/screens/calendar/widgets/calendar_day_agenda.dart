import 'package:flutter/material.dart';
import 'package:habit_up/models/task_model.dart';
import 'package:habit_up/providers/calendar_provider.dart';
import 'package:habit_up/screens/calendar/widgets/calendar_task_tile.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/theme/app_spacing.dart';
import 'package:habit_up/widgets/app_gaps.dart';

/// Displays all tasks for the selected date in a clean agenda list.
///
/// Sections:
/// - Overdue tasks (if any)
/// - Scheduled tasks for this day
/// - Recurring tasks mapped to this day
/// - Completed tasks
///
/// Also shows productivity density summary at the top.
class CalendarDayAgenda extends StatelessWidget {
  const CalendarDayAgenda({
    required this.provider,
    required this.onTaskTap,
    super.key,
  });

  final CalendarProvider provider;
  final ValueChanged<TaskModel> onTaskTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final date = provider.selectedDate;
    final tasks = provider.getTasksForDay(date);
    final isToday = provider.isToday(date);

    // Categorize tasks
    final overdueTasks = tasks
        .where((t) => !t.isCompleted && t.status == TaskStatus.overdue)
        .toList(growable: false);
    final scheduledTasks = tasks
        .where((t) => !t.isCompleted && t.status != TaskStatus.overdue)
        .toList(growable: false);
    final completedTasks =
        tasks.where((t) => t.isCompleted).toList(growable: false);

    final totalCount = tasks.length;
    final completedCount = completedTasks.length;

    // Date label
    final dateLabel = _formatDateHeader(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header with productivity summary
        _DateHeader(
          dateLabel: dateLabel,
          isToday: isToday,
          totalCount: totalCount,
          completedCount: completedCount,
          textTheme: textTheme,
        ),
        AppGaps.v16,

        // Overdue section
        if (overdueTasks.isNotEmpty) ...[
          _SectionHeader(
            label: 'Overdue',
            count: overdueTasks.length,
            color: AppColors.error,
          ),
          AppGaps.v8,
          ...overdueTasks.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: CalendarTaskTile(
                task: task,
                onTap: () => onTaskTap(task),
              ),
            ),
          ),
          AppGaps.v12,
        ],

        // Scheduled section
        if (scheduledTasks.isNotEmpty) ...[
          _SectionHeader(
            label: 'Scheduled',
            count: scheduledTasks.length,
            color: AppColors.neonCyan,
          ),
          AppGaps.v8,
          ...scheduledTasks.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: CalendarTaskTile(
                task: task,
                onTap: () => onTaskTap(task),
              ),
            ),
          ),
          AppGaps.v12,
        ],

        // Completed section
        if (completedTasks.isNotEmpty) ...[
          _SectionHeader(
            label: 'Completed',
            count: completedTasks.length,
            color: AppColors.success,
          ),
          AppGaps.v8,
          ...completedTasks.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: CalendarTaskTile(
                task: task,
                onTap: () => onTaskTap(task),
              ),
            ),
          ),
          AppGaps.v12,
        ],

        // Empty state
        if (tasks.isEmpty) ...[
          _EmptyDayState(dateLabel: dateLabel, isToday: isToday, textTheme: textTheme),
        ],
      ],
    );
  }

  String _formatDateHeader(DateTime date) {
    final months = <String>[
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final days = <String>[
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({
    required this.dateLabel,
    required this.isToday,
    required this.totalCount,
    required this.completedCount,
    required this.textTheme,
  });

  final String dateLabel;
  final bool isToday;
  final int totalCount;
  final int completedCount;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surface,
        border: Border.all(
          color: isToday
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outline.withValues(alpha: 0.19),
        ),
      ),
      child: Row(
        children: [
          // Date info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? 'Today' : dateLabel,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isToday ? colorScheme.primary : colorScheme.onSurface,
                  ),
                ),
                AppGaps.v4,
                Text(
                  totalCount == 0
                      ? 'No tasks scheduled'
                      : '$completedCount of $totalCount tasks completed',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          // Progress ring (compact)
          if (totalCount > 0)
            SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4,
                    strokeCap: StrokeCap.round,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isToday ? colorScheme.primary : AppColors.neonBlue,
                    ),
                    backgroundColor: Colors.transparent,
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            color: color,
          ),
        ),
        AppGaps.h8,
        Text(
          label,
          style: textTheme.labelLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            color: color.withValues(alpha: 0.12),
          ),
          child: Text(
            count.toString(),
            style: textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyDayState extends StatelessWidget {
  const _EmptyDayState({
    required this.dateLabel,
    required this.isToday,
    required this.textTheme,
  });

  final String dateLabel;
  final bool isToday;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
        ),
        color: colorScheme.surface,
      ),
      child: Column(
        children: [
          Icon(
            isToday ? Icons.wb_sunny_outlined : Icons.calendar_today_outlined,
            color: colorScheme.primary.withValues(alpha: 0.4),
            size: 32,
          ),
          AppGaps.v12,
          Text(
            isToday ? 'No tasks for today' : 'No tasks scheduled',
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          AppGaps.v4,
          Text(
            isToday
                ? 'Add a task to start building momentum.'
                : 'Schedule a task for this day to plan ahead.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
