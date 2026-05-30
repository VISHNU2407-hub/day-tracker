import 'package:habit_up/providers/goal_provider.dart';
import 'package:habit_up/providers/sub_goal_provider.dart';
import 'package:habit_up/providers/task_provider.dart';
import 'package:habit_up/services/xp_streak_service.dart';

/// Coordinates automatic progress, XP, and streak propagation across the
/// Task → SubGoal → Goal hierarchy.
///
/// Responsibilities:
///   - Task completion/update → SubGoal progress recalculation
///   - SubGoal completion/update → Goal progress recalculation
///   - Task XP → SubGoal XP → Goal XP propagation
///   - Task streak → SubGoal streak → Goal streak propagation
///   - XP/streak sync with [XpStreakService] for user-level persistence
///
/// All hooks are wired in the constructor and will fire automatically whenever
/// the respective provider mutates a model in the hierarchy.
class HierarchyCascadeService {
  final TaskProvider _taskProvider;
  final SubGoalProvider _subGoalProvider;
  final GoalProvider _goalProvider;
  final XpStreakService? _xpStreakService;

  HierarchyCascadeService(
    this._taskProvider,
    this._subGoalProvider,
    this._goalProvider, {
    this._xpStreakService,
  }) {
    _wireTaskToSubGoal();
    _wireSubGoalToGoal();
    _wireDeleteCascades();
  }

  // ---------------------------------------------------------------------------
  // Task → SubGoal wiring
  // ---------------------------------------------------------------------------

  void _wireTaskToSubGoal() {
    // Progress cascade: task created / updated / deleted / toggled
    _taskProvider.onTaskProgressCascadeRequested = (task) async {
      // The hook fires after the mutation is applied. Check if the task
      // still exists in the provider — if not, it was deleted.
      final taskStillExists = await _taskProvider.getTaskById(task.id) != null;
      if (!taskStillExists) {
        if (task.subGoalId != null) {
          final subGoal = _subGoalProvider.getSubGoalById(task.subGoalId!);
          if (subGoal != null && subGoal.taskIds.contains(task.id)) {
            await _subGoalProvider.removeTaskFromSubGoal(
              task.subGoalId!,
              task.id,
            );
          }
        }
      }

      if (task.subGoalId != null) {
        await _syncSubGoalProgressFromTasks(task.subGoalId!);
      }
      // If the task has a goalId but no subGoalId, cascade straight to Goal.
      if (task.goalId != null && task.subGoalId == null) {
        await _syncGoalProgressFromSubGoals(task.goalId!);
      }
    };

    // XP propagation: task completed → subGoal XP → goal XP.
    // Also notifies XpStreakService for user-level XP persistence.
    _taskProvider.onTaskXpAwarded = (task, xp) async {
      if (task.subGoalId != null) {
        // SubGoal's onXpAwarded hook cascades to Goal automatically.
        await _subGoalProvider.addSubGoalXp(task.subGoalId!, xp);
      } else if (task.goalId != null) {
        // No subGoal — direct to goal.
        await _goalProvider.addGoalXp(task.goalId!, xp);
      }
      // User-level XP persistence (streak bonuses, level progression).
      await _xpStreakService?.onTaskXpAwarded(task, xp);
    };

    // XP reversal: task uncompleted → subGoal XP subtract → goal XP subtract.
    // Also notifies XpStreakService for user-level XP ledger adjustment.
    _taskProvider.onTaskXpReversed = (task, xp) async {
      if (task.subGoalId != null) {
        // Subtract XP from subGoal (pass negative delta)
        await _subGoalProvider.addSubGoalXp(task.subGoalId!, -xp);
      } else if (task.goalId != null) {
        // No subGoal — subtract directly from goal.
        await _goalProvider.addGoalXp(task.goalId!, -xp);
      }
      // User-level XP reversal (adjust ledger, update cached XP).
      await _xpStreakService?.onTaskXpReversed(task, xp);
    };

    // Streak propagation: task completed → subGoal streak → goal streak.
    // Also notifies XpStreakService for user-level streak tracking.
    _taskProvider.onTaskCompletedForStreak = (task) async {
      if (task.subGoalId != null &&
          _subGoalProvider.getSubGoalById(task.subGoalId!) != null) {
        final current = _subGoalProvider
            .getSubGoalById(task.subGoalId!)!
            .streak;
        await _subGoalProvider.updateSubGoalStreak(
          task.subGoalId!,
          current + 1,
        );
      } else if (task.goalId != null &&
          _goalProvider.getGoalById(task.goalId!) != null) {
        final current = _goalProvider.getGoalById(task.goalId!)!.streak;
        await _goalProvider.updateGoalStreak(task.goalId!, current + 1);
      }
      // User-level daily streak tracking.
      await _xpStreakService?.onTaskCompletedForStreak(task);
    };
  }

  // ---------------------------------------------------------------------------
  // SubGoal → Goal wiring
  // ---------------------------------------------------------------------------

  void _wireSubGoalToGoal() {
    // Progress cascade: subGoal created / updated / deleted / recalculated
    _subGoalProvider.onProgressCascadeRequested = (subGoal) async {
      await _syncGoalProgressFromSubGoals(subGoal.goalId);
    };

    // XP propagation: subGoal XP earned → goal XP
    _subGoalProvider.onXpAwarded = (subGoal, xp) async {
      await _goalProvider.addGoalXp(subGoal.goalId, xp);
    };

    // Streak propagation: subGoal streak updated → goal streak
    _subGoalProvider.onStreakUpdated = (subGoal) async {
      await _goalProvider.updateGoalStreak(subGoal.goalId, subGoal.streak);
    };
  }

  // ---------------------------------------------------------------------------
  // Delete cascade wiring — when a goal or subgoal is deleted, clean up
  // linked entities in storage so no orphaned data remains after restart.
  // ---------------------------------------------------------------------------

  void _wireDeleteCascades() {
    // Goal deleted → delete linked subgoals, tasks, and notifications
    _goalProvider.onCascadeDeleteRequested = (goalId) async {
      final linkedSubGoals = _subGoalProvider.getSubGoalsByGoalId(goalId);
      for (final sg in linkedSubGoals) {
        // Delete tasks linked to this subgoal
        for (final taskId in sg.taskIds) {
          final task = await _taskProvider.getTaskById(taskId);
          if (task != null) {
            await _taskProvider.deleteTask(taskId);
          }
        }
        await _subGoalProvider.deleteSubGoal(sg.id);
      }
      // Also find tasks directly linked to the goal (no subgoal)
      final goalTasks = _taskProvider.getTasksForGoal(goalId);
      for (final task in goalTasks) {
        await _taskProvider.deleteTask(task.id);
      }
    };

    // SubGoal deleted → delete linked tasks and notification reminders
    _subGoalProvider.onCascadeDeleteRequested = (subGoalId) async {
      final sg = _subGoalProvider.getSubGoalById(subGoalId);
      if (sg != null) {
        for (final taskId in sg.taskIds) {
          final task = await _taskProvider.getTaskById(taskId);
          if (task != null) {
            await _taskProvider.deleteTask(taskId);
          }
        }
      }
    };
  }

  // ---------------------------------------------------------------------------
  // Internal sync helpers
  // ---------------------------------------------------------------------------

  /// Count completed / total tasks for [subGoalId] and recalculate progress.
  Future<void> _syncSubGoalProgressFromTasks(String subGoalId) async {
    final subGoalTasks = _taskProvider.getTasksForSubGoal(subGoalId);
    final completedCount = subGoalTasks.where((t) => t.isCompleted).length;

    await _subGoalProvider.calculateProgressFromTasks(
      subGoalId: subGoalId,
      completedTaskCount: completedCount,
      totalTaskCount: subGoalTasks.length,
    );
  }

  /// Count completed / total subGoals for [goalId] and recalculate progress.
  Future<void> _syncGoalProgressFromSubGoals(String goalId) async {
    final goalSubGoals = _subGoalProvider.getSubGoalsByGoalId(goalId);
    final completedCount = goalSubGoals.where((sg) => sg.isCompleted).length;

    if (goalSubGoals.isEmpty) {
      await _goalProvider.recalculateGoalProgress(goalId, completedRatio: 0.0);
    } else {
      await _goalProvider.recalculateGoalProgress(
        goalId,
        completedRatio: completedCount / goalSubGoals.length,
      );
    }
  }
}
