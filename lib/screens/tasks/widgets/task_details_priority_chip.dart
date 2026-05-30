import 'package:flutter/material.dart';
import 'package:habit_up/screens/tasks/widgets/task_details_models.dart';
import 'package:habit_up/theme/app_colors.dart';

class TaskDetailsPriorityChip extends StatelessWidget {
  const TaskDetailsPriorityChip({
    required this.priority,
    super.key,
  });

  final TaskExecutionPriority priority;

  Color get _accent {
    switch (priority) {
      case TaskExecutionPriority.low:
        return AppColors.neonGreen;
      case TaskExecutionPriority.medium:
        return AppColors.neonBlue;
      case TaskExecutionPriority.high:
        return AppColors.warning;
      case TaskExecutionPriority.critical:
        return const Color(0xFFFF8B78);
    }
  }

  String get _label {
    switch (priority) {
      case TaskExecutionPriority.low:
        return 'Low';
      case TaskExecutionPriority.medium:
        return 'Medium';
      case TaskExecutionPriority.high:
        return 'High';
      case TaskExecutionPriority.critical:
        return 'Critical';
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
      child: Text(
        _label,
        style: textTheme.labelSmall?.copyWith(
          color: accent,
          fontWeight: FontWeight.w700,
          fontSize: 10.2,
        ),
      ),
    );
  }
}
