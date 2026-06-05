import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:habit_up/models/goal_model.dart';
import 'package:habit_up/services/goal_storage_service.dart';

typedef GoalProgressCascadeHook = Future<void> Function(GoalModel goal);
typedef GoalXpAwardHook = Future<void> Function(GoalModel goal, int xpAwarded);
typedef GoalStreakHook = Future<void> Function(GoalModel goal);

/// Rich summary of the currently pinned goal for dashboard consumption.
class PinnedGoalDetails {
  const PinnedGoalDetails({
    required this.goalId,
    required this.title,
    required this.progress,
    required this.isCompleted,
    required this.motivationalSubtitle,
    required this.colorHex,
    required this.themeKey,
    required this.xp,
    required this.streak,
    required this.subGoalCount,
    required this.status,
  });

  final String goalId;
  final String title;
  final double progress;
  final bool isCompleted;
  final String? motivationalSubtitle;
  final String? colorHex;
  final String? themeKey;
  final int xp;
  final int streak;
  final int subGoalCount;
  final GoalStatus status;

  bool get isPinnable =>
      status == GoalStatus.active && !isCompleted;

  String get progressPercent => '${(progress * 100).toStringAsFixed(0)}%';
}

class DashboardGoalSummary {
  const DashboardGoalSummary({
    required this.totalCount,
    required this.activeCount,
    required this.completedCount,
    required this.pausedCount,
    required this.archivedCount,
    required this.pinnedGoalProgress,
    required this.pinnedGoalTitle,
    required this.pinnedGoalSubtitle,
    required this.pinnedGoalXp,
    required this.pinnedGoalStreak,
    required this.pinnedGoalIsCompleted,
    required this.averageProgress,
    required this.totalXp,
    required this.totalStreak,
  });

  final int totalCount;
  final int activeCount;
  final int completedCount;
  final int pausedCount;
  final int archivedCount;
  final double pinnedGoalProgress;
  final String? pinnedGoalTitle;
  final String? pinnedGoalSubtitle;
  final int pinnedGoalXp;
  final int pinnedGoalStreak;
  final bool pinnedGoalIsCompleted;
  final double averageProgress;
  final int totalXp;
  final int totalStreak;

  bool get hasPinnedGoal => pinnedGoalTitle != null;
}

class GoalProvider extends ChangeNotifier {
  GoalProvider({
    this._goalStorageService = const GoalStorageService(),
  });

  final GoalStorageService _goalStorageService;
  final List<GoalModel> _goals = <GoalModel>[];

  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  /// Hooks for hierarchy synchronization (Task → SubGoal → Goal)
  GoalProgressCascadeHook? onProgressCascadeRequested;
  GoalXpAwardHook? onXpAwarded;
  GoalStreakHook? onStreakUpdated;

  /// Fired when a goal is deleted — allows cascade cleanup of subgoals, tasks, etc.
  Future<void> Function(String goalId)? onCascadeDeleteRequested;

  // ---------------------------------------------------------------------------
  // Accessors
  // ---------------------------------------------------------------------------

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  UnmodifiableListView<GoalModel> get allGoals =>
      UnmodifiableListView<GoalModel>(_goals);

  /// Returns the currently pinned goal, or null if none is pinned.
  /// Safely ignores goals that have been deleted or have invalid state.
  GoalModel? get pinnedGoal {
    for (final goal in _goals) {
      if (goal.isPinned && _isValidGoal(goal)) {
        return goal;
      }
    }
    return null;
  }

  /// Returns a rich summary of the pinned goal for the dashboard hero.
  /// Returns null if no valid pinned goal exists.
  PinnedGoalDetails? get pinnedGoalDetails {
    final goal = pinnedGoal;
    if (goal == null) return null;

    return PinnedGoalDetails(
      goalId: goal.id,
      title: goal.title,
      progress: goal.progress,
      isCompleted: goal.isCompleted,
      motivationalSubtitle: goal.motivationalSubtitle,
      colorHex: goal.colorHex,
      themeKey: goal.themeKey,
      xp: goal.xp,
      streak: goal.streak,
      subGoalCount: goal.subGoalIds.length,
      status: goal.status,
    );
  }

  /// Safely check if a goal model is in a valid state for display/navigation.
  bool _isValidGoal(GoalModel? goal) {
    if (goal == null) return false;
    if (goal.id.isEmpty) return false;
    if (goal.title.isEmpty) return false;
    return true;
  }

  /// Whether a goal with [id] is eligible to be pinned (must be active).
  bool canPinGoal(String id) {
    final goal = getGoalById(id);
    if (goal == null) return false;
    return goal.status == GoalStatus.active && !goal.isCompleted;
  }

  // ---------------------------------------------------------------------------
  // Initialization & Hydration
  // ---------------------------------------------------------------------------

  Future<void> initialize() async {
    await _guardedMutation(() async {
      await _hydrateGoalsFromStorage();
      _isInitialized = true;
    });
  }

  Future<void> reload() async {
    await _guardedMutation(_hydrateGoalsFromStorage);
  }

  // ---------------------------------------------------------------------------
  // Core CRUD
  // ---------------------------------------------------------------------------

  Future<GoalModel> createGoal({
    required String id,
    required String title,
    String? description,
    String? colorHex,
    String? themeKey,
    String? motivationalSubtitle,
    DateTime? deadline,
    DateTime? targetCompletionDate,
  }) async {
    late GoalModel createdGoal;
    await _guardedMutation(() async {
      final now = DateTime.now();
      createdGoal = GoalModel(
        id: id,
        title: title.trim(),
        description: description?.trim(),
        colorHex: colorHex,
        themeKey: themeKey,
        progress: 0.0,
        isPinned: false,
        isCompleted: false,
        status: GoalStatus.active,
        motivationalSubtitle: motivationalSubtitle?.trim(),
        deadline: deadline,
        targetCompletionDate: targetCompletionDate,
        xp: 0,
        streak: 0,
        createdAt: now,
        completedAt: null,
        subGoalIds: const <String>[],
        updatedAt: now,
      );

      _goals.removeWhere((g) => g.id == createdGoal.id);
      _goals.add(createdGoal);
      _sortGoals();
      await _goalStorageService.saveGoal(createdGoal);
    });
    return createdGoal;
  }

  Future<GoalModel?> updateGoal({
    required String id,
    String? title,
    String? description,
    String? colorHex,
    String? themeKey,
    double? progress,
    bool? isPinned,
    bool? isCompleted,
    GoalStatus? status,
    DateTime? deadline,
    DateTime? targetCompletionDate,
    String? motivationalSubtitle,
    int? xp,
    int? streak,
    DateTime? completedAt,
    List<String>? subGoalIds,
    bool clearDescription = false,
    bool clearColorHex = false,
    bool clearThemeKey = false,
    bool clearDeadline = false,
    bool clearTargetCompletionDate = false,
    bool clearMotivationalSubtitle = false,
    bool clearCompletedAt = false,
  }) async {
    GoalModel? updatedGoal;
    await _guardedMutation(() async {
      final index = _goals.indexWhere((g) => g.id == id);
      if (index < 0) {
        return;
      }

      final existing = _goals[index];
      final now = DateTime.now();

      // If completing, set completedAt and update status
      final willComplete =
          isCompleted == true || (progress != null && progress >= 1.0);
      final resolvedCompletedAt = clearCompletedAt
          ? null
          : (completedAt ??
              (willComplete
                  ? (existing.completedAt ?? now)
                  : existing.completedAt));
      final resolvedStatus =
          willComplete ? GoalStatus.completed : (status ?? existing.status);

      updatedGoal = existing.copyWith(
        title: title?.trim(),
        description: description?.trim(),
        colorHex: colorHex,
        themeKey: themeKey,
        progress: progress?.clamp(0.0, 1.0),
        isPinned: isPinned,
        isCompleted: willComplete || (isCompleted ?? existing.isCompleted),
        status: resolvedStatus,
        deadline: deadline,
        targetCompletionDate: targetCompletionDate,
        motivationalSubtitle: motivationalSubtitle?.trim(),
        xp: xp,
        streak: streak,
        completedAt: resolvedCompletedAt,
        subGoalIds: subGoalIds,
        updatedAt: now,
        clearDescription: clearDescription,
        clearColorHex: clearColorHex,
        clearThemeKey: clearThemeKey,
        clearDeadline: clearDeadline,
        clearTargetCompletionDate: clearTargetCompletionDate,
        clearMotivationalSubtitle: clearMotivationalSubtitle,
        clearCompletedAt: clearCompletedAt,
      );

      _goals[index] = updatedGoal!;
      _sortGoals();
      await _goalStorageService.updateGoal(updatedGoal!);

      // Auto-unpin if the goal was pinned and its status is no longer pinnable
      if (updatedGoal!.isPinned) {
        await _autoUnpinIfNotPinnable(updatedGoal!);
      }

      await _triggerProgressCascadeHook(updatedGoal!);
    });
    return updatedGoal;
  }

  Future<void> deleteGoal(String id) async {
    await _guardedMutation(() async {
      final removedGoal = getGoalById(id);
      if (removedGoal == null) {
        return;
      }
      _goals.removeWhere((g) => g.id == id);
      await _goalStorageService.deleteGoal(id);
      await _triggerCascadeDeleteHook(removedGoal.id);
      await _triggerProgressCascadeHook(removedGoal);
    });
  }

  /// Returns a goal by ID, or null if not found or invalid.
  /// Safely handles deleted-goal references that still live in Hive.
  GoalModel? getGoalById(String id) {
    if (id.isEmpty) return null;
    for (final goal in _goals) {
      if (goal.id == id) {
        return _isValidGoal(goal) ? goal : null;
      }
    }
    return null;
  }

  /// Returns a safe dashboard-ready summary. Guarantees no crashed from
  /// missing provider data, deleted goals, or invalid pinned references.
  DashboardGoalSummary getSafeDashboardSummary() {
    try {
      return dashboardSummary;
    } catch (_) {
      return DashboardGoalSummary(
        totalCount: 0,
        activeCount: 0,
        completedCount: 0,
        pausedCount: 0,
        archivedCount: 0,
        pinnedGoalProgress: 0.0,
        pinnedGoalTitle: null,
        pinnedGoalSubtitle: null,
        pinnedGoalXp: 0,
        pinnedGoalStreak: 0,
        pinnedGoalIsCompleted: false,
        averageProgress: 0.0,
        totalXp: 0,
        totalStreak: 0,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Pinned Goal Management
  // ---------------------------------------------------------------------------

  /// Pin a goal as the single active mission.
  ///
  /// Only goals with [GoalStatus.active] can be pinned. If a different goal
  /// is already pinned it will be automatically unpinned first.
  Future<void> pinGoal(String id) async {
    await _guardedMutation(() async {
      final targetIndex = _goals.indexWhere((g) => g.id == id);
      if (targetIndex < 0) {
        return;
      }

      final target = _goals[targetIndex];

      // Validate — only active goals can be pinned
      if (target.status != GoalStatus.active || target.isCompleted) {
        return;
      }

      // Unpin current pinned goal if different
      final currentPinnedIndex = _goals.indexWhere((g) => g.isPinned);
      if (currentPinnedIndex >= 0 &&
          _goals[currentPinnedIndex].id != id) {
        final current = _goals[currentPinnedIndex];
        _goals[currentPinnedIndex] = current.copyWith(
          isPinned: false,
          updatedAt: DateTime.now(),
        );
      }

      _goals[targetIndex] = target.copyWith(
        isPinned: true,
        updatedAt: DateTime.now(),
      );

      await _goalStorageService.pinGoal(id);
    });
  }

  /// Unpin a specific goal.
  Future<void> unpinGoal(String id) async {
    await _guardedMutation(() async {
      final index = _goals.indexWhere((g) => g.id == id);
      if (index < 0) {
        return;
      }

      final current = _goals[index];
      _goals[index] = current.copyWith(
        isPinned: false,
        updatedAt: DateTime.now(),
      );

      await _goalStorageService.unpinGoal(id);
    });
  }

  /// Switch the pinned goal to [id] (same as [pinGoal]).
  Future<void> switchPinnedGoal(String id) async {
    await pinGoal(id);
  }

  /// Return [PinnedGoalDetails] for the currently pinned goal, or null.
  PinnedGoalDetails? getPinnedGoal() {
    return pinnedGoalDetails;
  }

  // ---------------------------------------------------------------------------
  // Progress Aggregation
  // ---------------------------------------------------------------------------

  /// Recalculate progress based on completed subgoals/tasks ratio.
  /// The [completedRatio] should be a value between 0.0 and 1.0.
  Future<void> recalculateGoalProgress(
    String id, {
    double? completedRatio,
  }) async {
    await _guardedMutation(() async {
      final index = _goals.indexWhere((g) => g.id == id);
      if (index < 0) {
        return;
      }

      final existing = _goals[index];
      final newProgress =
          completedRatio?.clamp(0.0, 1.0) ?? existing.progress;
      final willComplete = newProgress >= 1.0;
      final now = DateTime.now();

      _goals[index] = existing.copyWith(
        progress: newProgress,
        isCompleted: willComplete,
        completedAt: willComplete ? (existing.completedAt ?? now) : null,
        status: willComplete ? GoalStatus.completed : GoalStatus.active,
        updatedAt: now,
        clearCompletedAt: !willComplete,
      );

      await _goalStorageService.updateGoalProgress(id, newProgress);
      await _triggerProgressCascadeHook(_goals[index]);
    });
  }

  /// Update completion status for a goal.
  Future<void> updateGoalCompletion(String id, bool isCompleted) async {
    await _guardedMutation(() async {
      final index = _goals.indexWhere((g) => g.id == id);
      if (index < 0) {
        return;
      }

      final existing = _goals[index];
      final now = DateTime.now();

      _goals[index] = existing.copyWith(
        isCompleted: isCompleted,
        progress: isCompleted ? 1.0 : existing.progress,
        completedAt: isCompleted ? (existing.completedAt ?? now) : null,
        status: isCompleted ? GoalStatus.completed : GoalStatus.active,
        updatedAt: now,
        clearCompletedAt: !isCompleted,
      );

      await _goalStorageService.updateGoalProgress(
        id,
        isCompleted ? 1.0 : existing.progress,
      );
      await _triggerProgressCascadeHook(_goals[index]);
    });
  }

  /// Sync goal progress from subgoal/task changes (hook receiver).
  Future<void> syncGoalProgress(String id) async {
    await recalculateGoalProgress(id);
  }

  // ---------------------------------------------------------------------------
  // Status Management
  // ---------------------------------------------------------------------------

  Future<void> setGoalStatus(String id, GoalStatus status) async {
    await _guardedMutation(() async {
      final index = _goals.indexWhere((g) => g.id == id);
      if (index < 0) {
        return;
      }

      final existing = _goals[index];
      final now = DateTime.now();
      final isCompleted = status == GoalStatus.completed;

      _goals[index] = existing.copyWith(
        status: status,
        isCompleted: isCompleted || existing.isCompleted,
        progress: isCompleted ? 1.0 : existing.progress,
        completedAt:
            isCompleted ? (existing.completedAt ?? now) : existing.completedAt,
        updatedAt: now,
      );

      await _goalStorageService.updateGoal(_goals[index]);

      // Auto-unpin if the pinned goal was moved to a non-pinnable status
      if (_goals[index].isPinned) {
        await _autoUnpinIfNotPinnable(_goals[index]);
      }
    });
  }

  List<GoalModel> getGoalsByStatus(GoalStatus status) {
    return _goals
        .where((goal) => goal.status == status)
        .toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // XP & Streak
  // ---------------------------------------------------------------------------

  Future<void> addGoalXp(String id, int xpDelta) async {
    await _guardedMutation(() async {
      final index = _goals.indexWhere((g) => g.id == id);
      if (index < 0) {
        return;
      }

      final existing = _goals[index];
      final newXp =
          (existing.xp + xpDelta).clamp(0, double.maxFinite).toInt();

      _goals[index] = existing.copyWith(
        xp: newXp,
        updatedAt: DateTime.now(),
      );

      await _goalStorageService.updateGoalXp(id, xpDelta);

      final hook = onXpAwarded;
      if (hook != null) {
        await hook(_goals[index], xpDelta);
      }
    });
  }

  Future<void> updateGoalStreak(String id, int streak) async {
    await _guardedMutation(() async {
      final index = _goals.indexWhere((g) => g.id == id);
      if (index < 0) {
        return;
      }

      final existing = _goals[index];
      _goals[index] = existing.copyWith(
        streak: streak,
        updatedAt: DateTime.now(),
      );

      await _goalStorageService.updateGoalStreak(id, streak);

      final hook = onStreakUpdated;
      if (hook != null) {
        await hook(_goals[index]);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Memoization — cached computed properties with dirty flag
  // ---------------------------------------------------------------------------

  /// Cache for computed views that are expensive to rebuild.
  int _cachedGoalsHash = 0;
  List<GoalModel>? _cachedActiveGoals;
  List<GoalModel>? _cachedCompletedGoals;
  List<GoalModel>? _cachedPausedGoals;
  List<GoalModel>? _cachedArchivedGoals;
  DashboardGoalSummary? _cachedDashboardSummary;

  /// Returns true if the goals list hasn't changed since the last cache build.
  bool get _goalsListUnchanged {
    final hash = Object.hashAll(_goals);
    if (hash == _cachedGoalsHash) return true;
    _cachedGoalsHash = hash;
    return false;
  }

  /// Invalidates all memoized caches. Call after any mutation to [_goals].
  void _invalidateCaches() {
    _cachedGoalsHash = 0; // Force rebuild on next access
    _cachedActiveGoals = null;
    _cachedCompletedGoals = null;
    _cachedPausedGoals = null;
    _cachedArchivedGoals = null;
    _cachedDashboardSummary = null;
  }

  UnmodifiableListView<GoalModel> get activeGoals {
    if (_cachedActiveGoals == null || !_goalsListUnchanged) {
      _cachedActiveGoals = _goals
          .where((goal) => goal.status == GoalStatus.active)
          .toList(growable: false);
    }
    return UnmodifiableListView<GoalModel>(_cachedActiveGoals!);
  }

  UnmodifiableListView<GoalModel> get completedGoals {
    if (_cachedCompletedGoals == null || !_goalsListUnchanged) {
      _cachedCompletedGoals = _goals
          .where((goal) => goal.status == GoalStatus.completed)
          .toList(growable: false);
    }
    return UnmodifiableListView<GoalModel>(_cachedCompletedGoals!);
  }

  UnmodifiableListView<GoalModel> get pausedGoals {
    if (_cachedPausedGoals == null || !_goalsListUnchanged) {
      _cachedPausedGoals = _goals
          .where((goal) => goal.status == GoalStatus.paused)
          .toList(growable: false);
    }
    return UnmodifiableListView<GoalModel>(_cachedPausedGoals!);
  }

  UnmodifiableListView<GoalModel> get archivedGoals {
    if (_cachedArchivedGoals == null || !_goalsListUnchanged) {
      _cachedArchivedGoals = _goals
          .where((goal) => goal.status == GoalStatus.archived)
          .toList(growable: false);
    }
    return UnmodifiableListView<GoalModel>(_cachedArchivedGoals!);
  }

  DashboardGoalSummary get dashboardSummary {
    if (_cachedDashboardSummary != null && _goalsListUnchanged) {
      return _cachedDashboardSummary!;
    }
    final summary = _buildDashboardSummary();
    _cachedDashboardSummary = summary;
    return summary;
  }

  DashboardGoalSummary _buildDashboardSummary() {
    final activeCount =
        _goals.where((g) => g.status == GoalStatus.active).length;
    final completedCount =
        _goals.where((g) => g.status == GoalStatus.completed).length;
    final pausedCount =
        _goals.where((g) => g.status == GoalStatus.paused).length;
    final archivedCount =
        _goals.where((g) => g.status == GoalStatus.archived).length;
    final averageProgress = _goals.isEmpty
        ? 0.0
        : _goals.fold<double>(0.0, (sum, g) => sum + g.progress) /
            _goals.length;
    final pinGoal = pinnedGoal;
    final totalXp = _goals.fold<int>(0, (sum, g) => sum + g.xp);
    final totalStreak = _goals.fold<int>(0, (sum, g) => sum + g.streak);

    return DashboardGoalSummary(
      totalCount: _goals.length,
      activeCount: activeCount,
      completedCount: completedCount,
      pausedCount: pausedCount,
      archivedCount: archivedCount,
      pinnedGoalProgress: pinGoal?.progress ?? 0.0,
      pinnedGoalTitle: pinGoal?.title,
      pinnedGoalSubtitle: pinGoal?.motivationalSubtitle,
      pinnedGoalXp: pinGoal?.xp ?? 0,
      pinnedGoalStreak: pinGoal?.streak ?? 0,
      pinnedGoalIsCompleted: pinGoal?.isCompleted ?? false,
      averageProgress: averageProgress,
      totalXp: totalXp,
      totalStreak: totalStreak,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> _hydrateGoalsFromStorage() async {
    final goals = await _goalStorageService.getAllGoals();
    _goals
      ..clear()
      ..addAll(goals);
    _validatePinnedGoalOnHydration();
    _sortGoals();
    _invalidateCaches();
  }

  /// Ensure the pinned goal is still valid after loading from storage.
  /// If the pinned goal was archived or paused, auto-unpin it.
  void _validatePinnedGoalOnHydration() {
    final pinIndex = _goals.indexWhere((g) => g.isPinned);
    if (pinIndex < 0) return;

    final goal = _goals[pinIndex];
    if (goal.status == GoalStatus.archived ||
        goal.status == GoalStatus.paused) {
      _goals[pinIndex] = goal.copyWith(
        isPinned: false,
        updatedAt: DateTime.now(),
      );
      _goalStorageService.unpinGoal(goal.id);
    }
  }

  /// If [goal] is pinned but no longer eligible, auto-unpin it.
  Future<void> _autoUnpinIfNotPinnable(GoalModel goal) async {
    if (goal.status == GoalStatus.active) return;
    if (goal.status == GoalStatus.completed) return;

    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index < 0) return;

    _goals[index] = goal.copyWith(
      isPinned: false,
      updatedAt: DateTime.now(),
    );
    await _goalStorageService.unpinGoal(goal.id);
  }

  void _sortGoals() {
    _goals.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
  }

  Future<void> _guardedMutation(Future<void> Function() action) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await action();
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _setLoading(false);
      _invalidateCaches();
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
  }

  Future<void> _triggerProgressCascadeHook(GoalModel goal) async {
    final hook = onProgressCascadeRequested;
    if (hook != null) {
      await hook(goal);
    }
  }

  Future<void> _triggerCascadeDeleteHook(String goalId) async {
    final hook = onCascadeDeleteRequested;
    if (hook != null) {
      await hook(goalId);
    }
  }
}
