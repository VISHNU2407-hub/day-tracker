import 'package:flutter/material.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/theme/app_spacing.dart';

enum GoalTimeline {
  daily('Daily'),
  weekly('Weekly'),
  monthly('Monthly'),
  custom('Custom');

  const GoalTimeline(this.label);
  final String label;
}

class GoalTimelineSelector extends StatelessWidget {
  const GoalTimelineSelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final GoalTimeline value;
  final ValueChanged<GoalTimeline> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Duration', style: textTheme.labelMedium?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: GoalTimeline.values.map((timeline) {
            final isSelected = value == timeline;
            return ChoiceChip(
              showCheckmark: false,
              selected: isSelected,
              label: Text(timeline.label),
              labelStyle: textTheme.labelSmall?.copyWith(
                color: isSelected ? AppColors.neonCyan : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 11.2,
              ),
              side: BorderSide(color: isSelected ? const Color(0x564D7CFF) : AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
              selectedColor: const Color(0x2B355EEA),
              backgroundColor: const Color(0xD0121A30),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              onSelected: (_) => onChanged(timeline),
            );
          }).toList(),
        ),
      ],
    );
  }
}
