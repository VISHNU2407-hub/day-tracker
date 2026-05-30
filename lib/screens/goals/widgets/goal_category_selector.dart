import 'package:flutter/material.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/theme/app_spacing.dart';

enum GoalCategory {
  productivity('Productivity', Icons.tune_rounded),
  fitness('Fitness', Icons.fitness_center_rounded),
  learning('Learning', Icons.auto_stories_rounded),
  health('Health', Icons.favorite_rounded),
  coding('Coding', Icons.code_rounded),
  reading('Reading', Icons.menu_book_rounded),
  custom('Custom', Icons.edit_rounded);

  const GoalCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

class GoalCategorySelector extends StatelessWidget {
  const GoalCategorySelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final GoalCategory value;
  final ValueChanged<GoalCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category', style: textTheme.labelMedium?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: GoalCategory.values.map((category) {
            final isSelected = value == category;
            return _CategoryChip(
              category: category,
              isSelected: isSelected,
              onTap: () => onChanged(category),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final GoalCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accent = isSelected ? AppColors.neonCyan : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: isSelected ? AppColors.neonBlue.withValues(alpha: 0.42) : AppColors.border,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? const <Color>[Color(0xE2253053), Color(0xD716223F)]
                : const <Color>[Color(0xD3172038), Color(0xCC10182C)],
          ),
          boxShadow: isSelected
              ? const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x1A4D7CFF),
                    blurRadius: 10,
                    spreadRadius: -7,
                    offset: Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon, size: 13, color: accent),
            const SizedBox(width: 4),
            Text(
              category.label,
              style: textTheme.labelSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
