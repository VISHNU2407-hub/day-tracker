import 'package:flutter/material.dart';
import 'package:habit_up/screens/tasks/widgets/task_details_surface.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/theme/app_spacing.dart';

class TaskDetailsCompletionSection extends StatelessWidget {
  const TaskDetailsCompletionSection({
    required this.isCompleted,
    required this.xpReward,
    required this.streakDays,
    this.onToggleCompleted,
    super.key,
  });

  final bool isCompleted;
  final int xpReward;
  final int streakDays;
  final VoidCallback? onToggleCompleted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return TaskDetailsSurface(
      child: Row(
        children: [
          InkWell(
            onTap: onToggleCompleted,
            borderRadius: BorderRadius.circular(99),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted ? AppColors.success : AppColors.neonBlue,
                  width: 1.6,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isCompleted
                      ? const <Color>[Color(0x4421D19F), Color(0x120E1C2A)]
                      : const <Color>[Color(0x351D2A48), Color(0x12101725)],
                ),
              ),
              child: Icon(
                isCompleted ? Icons.check_rounded : Icons.play_arrow_rounded,
                color: isCompleted ? AppColors.success : AppColors.neonBlue,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCompleted ? 'Task Completed' : 'Mark as Complete',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isCompleted
                      ? 'XP credited. Streak continuity preserved.'
                      : 'Completion will trigger XP and streak updates.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 66),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+$xpReward XP',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.neonCyan,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$streakDays day streak',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.warning,
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
