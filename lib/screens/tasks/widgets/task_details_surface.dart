import 'package:flutter/material.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/theme/app_spacing.dart';

class TaskDetailsSurface extends StatelessWidget {
  const TaskDetailsSurface({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x49384D80)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xD0161D35), Color(0xB6101729)],
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x26040915),
            blurRadius: 14,
            spreadRadius: -9,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x1F7A94CA)),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0x0900E5FF), AppColors.transparent],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(1),
          child: child,
        ),
      ),
    );
  }
}

