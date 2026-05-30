import 'package:flutter/material.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/theme/app_spacing.dart';
import 'package:habit_up/theme/app_text_styles.dart';

enum AppButtonVariant {
  primary,
  secondary,
  ghost,
}

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.leading,
    this.fullWidth = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final Widget? leading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final style = _styleForVariant();

    final child = isLoading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(label),
            ],
          );

    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: child,
    );

    if (!fullWidth) {
      return button;
    }

    return SizedBox(width: double.infinity, child: button);
  }

  ButtonStyle _styleForVariant() {
    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonCyan,
          foregroundColor: AppColors.background,
          disabledBackgroundColor: AppColors.surfaceHighest,
          disabledForegroundColor: AppColors.textSecondary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 50),
          textStyle: AppTextStyles.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        );
      case AppButtonVariant.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.surfaceHighest,
          foregroundColor: AppColors.textPrimary,
          disabledBackgroundColor: AppColors.surfaceHighest,
          disabledForegroundColor: AppColors.textSecondary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 50),
          textStyle: AppTextStyles.labelLarge,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        );
      case AppButtonVariant.ghost:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.transparent,
          foregroundColor: AppColors.neonCyan,
          disabledBackgroundColor: AppColors.transparent,
          disabledForegroundColor: AppColors.textSecondary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 50),
          textStyle: AppTextStyles.labelLarge,
          side: const BorderSide(color: AppColors.neonCyan),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        );
    }
  }
}
