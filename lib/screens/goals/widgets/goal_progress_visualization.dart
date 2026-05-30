import 'package:flutter/material.dart';
import 'package:habit_up/theme/app_colors.dart';

class GoalMiniProgressBars extends StatelessWidget {
  const GoalMiniProgressBars({
    required this.values,
    required this.accent,
    super.key,
  });

  final List<double> values;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: values.map((value) {
        final normalized = value.clamp(0.0, 1.0);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 5,
                child: Stack(
                  children: [
                    Container(color: const Color(0xFF243051)),
                    FractionallySizedBox(
                      widthFactor: normalized,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: <Color>[accent.withValues(alpha: 0.65), accent],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class GoalCompletionDot extends StatelessWidget {
  const GoalCompletionDot({
    required this.isComplete,
    super.key,
  });

  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isComplete ? AppColors.success : AppColors.border,
        boxShadow: isComplete
            ? const <BoxShadow>[
                BoxShadow(
                  color: Color(0x3321D19F),
                  blurRadius: 7,
                  spreadRadius: -5.5,
                ),
              ]
            : null,
      ),
    );
  }
}
