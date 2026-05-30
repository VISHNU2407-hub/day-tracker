import 'package:flutter/material.dart';
import 'package:habit_up/motion/motion.dart';
import 'package:habit_up/theme/app_colors.dart';

class TaskCompletionIndicator extends StatelessWidget {
  const TaskCompletionIndicator({
    required this.isCompleted,
    required this.isHighPriority,
    super.key,
  });

  final bool isCompleted;
  final bool isHighPriority;

  @override
  Widget build(BuildContext context) {
    final accent = isCompleted
        ? AppColors.success
        : (isHighPriority
            ? const Color(0xFFFF8B78)
            : const Color(0xFF4A6092));

    return AnimatedCheckmark(
      isCompleted: isCompleted,
      size: 24,
      completedColor: accent,
      incompleteColor: isHighPriority
          ? const Color(0xFFFF8B78)
          : const Color(0xFF4A6092),
    );
  }
}
