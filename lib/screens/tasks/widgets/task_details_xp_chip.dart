import 'package:flutter/material.dart';
import 'package:habit_up/theme/app_colors.dart';

class TaskDetailsXpChip extends StatelessWidget {
  const TaskDetailsXpChip({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: const Color(0x1700E5FF),
        border: Border.all(color: const Color(0x2D00E5FF)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1800E5FF),
            blurRadius: 8,
            spreadRadius: -6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.neonCyan,
              fontWeight: FontWeight.w800,
              fontSize: 10.4,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: const Color(0xFF87D9F2),
              fontWeight: FontWeight.w600,
              fontSize: 9.8,
            ),
          ),
        ],
      ),
    );
  }
}
