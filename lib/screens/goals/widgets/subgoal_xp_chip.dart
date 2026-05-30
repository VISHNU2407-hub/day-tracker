import 'package:flutter/material.dart';

class SubGoalXpChip extends StatelessWidget {
  const SubGoalXpChip({
    required this.xp,
    super.key,
  });

  final int xp;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0x1C00E5FF),
        border: Border.all(color: const Color(0x3A00E5FF)),
      ),
      child: Text(
        '+$xp XP',
        style: textTheme.labelSmall?.copyWith(
          color: const Color(0xFF9FE8FF),
          fontSize: 10.8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
