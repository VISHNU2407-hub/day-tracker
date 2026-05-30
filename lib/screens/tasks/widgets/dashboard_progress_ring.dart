import 'package:flutter/material.dart';
import 'package:habit_up/motion/motion.dart';

class DashboardProgressRing extends StatelessWidget {
  const DashboardProgressRing({
    required this.progress,
    required this.size,
    required this.accentColor,
    this.centerChild,
    this.strokeWidth = 7,
    super.key,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final Color accentColor;
  final Widget? centerChild;

  @override
  Widget build(BuildContext context) {
    return AnimatedProgressRing(
      progress: progress,
      size: size,
      strokeWidth: strokeWidth,
      accentColor: accentColor,
      centerChild: centerChild,
    );
  }
}
