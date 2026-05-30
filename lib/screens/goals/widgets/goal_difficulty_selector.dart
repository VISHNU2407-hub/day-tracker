import 'package:flutter/material.dart';
import 'package:habit_up/theme/app_colors.dart';

enum GoalDifficulty {
  easy('Easy', Color(0xFF31D79E)),
  medium('Medium', Color(0xFF74A3FF)),
  hard('Hard', Color(0xFFFF8A66));

  const GoalDifficulty(this.label, this.color);
  final String label;
  final Color color;
}

class GoalDifficultySelector extends StatelessWidget {
  const GoalDifficultySelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final GoalDifficulty value;
  final ValueChanged<GoalDifficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Difficulty', style: textTheme.labelMedium?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Row(
          children: GoalDifficulty.values.map((difficulty) {
            final isSelected = value == difficulty;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: difficulty == GoalDifficulty.hard ? 0 : 6,
                ),
                child: InkWell(
                  onTap: () => onChanged(difficulty),
                  borderRadius: BorderRadius.circular(10),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? difficulty.color.withValues(alpha: 0.5) : AppColors.border,
                      ),
                      color: isSelected
                          ? difficulty.color.withValues(alpha: 0.08)
                          : AppColors.transparent,
                    ),
                    child: Text(
                      difficulty.label,
                      textAlign: TextAlign.center,
                      style: textTheme.labelSmall?.copyWith(
                        color: isSelected ? difficulty.color : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
