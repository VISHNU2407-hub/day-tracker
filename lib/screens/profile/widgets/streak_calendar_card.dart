import 'package:flutter/material.dart';
import 'package:habit_up/providers/task_provider.dart';
import 'package:habit_up/services/productivity_quality_service.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/theme/app_text_styles.dart';

/// A habit-tracker-style streak calendar that displays the current week
/// with circular day indicators.
///
/// **Layout (Mon–Sun):**
/// ```
///   S    M    T    W    T    F    S      ← weekday labels
///  🔥   🔥                               ← above streak-day circles
///  ◉    ◉    ◉    ○    ○    ○    ○       ← filled / outlined circles
///  25   26   27   28   29   30   31      ← day numbers
/// ```
/// **Below:** `🔥 Current Streak: X DAYS`
///
/// **Reuses without modifying:**
/// - [ProductivityQualityService.isFullStreakDay] → completed-day check
/// - [TaskProvider.getTasksForDate] → neutral-day (no tasks) check
/// - [currentStreak] param from [XpStreakService.snapshot]
class StreakCalendarCard extends StatelessWidget {
  const StreakCalendarCard({
    required this.taskProvider,
    required this.currentStreak,
    required this.level,
    required this.xp,
    required this.taskCount,
    required this.totalToday,
    super.key,
  });

  final TaskProvider taskProvider;
  final int currentStreak;
  final int level;
  final int xp;
  final int taskCount;
  final int totalToday;

  // ─── Instance helpers ──────────────────────────────────────────────────

  DateTime get _monday {
    final now = DateTime.now();
    final daysFromMonday = now.weekday - DateTime.monday;
    return DateTime(now.year, now.month, now.day - daysFromMonday);
  }

  static DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  /// Whether [date] is a "completed" day (≥90% XP earned).
  bool _isCompletedDay(DateTime date) {
    const quality = ProductivityQualityService();
    return quality.isFullStreakDay(date, taskProvider);
  }

  /// Whether [date] has any scheduled tasks at all.
  bool _hasTasks(DateTime date) =>
      taskProvider.getTasksForDate(date).isNotEmpty;

  /// True if [date] is part of the current streak — every day from [date]
  /// through today where tasks were scheduled is a completed day.
  ///
  /// Days without any scheduled tasks are treated as **neutral** (skipped),
  /// matching [XpStreakService.calculateDailyStreak] behavior.
  bool _inCurrentStreak(DateTime date) {
    final today = _normalize(DateTime.now());
    var cursor = _normalize(date);
    if (cursor.isAfter(today)) return false;

    while (!cursor.isAfter(today)) {
      // Days without tasks are neutral — skip them (matches XpStreakService).
      if (_hasTasks(cursor) && !_isCompletedDay(cursor)) return false;
      cursor = cursor.add(const Duration(days: 1));
    }
    return true;
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final monday = _monday;
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          'Progress',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary.withValues(alpha: 0.9),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),

        // Calendar card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF11172B), Color(0xFF0D1320)],
            ),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              // ── Weekday labels ────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: labels.map((l) => _label(l)).toList(),
              ),
              const SizedBox(height: 6),

              // ── Flame row ─────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: weekDays.map((d) => _flameCell(d)).toList(),
              ),

              // ── Circle row ────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: weekDays.map((d) => _circleCell(context, d)).toList(),
              ),
              const SizedBox(height: 4),

              // ── Day number row ────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: weekDays.map((d) => _dayNumberCell(d)).toList(),
              ),
            ],
          ),
        ),

        // ── Current Streak & Stats row ────────────────────────
        const SizedBox(height: 10),
        Row(
          children: [
            // Streak label (left side)
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🔥',
                    style: TextStyle(
                      fontSize: 16,
                      color: currentStreak > 0
                          ? AppColors.warning
                          : AppColors.textSecondary.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Streak $currentStreak',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: currentStreak > 0
                            ? AppColors.warning
                            : AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Inline stats: Level · XP · Done
            _StatPill(label: 'Level', value: '$level'),
            const SizedBox(width: 6),
            _StatPill(label: 'XP', value: '$xp'),
            const SizedBox(width: 6),
            _StatPill(
              label: 'Done',
              value: totalToday > 0 ? '$taskCount/$totalToday' : '$taskCount',
            ),
          ],
        ),
      ],
    );
  }

  // ─── Cell builders ─────────────────────────────────────────────────────

  Widget _label(String l) => SizedBox(
        width: 32,
        child: Text(
          l,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
        ),
      );

  Widget _flameCell(DateTime date) {
    final showFlame = _hasTasks(date) &&
        _isCompletedDay(date) &&
        _inCurrentStreak(date);
    return SizedBox(
      width: 32,
      height: 16,
      child: showFlame
          ? const Text('🔥',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12))
          : null,
    );
  }

  Widget _circleCell(BuildContext context, DateTime date) {
    final today = _isToday(date);
    final hasTasks = _hasTasks(date);
    final completed = hasTasks && _isCompletedDay(date);
    final neutral = !hasTasks;

    // Compute completion stats for the tooltip.
    final tasks = taskProvider.getTasksForDate(date);
    final totalCount = tasks.length;
    final completedCount = tasks.where((t) => t.isCompleted).length;
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayLabel = dayNames[date.weekday - DateTime.monday];

    String tooltipText;
    if (totalCount == 0) {
      tooltipText = '$dayLabel: No tasks scheduled';
    } else {
      tooltipText =
          '$dayLabel: $completedCount/$totalCount tasks completed';
    }

    Widget circle;
    if (neutral) {
      circle = Container(
        width: today ? 10 : 6,
        height: today ? 10 : 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.textSecondary.withValues(alpha: 0.15),
        ),
      );
    } else {
      const size = 22.0;
      final todaySize = 28.0;
      final accent = completed ? AppColors.neonCyan : AppColors.textSecondary;

      circle = Container(
        width: today ? todaySize : size,
        height: today ? todaySize : size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: completed
              ? accent.withValues(alpha: 0.20)
              : Colors.transparent,
          border: Border.all(
            color: completed ? accent : accent.withValues(alpha: 0.35),
            width: completed ? 2.0 : 1.5,
          ),
          boxShadow: today
              ? [
                  BoxShadow(
                    color: accent.withValues(
                        alpha: completed ? 0.35 : 0.10),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: completed
            ? Icon(Icons.check_rounded,
                size: today ? 14 : 11, color: accent)
            : null,
      );
    }

    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tooltipText,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: const Color(0xFF1E2740),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        );
      },
      child: SizedBox(
        width: 32,
        height: today ? 34 : 28,
        child: Center(child: circle),
      ),
    );
  }

  Widget _dayNumberCell(DateTime date) {
    final today = _isToday(date);
    return SizedBox(
      width: 32,
      child: Text(
        '${date.day}',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: today ? 12 : 11,
          fontWeight: today ? FontWeight.w800 : FontWeight.w500,
          color: today
              ? AppColors.neonCyan
              : AppColors.textSecondary.withValues(alpha: 0.65),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Inline stat pill (Level · XP · Done)
// ═══════════════════════════════════════════════════════════════════════════════

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.border.withValues(alpha: 0.25),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
