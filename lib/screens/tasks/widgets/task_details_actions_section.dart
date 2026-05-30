import 'package:flutter/material.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/theme/app_spacing.dart';

class TaskDetailsActionsSection extends StatelessWidget {
  const TaskDetailsActionsSection({
    this.onMarkComplete,
    this.onReschedule,
    this.onEditTask,
    this.onDeleteTask,
    this.onPushToday,
    this.onPushTomorrow,
    this.onPickDate,
    super.key,
  });

  final VoidCallback? onMarkComplete;
  final VoidCallback? onReschedule;
  final VoidCallback? onEditTask;
  final VoidCallback? onDeleteTask;
  final VoidCallback? onPushToday;
  final VoidCallback? onPushTomorrow;
  final VoidCallback? onPickDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Scheduling section
        Text(
          'Schedule',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          'Push to your execution day',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Today',
                icon: Icons.wb_sunny_outlined,
                accent: AppColors.neonCyan,
                onTap: onPushToday,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                label: 'Tomorrow',
                icon: Icons.nightlight_round,
                accent: AppColors.neonBlue,
                onTap: onPushTomorrow,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                label: 'Pick Date',
                icon: Icons.calendar_today_rounded,
                accent: AppColors.warning,
                onTap: onPickDate,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, thickness: 0.5, color: Color(0x2A364D80)),
        const SizedBox(height: 12),
        // Task actions section
        Text(
          'Task Actions',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          'Quick execution controls',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Mark Complete',
                icon: Icons.task_alt_rounded,
                accent: AppColors.success,
                onTap: onMarkComplete,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                label: 'Reschedule',
                icon: Icons.update_rounded,
                accent: AppColors.neonBlue,
                onTap: onReschedule,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Edit Task',
                icon: Icons.edit_rounded,
                accent: AppColors.neonCyan,
                onTap: onEditTask,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                label: 'Delete Task',
                icon: Icons.delete_outline_rounded,
                accent: AppColors.error,
                onTap: onDeleteTask,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          color: accent.withValues(alpha: 0.09),
          border: Border.all(color: accent.withValues(alpha: 0.26)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: accent),
            const SizedBox(width: 5),
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
                fontSize: 10.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
