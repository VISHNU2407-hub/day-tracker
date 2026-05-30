import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:habit_up/models/task_model.dart';
import 'package:habit_up/services/task_storage_service.dart';

typedef TaskProgressCascadeHook = Future<void> Function(TaskModel task);
typedef TaskXpAwardHook = Future<void> Function(TaskModel task, int xpAwarded);
typedef TaskStreakHook = Future<void> Function(TaskModel task);

/// Fired when a task is created or updated with a non-null [reminderTime],
/// allowing the ReminderSchedulingService to create a NotificationModel.
typedef TaskReminderCreatedHook = Future<void> Function(TaskModel task);

/// Fired when a task is deleted or completed, allowing the
/// ReminderSchedulingService to cancel any pending native notification
/// and clean up Hive notification records.
typedef TaskReminderCancelledHook = Future<void> Function(String taskId);

class DashboardTaskSummary {
  const DashboardTaskSummary({
    required this.totalCount,
    required this.completedCount,
    required this.pendingCount,
    required this.overdueCount,
    required this.todayCount,
    required this.todayCompletedCount,
    required this.todayOverdueCount,
    required this.upcomingCount,
    required this.tomorrowCount,
    required this.totalXpPotential,
    required this.totalXpCompleted,
    required this.todayXpEarned,
    required this.todayXpPotential,
    required this.todayCompletionRate,
    this.recurringTaskCount = 0,
    this.todayRecurringCount = 0,
    this.todayRecurringCompleted = 0,
  });

  final int totalCount;
  final int completedCount;
  final int pendingCount;
  final int overdueCount;
  final int todayCount;
  final int todayCompletedCount;
  final int todayOverdueCount;
  final int upcomingCount;
  final int tomorrowCount;
  final int totalXpPotential;
  final int totalXpCompleted;
  final int todayXpEarned;
  final int todayXpPotential;
  final double todayCompletionRate;
  final int recurringTaskCount;
  final int todayRecurringCount;
  final int todayRecurringCompleted;
}

class TaskProvider extends ChangeNotifier {
  TaskProvider({
    this._taskStorageService = const TaskStorageService(),
  });

  final TaskStorageService _taskStorageService;
  final List<TaskModel> _tasks = <TaskModel>[];

  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  TaskProgressCascadeHook? onTaskProgressCascadeRequested;
  TaskXpAwardHook? onTaskXpAwarded;
  /// Fired when a task is toggled from complete → incomplete.
  /// Passes the task and the XP that should be reversed.
  TaskXpAwardHook? onTaskXpReversed;
  TaskStreakHook? onTaskCompletedForStreak;
  TaskReminderCreatedHook? onTaskReminderCreated;

  /// Fired when a task is deleted or completed so pending reminders can be
  /// cancelled without rescheduling.
  TaskReminderCancelledHook? onTaskReminderCancelled;

  // ---------------------------------------------------------------------------
  // Duplicate / exploit prevention guards
  // ---------------------------------------------------------------------------

  /// Tracks task IDs that have already been processed for XP award today.
  /// Prevents duplicate XP from rapid toggle clicks or race conditions.
  final Set<String> _todayProcessedXpTaskIds = <String>{};

  /// Tracks task IDs that have already been processed for streak today.
  final Set<String> _todayProcessedStreakTaskIds = <String>{};

  /// Tracks task IDs that have been processed for cascade hooks today
  /// (recurring generation, hierarchy sync).
  final Set<String> _todayProcessedCascadeIds = <String>{};

  /// The last date key (yyyy-MM-dd) for which the guard sets were cleared.
  String _lastGuardCleanupDateKey = '';

  /// Clears daily guards if a new calendar day has started (handles
  /// midnight transitions cleanly).
  void _ensureDailyGuardCleanup() {
    final todayKey = _dateKey(DateTime.now());
    if (_lastGuardCleanupDateKey == todayKey) return;
    _lastGuardCleanupDateKey = todayKey;
    _todayProcessedXpTaskIds.clear();
    _todayProcessedStreakTaskIds.clear();
    _todayProcessedCascadeIds.clear();
  }

  // ---------------------------------------------------------------------------
  // Memoization — cached computed properties with dirty flag
  // ---------------------------------------------------------------------------

  /// Hash of the full _tasks list; used to detect mutations cheaply.
  int _cachedTasksHash = 0;

  /// Cached filtered views.
  List<TaskModel>? _cachedCompletedTasks;
  List<TaskModel>? _cachedPendingTasks;
  List<TaskModel>? _cachedScheduledTasks;
  DashboardTaskSummary? _cachedDashboardSummary;

  /// Returns true if the tasks list hasn't changed since the last cache build.
  bool get _tasksListUnchanged {
    final hash = Object.hashAll(_tasks);
    if (hash == _cachedTasksHash) return true;
    _cachedTasksHash = hash;
    return false;
  }

  /// Invalidates all memoized caches. Call after any mutation to [_tasks].
  void _invalidateCaches() {
    _cachedTasksHash = 0;
    _cachedCompletedTasks = null;
    _cachedPendingTasks = null;
    _cachedScheduledTasks = null;
    _cachedDashboardSummary = null;
  }

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  UnmodifiableListView<TaskModel> get allTasks =>
      UnmodifiableListView<TaskModel>(_tasks);

  UnmodifiableListView<TaskModel> get completedTasks {
    if (_cachedCompletedTasks == null || !_tasksListUnchanged) {
      _cachedCompletedTasks = _tasks
          .where((task) => task.isCompleted)
          .toList(growable: false);
    }
    return UnmodifiableListView<TaskModel>(_cachedCompletedTasks!);
  }

  UnmodifiableListView<TaskModel> get pendingTasks {
    if (_cachedPendingTasks == null || !_tasksListUnchanged) {
      _cachedPendingTasks = _tasks
          .where((task) => !task.isCompleted)
          .toList(growable: false);
    }
    return UnmodifiableListView<TaskModel>(_cachedPendingTasks!);
  }

  UnmodifiableListView<TaskModel> get scheduledTasks {
    if (_cachedScheduledTasks == null || !_tasksListUnchanged) {
      _cachedScheduledTasks = _tasks
          .where((task) => task.status == TaskStatus.scheduled)
          .toList(growable: false);
    }
    return UnmodifiableListView<TaskModel>(_cachedScheduledTasks!);
  }

  UnmodifiableListView<TaskModel> get overdueTasks =>
      UnmodifiableListView<TaskModel>(getOverdueTasks());

  DashboardTaskSummary get dashboardSummary {
    if (_cachedDashboardSummary != null && _tasksListUnchanged) {
      return _cachedDashboardSummary!;
    }
    final summary = _buildDashboardSummary();
    _cachedDashboardSummary = summary;
    return summary;
  }

  DashboardTaskSummary _buildDashboardSummary() {
    final todayTasks = getTodayTasks();
    final todayCompleted = todayTasks.where((task) => task.isCompleted).length;
    final todayOverdue = todayTasks.where((task) => task.status == TaskStatus.overdue).length;
    final completed = completedTasks;
    final upcoming = getUpcomingTasks();
    final tomorrow = getTomorrowTasks();

    final todayXpEarned =
        todayTasks.where((task) => task.isCompleted).fold<int>(0, (sum, task) => sum + task.xpReward);
    final todayXpPotential =
        todayTasks.fold<int>(0, (sum, task) => sum + task.xpReward);

    final recurring = getRecurringTasks();
    final todayRecurringTasks = getTodayRecurringTasks();

    return DashboardTaskSummary(
      totalCount: _tasks.length,
      completedCount: completed.length,
      pendingCount: _tasks.length - completed.length,
      overdueCount: getOverdueTasks().length,
      todayCount: todayTasks.length,
      todayCompletedCount: todayCompleted,
      todayOverdueCount: todayOverdue,
      upcomingCount: upcoming.length,
      tomorrowCount: tomorrow.length,
      totalXpPotential: _tasks.fold<int>(0, (sum, task) => sum + task.xpReward),
      totalXpCompleted: completed.fold<int>(0, (sum, task) => sum + task.xpReward),
      todayXpEarned: todayXpEarned,
      todayXpPotential: todayXpPotential,
      todayCompletionRate: todayTasks.isEmpty ? 0.0 : todayCompleted / todayTasks.length,
      recurringTaskCount: recurring.length,
      todayRecurringCount: todayRecurringTasks.length,
      todayRecurringCompleted:
          todayRecurringTasks.where((t) => t.isCompleted).length,
    );
  }

  Future<void> initialize() async {
    await _guardedMutation(() async {
      await _hydrateTasksFromStorage();
      _isInitialized = true;
    });
  }

  Future<void> reload() async {
    await _guardedMutation(_hydrateTasksFromStorage);
  }

  Future<TaskModel> createTask({
    required String id,
    required String title,
    required TaskDifficulty difficulty,
    required int xpReward,
    String? description,
    DateTime? startTime,
    DateTime? scheduledDate,
    DateTime? dueDate,
    DateTime? reminderTime,
    TaskRepeatType repeatType = TaskRepeatType.none,
    int? estimatedFocusDurationMinutes,
    String? goalId,
    String? subGoalId,
  }) async {
    late TaskModel createdTask;
    await _guardedMutation(() async {
      final now = DateTime.now();

      // Auto-set reminderTime from startTime if startTime is provided
      // but reminderTime is not. This ensures every time-bound task
      // automatically gets a reminder/alarm scheduled.
      final effectiveReminderTime = reminderTime ?? startTime;

      createdTask = TaskModel(
        id: id,
        title: title.trim(),
        description: description?.trim(),
        isCompleted: false,
        status: TaskStatus.active,
        difficulty: difficulty,
        xpReward: xpReward,
        startTime: startTime,
        scheduledDate: _normalizeDateOrNull(scheduledDate),
        dueDate: dueDate,
        reminderTime: effectiveReminderTime,
        repeatType: repeatType,
        estimatedFocusDurationMinutes: estimatedFocusDurationMinutes,
        goalId: goalId,
        subGoalId: subGoalId,
        createdAt: now,
        completedAt: null,
        updatedAt: now,
      );

      _tasks.removeWhere((task) => task.id == createdTask.id);
      _tasks.add(createdTask);
      _sortTasks();
      await _taskStorageService.saveTask(createdTask);
      await _triggerReminderHook(createdTask);
    });
    return createdTask;
  }

  Future<TaskModel?> updateTask({
    required String id,
    String? title,
    String? description,
    TaskDifficulty? difficulty,
    TaskStatus? status,
    int? xpReward,
    DateTime? startTime,
    DateTime? scheduledDate,
    DateTime? dueDate,
    DateTime? reminderTime,
    TaskRepeatType? repeatType,
    int? estimatedFocusDurationMinutes,
    String? goalId,
    String? subGoalId,
    bool clearDescription = false,
    bool clearStartTime = false,
    bool clearScheduledDate = false,
    bool clearDueDate = false,
    bool clearReminderTime = false,
    bool clearEstimatedFocusDuration = false,
    bool clearGoalId = false,
    bool clearSubGoalId = false,
  }) async {
    TaskModel? updatedTask;
    await _guardedMutation(() async {
      final index = _tasks.indexWhere((task) => task.id == id);
      if (index < 0) {
        return;
      }

      final existing = _tasks[index];
      final normalizedScheduledDate =
          clearScheduledDate ? null : _normalizeDateOrNull(scheduledDate ?? existing.scheduledDate);
      final resolvedStatus = _resolveStatus(
        currentStatus: status ?? existing.status,
        isCompleted: existing.isCompleted,
        dueDate: clearDueDate ? null : (dueDate ?? existing.dueDate),
        scheduledDate: normalizedScheduledDate,
      );

      // Auto-set reminderTime from startTime if startTime is provided
      // but reminderTime is not explicitly set. This ensures editing a
      // task's startTime updates the reminder schedule.
      final effectiveReminderTime =
          clearReminderTime ? null : (reminderTime ?? startTime ?? existing.reminderTime);

      updatedTask = existing.copyWith(
        title: title?.trim(),
        description: description?.trim(),
        difficulty: difficulty,
        status: resolvedStatus,
        xpReward: xpReward,
        startTime: startTime,
        scheduledDate: normalizedScheduledDate,
        dueDate: dueDate,
        reminderTime: effectiveReminderTime,
        repeatType: repeatType,
        estimatedFocusDurationMinutes: estimatedFocusDurationMinutes,
        goalId: goalId,
        subGoalId: subGoalId,
        updatedAt: DateTime.now(),
        clearDescription: clearDescription,
        clearStartTime: clearStartTime,
        clearScheduledDate: clearScheduledDate,
        clearDueDate: clearDueDate,
        clearReminderTime: clearReminderTime,
        clearEstimatedFocusDuration: clearEstimatedFocusDuration,
        clearGoalId: clearGoalId,
        clearSubGoalId: clearSubGoalId,
      );

      _tasks[index] = updatedTask!;
      _sortTasks();
      await _taskStorageService.updateTask(updatedTask!);
      await _triggerProgressCascadeHook(updatedTask!);
      await _triggerReminderHook(updatedTask!);
    });
    return updatedTask;
  }

  Future<void> deleteTask(String id) async {
    await _guardedMutation(() async {
      final removedTask = await getTaskById(id);
      if (removedTask == null) {
        return;
      }
      // Cancel any pending reminder BEFORE removing the task from the list.
      await _triggerReminderCancelledHook(id);
      _tasks.removeWhere((task) => task.id == id);
      await _taskStorageService.deleteTask(id);
      await _triggerProgressCascadeHook(removedTask);
    });
  }

  Future<TaskModel?> toggleTaskCompletion(String id) async {
    _ensureDailyGuardCleanup();

    TaskModel? updatedTask;
    await _guardedMutation(() async {
      final index = _tasks.indexWhere((task) => task.id == id);
      if (index < 0) {
        return;
      }
      final current = _tasks[index];
      final now = DateTime.now();
      final willComplete = !current.isCompleted;
      final nextStatus = willComplete
          ? TaskStatus.completed
          : _resolveStatus(
              currentStatus: current.status,
              isCompleted: false,
              dueDate: current.dueDate,
            );

      // Prevent duplicate completion if this ID was already processed today
      if (willComplete && _todayProcessedCascadeIds.contains(id)) {
        return;
      }

      updatedTask = current.copyWith(
        isCompleted: willComplete,
        status: nextStatus,
        completedAt: willComplete ? now : null,
        updatedAt: now,
        clearCompletedAt: !willComplete,
      );

      _tasks[index] = updatedTask!;
      _sortTasks();
      await _taskStorageService.updateTask(updatedTask!);

      if (willComplete) {
        // Cancel any pending reminder for this completed task so the
        // native notification and Hive reminder records are cleaned up.
        await _triggerReminderCancelledHook(id);

        _todayProcessedCascadeIds.add(id);

        // Only fire XP/streak hooks if this task hasn't been processed
        if (!_todayProcessedXpTaskIds.contains(id)) {
          _todayProcessedXpTaskIds.add(id);
          await _triggerXpHook(updatedTask!);
        }
        if (!_todayProcessedStreakTaskIds.contains(id)) {
          _todayProcessedStreakTaskIds.add(id);
          await _triggerStreakHook(updatedTask!);
        }
      } else {
        // Un-completing — remove from guards so it can be re-processed
        _todayProcessedCascadeIds.remove(id);
        _todayProcessedXpTaskIds.remove(id);
        _todayProcessedStreakTaskIds.remove(id);
        await _triggerReminderHook(updatedTask!);
        // Fire XP reversal hook so subgoal/goal XP is reduced and
        // user-level XP ledger is adjusted accordingly.
        await _triggerXpReversalHook(updatedTask!);
      }
      await _triggerProgressCascadeHook(updatedTask!);
    });
    return updatedTask;
  }

  Future<TaskModel?> getTaskById(String id) async {
    for (final task in _tasks) {
      if (task.id == id) {
        return task;
      }
    }
    return _taskStorageService.getTaskById(id);
  }

  // ---------------------------------------------------------------------------
  // Scheduling Mutation Methods
  // ---------------------------------------------------------------------------

  /// Schedule an existing task for today (sets scheduledDate to current date).
  Future<TaskModel?> scheduleTaskForToday(String id) async {
    return scheduleTaskForDate(id, DateTime.now());
  }

  /// Schedule an existing task for tomorrow.
  Future<TaskModel?> scheduleTaskForTomorrow(String id) async {
    return scheduleTaskForDate(id, DateTime.now().add(const Duration(days: 1)));
  }

  /// Schedule an existing task for a specific [date].
  Future<TaskModel?> scheduleTaskForDate(String id, DateTime date) async {
    return updateTask(
      id: id,
      scheduledDate: date,
      status: _resolveStatus(
        currentStatus: TaskStatus.active,
        isCompleted: false,
        dueDate: null, // will be re-resolved after scheduledDate set
        scheduledDate: date,
      ),
    );
  }

  /// Reschedule a task to a new date (alias for scheduling).
  Future<TaskModel?> rescheduleTask(String id, DateTime newDate) async {
    return scheduleTaskForDate(id, newDate);
  }

  // ---------------------------------------------------------------------------
  // Calendar Preparation Methods
  // ---------------------------------------------------------------------------

  /// Returns tasks whose effective date falls within [start] (inclusive) and
  /// [end] (inclusive). Dates are normalized to day-level granularity.
  List<TaskModel> getTasksByDateRange(DateTime start, DateTime end) {
    final normalizedStart = _normalizeDate(start);
    final normalizedEnd = _normalizeDate(end);
    return _tasks.where((task) {
      final taskDate = _effectiveTaskDate(task);
      if (taskDate == null) {
        return false;
      }
      return !taskDate.isBefore(normalizedStart) && !taskDate.isAfter(normalizedEnd);
    }).toList(growable: false);
  }

  /// Groups tasks by their effective date key (yyyy-MM-dd).
  /// Useful for calendar views and timeline grouping.
  Map<String, List<TaskModel>> getDateGroupedTasks() {
    final grouped = <String, List<TaskModel>>{};
    for (final task in _tasks) {
      final dateKey = _taskDateKey(task);
      if (dateKey == null) {
        continue;
      }
      grouped.putIfAbsent(dateKey, () => <TaskModel>[]).add(task);
    }
    return grouped;
  }

  /// Returns tasks scheduled for the current week (Monday–Sunday).
  Map<String, List<TaskModel>> getWeekSchedule() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final tasks = getTasksByDateRange(monday, sunday);

    final grouped = <String, List<TaskModel>>{};
    for (final task in tasks) {
      final dateKey = _taskDateKey(task) ?? '';
      grouped.putIfAbsent(dateKey, () => <TaskModel>[]).add(task);
    }
    return grouped;
  }

  /// Returns today's tasks that belong to the specified [goalId].
  /// Used by the pinned goal dashboard synchronization.
  List<TaskModel> getPinnedGoalTodayTasks(String goalId) {
    final today = _normalizeDate(DateTime.now());
    return _tasks.where((task) {
      final taskDate = _effectiveTaskDate(task);
      return task.goalId == goalId && taskDate == today;
    }).toList(growable: false);
  }

  /// Returns upcoming tasks for the specified [goalId].
  /// Used by the pinned goal dashboard synchronization.
  List<TaskModel> getPinnedGoalUpcomingTasks(String goalId, {int daysAhead = 7}) {
    final today = _normalizeDate(DateTime.now());
    final end = today.add(Duration(days: daysAhead));
    return _tasks.where((task) {
      final taskDate = _effectiveTaskDate(task);
      if (taskDate == null || task.isCompleted) {
        return false;
      }
      return task.goalId == goalId && taskDate.isAfter(today) && !taskDate.isAfter(end);
    }).toList(growable: false);
  }

  List<TaskModel> getTodayTasks() {
    final today = _normalizeDate(DateTime.now());
    return _tasks.where((task) => _effectiveTaskDate(task) == today).toList(growable: false);
  }

  List<TaskModel> getTomorrowTasks() {
    final tomorrow = _normalizeDate(DateTime.now().add(const Duration(days: 1)));
    return _tasks.where((task) => _effectiveTaskDate(task) == tomorrow).toList(growable: false);
  }

  List<TaskModel> getTasksForDate(DateTime date) {
    final target = _normalizeDate(date);
    return _tasks.where((task) => _effectiveTaskDate(task) == target).toList(growable: false);
  }

  List<TaskModel> getUpcomingTasks({int daysAhead = 7}) {
    final today = _normalizeDate(DateTime.now());
    final end = today.add(Duration(days: daysAhead));
    return _tasks.where((task) {
      final taskDate = _effectiveTaskDate(task);
      if (taskDate == null || task.isCompleted) {
        return false;
      }
      return taskDate.isAfter(today) && (taskDate.isBefore(end) || taskDate == end);
    }).toList(growable: false);
  }

  List<TaskModel> getOverdueTasks() {
    final now = DateTime.now();
    final today = _normalizeDate(now);
    return _tasks.where((task) {
      if (task.isCompleted) {
        return false;
      }
      final dueDate = task.dueDate;
      if (dueDate != null && dueDate.isBefore(now)) {
        return true;
      }
      final scheduled = task.scheduledDate;
      if (scheduled != null && scheduled.isBefore(today)) {
        return true;
      }
      return task.status == TaskStatus.overdue;
    }).toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // Recurring Task Engine
  // ---------------------------------------------------------------------------

  /// Returns all tasks with a non-none repeat type.
  List<TaskModel> getRecurringTasks() {
    return _tasks
        .where((task) => task.repeatType != TaskRepeatType.none)
        .toList(growable: false);
  }

  /// Returns recurring tasks whose effective date falls on today.
  List<TaskModel> getTodayRecurringTasks() {
    final today = _normalizeDate(DateTime.now());
    return _tasks.where((task) {
      if (task.repeatType == TaskRepeatType.none) {
        return false;
      }
      final taskDate = _effectiveTaskDate(task);
      return taskDate == today;
    }).toList(growable: false);
  }

  /// Computes the next recurrence date for a recurring [task].
  ///
  /// Uses [completedAt] (or [scheduledDate] as fallback) as the anchor and
  /// advances by one period according to [repeatType].
  DateTime? calculateNextRecurringDate(TaskModel task) {
    if (task.repeatType == TaskRepeatType.none) {
      return null;
    }
    final anchor = task.completedAt ?? task.scheduledDate;
    if (anchor == null) {
      return null;
    }
    final normalized = _normalizeDate(anchor);
    switch (task.repeatType) {
      case TaskRepeatType.daily:
        return normalized.add(const Duration(days: 1));
      case TaskRepeatType.weekly:
        return normalized.add(const Duration(days: 7));
      case TaskRepeatType.monthly:
        return DateTime(
          normalized.year,
          normalized.month + 1,
          normalized.day,
        );
      case TaskRepeatType.custom:
        // Preparation — custom intervals will be supported later.
        return null;
      case TaskRepeatType.none:
        return null;
    }
  }

  /// Generates the next occurrence task for a completed recurring [template].
  ///
  /// Copies the template fields (title, description, difficulty, xp,
  /// goalId, subGoalId, repeatType) into a fresh task with:
  ///   - a new unique [id]
  ///   - [scheduledDate] set to [calculateNextRecurringDate]
  ///   - [isCompleted] = false, status = scheduled/active
  ///   - fresh timestamps
  ///
  /// Returns the newly created task, or null if the template is not recurring
  /// or the next date could not be computed.
  Future<TaskModel?> generateNextOccurrence(TaskModel template) async {
    if (template.repeatType == TaskRepeatType.none) {
      return null;
    }

    final nextDate = calculateNextRecurringDate(template);
    if (nextDate == null) {
      return null;
    }

    // Prevent duplicate generation — check if a recurring occurrence
    // already exists for this template + next date combination.
    final candidateId = '${template.id}_recur_${nextDate.millisecondsSinceEpoch}';
    if (_tasks.any((t) => t.id == candidateId)) {
      // Occurrence already exists — skip to avoid duplicates
      return _tasks.firstWhere((t) => t.id == candidateId);
    }

    late TaskModel nextTask;
    await _guardedMutation(() async {
      final now = DateTime.now();
      final isFuture = nextDate.isAfter(_normalizeDate(now));

      nextTask = TaskModel(
        id: candidateId,
        title: template.title,
        description: template.description,
        isCompleted: false,
        status: isFuture ? TaskStatus.scheduled : TaskStatus.active,
        difficulty: template.difficulty,
        xpReward: template.xpReward,
        scheduledDate: nextDate,
        dueDate: template.dueDate,
        startTime: null,
        reminderTime: template.reminderTime,
        repeatType: template.repeatType,
        estimatedFocusDurationMinutes: template.estimatedFocusDurationMinutes,
        goalId: template.goalId,
        subGoalId: template.subGoalId,
        createdAt: now,
        completedAt: null,
        updatedAt: now,
      );

      _tasks.add(nextTask);
      _sortTasks();
      await _taskStorageService.saveTask(nextTask);
      await _triggerReminderHook(nextTask);
    });
    return nextTask;
  }

  /// Completes a recurring task and automatically generates the next
  /// occurrence.
  ///
  /// 1. Toggles the current task to completed via [toggleTaskCompletion]
  ///    (which fires cascade hooks for hierarchy sync).
  /// 2. If the task is recurring ([repeatType] != none), generates the
  ///    next occurrence via [generateNextOccurrence].
  ///
  /// Returns the completed task (or null if not found). The next occurrence
  /// is fire-and-forget from the caller's perspective — it is persisted and
  /// will appear in future queries.
  Future<TaskModel?> completeRecurringTask(String id) async {
    // Grab the pre-mutation state so we can check repeatType.
    final preIndex = _tasks.indexWhere((t) => t.id == id);
    if (preIndex < 0) {
      return null;
    }
    final template = _tasks[preIndex];
    final isRecurring = template.repeatType != TaskRepeatType.none;

    // Step 1: capture the real completion time for anchor calculation.
    final completionTime = DateTime.now();

    // Step 2: complete the current task (fires cascade hooks).
    final completed = await toggleTaskCompletion(id);
    if (completed == null) {
      return null;
    }

    // Step 3: generate next occurrence using the captured completion time
    //         as the anchor (avoids anchoring on a stale `scheduledDate`
    //         for overdue recurring tasks).
    if (isRecurring) {
      // Use a copy with the real completion time so
      // calculateNextRecurringDate anchors on the moment of completion
      // rather than a potentially-stale `scheduledDate`.
      final anchoredTemplate = template.copyWith(
        completedAt: completionTime,
        updatedAt: completionTime,
      );
      await generateNextOccurrence(anchoredTemplate);
    }

    return completed;
  }

  List<TaskModel> getTasksForSubGoal(String subGoalId) {
    return _tasks.where((task) => task.subGoalId == subGoalId).toList(growable: false);
  }

  /// Returns the count of uncompleted tasks (excluding completed ones).
  /// Used by the bedtime planner for context-aware messaging.
  int getUnfinishedTasksCount() {
    return _tasks.where((t) => !t.isCompleted).length;
  }

  List<TaskModel> getTasksForGoal(String goalId) {
    return _tasks.where((task) => task.goalId == goalId).toList(growable: false);
  }

  Future<void> refreshStatuses() async {
    await _guardedMutation(() async {
      final now = DateTime.now();
      final updated = <TaskModel>[];
      var changed = false;

      for (final task in _tasks) {
        if (task.isCompleted) {
          updated.add(task);
          continue;
        }
        final resolved = _resolveStatus(
          currentStatus: task.status,
          isCompleted: false,
          dueDate: task.dueDate,
          scheduledDate: task.scheduledDate,
          now: now,
        );
        if (resolved != task.status) {
          changed = true;
          updated.add(task.copyWith(status: resolved, updatedAt: now));
        } else {
          updated.add(task);
        }
      }

      if (!changed) {
        return;
      }

      _tasks
        ..clear()
        ..addAll(updated);
      _sortTasks();
      await _taskStorageService.saveAllTasks(updated);
    });
  }

  Future<void> _hydrateTasksFromStorage() async {
    final tasks = await _taskStorageService.getAllTasks();
    _tasks
      ..clear()
      ..addAll(tasks.map(_normalizeHydratedTask));
    _sortTasks();
    _invalidateCaches();
  }

  TaskModel _normalizeHydratedTask(TaskModel task) {
    final status = _resolveStatus(
      currentStatus: task.status,
      isCompleted: task.isCompleted,
      dueDate: task.dueDate,
      scheduledDate: task.scheduledDate,
    );
    if (status == task.status && task.scheduledDate == _normalizeDateOrNull(task.scheduledDate)) {
      return task;
    }
    return task.copyWith(
      status: status,
      scheduledDate: _normalizeDateOrNull(task.scheduledDate),
      updatedAt: task.updatedAt,
    );
  }

  DateTime? _effectiveTaskDate(TaskModel task) {
    return _normalizeDateOrNull(task.scheduledDate ?? task.dueDate ?? task.startTime);
  }

  /// Returns a yyyy-MM-dd string key for calendar grouping, or null if the
  /// task has no date-bound field.
  String? _taskDateKey(TaskModel task) {
    final date = _effectiveTaskDate(task);
    if (date == null) {
      return null;
    }
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Returns a yyyy-MM-dd string key for the given [date].
  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  DateTime _normalizeDate(DateTime date) => DateTime(date.year, date.month, date.day);

  DateTime? _normalizeDateOrNull(DateTime? date) {
    if (date == null) {
      return null;
    }
    return DateTime(date.year, date.month, date.day);
  }

  TaskStatus _resolveStatus({
    required TaskStatus currentStatus,
    required bool isCompleted,
    required DateTime? dueDate,
    DateTime? scheduledDate,
    DateTime? now,
  }) {
    if (isCompleted) {
      return TaskStatus.completed;
    }

    final timestamp = now ?? DateTime.now();
    if (dueDate != null && dueDate.isBefore(timestamp)) {
      return TaskStatus.overdue;
    }

    final scheduled = _normalizeDateOrNull(scheduledDate);
    if (scheduled != null && scheduled.isAfter(_normalizeDate(timestamp))) {
      return TaskStatus.scheduled;
    }

    if (currentStatus == TaskStatus.scheduled || currentStatus == TaskStatus.overdue) {
      return TaskStatus.active;
    }
    return currentStatus;
  }

  void _sortTasks() {
    _tasks.sort((a, b) {
      final aDate = a.dueDate ?? a.startTime ?? a.scheduledDate ?? a.updatedAt;
      final bDate = b.dueDate ?? b.startTime ?? b.scheduledDate ?? b.updatedAt;
      return aDate.compareTo(bDate);
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

  Future<void> _triggerProgressCascadeHook(TaskModel task) async {
    final hook = onTaskProgressCascadeRequested;
    if (hook != null) {
      await hook(task);
    }
  }

  Future<void> _triggerXpHook(TaskModel task) async {
    final hook = onTaskXpAwarded;
    if (hook != null) {
      await hook(task, task.xpReward);
    }
  }

  Future<void> _triggerXpReversalHook(TaskModel task) async {
    final hook = onTaskXpReversed;
    if (hook != null) {
      await hook(task, task.xpReward);
    }
  }

  Future<void> _triggerStreakHook(TaskModel task) async {
    final hook = onTaskCompletedForStreak;
    if (hook != null) {
      await hook(task);
    }
  }

  Future<void> _triggerReminderHook(TaskModel task) async {
    // Always fire the hook so `_onTaskReminderCreated` can clean up stale
    // notifications — even when [reminderTime] is null (i.e. reminder was
    // cleared). The hook handler is responsible for deciding whether to
    // create a new notification based on the task's current reminder state.
    final hook = onTaskReminderCreated;
    if (hook != null) {
      await hook(task);
    }
  }

  Future<void> _triggerReminderCancelledHook(String taskId) async {
    final hook = onTaskReminderCancelled;
    if (hook != null) {
      await hook(taskId);
    }
  }
}
