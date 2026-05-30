import 'package:flutter/material.dart';
import 'package:habit_up/screens/tasks/widgets/task_details_models.dart';
import 'package:habit_up/screens/tasks/widgets/task_details_priority_chip.dart';
import 'package:habit_up/screens/tasks/widgets/task_details_status_chip.dart';
import 'package:habit_up/screens/tasks/widgets/task_details_surface.dart';
import 'package:habit_up/screens/tasks/widgets/task_details_xp_chip.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/theme/app_spacing.dart';

class TaskDetailsOverviewCard extends StatelessWidget {
  const TaskDetailsOverviewCard({
    required this.viewModel,
    super.key,
  });

  final TaskDetailsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final progressPercent = (viewModel.progress.clamp(0, 1) * 100).round();

    return TaskDetailsSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Task Overview',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            'Current execution status and key delivery signals',
            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              TaskDetailsStatusChip(status: viewModel.status),
              TaskDetailsPriorityChip(priority: viewModel.priority),
              TaskDetailsXpChip(value: '+${viewModel.xpReward}', label: 'XP'),
              TaskDetailsXpChip(value: '+${viewModel.streakBonusXp}', label: 'Streak'),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: _Meta(
                  icon: Icons.schedule_rounded,
                  label: 'Due',
                  value: viewModel.dueDateLabel,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Meta(
                  icon: Icons.timer_outlined,
                  label: 'Focus',
                  value: viewModel.focusDurationLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Text(
                'Completion',
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$progressPercent%',
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.neonCyan,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: viewModel.progress.clamp(0, 1),
              backgroundColor: const Color(0xFF2A3354),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.neonBlue),
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        color: const Color(0x20293858),
        border: Border.all(color: const Color(0x403A4D7E)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: AppColors.neonBlue),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
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
