import 'package:flutter/foundation.dart' show ChangeNotifier, ValueChanged;
import 'package:habit_up/models/goal_model.dart';
import 'package:habit_up/models/task_model.dart';
import 'package:habit_up/providers/goal_provider.dart';
import 'package:habit_up/providers/task_provider.dart';
import 'package:habit_up/services/productivity_quality_service.dart';
import 'package:habit_up/services/user_storage_service.dart';

// ---------------------------------------------------------------------------
// Data classes for the XP/Streak intelligence layer
// ---------------------------------------------------------------------------

/// Snapshot of the user's current XP/level/streak state.
class XpStreakSnapshot {
  const XpStreakSnapshot({
    required this.totalXp,
    required this.level,
    required this.levelProgress,
    required this.currentStreak,
    required this.longestStreak,
    required this.todayXpEarned,
    required this.thisWeekXp,
    required this.thisMonthXp,
    required this.momentumScore,
    required this.consistencyRating,
    required this.dailyTaskCompletionRate,
    required this.weeklyTaskCompletionRate,
  });

  final int totalXp;
  final int level;
  final double levelProgress;
  final int currentStreak;
  final int longestStreak;
  final int todayXpEarned;
  final int thisWeekXp;
  final int thisMonthXp;
  final double momentumScore;
  final String consistencyRating;
  final double dailyTaskCompletionRate;
  final double weeklyTaskCompletionRate;

  /// XP needed to reach the next level.
  int get xpForNextLevel => (level) * XpStreakService.xpPerLevel;

  /// XP remaining to next level (never negative).
  int get xpRemaining => (xpForNextLevel - totalXp).clamp(0, double.maxFinite).toInt();

  /// Whether momentum is building (streak >= 3).
  bool get isMomentumBuilding => currentStreak >= 3;

  /// Whether streak is on fire (streak >= 7).
  bool get isStreakOnFire => currentStreak >= 7;
}

/// Productivity metrics summary.
class ProductivitySummary {
  const ProductivitySummary({
    required this.totalTasksCompleted,
    required this.totalXpEarned,
    required this.streakDays,
    required this.bestStreakDays,
    required this.averageCompletionRate,
    required this.totalFocusMinutes,
    required this.pinnedGoalXpEarned,
  });

  final int totalTasksCompleted;
  final int totalXpEarned;
  final int streakDays;
  final int bestStreakDays;
  final double averageCompletionRate;
  final int totalFocusMinutes;
  final int pinnedGoalXpEarned;

  String get productivityGrade {
    if (averageCompletionRate >= 0.9) return 'S';
    if (averageCompletionRate >= 0.75) return 'A';
    if (averageCompletionRate >= 0.6) return 'B';
    if (averageCompletionRate >= 0.4) return 'C';
    return 'D';
  }
}

/// Detailed momentum breakdown.
class MomentumDetails {
  const MomentumDetails({
    required this.score,
    required this.streakContribution,
    required this.completionRateContribution,
    required this.consistencyContribution,
    required this.bonusContribution,
  });

  final double score;
  final double streakContribution;
  final double completionRateContribution;
  final double consistencyContribution;
  final double bonusContribution;
}

// ---------------------------------------------------------------------------
// XpStreakService — Central Intelligence Engine
// ---------------------------------------------------------------------------

/// Central XP + Streak Intelligence Engine.
///
/// This service exposes pure methods (no direct hook wiring) so it can be
/// called collaboratively from [HierarchyCascadeService]'s existing hook
/// handlers. This avoids overwriting the cascade's hooks.
///
/// Wires only the **top-level** hooks ([GoalProvider.onXpAwarded] and
/// [GoalProvider.onStreakUpdated]) that are unused by the cascade.
class XpStreakService extends ChangeNotifier {
  XpStreakService({
    required this._taskProvider,
    required this._goalProvider,
    required this._userStorageService,
  });

  final TaskProvider _taskProvider;
  final GoalProvider _goalProvider;
  final UserStorageService _userStorageService;

  // ---------------------------------------------------------------------------
  // Configuration Constants
  // ---------------------------------------------------------------------------

  /// Base XP rewards per difficulty tier (used when `task.xpReward` is 0).
  static const Map<TaskDifficulty, int> baseXpByDifficulty = {
    TaskDifficulty.easy: 3,
    TaskDifficulty.medium: 5,
    TaskDifficulty.hard: 7,
  };

  /// Bonus XP on top of base for completing a task.
  static const Map<TaskDifficulty, int> difficultyBonusXp = {
    TaskDifficulty.easy: 0,
    TaskDifficulty.medium: 0,
    TaskDifficulty.hard: 0,
  };

  /// Streak multiplier: +X% per consecutive day, capped.
  static const double streakBonusPercentPerDay = 0.05; // 5% per day
  static const int maxStreakBonusDays = 14; // cap at 70% bonus

  /// XP required per level.
  static const int xpPerLevel = 500;

  // ---------------------------------------------------------------------------
  // Persisted state
  // ---------------------------------------------------------------------------

  int _cachedUserXp = 0;
  int _cachedUserLevel = 1;
  int _cachedCurrentStreak = 0;
  int _cachedLongestStreak = 0;
  bool _initialized = false;

  /// Daily XP ledger: maps date keys (yyyy-MM-dd) to actual XP earned that day
  /// (with streak bonuses applied). Updated by [onTaskXpAwarded].
  final Map<String, int> _dailyXpLedger = {};

  /// Last date key for which the ledger was cleaned.
  String _lastLedgerCleanupDate = '';

  // ---------------------------------------------------------------------------
  // Level-up detection
  // ---------------------------------------------------------------------------

  /// Fired when the user crosses a level threshold.
  /// Passes the new level number.
  ValueChanged<int>? onLevelUp;

  /// The level before the most recent XP award.
  int _previousLevel = 1;

  /// Pending level-up that hasn't been acknowledged by the UI yet.
  /// Set when a level-up occurs, cleared by [consumePendingLevelUp].
  int? _pendingLevelUp;

  /// The last level the user reached that hasn't been shown as a popup yet.
  int? get pendingLevelUp => _pendingLevelUp;

  /// Consume and return the pending level-up (clears it afterwards).
  /// Returns null if no pending level-up exists.
  int? consumePendingLevelUp() {
    final result = _pendingLevelUp;
    _pendingLevelUp = null;
    return result;
  }

  /// Check for level-up after an XP award and fire the callback.
  void _checkForLevelUp() {
    if (_cachedUserLevel > _previousLevel) {
      _pendingLevelUp = _cachedUserLevel;
      onLevelUp?.call(_cachedUserLevel);
    }
    _previousLevel = _cachedUserLevel;
  }

  /// Whether the service has loaded user data from storage.
  bool get isInitialized => _initialized;

  // ---------------------------------------------------------------------------
  // Duplicate award prevention guards
  // ---------------------------------------------------------------------------

  /// Tracks task IDs that have been processed for XP award.
  /// Prevents duplicate XP from the same task being counted multiple times.
  final Set<String> _processedTaskXpIds = <String>{};

  /// Tracks task IDs that have been processed for streak update.
  final Set<String> _processedStreakTaskIds = <String>{};

  /// Last date key for which the XP guard sets were cleaned.
  String _lastGuardCleanupDate = '';

  void _ensureDailyGuardCleanup() {
    final todayKey = _dateKey(DateTime.now());
    if (_lastGuardCleanupDate == todayKey) return;
    _lastGuardCleanupDate = todayKey;
    _processedTaskXpIds.clear();
    _processedStreakTaskIds.clear();
  }

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Loads persisted user XP/streak data. Call once at app startup.
  Future<void> initialize() async {
    await _loadUserData();
    _wireTopLevelHooks();
    _initialized = true;
    notifyListeners();
  }

  Future<void> _loadUserData() async {
    final user = await _userStorageService.getCurrentUser();
    if (user != null) {
      _cachedUserXp = user.xp;
      _cachedUserLevel = user.level;
      _previousLevel = user.level;
      _cachedCurrentStreak = user.currentStreak;
      _cachedLongestStreak = user.longestStreak;
    }
  }

  /// Wires ONLY the top-level hooks that [HierarchyCascadeService] does NOT
  /// already own: [GoalProvider.onXpAwarded] and [GoalProvider.onStreakUpdated].
  ///
  /// [HierarchyCascadeService] handles the Task → SubGoal → Goal chain
  /// for progress, XP, and streak. The XpStreakService picks up after the
  /// cascade updates the Goal level, then persists to the UserModel.
  void _wireTopLevelHooks() {
    _goalProvider.onXpAwarded = _onGoalXpAwarded;
    _goalProvider.onStreakUpdated = _onGoalStreakUpdated;
  }

  // ---------------------------------------------------------------------------
  // XP Calculation
  // ---------------------------------------------------------------------------

  /// Calculate the total XP to award for completing a [task], including
  /// difficulty bonus and streak multiplier.
  int calculateTaskXp(TaskModel task) {      final baseXp = task.xpReward > 0
        ? task.xpReward
        : (baseXpByDifficulty[task.difficulty] ?? 3);
    final difficultyBonus = difficultyBonusXp[task.difficulty] ?? 0;

    final streakDays = _cachedCurrentStreak.clamp(0, maxStreakBonusDays);
    final multiplier = 1.0 + (streakDays * streakBonusPercentPerDay);

    final total = ((baseXp + difficultyBonus) * multiplier).round();
    return total.clamp(0, double.maxFinite).toInt();
  }

  /// Calculate level from total XP.
  int calculateLevel(int totalXp) {
    return (totalXp ~/ xpPerLevel) + 1;
  }

  /// Calculate progress within the current level (0.0 to 1.0).
  double calculateLevelProgress(int totalXp) {
    return (totalXp % xpPerLevel) / xpPerLevel;
  }

  /// The productivity quality scoring engine used for XP-ratio-based
  /// streak evaluation.
  final ProductivityQualityService _qualityService =
      const ProductivityQualityService();

  // ---------------------------------------------------------------------------
  // Streak Management (Productivity-Quality Based)
  // ---------------------------------------------------------------------------

  /// Calculate the current daily streak based on XP-ratio productivity
  /// quality rules:
  ///   - 90%+  → full streak day
  ///   - 50–89% → partial productivity day
  ///   - <50%  → streak-break / failed day
  ///
  /// A streak continues as long as each day is at least a **partial**
  /// productivity day (≥50%). Days without any scheduled tasks are
  /// treated as neutral (neither breaks nor extends the streak).
  int calculateDailyStreak() {
    final today = DateTime.now();
    var streakDays = 0;

    for (var i = 0; i < 365; i++) {
      final date = today.subtract(Duration(days: i));
      final score = _qualityService.calculateDailyProductivityScore(
        date,
        _taskProvider,
      );

      // No tasks scheduled — neutral day, neither breaks nor extends
      final tasksOnDate = _taskProvider.getTasksForDate(date);
      if (tasksOnDate.isEmpty && i > 0) {
        continue;
      }
      if (tasksOnDate.isEmpty) continue;

      if (score >= ProductivityQualityService.partialStreakThreshold) {
        // Partial or full productivity day — streak continues
        streakDays++;
      } else {
        // Failed day — streak breaks
        if (i == 0) break;
        if (streakDays > 0) break;
        return 0;
      }
    }

    return streakDays;
  }

  /// Update streak from task completion data using productivity quality
  /// scoring. Call this when a task is completed (typically from
  /// [HierarchyCascadeService]'s hooks).
  Future<void> updateDailyStreak() async {
    final streak = calculateDailyStreak();
    if (streak > _cachedLongestStreak) {
      _cachedLongestStreak = streak;
    }
    _cachedCurrentStreak = streak;
    await _persistUserData();
    _invalidateSnapshotCache();
    notifyListeners();
  }

  /// Reset the streak (called when streak is broken).
  Future<void> resetBrokenStreak() async {
    _cachedCurrentStreak = 0;
    await _persistUserData();
    _invalidateSnapshotCache();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Momentum Score
  // ---------------------------------------------------------------------------

  /// Calculate the momentum score (0.0 to 1.0).
  double calculateMomentumScore() {
    final streakContribution =
        (_cachedCurrentStreak / 30.0).clamp(0.0, 0.5);
    final last7Days = _getLast7DaysCompletionRate();
    final completionContribution = last7Days * 0.3;
    final consistency = _calculateWeeklyConsistency();
    final consistencyContribution = consistency * 0.2;
    final bonusContribution = _cachedCurrentStreak >= 7
        ? 0.1
        : _cachedCurrentStreak >= 3
            ? 0.05
            : 0.0;

    return (streakContribution +
            completionContribution +
            consistencyContribution +
            bonusContribution)
        .clamp(0.0, 1.0);
  }

  /// Get detailed momentum breakdown.
  MomentumDetails getMomentumDetails() {
    final streakContribution =
        (_cachedCurrentStreak / 30.0).clamp(0.0, 0.5);
    final last7Days = _getLast7DaysCompletionRate();
    final completionContribution = last7Days * 0.3;
    final consistency = _calculateWeeklyConsistency();
    final consistencyContribution = consistency * 0.2;
    final bonusContribution = _cachedCurrentStreak >= 7
        ? 0.1
        : _cachedCurrentStreak >= 3
            ? 0.05
            : 0.0;

    return MomentumDetails(
      score: (streakContribution +
              completionContribution +
              consistencyContribution +
              bonusContribution)
          .clamp(0.0, 1.0),
      streakContribution: streakContribution,
      completionRateContribution: completionContribution,
      consistencyContribution: consistencyContribution,
      bonusContribution: bonusContribution,
    );
  }

  /// Get a human-readable consistency rating.
  String getConsistencyRating() {
    final score = calculateMomentumScore();
    if (score >= 0.85) return 'Exceptional';
    if (score >= 0.7) return 'Strong';
    if (score >= 0.5) return 'Building';
    if (score >= 0.3) return 'Getting Started';
    return 'Needs Momentum';
  }

  double _getLast7DaysCompletionRate() {
    final now = DateTime.now();
    double totalScore = 0.0;
    int count = 0;

    for (var i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final tasks = _taskProvider.getTasksForDate(date);
      if (tasks.isEmpty) continue;
      totalScore += _qualityService.calculateDailyProductivityScore(
        date,
        _taskProvider,
      );
      count++;
    }

    return count == 0 ? 0.0 : totalScore / count;
  }

  double _calculateWeeklyConsistency() {
    final now = DateTime.now();
    var activeDays = 0;

    for (var i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final tasks = _taskProvider.getTasksForDate(date);
      if (tasks.any((t) => t.isCompleted)) {
        activeDays++;
      }
    }

    return activeDays / 7.0;
  }

  double getDailyTaskCompletionRate() {
    return _qualityService.calculateDailyProductivityScore(
      DateTime.now(),
      _taskProvider,
    );
  }

  double getWeeklyTaskCompletionRate() {
    return _getLast7DaysCompletionRate();
  }

  // ---------------------------------------------------------------------------
  // XP Aggregation Queries
  // ---------------------------------------------------------------------------

  /// Return the date key (yyyy-MM-dd) for the given [date].
  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Remove ledger entries older than 60 days to prevent unbounded growth.
  void _pruneOldLedgerEntries() {
    final todayKey = _dateKey(DateTime.now());
    if (_lastLedgerCleanupDate == todayKey) return;
    _lastLedgerCleanupDate = todayKey;
    if (_dailyXpLedger.length <= 60) return;

    final threshold = DateTime.now().subtract(const Duration(days: 60));
    _dailyXpLedger.removeWhere((key, _) {
      final parts = key.split('-');
      if (parts.length != 3) return false;
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      return date.isBefore(threshold);
    });
  }

  int getTodayXp() {
    // Use the ledged amount which includes streak bonuses.
    final todayKey = _dateKey(DateTime.now());
    return _dailyXpLedger[todayKey] ?? 0;
  }

  int getThisWeekXp() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    var total = 0;
    for (var i = 0; i < 7; i++) {
      final date = monday.add(Duration(days: i));
      final key = _dateKey(date);
      total += _dailyXpLedger[key] ?? 0;
    }
    return total;
  }

  int getThisMonthXp() {
    final now = DateTime.now();
    var total = 0;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(now.year, now.month, day);
      final key = _dateKey(date);
      total += _dailyXpLedger[key] ?? 0;
    }
    return total;
  }

  /// Returns the user's total XP from the authoritative source:
  /// [_cachedUserXp], which is updated by [onTaskXpAwarded] and
  /// [onTaskXpReversed].
  ///
  /// Do NOT add subGoal.xp or goal.xp here — those are already accumulated
  /// into [_cachedUserXp] via the hierarchy cascade hook chain.
  int getTotalXp() {
    return _cachedUserXp;
  }

  int getPinnedGoalXp() {
    return _goalProvider.pinnedGoal?.xp ?? 0;
  }

  int getTodayFocusMinutes() {
    final todayTasks = _taskProvider.getTodayTasks();
    return todayTasks
        .where((t) => t.isCompleted && t.estimatedFocusDurationMinutes != null)
        .fold<int>(
            0, (sum, t) => sum + (t.estimatedFocusDurationMinutes ?? 0));
  }

  // ---------------------------------------------------------------------------
  // Public methods called by HierarchyCascadeService
  // ---------------------------------------------------------------------------

  /// Called by [HierarchyCascadeService] when a task is completed and XP is
  /// awarded. Updates user-level XP and level.
  ///
  /// Includes duplicate award prevention — the same task ID will not be
  /// processed more than once per day.
  Future<void> onTaskXpAwarded(TaskModel task, int baseXp) async {
    _ensureDailyGuardCleanup();

    // Prevent duplicate XP awards for the same task
    if (_processedTaskXpIds.contains(task.id)) {
      return;
    }
    _processedTaskXpIds.add(task.id);

    final totalXp = calculateTaskXp(task);
    _cachedUserXp += totalXp;
    final newLevel = calculateLevel(_cachedUserXp);
    _cachedUserLevel = newLevel;
    _checkForLevelUp();

    // Track earned XP with streak bonuses in the daily ledger.
    _pruneOldLedgerEntries();
    final todayKey = _dateKey(DateTime.now());
    _dailyXpLedger[todayKey] = (_dailyXpLedger[todayKey] ?? 0) + totalXp;

    await _persistUserData();
    _invalidateSnapshotCache();
    notifyListeners();
  }

  /// Called by [HierarchyCascadeService] when a task is toggled from
  /// complete → incomplete. Reverses the XP awarded for that task:
  /// subtracts the base XP (without streak bonus) from the user-level
  /// cached XP and from the daily ledger.
  ///
  /// Does NOT trigger level-down — the level stays as-is even if XP drops
  /// below the threshold. The level will naturally correct when the user
  /// earns enough XP to level up again.
  Future<void> onTaskXpReversed(TaskModel task, int baseXp) async {
    _ensureDailyGuardCleanup();

    final totalXp = calculateTaskXp(task);
    _cachedUserXp = (_cachedUserXp - totalXp).clamp(0, double.maxFinite).toInt();

    // Remove from processed guard so the task can be re-processed on
    // re-completion (the toggleTaskCompletion method already handles this,
    // but we clear it here too for safety).
    _processedTaskXpIds.remove(task.id);

    // Adjust the daily XP ledger.
    _pruneOldLedgerEntries();
    final todayKey = _dateKey(DateTime.now());
    final currentLedger = _dailyXpLedger[todayKey] ?? 0;
    final adjusted = (currentLedger - totalXp).clamp(0, double.maxFinite).toInt();
    if (adjusted <= 0) {
      _dailyXpLedger.remove(todayKey);
    } else {
      _dailyXpLedger[todayKey] = adjusted;
    }

    await _persistUserData();
    _invalidateSnapshotCache();
    notifyListeners();
  }

  /// Called by [HierarchyCascadeService] when a task is completed for streak
  /// tracking. Updates the user-level daily streak.
  ///
  /// Includes duplicate streak prevention — the same task ID will not trigger
  /// a streak recalculation more than once per day.
  Future<void> onTaskCompletedForStreak(TaskModel task) async {
    _ensureDailyGuardCleanup();

    // Prevent duplicate streak updates for the same task
    if (_processedStreakTaskIds.contains(task.id)) {
      return;
    }
    _processedStreakTaskIds.add(task.id);

    await updateDailyStreak();
  }

  // ---------------------------------------------------------------------------
  // Memoized snapshot with dirty flag
  // ---------------------------------------------------------------------------

  XpStreakSnapshot? _cachedSnapshot;
  ProductivitySummary? _cachedProductivitySummary;
  int _cachedCurrentStreakForSnapshot = -1;
  int _cachedLongestStreakForSnapshot = -1;

  void _invalidateSnapshotCache() {
    _cachedSnapshot = null;
    _cachedProductivitySummary = null;
  }

  /// Returns a complete snapshot of the current XP/streak/momentum state.
  ///
  /// Result is cached and only recomputed when streak, XP, or ledger changes.
  XpStreakSnapshot get snapshot {
    if (_cachedSnapshot != null &&
        _cachedCurrentStreakForSnapshot == _cachedCurrentStreak &&
        _cachedLongestStreakForSnapshot == _cachedLongestStreak) {
      return _cachedSnapshot!;
    }

    final totalXp = getTotalXp();
    final result = XpStreakSnapshot(
      totalXp: totalXp,
      level: calculateLevel(totalXp),
      levelProgress: calculateLevelProgress(totalXp),
      currentStreak: _cachedCurrentStreak,
      longestStreak: _cachedLongestStreak,
      todayXpEarned: getTodayXp(),
      thisWeekXp: getThisWeekXp(),
      thisMonthXp: getThisMonthXp(),
      momentumScore: calculateMomentumScore(),
      consistencyRating: getConsistencyRating(),
      dailyTaskCompletionRate: getDailyTaskCompletionRate(),
      weeklyTaskCompletionRate: getWeeklyTaskCompletionRate(),
    );

    _cachedSnapshot = result;
    _cachedCurrentStreakForSnapshot = _cachedCurrentStreak;
    _cachedLongestStreakForSnapshot = _cachedLongestStreak;
    return result;
  }

  ProductivitySummary get productivitySummary {
    if (_cachedProductivitySummary != null &&
        _cachedCurrentStreakForSnapshot == _cachedCurrentStreak) {
      return _cachedProductivitySummary!;
    }

    final result = ProductivitySummary(
      totalTasksCompleted: _taskProvider.completedTasks.length,
      totalXpEarned: getTotalXp(),
      streakDays: _cachedCurrentStreak,
      bestStreakDays: _cachedLongestStreak,
      averageCompletionRate: getWeeklyTaskCompletionRate(),
      totalFocusMinutes: getTodayFocusMinutes(),
      pinnedGoalXpEarned: getPinnedGoalXp(),
    );

    _cachedProductivitySummary = result;
    return result;
  }

  // ---------------------------------------------------------------------------
  // Top-level hook handlers (wired by _wireTopLevelHooks)
  // ---------------------------------------------------------------------------

  /// Catch goal XP updates from the cascade and refresh UI.
  Future<void> _onGoalXpAwarded(GoalModel goal, int xpDelta) async {
    _invalidateSnapshotCache();
    notifyListeners();
  }

  /// Catch goal streak updates from the cascade and refresh UI.
  Future<void> _onGoalStreakUpdated(GoalModel goal) async {
    _invalidateSnapshotCache();
    notifyListeners();
  }

  /// Clear the top-level hooks so the service can be safely garbage-collected.
  @override
  void dispose() {
    if (_goalProvider.onXpAwarded == _onGoalXpAwarded) {
      _goalProvider.onXpAwarded = null;
    }
    if (_goalProvider.onStreakUpdated == _onGoalStreakUpdated) {
      _goalProvider.onStreakUpdated = null;
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  Future<void> _persistUserData() async {
    final user = await _userStorageService.getCurrentUser();
    if (user == null) return;

    await _userStorageService.updateXp(_cachedUserXp);
    await _userStorageService.updateLevel(_cachedUserLevel);
    await _userStorageService.updateStreaks(
      currentStreak: _cachedCurrentStreak,
      longestStreak: _cachedLongestStreak,
    );
  }

  /// Force refresh from storage.
  Future<void> refreshFromStorage() async {
    await _loadUserData();
    _invalidateSnapshotCache();
    notifyListeners();
  }
}
