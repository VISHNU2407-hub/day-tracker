import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/theme/app_spacing.dart';

class SubGoalProgressOverviewSection extends StatelessWidget {
  const SubGoalProgressOverviewSection({
    required this.progress,
    required this.completedTasks,
    required this.totalTasks,
    required this.activeStreakDays,
    required this.timelineSummary,
    super.key,
  });

  final double progress;
  final int completedTasks;
  final int totalTasks;
  final int activeStreakDays;
  final String timelineSummary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final percent = (progress.clamp(0, 1) * 100).round();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        color: colorScheme.surface,
      ),
      child: Row(
        children: [
          _ProgressRing(progress: progress, percent: percent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$completedTasks of $totalTasks tasks complete',
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  'Execution stability: $activeStreakDays-day streak active',
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.92)),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded, size: 14, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text(
                      '$activeStreakDays day momentum',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 14, color: AppColors.neonBlue),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        timelineSummary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(color: AppColors.neonBlue),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.progress,
    required this.percent,
  });

  final double progress;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(84),
            painter: _RingPainter(
              progress: progress.clamp(0, 1),
              trackColor: colorScheme.surfaceContainerHighest,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$percent%',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                'Done',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.trackColor});

  final double progress;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    const start = -math.pi / 2;
    final rect = Offset.zero & size;

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..color = trackColor
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..shader = const LinearGradient(
        colors: <Color>[Color(0xFF00E5FF), Color(0xFF4D7CFF)],
      ).createShader(rect)
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect.deflate(3), start, math.pi * 2, false, basePaint);
    canvas.drawArc(rect.deflate(3), start, math.pi * 2 * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

