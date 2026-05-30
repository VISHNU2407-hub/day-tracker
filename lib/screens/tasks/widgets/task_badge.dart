import 'package:flutter/material.dart';
import 'package:habit_up/models/task_model.dart';

class TaskBadge extends StatelessWidget {
  const TaskBadge({
    required this.label,
    required this.background,
    required this.border,
    required this.foreground,
    required this.icon,
    super.key,
  });

  final String label;
  final Color background;
  final Color border;
  final Color foreground;
  final IconData icon;

  factory TaskBadge.difficulty(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return const TaskBadge(
          label: 'Easy',
          background: Color(0x1F21D19F),
          border: Color(0x3D21D19F),
          foreground: Color(0xFF74DDBD),
          icon: Icons.bolt_rounded,
        );
      case TaskDifficulty.medium:
        return const TaskBadge(
          label: 'Medium',
          background: Color(0x1F69A4FF),
          border: Color(0x3D69A4FF),
          foreground: Color(0xFF9AC1FF),
          icon: Icons.tune_rounded,
        );
      case TaskDifficulty.hard:
        return const TaskBadge(
          label: 'Hard',
          background: Color(0x1FFF8B78),
          border: Color(0x3DFF8B78),
          foreground: Color(0xFFFFB29F),
          icon: Icons.local_fire_department_rounded,
        );
    }
  }

  factory TaskBadge.time(String timeLabel) {
    return TaskBadge(
      label: timeLabel,
      background: const Color(0x204D7CFF),
      border: const Color(0x3D4D7CFF),
      foreground: const Color(0xFFA8BFFF),
      icon: Icons.schedule_rounded,
    );
  }

  factory TaskBadge.priority(String label) {
    return TaskBadge(
      label: label,
      background: const Color(0x1FFF7E5B),
      border: const Color(0x3DFF7E5B),
      foreground: const Color(0xFFFFB7A6),
      icon: Icons.priority_high_rounded,
    );
  }

  factory TaskBadge.recurring(TaskRepeatType repeatType) {
    final label = switch (repeatType) {
      TaskRepeatType.daily => 'Daily',
      TaskRepeatType.weekly => 'Weekly',
      TaskRepeatType.monthly => 'Monthly',
      TaskRepeatType.custom => 'Custom',
      TaskRepeatType.none => '',
    };
    return TaskBadge(
      label: label,
      background: const Color(0x1F9D7CFF),
      border: const Color(0x3D9D7CFF),
      foreground: const Color(0xFFC9B5FF),
      icon: Icons.repeat_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: background,
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
