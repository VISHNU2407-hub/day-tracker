import 'package:flutter/material.dart';
import 'package:habit_up/screens/tasks/widgets/task_details_models.dart';
import 'package:habit_up/theme/app_colors.dart';

class TaskDetailsStatusChip extends StatelessWidget {
  const TaskDetailsStatusChip({
    required this.status,
    super.key,
  });

  final TaskExecutionStatus status;

  Color get _accent {
    switch (status) {
      case TaskExecutionStatus.active:
        return AppColors.neonBlue;
      case TaskExecutionStatus.completed:
        return AppColors.success;
      case TaskExecutionStatus.overdue:
        return AppColors.error;
      case TaskExecutionStatus.scheduled:
        return AppColors.warning;
    }
  }

  String get _label {
    switch (status) {
      case TaskExecutionStatus.active:
        return 'Active';
      case TaskExecutionStatus.completed:
        return 'Completed';
      case TaskExecutionStatus.overdue:
        return 'Overdue';
      case TaskExecutionStatus.scheduled:
        return 'Scheduled';
    }
  }

  IconData get _icon {
    switch (status) {
      case TaskExecutionStatus.active:
        return Icons.play_circle_outline_rounded;
      case TaskExecutionStatus.completed:
        return Icons.task_alt_rounded;
      case TaskExecutionStatus.overdue:
        return Icons.error_outline_rounded;
      case TaskExecutionStatus.scheduled:
        return Icons.event_repeat_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accent = _accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: accent.withValues(alpha: 0.1),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 10.5, color: accent),
          const SizedBox(width: 4),
          Text(
            _label,
            style: textTheme.labelSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
              fontSize: 10.2,
            ),
          ),
        ],
      ),
    );
  }
}
