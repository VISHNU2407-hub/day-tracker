import 'package:flutter/material.dart';
import 'package:habit_up/screens/tasks/widgets/task_details_surface.dart';
import 'package:habit_up/screens/tasks/widgets/task_details_xp_chip.dart';
import 'package:habit_up/theme/app_colors.dart';

class TaskDetailsRewardsSection extends StatelessWidget {
  const TaskDetailsRewardsSection({
    required this.xpReward,
    required this.streakBonusXp,
    super.key,
  });

  final int xpReward;
  final int streakBonusXp;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return TaskDetailsSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'XP & Rewards',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            'Completion rewards and milestone hints',
            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              TaskDetailsXpChip(value: '+$xpReward', label: 'Task XP'),
              TaskDetailsXpChip(value: '+$streakBonusXp', label: 'Streak Bonus'),
              const TaskDetailsXpChip(value: '+20', label: 'Consistency Bonus'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Milestone hint: complete 3 deep-focus tasks today to unlock bonus momentum XP.',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}
