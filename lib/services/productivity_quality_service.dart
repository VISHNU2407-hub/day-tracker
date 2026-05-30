import 'package:flutter/material.dart';
import 'package:habit_up/models/task_model.dart';
import 'package:habit_up/providers/task_provider.dart';
import 'package:habit_up/theme/app_colors.dart';

// ---------------------------------------------------------------------------
// Productivity Quality Scoring Engine
// ---------------------------------------------------------------------------

/// The core engine for computing daily productivity quality based on the
/// ratio: `completed XP / total scheduled XP`.
///
/// **Streak quality rules:**
/// - 90%+ completion → FULL streak success
/// - 50%–89%        → partial productivity day
/// - below 50%      → streak-break / failed day
///
/// All calculations are provider-safe, scalable, and designed for live
/// dashboard and calendar synchronisation.
class ProductivityQualityService {
  const ProductivityQualityService();

  // ---------------------------------------------------------------------------
  // Scoring thresholds
  // ---------------------------------------------------------------------------

  /// Minimum ratio for a **full** streak-quality day.
  static const double fullStreakThreshold = 0.9;

  /// Minimum ratio for a **partial** productivity day.
  static const double partialStreakThreshold = 0.5;

  // ---------------------------------------------------------------------------
  // Core scoring API
  // ---------------------------------------------------------------------------

  /// Calculate the raw productivity score (0.0 – 1.0) for the given [date]
  /// based on `completed XP / total scheduled XP`.
  ///
  /// Returns 0.0 when there are no scheduled tasks for the day.
  double calculateDailyProductivityScore(
    DateTime date,
    TaskProvider taskProvider,
  ) {
    final tasks = taskProvider.getTasksForDate(date);
    return _computeXpRatio(tasks);
  }

  /// Convenience wrapper that returns the XP ratio as a percentage (0 – 100).
  double calculateCompletionXPPercentage(
    DateTime date,
    TaskProvider taskProvider,
  ) {
    return calculateDailyProductivityScore(date, taskProvider) * 100;
  }

  /// Returns the productivity colour for a given [score] (0.0 – 1.0).
  ///
  /// **Colour rules:**
  /// - 90%+  → DARK GREEN  (full streak)
  /// - 50–89% → LIGHT GREEN (partial productivity)
  /// - <50%   → RED         (missed / broken streak)
  static Color getProductivityColorForScore(double score) {
    if (score >= fullStreakThreshold) return const Color(0xFF1B8C5E);
    if (score >= partialStreakThreshold) return const Color(0xFF3DDC97);
    return AppColors.error;
  }

  /// Convenience method — compute score and return colour in one call.
  Color getProductivityColorForDay(
    DateTime date,
    TaskProvider taskProvider,
  ) {
    final score = calculateDailyProductivityScore(date, taskProvider);
    return getProductivityColorForScore(score);
  }

  // ---------------------------------------------------------------------------
  // Quality classification
  // ---------------------------------------------------------------------------

  /// Whether the day qualifies as a **full** streak day (90%+).
  bool isFullStreakDay(DateTime date, TaskProvider taskProvider) {
    return calculateDailyProductivityScore(date, taskProvider) >=
        fullStreakThreshold;
  }

  /// Whether the day qualifies as at least a **partial** productivity day
  /// (50%+).
  bool isPartialStreakDay(DateTime date, TaskProvider taskProvider) {
    return calculateDailyProductivityScore(date, taskProvider) >=
        partialStreakThreshold;
  }

  /// Whether the day is a **streak-break** / failed day (< 50%).
  bool isFailedDay(DateTime date, TaskProvider taskProvider) {
    final tasks = taskProvider.getTasksForDate(date);
    if (tasks.isEmpty) return false; // No tasks scheduled — neutral
    return _computeXpRatio(tasks) < partialStreakThreshold;
  }

  // ---------------------------------------------------------------------------
  // Analytics helpers
  // ---------------------------------------------------------------------------

  /// Compute the average productivity score over the last [days] days.
  double averageProductivityScoreOverDays({
    required TaskProvider taskProvider,
    int days = 30,
  }) {
    final now = DateTime.now();
    double total = 0;
    int count = 0;

    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final tasks = taskProvider.getTasksForDate(date);
      if (tasks.isEmpty) continue;
      total += _computeXpRatio(tasks);
      count++;
    }

    return count == 0 ? 0.0 : total / count;
  }

  /// Returns the number of full streak days (90%+) in the last [days] days.
  int countFullStreakDays({
    required TaskProvider taskProvider,
    int days = 30,
  }) {
    final now = DateTime.now();
    int count = 0;

    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final tasks = taskProvider.getTasksForDate(date);
      if (tasks.isEmpty) continue;
      if (_computeXpRatio(tasks) >= fullStreakThreshold) count++;
    }

    return count;
  }

  /// Returns the number of partial Productivity Days (50–89%) in the last
  /// [days] days.
  int countPartialProductivityDays({
    required TaskProvider taskProvider,
    int days = 30,
  }) {
    final now = DateTime.now();
    int count = 0;

    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final tasks = taskProvider.getTasksForDate(date);
      if (tasks.isEmpty) continue;
      final ratio = _computeXpRatio(tasks);
      if (ratio >= partialStreakThreshold && ratio < fullStreakThreshold) {
        count++;
      }
    }

    return count;
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  /// Compute completed XP / total scheduled XP from a list of [tasks].
  ///
  /// - Uses `xpReward` for weighting so harder tasks carry more weight.
  /// - Scheduled-task-only logic: only tasks that are scheduled / active /
  ///   overdue count toward the total.
  /// - Recurring tasks are supported because they appear as normal tasks with
  ///   `xpReward` and `isCompleted` fields.
  double _computeXpRatio(List<TaskModel> tasks) {
    // Filter to tasks that are relevant for scoring — exclude purely
    // scheduled (future) tasks that haven't begun yet.
    final scorable = tasks.where((t) => _isScorable(t)).toList();
    if (scorable.isEmpty) return 0.0;

    int completedXp = 0;
    int totalXp = 0;

    for (final task in scorable) {
      final xp = task.xpReward > 0 ? task.xpReward : 3; // default 3 XP
      totalXp += xp;
      if (task.isCompleted) {
        completedXp += xp;
      }
    }

    if (totalXp == 0) return 0.0;
    return (completedXp / totalXp).clamp(0.0, 1.0);
  }

  /// A task is "scorable" if it has an effective date on the target day and
  /// is either active, completed, or overdue — not a far-future scheduled task.
  bool _isScorable(TaskModel task) {
    if (task.status == TaskStatus.scheduled && !task.isCompleted) {
      // Only include scheduled tasks if they're effectively due today
      // (the caller already filtered by date, so this is safe).
      return true;
    }
    return task.status == TaskStatus.active ||
        task.status == TaskStatus.completed ||
        task.status == TaskStatus.overdue;
  }
}

/// Immutable snapshot of a single day's productivity quality for calendar
/// rendering and analytics.
class DailyProductivitySnapshot {
  const DailyProductivitySnapshot({
    required this.date,
    required this.score,
    required this.completedXp,
    required this.totalScheduledXp,
  });

  final DateTime date;
  final double score;
  final int completedXp;
  final int totalScheduledXp;

  /// Derived colour for calendar heatmap visualisation.
  Color get color => ProductivityQualityService.getProductivityColorForScore(score);

  /// Human-readable quality label.
  String get qualityLabel {
    if (score >= ProductivityQualityService.fullStreakThreshold) return 'Full';
    if (score >= ProductivityQualityService.partialStreakThreshold) {
      return 'Partial';
    }
    return 'Missed';
  }

  /// Whether there were any scheduled tasks (avoids showing a neutral day as
  /// "missed").
  bool get hasActivity => totalScheduledXp > 0;
}
