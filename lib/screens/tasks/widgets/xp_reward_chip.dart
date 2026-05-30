import 'package:flutter/material.dart';

class XpRewardChip extends StatelessWidget {
  const XpRewardChip({
    required this.xp,
    super.key,
  });

  final int xp;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: colorScheme.primary.withValues(alpha: 0.12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.24)),
      ),
      child: Text(
        '+$xp XP',
        style: textTheme.labelSmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
