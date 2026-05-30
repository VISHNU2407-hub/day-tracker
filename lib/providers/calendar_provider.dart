import 'package:flutter/material.dart';
import 'package:habit_up/models/task_model.dart';
import 'package:habit_up/providers/task_provider.dart';
import 'package:habit_up/theme/app_colors.dart';

/// View modes for the calendar.
enum CalendarViewMode { month, week, day }

/// Lightweight date-count info for rendering month grid dots and
/// productivity heatmap colours.
class CalendarDateInfo {
  const CalendarDateInfo({
    required this.date,
    required this.taskCount,
    required this.completedCount,
    required this.hasOverdue,
    this.productivityScore = 0.0,
    this.totalScheduledXp = 0,
    this.completedXp = 0,
  });

  final DateTime date;
  final int taskCount;
  final int completedCount;
  final bool hasOverdue;

  /// Productivity score (0.0 – 1.0) based on completed XP / total scheduled XP.
  final double productivityScore;

  /// Total XP scheduled for this day.
  final int totalScheduledXp;

  /// XP completed this day.
  final int completedXp;

  bool get hasTasks => taskCount > 0;
  bool get allCompleted => taskCount > 0 && taskCount == completedCount;

  /// Whether any tasks were scheduled (avoids false "missed" labels).
  bool get hasActivity => totalScheduledXp > 0;

  /// Productivity colour for calendar heatmap visualisation.
  ///
  /// **Colour rules:**
  /// - 90%+  → DARK GREEN  (full streak)
  /// - 50–89% → LIGHT GREEN (partial productivity)
  /// - <50%   → RED         (missed / broken streak)
  Color get productivityColor {
    if (!hasActivity) return AppColors.transparent;
    if (productivityScore >= 0.9) return const Color(0xFF1B8C5E);
    if (productivityScore >= 0.5) return const Color(0xFF3DDC97);
    return AppColors.error;
  }
}

/// Manages calendar UI state, date navigation, and efficient date-based
/// task querying by delegating to [TaskProvider].
///
/// Does NOT duplicate scheduling logic — it uses the existing
/// `TaskProvider.getTasksForDate()`, recurring engine, and overdue queries.
///
/// Synchronises automatically whenever [TaskProvider] notifies listeners.
class CalendarProvider extends ChangeNotifier {
  CalendarProvider() {
    _taskProvider = null; // wired externally via [connectTaskProvider]
  }

  TaskProvider? _taskProvider;

  // ---------------------------------------------------------------------------
  // Wired provider reference (no circular dependency — reads only)
  // ---------------------------------------------------------------------------

  /// Connects to the app's [TaskProvider] and listens for updates so the
  /// calendar refreshes automatically when tasks change.
  void connectTaskProvider(TaskProvider provider) {
    if (_taskProvider == provider) return;
    _taskProvider?.removeListener(_onTaskProviderChanged);
    _taskProvider = provider;
    _taskProvider!.addListener(_onTaskProviderChanged);
    _invalidateCache();
    notifyListeners();
  }

  void disconnectTaskProvider() {
    _taskProvider?.removeListener(_onTaskProviderChanged);
    _taskProvider = null;
    _invalidateCache();
  }

  /// Throttle flag — prevents rapid re-notifies when multiple tasks change
  /// in quick succession (e.g., batch update, recurring generation).
  bool _needsRefresh = false;
  bool _refreshScheduled = false;

  void _onTaskProviderChanged() {
    if (_refreshScheduled) {
      _needsRefresh = true;
      return;
    }
    _refreshScheduled = true;
    _needsRefresh = false;
    _scheduleCoalescedRefresh();
  }

  void _scheduleCoalescedRefresh() {
    Future<void>.delayed(const Duration(milliseconds: 50), () {
      _refreshScheduled = false;
      if (_needsRefresh || _cachedMonthDateInfo != null) {
        _invalidateCache();
        notifyListeners();
      }
      _needsRefresh = false;
    });
  }

  @override
  void dispose() {
    _taskProvider?.removeListener(_onTaskProviderChanged);
    _taskProvider = null;
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  CalendarViewMode _viewMode = CalendarViewMode.month;

  DateTime get selectedDate => _selectedDate;
  DateTime get focusedMonth => _focusedMonth;
  CalendarViewMode get viewMode => _viewMode;

  // ---------------------------------------------------------------------------
  // Date Navigation
  // ---------------------------------------------------------------------------

  void selectDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    if (_selectedDate == normalized) return;
    _selectedDate = normalized;
    // Auto-navigate the focused month to match the selected date
    final newMonth = DateTime(normalized.year, normalized.month);
    if (newMonth != _focusedMonth) {
      _focusedMonth = newMonth;
    }
    notifyListeners();
  }

  void setViewMode(CalendarViewMode mode) {
    if (_viewMode == mode) return;
    _viewMode = mode;
    notifyListeners();
  }

  void goToNextMonth() {
    _focusedMonth = DateTime(
      _focusedMonth.month == 12 ? _focusedMonth.year + 1 : _focusedMonth.year,
      _focusedMonth.month == 12 ? 1 : _focusedMonth.month + 1,
    );
    notifyListeners();
  }

  void goToPreviousMonth() {
    _focusedMonth = DateTime(
      _focusedMonth.month == 1 ? _focusedMonth.year - 1 : _focusedMonth.year,
      _focusedMonth.month == 1 ? 12 : _focusedMonth.month - 1,
    );
    notifyListeners();
  }

  void goToToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _selectedDate = today;
    _focusedMonth = DateTime(today.year, today.month);
    notifyListeners();
  }

  /// Navigate to the next day (for day view).
  void goToNextDay() {
    selectDate(_selectedDate.add(const Duration(days: 1)));
  }

  /// Navigate to the previous day (for day view).
  void goToPreviousDay() {
    selectDate(_selectedDate.subtract(const Duration(days: 1)));
  }

  /// Navigate to the next week (for week view).
  void goToNextWeek() {
    selectDate(_selectedDate.add(const Duration(days: 7)));
  }

  /// Navigate to the previous week (for week view).
  void goToPreviousWeek() {
    selectDate(_selectedDate.subtract(const Duration(days: 7)));
  }

  // ---------------------------------------------------------------------------
  // Task Queries (delegate to TaskProvider)
  // ---------------------------------------------------------------------------

  /// Returns tasks for a specific day, including recurring task expansions.
  List<TaskModel> getTasksForDay(DateTime date) {
    final provider = _taskProvider;
    if (provider == null) return const <TaskModel>[];

    final normalizedDate = DateTime(date.year, date.month, date.day);
    final tasks = provider.getTasksForDate(normalizedDate);

    // Also include recurring tasks whose effective date falls on this day.
    // The provider's getTasksForDate already covers this, but ensure we
    // also include recurring tasks that may have been regenerated.
    return tasks;
  }

  /// Returns all tasks for the focused month, grouped by date key (yyyy-MM-dd).
  ///
  /// Includes scheduled, recurring, and overdue tasks that fall within the
  /// month boundaries. This is the primary query for the month grid view.
  Map<String, List<TaskModel>> getMonthGroupedTasks() {
    final provider = _taskProvider;
    if (provider == null) return const <String, List<TaskModel>>{};

    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);

    // Extend slightly to capture edge days (first/last week overlap)
    final start = firstDay.subtract(const Duration(days: 6));
    final end = lastDay.add(const Duration(days: 6));

    final allTasks = provider.getTasksByDateRange(start, end);

    final grouped = <String, List<TaskModel>>{};
    for (final task in allTasks) {
      final dateKey = _taskDateKey(task);
      if (dateKey == null) continue;
      grouped.putIfAbsent(dateKey, () => <TaskModel>[]).add(task);
    }
    return grouped;
  }

  // ---------------------------------------------------------------------------
  // Cache — avoid recomputing month data on every frame
  // ---------------------------------------------------------------------------

  /// Cached month grid date info — invalidated when focused month or tasks change.
  List<CalendarDateInfo>? _cachedMonthDateInfo;
  DateTime? _cachedFocusedMonth;

  void _invalidateCache() {
    _cachedMonthDateInfo = null;
    _cachedFocusedMonth = null;
  }

  /// Returns [CalendarDateInfo] for every day in the focused month.
  /// Used by the month grid for rendering productivity heatmap and
  /// task-density dots/indicators.
  ///
  /// Each day includes a [CalendarDateInfo.productivityScore] computed from
  /// the completed-XP / total-scheduled-XP ratio for that day.
  ///
  /// Result is lazily cached and only recomputed when [focusedMonth] or
  /// the underlying task data changes.
  List<CalendarDateInfo> getMonthDateInfo() {
    if (_cachedMonthDateInfo != null &&
        _cachedFocusedMonth == _focusedMonth) {
      return _cachedMonthDateInfo!;
    }

    final provider = _taskProvider;
    if (provider == null) {
      _cachedMonthDateInfo = const <CalendarDateInfo>[];
      _cachedFocusedMonth = _focusedMonth;
      return _cachedMonthDateInfo!;
    }

    final grouped = getMonthGroupedTasks();
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;

    final result = <CalendarDateInfo>[];
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final key = _dateToKey(date);
      final tasks = grouped[key] ?? const <TaskModel>[];
      final completedCount = tasks.where((t) => t.isCompleted).length;
      final hasOverdue =
          tasks.any((t) => !t.isCompleted && t.status == TaskStatus.overdue);

      // Compute XP-based productivity score
      int totalXp = 0;
      int completedXp = 0;
      for (final task in tasks) {
        final xp = task.xpReward > 0 ? task.xpReward : 10;
        totalXp += xp;
        if (task.isCompleted) completedXp += xp;
      }
      final score =
          totalXp > 0 ? (completedXp / totalXp).clamp(0.0, 1.0) : 0.0;

      result.add(CalendarDateInfo(
        date: date,
        taskCount: tasks.length,
        completedCount: completedCount,
        hasOverdue: hasOverdue,
        productivityScore: score,
        totalScheduledXp: totalXp,
        completedXp: completedXp,
      ));
    }

    _cachedMonthDateInfo = result;
    _cachedFocusedMonth = _focusedMonth;
    return result;
  }

  /// Returns [CalendarDateInfo] for a single day — used for week bar dots.
  CalendarDateInfo getDateInfo(DateTime date) {
    final provider = _taskProvider;
    if (provider == null) {
      return CalendarDateInfo(date: date, taskCount: 0, completedCount: 0, hasOverdue: false);
    }

    final tasks = provider.getTasksForDate(date);
    final completedCount = tasks.where((t) => t.isCompleted).length;
    final hasOverdue = tasks.any((t) => !t.isCompleted && t.status == TaskStatus.overdue);

    // Compute XP-based productivity score
    int totalXp = 0;
    int completedXp = 0;
    for (final task in tasks) {
      final xp = task.xpReward > 0 ? task.xpReward : 10;
      totalXp += xp;
      if (task.isCompleted) completedXp += xp;
    }
    final score = totalXp > 0 ? (completedXp / totalXp).clamp(0.0, 1.0) : 0.0;

    return CalendarDateInfo(
      date: date,
      taskCount: tasks.length,
      completedCount: completedCount,
      hasOverdue: hasOverdue,
      productivityScore: score,
      totalScheduledXp: totalXp,
      completedXp: completedXp,
    );
  }

  /// Returns 7 days of [CalendarDateInfo] starting from [startDate].
  List<CalendarDateInfo> getWeekDateInfo(DateTime startDate) {
    if (_taskProvider == null) {
      return List<CalendarDateInfo>.generate(
        7, (i) => CalendarDateInfo(
          date: startDate.add(Duration(days: i)),
          taskCount: 0,
          completedCount: 0,
          hasOverdue: false,
        ),
      );
    }

    final result = <CalendarDateInfo>[];
    for (var i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      result.add(getDateInfo(date));
    }
    return result;
  }

  /// Returns the start of the week (Monday) containing [date].
  DateTime weekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  /// Returns the end of the week (Sunday) containing [date].
  DateTime weekEnd(DateTime date) {
    return weekStart(date).add(const Duration(days: 6));
  }

  /// Returns all overdue tasks from the provider.
  List<TaskModel> getOverdueTasks() {
    final provider = _taskProvider;
    if (provider == null) return const <TaskModel>[];
    return provider.getOverdueTasks();
  }

  /// Returns the start day of the month grid (the Monday of the week
  /// containing the 1st, with possible overflow into previous month).
  DateTime get monthGridStartDate {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    // Start from Monday of the week containing the 1st
    return weekStart(firstDay);
  }

  /// Returns the number of days to display in the month grid (5 or 6 rows
  /// of 7 days, enough to cover the month).
  int get monthGridDayCount {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final start = weekStart(firstDay);
    final end = weekEnd(lastDay);
    return end.difference(start).inDays + 1;
  }

  /// Returns whether [date] falls within the focused month.
  bool isInFocusedMonth(DateTime date) {
    return date.month == _focusedMonth.month && date.year == _focusedMonth.year;
  }

  /// Returns whether [date] is today.
  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns a yyyy-MM-dd string key for the given [date].
  String _dateToKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String? _taskDateKey(TaskModel task) {
    final effective = task.scheduledDate ?? task.dueDate ?? task.startTime;
    if (effective == null) return null;
    return _dateToKey(effective);
  }
}
