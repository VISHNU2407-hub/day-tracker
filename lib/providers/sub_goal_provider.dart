import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:habit_up/models/sub_goal_model.dart';
import 'package:habit_up/services/sub_goal_storage_service.dart';

typedef SubGoalProgressCascadeHook = Future<void> Function(SubGoalModel subGoal);
typedef SubGoalXpAwardHook = Future<void> Function(SubGoalModel subGoal, int xpAwarded);
typedef SubGoalStreakHook = Future<void> Function(SubGoalModel subGoal);

class DashboardSubGoalSummary {
  const DashboardSubGoalSummary({
    required this.activeCount,
    required this.completedCount,
    required this.pausedCount,
    required this.overdueCount,
    required this.archivedCount,
    required this.totalXp,
    required this.averageProgress,
  });

  final int activeCount;
  final int completedCount;
  final int pausedCount;
  final int overdueCount;
  final int archivedCount;
  final int totalXp;
  final double averageProgress;
}

class SubGoalProvider extends ChangeNotifier {
  SubGoalProvider({
    this._subGoalStorageService = const SubGoalStorageService(),
  });

  final SubGoalStorageService _subGoalStorageService;
  final List<SubGoalModel> _subGoals = <SubGoalModel>[];

  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  /// Hooks for hierarchy synchronization (Task -> SubGoal -> Goal)
  SubGoalProgressCascadeHook? onProgressCascadeRequested;
  SubGoalXpAwardHook? onXpAwarded;
  SubGoalStreakHook? onStreakUpdated;

  /// Fired when a subgoal is deleted — allows cascade cleanup of linked tasks, etc.
  Future<void> Function(String subGoalId)? onCascadeDeleteRequested;

  // ---------------------------------------------------------------------------
  // Accessors
  // ---------------------------------------------------------------------------

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  // ---------------------------------------------------------------------------
  // Memoization - cached computed properties with dirty flag
  // ---------------------------------------------------------------------------

  int _cachedSubGoalsHash = 0;
  List<SubGoalModel>? _cachedActiveSubGoals;
  List<SubGoalModel>? _cachedCompletedSubGoals;
  List<SubGoalModel>? _cachedPausedSubGoals;
  List<SubGoalModel>? _cachedOverdueSubGoals;
  List<SubGoalModel>? _cachedArchivedSubGoals;
  DashboardSubGoalSummary? _cachedDashboardSummary;

  bool get _subGoalsListUnchanged {
    final hash = Object.hashAll(_subGoals);
    if (hash == _cachedSubGoalsHash) return true;
    _cachedSubGoalsHash = hash;
    return false;
  }

  void _invalidateCaches() {
    _cachedSubGoalsHash = 0;
    _cachedActiveSubGoals = null;
    _cachedCompletedSubGoals = null;
    _cachedPausedSubGoals = null;
    _cachedOverdueSubGoals = null;
    _cachedArchivedSubGoals = null;
    _cachedDashboardSummary = null;
  }

  UnmodifiableListView<SubGoalModel> get allSubGoals =>
      UnmodifiableListView<SubGoalModel>(_subGoals);

  UnmodifiableListView<SubGoalModel> get activeSubGoals {
    if (_cachedActiveSubGoals == null || !_subGoalsListUnchanged) {
      _cachedActiveSubGoals = _subGoals
          .where((sg) => sg.status == SubGoalStatus.active)
          .toList(growable: false);
    }
    return UnmodifiableListView<SubGoalModel>(_cachedActiveSubGoals!);
  }

  UnmodifiableListView<SubGoalModel> get completedSubGoals {
    if (_cachedCompletedSubGoals == null || !_subGoalsListUnchanged) {
      _cachedCompletedSubGoals = _subGoals
          .where((sg) => sg.status == SubGoalStatus.completed)
          .toList(growable: false);
    }
    return UnmodifiableListView<SubGoalModel>(_cachedCompletedSubGoals!);
  }

  UnmodifiableListView<SubGoalModel> get pausedSubGoals {
    if (_cachedPausedSubGoals == null || !_subGoalsListUnchanged) {
      _cachedPausedSubGoals = _subGoals
          .where((sg) => sg.status == SubGoalStatus.paused)
          .toList(growable: false);
    }
    return UnmodifiableListView<SubGoalModel>(_cachedPausedSubGoals!);
  }

  UnmodifiableListView<SubGoalModel> get overdueSubGoals {
    if (_cachedOverdueSubGoals == null || !_subGoalsListUnchanged) {
      _cachedOverdueSubGoals = _subGoals
          .where((sg) => sg.status == SubGoalStatus.overdue)
          .toList(growable: false);
    }
    return UnmodifiableListView<SubGoalModel>(_cachedOverdueSubGoals!);
  }

  UnmodifiableListView<SubGoalModel> get archivedSubGoals {
    if (_cachedArchivedSubGoals == null || !_subGoalsListUnchanged) {
      _cachedArchivedSubGoals = _subGoals
          .where((sg) => sg.status == SubGoalStatus.archived)
          .toList(growable: false);
    }
    return UnmodifiableListView<SubGoalModel>(_cachedArchivedSubGoals!);
  }

  DashboardSubGoalSummary get dashboardSummary {
    if (_cachedDashboardSummary != null && _subGoalsListUnchanged) {
      return _cachedDashboardSummary!;
    }
    final summary = _buildDashboardSummary();
    _cachedDashboardSummary = summary;
    return summary;
  }

  DashboardSubGoalSummary _buildDashboardSummary() {
    final activeCount =
        _subGoals.where((sg) => sg.status == SubGoalStatus.active).length;
    final completedCount =
        _subGoals.where((sg) => sg.status == SubGoalStatus.completed).length;
    final pausedCount =
        _subGoals.where((sg) => sg.status == SubGoalStatus.paused).length;
    final overdueCount =
        _subGoals.where((sg) => sg.status == SubGoalStatus.overdue).length;
    final archivedCount =
        _subGoals.where((sg) => sg.status == SubGoalStatus.archived).length;
    final averageProgress = _subGoals.isEmpty
        ? 0.0
        : _subGoals.fold<double>(0.0, (sum, sg) => sum + sg.progress) /
            _subGoals.length;
    final totalXp = _subGoals.fold<int>(0, (sum, sg) => sum + sg.xp);

    return DashboardSubGoalSummary(
      activeCount: activeCount,
      completedCount: completedCount,
      pausedCount: pausedCount,
      overdueCount: overdueCount,
      archivedCount: archivedCount,
      totalXp: totalXp,
      averageProgress: averageProgress,
    );
  }

  // ---------------------------------------------------------------------------
  // Initialization & Hydration
  // ---------------------------------------------------------------------------

  Future<void> initialize() async {
    await _guardedMutation(() async {
      await _hydrateSubGoalsFromStorage();
      _isInitialized = true;
    });
  }

  Future<void> reload() async {
    await _guardedMutation(_hydrateSubGoalsFromStorage);
  }

  // ---------------------------------------------------------------------------
  // Core CRUD
  // ---------------------------------------------------------------------------

  Future<SubGoalModel> createSubGoal({
    required String id,
    required String goalId,
    required String title,
    String? description,
    String? motivationalSubtitle,
    DateTime? deadline,
  }) async {
    late SubGoalModel createdSubGoal;
    await _guardedMutation(() async {
      final now = DateTime.now();
      createdSubGoal = SubGoalModel(
        id: id,
        goalId: goalId,
        title: title.trim(),
        description: description?.trim(),
        progress: 0.0,
        isCompleted: false,
        status: SubGoalStatus.active,
        taskIds: const <String>[],
        motivationalSubtitle: motivationalSubtitle?.trim(),
        deadline: deadline,
        xp: 0,
        streak: 0,
        createdAt: now,
        completedAt: null,
        updatedAt: now,
      );

      _subGoals.removeWhere((sg) => sg.id == createdSubGoal.id);
      _subGoals.add(createdSubGoal);
      _sortSubGoals();
      await _subGoalStorageService.saveSubGoal(createdSubGoal);
    });
    return createdSubGoal;
  }

  Future<SubGoalModel?> updateSubGoal({
    required String id,
    String? goalId,
    String? title,
    String? description,
    double? progress,
    bool? isCompleted,
    SubGoalStatus? status,
    DateTime? deadline,
    String? motivationalSubtitle,
    int? xp,
    int? streak,
    DateTime? completedAt,
    List<String>? taskIds,
    bool clearDescription = false,
    bool clearDeadline = false,
    bool clearMotivationalSubtitle = false,
    bool clearCompletedAt = false,
  }) async {
    SubGoalModel? updatedSubGoal;
    await _guardedMutation(() async {
      final index = _subGoals.indexWhere((sg) => sg.id == id);
      if (index < 0) {
        return;
      }

      final existing = _subGoals[index];
      final now = DateTime.now();

      final willComplete =
          isCompleted == true || (progress != null && progress >= 1.0);
      final resolvedCompletedAt = clearCompletedAt
          ? null
          : (completedAt ??
              (willComplete
                  ? (existing.completedAt ?? now)
                  : existing.completedAt));
      final resolvedStatus =
          willComplete ? SubGoalStatus.completed : (status ?? existing.status);

      updatedSubGoal = existing.copyWith(
        goalId: goalId,
        title: title?.trim(),
        description: description?.trim(),
        progress: progress?.clamp(0.0, 1.0),
        isCompleted: willComplete || (isCompleted ?? existing.isCompleted),
        status: resolvedStatus,
        deadline: deadline,
        motivationalSubtitle: motivationalSubtitle?.trim(),
        xp: xp,
        streak: streak,
        completedAt: resolvedCompletedAt,
        taskIds: taskIds,
        updatedAt: now,
        clearDescription: clearDescription,
        clearDeadline: clearDeadline,
        clearMotivationalSubtitle: clearMotivationalSubtitle,
        clearCompletedAt: clearCompletedAt,
      );

      _subGoals[index] = updatedSubGoal!;
      _sortSubGoals();
      await _subGoalStorageService.updateSubGoal(updatedSubGoal!);
      await _triggerProgressCascadeHook(updatedSubGoal!);
    });
    return updatedSubGoal;
  }

  Future<void> deleteSubGoal(String id) async {
    await _guardedMutation(() async {
      final removedSubGoal = getSubGoalById(id);
      if (removedSubGoal == null) {
        return;
      }
      // Fire cascade hook BEFORE removing from list so the subscriber
      // (HierarchyCascadeService) can still read the subgoal's taskIds
      // to clean up linked tasks.
      await _triggerCascadeDeleteHook(removedSubGoal.id);
      _subGoals.removeWhere((sg) => sg.id == id);
      await _subGoalStorageService.deleteSubGoal(id);
      await _triggerProgressCascadeHook(removedSubGoal);
    });
  }

  SubGoalModel? getSubGoalById(String id) {
    for (final sg in _subGoals) {
      if (sg.id == id) {
        return sg;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Collection Queries
  // ---------------------------------------------------------------------------

  List<SubGoalModel> getSubGoalsByGoalId(String goalId) {
    return _subGoals
        .where((sg) => sg.goalId == goalId)
        .toList(growable: false);
  }

  List<SubGoalModel> getSubGoalsByGoalIdAndStatus(
    String goalId,
    SubGoalStatus status,
  ) {
    return _subGoals
        .where((sg) => sg.goalId == goalId && sg.status == status)
        .toList(growable: false);
  }

  List<SubGoalModel> getSubGoalsByStatus(SubGoalStatus status) {
    return _subGoals
        .where((sg) => sg.status == status)
        .toList(growable: false);
  }

  List<SubGoalModel> getSubGoalsByTaskId(String taskId) {
    return _subGoals
        .where((sg) => sg.taskIds.contains(taskId))
        .toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // Progress Aggregation
  // ---------------------------------------------------------------------------

  Future<void> recalculateSubGoalProgress(
    String id, {
    double? completedRatio,
  }) async {
    await _guardedMutation(() async {
      final index = _subGoals.indexWhere((sg) => sg.id == id);
      if (index < 0) {
        return;
      }

      final existing = _subGoals[index];
      final newProgress =
          completedRatio?.clamp(0.0, 1.0) ?? existing.progress;
      final willComplete = newProgress >= 1.0;
      final now = DateTime.now();

      _subGoals[index] = existing.copyWith(
        progress: newProgress,
        isCompleted: willComplete,
        completedAt: willComplete ? (existing.completedAt ?? now) : null,
        status: willComplete ? SubGoalStatus.completed : SubGoalStatus.active,
        updatedAt: now,
        clearCompletedAt: !willComplete,
      );

      await _subGoalStorageService.updateSubGoalProgress(id, newProgress);
      await _triggerProgressCascadeHook(_subGoals[index]);
    });
  }

  Future<void> updateSubGoalCompletion(String id, bool isCompleted) async {
    await _guardedMutation(() async {
      final index = _subGoals.indexWhere((sg) => sg.id == id);
      if (index < 0) {
        return;
      }

      final existing = _subGoals[index];
      final now = DateTime.now();

      _subGoals[index] = existing.copyWith(
        isCompleted: isCompleted,
        progress: isCompleted ? 1.0 : existing.progress,
        completedAt: isCompleted ? (existing.completedAt ?? now) : null,
        status: isCompleted ? SubGoalStatus.completed : SubGoalStatus.active,
        updatedAt: now,
        clearCompletedAt: !isCompleted,
      );

      await _subGoalStorageService.updateSubGoalProgress(
        id,
        isCompleted ? 1.0 : existing.progress,
      );
      await _triggerProgressCascadeHook(_subGoals[index]);
    });
  }

  /// Aggregates task completion data from the given counts and recalculates
  /// progress. Called by [HierarchyCascadeService] — the actual task-counting
  /// logic lives there.
  Future<void> calculateProgressFromTasks({
    required String subGoalId,
    required int completedTaskCount,
    required int totalTaskCount,
  }) async {
    if (totalTaskCount <= 0) {
      await recalculateSubGoalProgress(subGoalId, completedRatio: 0.0);
      return;
    }

    final ratio = completedTaskCount / totalTaskCount;
    await recalculateSubGoalProgress(subGoalId, completedRatio: ratio);
  }

  // ---------------------------------------------------------------------------
  // Status Management
  // ---------------------------------------------------------------------------

  Future<void> setSubGoalStatus(String id, SubGoalStatus status) async {
    await _guardedMutation(() async {
      final index = _subGoals.indexWhere((sg) => sg.id == id);
      if (index < 0) {
        return;
      }

      final existing = _subGoals[index];
      final now = DateTime.now();
      final isCompleted = status == SubGoalStatus.completed;

      _subGoals[index] = existing.copyWith(
        status: status,
        isCompleted: isCompleted || existing.isCompleted,
        progress: isCompleted ? 1.0 : existing.progress,
        completedAt:
            isCompleted ? (existing.completedAt ?? now) : existing.completedAt,
        updatedAt: now,
      );

      await _subGoalStorageService.updateSubGoal(_subGoals[index]);
    });
  }

  // ---------------------------------------------------------------------------
  // XP & Streak
  // ---------------------------------------------------------------------------

  Future<void> addSubGoalXp(String id, int xpDelta) async {
    await _guardedMutation(() async {
      final index = _subGoals.indexWhere((sg) => sg.id == id);
      if (index < 0) {
        return;
      }

      final existing = _subGoals[index];
      final newXp = (existing.xp + xpDelta).clamp(0, double.maxFinite).toInt();

      _subGoals[index] = existing.copyWith(
        xp: newXp,
        updatedAt: DateTime.now(),
      );

      await _subGoalStorageService.updateSubGoalXp(id, xpDelta);

      final hook = onXpAwarded;
      if (hook != null) {
        await hook(_subGoals[index], xpDelta);
      }
    });
  }

  Future<void> updateSubGoalStreak(String id, int streak) async {
    await _guardedMutation(() async {
      final index = _subGoals.indexWhere((sg) => sg.id == id);
      if (index < 0) {
        return;
      }

      final existing = _subGoals[index];
      _subGoals[index] = existing.copyWith(
        streak: streak,
        updatedAt: DateTime.now(),
      );

      await _subGoalStorageService.updateSubGoalStreak(id, streak);

      final hook = onStreakUpdated;
      if (hook != null) {
        await hook(_subGoals[index]);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Task Aggregation Helpers
  // ---------------------------------------------------------------------------

  Future<void> addTaskToSubGoal(String subGoalId, String taskId) async {
    await _guardedMutation(() async {
      final index = _subGoals.indexWhere((sg) => sg.id == subGoalId);
      if (index < 0) {
        return;
      }

      final existing = _subGoals[index];
      if (existing.taskIds.contains(taskId)) {
        return;
      }

      final updatedTaskIds = List<String>.from(existing.taskIds)..add(taskId);

      _subGoals[index] = existing.copyWith(
        taskIds: updatedTaskIds,
        updatedAt: DateTime.now(),
      );

      await _subGoalStorageService.addTaskIdToSubGoal(subGoalId, taskId);
    });
  }

  Future<void> removeTaskFromSubGoal(String subGoalId, String taskId) async {
    await _guardedMutation(() async {
      final index = _subGoals.indexWhere((sg) => sg.id == subGoalId);
      if (index < 0) {
        return;
      }

      final existing = _subGoals[index];
      final updatedTaskIds = List<String>.from(existing.taskIds)
        ..remove(taskId);

      _subGoals[index] = existing.copyWith(
        taskIds: updatedTaskIds,
        updatedAt: DateTime.now(),
      );

      await _subGoalStorageService.removeTaskIdFromSubGoal(subGoalId, taskId);
    });
  }

  int getSubGoalTaskCount(String subGoalId) {
    final sg = getSubGoalById(subGoalId);
    return sg?.taskIds.length ?? 0;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> _hydrateSubGoalsFromStorage() async {
    final subGoals = await _subGoalStorageService.getAllSubGoals();
    _subGoals
      ..clear()
      ..addAll(subGoals);
    _sortSubGoals();
    _invalidateCaches();
  }

  void _sortSubGoals() {
    _subGoals.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
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

  Future<void> _triggerProgressCascadeHook(SubGoalModel subGoal) async {
    final hook = onProgressCascadeRequested;
    if (hook != null) {
      await hook(subGoal);
    }
  }

  Future<void> _triggerCascadeDeleteHook(String subGoalId) async {
    final hook = onCascadeDeleteRequested;
    if (hook != null) {
      await hook(subGoalId);
    }
  }
}
