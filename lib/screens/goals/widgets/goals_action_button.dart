import 'package:flutter/material.dart';
import 'package:habit_up/theme/app_colors.dart';

class GoalsActionButton extends StatelessWidget {
  const GoalsActionButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(11),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0x2B3B63D9), Color(0x1800CFFF)],
          ),
          border: Border.all(color: const Color(0x4F4D7CFF)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x1600E5FF),
              blurRadius: 10,
              spreadRadius: -8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 15, color: AppColors.neonCyan),
            const SizedBox(width: 5),
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.neonCyan,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
