import 'package:flutter/material.dart';
import 'package:habit_up/screens/tasks/widgets/task_details_surface.dart';
import 'package:habit_up/theme/app_colors.dart';

class TaskDetailsFocusSection extends StatelessWidget {
  const TaskDetailsFocusSection({
    required this.focusDurationLabel,
    required this.focusStreakDays,
    required this.intensityLabel,
    super.key,
  });

  final String focusDurationLabel;
  final int focusStreakDays;
  final String intensityLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return TaskDetailsSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Focus Session',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            'Execution timer preview and productivity intensity',
            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 98,
                child: _FocusStat(
                  label: 'Planned',
                  value: focusDurationLabel,
                  accent: AppColors.neonCyan,
                ),
              ),
              SizedBox(
                width: 106,
                child: _FocusStat(
                  label: 'Focus Streak',
                  value: '$focusStreakDays days',
                  accent: AppColors.warning,
                ),
              ),
              SizedBox(
                width: 90,
                child: _FocusStat(
                  label: 'Intensity',
                  value: intensityLabel,
                  accent: AppColors.neonGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FocusStat extends StatelessWidget {
  const _FocusStat({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        color: accent.withValues(alpha: 0.08),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary, fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(value, style: textTheme.labelSmall?.copyWith(color: accent, fontWeight: FontWeight.w700, fontSize: 10.4)),
        ],
      ),
    );
  }
}
