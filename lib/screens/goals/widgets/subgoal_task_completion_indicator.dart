import 'package:flutter/material.dart';
import 'package:habit_up/screens/goals/widgets/subgoal_details_models.dart';
import 'package:habit_up/theme/app_colors.dart';

class SubGoalTaskCompletionIndicator extends StatelessWidget {
  const SubGoalTaskCompletionIndicator({
    required this.state,
    required this.priority,
    super.key,
  });

  final SubGoalTaskState state;
  final SubGoalTaskPriority priority;

  Color get _accent {
    if (state == SubGoalTaskState.completed) {
      return AppColors.success;
    }
    if (state == SubGoalTaskState.overdue) {
      return AppColors.error;
    }
    switch (priority) {
      case SubGoalTaskPriority.low:
        return const Color(0xFF5C87D3);
      case SubGoalTaskPriority.medium:
        return AppColors.neonBlue;
      case SubGoalTaskPriority.high:
        return AppColors.warning;
      case SubGoalTaskPriority.critical:
        return const Color(0xFFFF8B78);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    return Container(
      width: 23,
      height: 23,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accent, width: 1.5),
        color: state == SubGoalTaskState.completed
            ? accent.withValues(alpha: 0.12)
            : Theme.of(context).colorScheme.surface,
      ),
      alignment: Alignment.center,
      child: state == SubGoalTaskState.completed
          ? const Icon(Icons.check_rounded, size: 12, color: AppColors.success)
          : Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.68),
              ),
            ),
    );
  }
}

