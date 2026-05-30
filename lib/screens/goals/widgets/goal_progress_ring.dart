import 'package:flutter/material.dart';
import 'package:habit_up/theme/app_colors.dart';

class GoalProgressRing extends StatelessWidget {
  const GoalProgressRing({
    required this.progress,
    required this.accent,
    this.size = 78,
    super.key,
  });

  final double progress;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final normalized = progress.clamp(0.0, 1.0);
    final textTheme = Theme.of(context).textTheme;
    final stroke = size * 0.082;
    final centerStyle = size < 72 ? textTheme.labelSmall : textTheme.labelMedium;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[
            accent.withValues(alpha: 0.08),
            const Color(0x00000000),
          ],
          stops: const <double>[0.1, 1.0],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accent.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: -8.5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: stroke,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF273250)),
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: normalized,
              strokeWidth: stroke,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
              backgroundColor: Colors.transparent,
            ),
          ),
          Text(
            '${(normalized * 100).round()}%',
            style: centerStyle?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
