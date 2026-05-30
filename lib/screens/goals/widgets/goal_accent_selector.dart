import 'package:flutter/material.dart';
import 'package:habit_up/screens/goals/widgets/goal_accent.dart';
import 'package:habit_up/theme/app_colors.dart';

/// Enhanced compact premium color picker for goal personalization.
///
/// Provides a productivity-oriented palette optimised for dark themes.
/// Each color maps to a [GoalAccent] for backwards compatibility with
/// existing widgets, plus a [colorHex] string that can be persisted to
/// [GoalModel.colorHex].
class GoalAccentSelector extends StatelessWidget {
  const GoalAccentSelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final GoalAccent value;
  final ValueChanged<GoalAccent> onChanged;

  /// Extended productivity-oriented colour palette (8 colours).
  ///
  /// All colours are tested against the dark theme for readability and
  /// visual hierarchy.
  static const Map<GoalAccent, Color> accentMap = <GoalAccent, Color>{
    GoalAccent.purple: Color(0xFFB18BFF),
    GoalAccent.blue: Color(0xFF84B3FF),
    GoalAccent.green: Color(0xFF74DDBD),
    GoalAccent.orange: Color(0xFFFFB089),
    GoalAccent.cyan: Color(0xFF5FDDFF),
    GoalAccent.pink: Color(0xFFFF8FDB),
    GoalAccent.yellow: Color(0xFFFFD666),
    GoalAccent.red: Color(0xFFFF7B89),
  };

  /// Returns the hex colour string (e.g. "#B18BFF") for a given [accent].
  static String hexStringForAccent(GoalAccent accent) {
    final color = accentMap[accent] ?? accentMap[GoalAccent.purple]!;
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Returns the [GoalAccent] from a hex string, or [GoalAccent.purple] as
  /// fallback if no match is found.
  static GoalAccent accentFromHex(String? hex) {
    if (hex == null || hex.length < 6) return GoalAccent.purple;
    final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
    for (final entry in accentMap.entries) {
      if (entry.value.toARGB32() == color.toARGB32()) return entry.key;
    }
    return GoalAccent.purple;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accentColors = accentMap.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Colour',
          style: textTheme.labelMedium?.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: accentColors.map((entry) {
            final isSelected = value == entry.key;
            return _AccentSwatch(
              color: entry.value,
              isSelected: isSelected,
              onTap: () => onChanged(entry.key),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: isSelected ? 32 : 30,
        height: isSelected ? 32 : 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              color.withValues(alpha: 0.96),
              color.withValues(alpha: 0.82),
            ],
          ),
          border: Border.all(
            color: isSelected
                ? AppColors.textPrimary
                : color.withValues(alpha: 0.30),
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isSelected ? 0.25 : 0.06),
              blurRadius: isSelected ? 10 : 4,
              spreadRadius: isSelected ? -3 : -5,
            ),
          ],
        ),
      ),
    );
  }
}
