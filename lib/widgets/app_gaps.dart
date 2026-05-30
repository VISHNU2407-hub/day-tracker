import 'package:flutter/widgets.dart';
import 'package:habit_up/theme/app_spacing.dart';

/// Simple reusable spacing widgets to keep layouts clean.
abstract final class AppGaps {
  static const Widget h2 = SizedBox(width: 2);
  static const Widget h4 = SizedBox(width: AppSpacing.xxs);
  static const Widget h6 = SizedBox(width: 6);
  static const Widget h8 = SizedBox(width: AppSpacing.xs);
  static const Widget h10 = SizedBox(width: 10);
  static const Widget h12 = SizedBox(width: AppSpacing.sm);
  static const Widget h14 = SizedBox(width: 14);
  static const Widget h16 = SizedBox(width: AppSpacing.md);
  static const Widget h20 = SizedBox(width: AppSpacing.lg);
  static const Widget h24 = SizedBox(width: AppSpacing.xl);
  static const Widget h32 = SizedBox(width: AppSpacing.xxl);

  static const Widget v2 = SizedBox(height: 2);
  static const Widget v4 = SizedBox(height: AppSpacing.xxs);
  static const Widget v6 = SizedBox(height: 6);
  static const Widget v8 = SizedBox(height: AppSpacing.xs);
  static const Widget v10 = SizedBox(height: 10);
  static const Widget v12 = SizedBox(height: AppSpacing.sm);
  static const Widget v14 = SizedBox(height: 14);
  static const Widget v16 = SizedBox(height: AppSpacing.md);
  static const Widget v20 = SizedBox(height: AppSpacing.lg);
  static const Widget v24 = SizedBox(height: AppSpacing.xl);
  static const Widget v32 = SizedBox(height: AppSpacing.xxl);
  static const Widget v40 = SizedBox(height: 40);
}
