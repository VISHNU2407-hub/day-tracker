import 'package:flutter/material.dart';
import 'package:habit_up/models/goal_model.dart';
import 'package:habit_up/motion/motion.dart';
import 'package:habit_up/screens/goals/widgets/goal_progress_ring.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/theme/app_spacing.dart';

/// Helper that converts a [GoalModel] into display-friendly view data.
class GoalViewData {
  const GoalViewData({
    required this.title,
    required this.subtitle,
    required this.subGoalCount,
    required this.taskCount,
    required this.progress,
    required this.accentColor,
    required this.colorHex,
    required this.goalId,
    required this.isPinned,
  });

  final String title;
  final String subtitle;
  final int subGoalCount;
  final int taskCount;
  final double progress;
  final Color accentColor;
  final String? colorHex;
  final String goalId;
  final bool isPinned;

  factory GoalViewData.fromGoalModel(
    GoalModel goal, {
    int subGoalCount = 0,
    int taskCount = 0,
  }) {
    return GoalViewData(
      title: goal.title,
      subtitle:
          goal.description ?? goal.motivationalSubtitle ?? 'No description',
      subGoalCount: subGoalCount,
      taskCount: taskCount,
      progress: goal.progress,
      accentColor: _accentFromColorHex(goal.colorHex),
      colorHex: goal.colorHex,
      goalId: goal.id,
      isPinned: goal.isPinned,
    );
  }

  static Color _accentFromColorHex(String? hex) {
    if (hex != null && hex.length >= 6) {
      try {
        return Color(int.parse(hex.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }
    return const Color(0xFFB18BFF); // default purple
  }

  String get progressPercent => '${(progress * 100).toStringAsFixed(0)}%';
}

class GoalCard extends StatelessWidget {
  const GoalCard({
    required this.goal,
    required this.onTap,
    this.onPinToggle,
    super.key,
  });

  final GoalViewData goal;
  final VoidCallback onTap;
  final VoidCallback? onPinToggle;

  Color get _accentColor => goal.accentColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ScalePress(
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          11,
          AppSpacing.sm,
          11,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _accentColor.withValues(alpha: 0.24)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              const Color(0xEA17213C),
              const Color(0xD311182B),
              _accentColor.withValues(alpha: 0.045),
            ],
            stops: const <double>[0.0, 0.72, 1.0],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 18,
              spreadRadius: -10,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: _accentColor.withValues(alpha: 0.07),
              blurRadius: 14,
              spreadRadius: -8,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          goal.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.8,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                      if (goal.isPinned)
                        GestureDetector(
                          onTap: () {
                            // Unpin via the callback
                            onPinToggle?.call();
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.push_pin_rounded,
                              size: 14,
                              color: Color(0xFFFFB15A),
                            ),
                          ),
                        )
                      else
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => onPinToggle?.call(),
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.push_pin_outlined,
                                size: 14,
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    goal.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.85),
                      height: 1.32,
                    ),
                  ),
                  const SizedBox(height: 9),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _MetaChip(
                          label: '${goal.subGoalCount} Sub Goals',
                          accent: _accentColor,
                        ),
                        const SizedBox(width: 7),
                        _MetaChip(
                          label: '${goal.taskCount} Tasks',
                          accent: AppColors.neonBlue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            GoalProgressRing(
              progress: goal.progress,
              accent: _accentColor,
              size: 68,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: accent.withValues(alpha: 0.1),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          color: accent,
          fontWeight: FontWeight.w600,
          fontSize: 10.4,
        ),
      ),
    );
  }
}
