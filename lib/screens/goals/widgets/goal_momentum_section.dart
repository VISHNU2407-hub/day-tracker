import 'package:flutter/material.dart';
import 'package:habit_up/providers/task_provider.dart';
import 'package:habit_up/services/xp_streak_service.dart';
import 'package:habit_up/screens/goals/widgets/goal_progress_visualization.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:provider/provider.dart';

class GoalMomentumSection extends StatelessWidget {
  const GoalMomentumSection({
    required this.accent,
    required this.goalId,
    super.key,
  });

  final Color accent;
  final String goalId;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final xpService = context.watch<XpStreakService>();
    final taskProvider = context.watch<TaskProvider>();
    final momentum = xpService.getMomentumDetails();

    // Get today's and weekly completion for this goal's tasks
    final todayTasks = taskProvider.getTodayTasks().where((t) => t.goalId == goalId).toList();
    final todayCompleted = todayTasks.where((t) => t.isCompleted).length;
    final todayRate = todayTasks.isEmpty ? 0.0 : todayCompleted / todayTasks.length;

    // Get weekly data points for the mini progress bars
    final weekData = List<double>.generate(7, (i) {
      final date = DateTime.now().subtract(Duration(days: 6 - i));
      final dayTasks = taskProvider.getTasksForDate(date).where((t) => t.goalId == goalId).toList();
      if (dayTasks.isEmpty) return 0.0;
      final completed = dayTasks.where((t) => t.isCompleted).length;
      return completed / dayTasks.length;
    });

    return Container(
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline),
        color: colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Momentum',
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _momentumMessage(momentum.score, todayRate),
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
              height: 1.28,
            ),
          ),
          const SizedBox(height: 10),
          GoalMiniProgressBars(
            values: weekData,
            accent: accent,
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              if (todayRate > 0)
                _MomentumPill(
                  label: 'Today +${(todayRate * 100).toStringAsFixed(0)}%',
                  accent: AppColors.neonGreen,
                )
              else
              _MomentumPill(
                label: 'No tasks today',
                accent: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              _MomentumPill(
                label: 'Momentum ${(momentum.score * 100).toStringAsFixed(0)}%',
                accent: AppColors.neonBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _momentumMessage(double momentumScore, double todayRate) {
    if (momentumScore >= 0.8) return 'Exceptional consistency. Keep your deep-work blocks protected.';
    if (momentumScore >= 0.6) return 'Your consistency is building nicely. Stay the course.';
    if (todayRate >= 0.5) return 'Good progress today. Momentum is growing.';
    return 'Small steps build big momentum. Start with one task today.';
  }
}

class _MomentumPill extends StatelessWidget {
  const _MomentumPill({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
        color: accent.withValues(alpha: 0.1),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          color: accent,
          fontWeight: FontWeight.w700,
          fontSize: 10.4,
        ),
      ),
    );
  }
}
