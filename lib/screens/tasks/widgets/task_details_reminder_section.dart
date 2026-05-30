import 'package:flutter/material.dart';
import 'package:habit_up/screens/tasks/widgets/task_details_surface.dart';
import 'package:habit_up/theme/app_colors.dart';

class TaskDetailsReminderSection extends StatelessWidget {
  const TaskDetailsReminderSection({
    required this.reminderLabel,
    required this.dueLabel,
    required this.recurringLabel,
    required this.focusDurationLabel,
    super.key,
  });

  final String reminderLabel;
  final String dueLabel;
  final String recurringLabel;
  final String focusDurationLabel;

  @override
  Widget build(BuildContext context) {
    return TaskDetailsSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reminder & Schedule',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            'Prepared for reminders, recurring cadence, and calendar sync',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          _ScheduleItem(icon: Icons.notifications_active_outlined, label: 'Reminder', value: reminderLabel),
          const SizedBox(height: 8),
          _ScheduleItem(icon: Icons.event_rounded, label: 'Due Date', value: dueLabel),
          const SizedBox(height: 8),
          _ScheduleItem(icon: Icons.repeat_rounded, label: 'Recurring', value: recurringLabel),
          const SizedBox(height: 8),
          _ScheduleItem(icon: Icons.timer_rounded, label: 'Focus Session', value: focusDurationLabel),
        ],
      ),
    );
  }
}

class _ScheduleItem extends StatelessWidget {
  const _ScheduleItem({
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0x1D2A3858),
        border: Border.all(color: const Color(0x363A4D7D)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.neonBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12.4,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 10.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
