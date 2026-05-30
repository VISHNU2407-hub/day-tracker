import 'package:flutter/material.dart';
import 'package:habit_up/screens/goals/widgets/subgoal_details_models.dart';
import 'package:habit_up/theme/app_colors.dart';

class SubGoalPriorityChip extends StatelessWidget {
  const SubGoalPriorityChip({
    required this.priority,
    super.key,
  });

  final SubGoalTaskPriority priority;

  Color get _accent {
    switch (priority) {
      case SubGoalTaskPriority.low:
        return AppColors.neonGreen;
      case SubGoalTaskPriority.medium:
        return AppColors.neonBlue;
      case SubGoalTaskPriority.high:
        return AppColors.warning;
      case SubGoalTaskPriority.critical:
        return const Color(0xFFFF8B78);
    }
  }

  String get _label {
    switch (priority) {
      case SubGoalTaskPriority.low:
        return 'Low';
      case SubGoalTaskPriority.medium:
        return 'Medium';
      case SubGoalTaskPriority.high:
        return 'High';
      case SubGoalTaskPriority.critical:
        return 'Critical';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accent = _accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: accent.withValues(alpha: 0.12),
        border: Border.all(color: accent.withValues(alpha: 0.32)),
      ),
      child: Text(
        _label,
        style: textTheme.labelSmall?.copyWith(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: accent,
        ),
      ),
    );
  }
}

