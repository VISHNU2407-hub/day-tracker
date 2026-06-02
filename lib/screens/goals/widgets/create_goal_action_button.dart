import 'package:flutter/material.dart';
import 'package:habit_up/theme/app_colors.dart';

class CreateGoalActionButton extends StatelessWidget {
  const CreateGoalActionButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.transparent,
        ).copyWith(
          backgroundColor: const WidgetStatePropertyAll<Color>(AppColors.transparent),
          shadowColor: const WidgetStatePropertyAll<Color>(AppColors.transparent),
        ),
        child: Ink(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color(0xFF2B4AE6),
                Color(0xFF3860E8),
                Color(0xFF2A46CC),
              ],
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
