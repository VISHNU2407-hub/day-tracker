import 'package:habit_up/models/goal_model.dart';
import 'package:habit_up/storage/hive_boxes.dart';
import 'package:hive/hive.dart';

class GoalStorageService {
  const GoalStorageService();

  Box<GoalModel> get _goalBox => HiveBoxManager.goalBox;

  Future<void> saveGoal(GoalModel goal) async {
    await _goalBox.put(goal.id, goal);
  }

  Future<List<GoalModel>> getAllGoals() async {
    return _goalBox.values.toList(growable: false);
  }

  Future<GoalModel?> getGoalById(String id) async {
    return _goalBox.get(id);
  }

  Future<void> updateGoal(GoalModel goal) async {
    await _goalBox.put(goal.id, goal);
  }

  Future<void> deleteGoal(String id) async {
    await _goalBox.delete(id);
  }

  Future<void> clearAllGoals() async {
    await _goalBox.clear();
  }

  Future<bool> goalExists(String id) async {
    return _goalBox.containsKey(id);
  }

  Future<void> saveAllGoals(List<GoalModel> goals) async {
    if (goals.isEmpty) {
      return;
    }
    final entries = <String, GoalModel>{
      for (final goal in goals) goal.id: goal,
    };
    await _goalBox.putAll(entries);
  }

  Future<List<GoalModel>> getGoalsByStatus(GoalStatus status) async {
    return _goalBox.values
        .where((GoalModel goal) => goal.status == status)
        .toList(growable: false);
  }

  Future<GoalModel?> getPinnedGoal() async {
    final goals = _goalBox.values;
    for (final goal in goals) {
      if (goal.isPinned) {
        return goal;
      }
    }
    return null;
  }

  Future<void> pinGoal(String id) async {
    final GoalModel? existingGoal = _goalBox.get(id);
    if (existingGoal == null) {
      return;
    }

    // Unpin any currently pinned goal
    final GoalModel? currentPinned = await getPinnedGoal();
    if (currentPinned != null && currentPinned.id != id) {
      await _goalBox.put(
        currentPinned.id,
        currentPinned.copyWith(
          isPinned: false,
          updatedAt: DateTime.now(),
        ),
      );
    }

    await _goalBox.put(
      id,
      existingGoal.copyWith(
        isPinned: true,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> unpinGoal(String id) async {
    final GoalModel? existingGoal = _goalBox.get(id);
    if (existingGoal == null) {
      return;
    }

    await _goalBox.put(
      id,
      existingGoal.copyWith(
        isPinned: false,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> switchPinnedGoal(String newId) async {
    final GoalModel? currentPinned = await getPinnedGoal();
    if (currentPinned != null && currentPinned.id != newId) {
      await _goalBox.put(
        currentPinned.id,
        currentPinned.copyWith(
          isPinned: false,
          updatedAt: DateTime.now(),
        ),
      );
    }

    final GoalModel? newGoal = _goalBox.get(newId);
    if (newGoal != null) {
      await _goalBox.put(
        newId,
        newGoal.copyWith(
          isPinned: true,
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  Future<void> updateGoalProgress(String id, double progress) async {
    final GoalModel? existingGoal = _goalBox.get(id);
    if (existingGoal == null) {
      return;
    }

    final double normalizedProgress = progress.clamp(0.0, 1.0);
    final bool willComplete = normalizedProgress >= 1.0;
    final DateTime now = DateTime.now();

    await _goalBox.put(
      id,
      existingGoal.copyWith(
        progress: normalizedProgress,
        isCompleted: willComplete || existingGoal.isCompleted,
        completedAt: willComplete ? (existingGoal.completedAt ?? now) : existingGoal.completedAt,
        status: willComplete ? GoalStatus.completed : existingGoal.status,
        updatedAt: now,
      ),
    );
  }

  Future<void> updateGoalXp(String id, int xpDelta) async {
    final GoalModel? existingGoal = _goalBox.get(id);
    if (existingGoal == null) {
      return;
    }

    await _goalBox.put(
      id,
      existingGoal.copyWith(
        xp: (existingGoal.xp + xpDelta).clamp(0, double.maxFinite).toInt(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> updateGoalStreak(String id, int streak) async {
    final GoalModel? existingGoal = _goalBox.get(id);
    if (existingGoal == null) {
      return;
    }

    await _goalBox.put(
      id,
      existingGoal.copyWith(
        streak: streak,
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Unpin all goals in bulk (useful for cleanup / re-initialisation).
  Future<void> unpinAllBulk() async {
    final pinnedGoals = _goalBox.values
        .where((GoalModel g) => g.isPinned)
        .toList(growable: false);

    if (pinnedGoals.isEmpty) return;

    final now = DateTime.now();
    final entries = <String, GoalModel>{
      for (final goal in pinnedGoals)
        goal.id: goal.copyWith(isPinned: false, updatedAt: now),
    };
    await _goalBox.putAll(entries);
  }

  /// How many goals are currently marked as pinned (should be 0 or 1).
  int countPinnedGoals() {
    return _goalBox.values.where((GoalModel g) => g.isPinned).length;
  }
}
