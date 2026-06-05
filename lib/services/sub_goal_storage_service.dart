import 'package:habit_up/models/sub_goal_model.dart';
import 'package:habit_up/storage/hive_boxes.dart';
import 'package:hive/hive.dart';

class SubGoalStorageService {
  const SubGoalStorageService();

  Box<SubGoalModel> get _subGoalBox => HiveBoxManager.subGoalBox;

  Future<void> saveSubGoal(SubGoalModel subGoal) async {
    await _subGoalBox.put(subGoal.id, subGoal);
  }

  Future<List<SubGoalModel>> getAllSubGoals() async {
    return _subGoalBox.values.toList(growable: false);
  }

  Future<SubGoalModel?> getSubGoalById(String id) async {
    return _subGoalBox.get(id);
  }

  Future<void> updateSubGoal(SubGoalModel subGoal) async {
    await _subGoalBox.put(subGoal.id, subGoal);
  }

  Future<void> deleteSubGoal(String id) async {
    await _subGoalBox.delete(id);
  }

  Future<void> clearAllSubGoals() async {
    await _subGoalBox.clear();
  }

  Future<bool> subGoalExists(String id) async {
    return _subGoalBox.containsKey(id);
  }

  Future<void> saveAllSubGoals(List<SubGoalModel> subGoals) async {
    if (subGoals.isEmpty) {
      return;
    }
    final entries = <String, SubGoalModel>{
      for (final sg in subGoals) sg.id: sg,
    };
    await _subGoalBox.putAll(entries);
  }

  Future<List<SubGoalModel>> getSubGoalsByGoalId(String goalId) async {
    return _subGoalBox.values
        .where((SubGoalModel subGoal) => subGoal.goalId == goalId)
        .toList(growable: false);
  }

  Future<List<SubGoalModel>> getSubGoalsByStatus(SubGoalStatus status) async {
    return _subGoalBox.values
        .where((SubGoalModel subGoal) => subGoal.status == status)
        .toList(growable: false);
  }

  Future<List<SubGoalModel>> getSubGoalsByGoalIdAndStatus(
    String goalId,
    SubGoalStatus status,
  ) async {
    return _subGoalBox.values
        .where(
          (SubGoalModel subGoal) =>
              subGoal.goalId == goalId && subGoal.status == status,
        )
        .toList(growable: false);
  }

  Future<void> updateSubGoalProgress(String id, double progress) async {
    final SubGoalModel? existing = _subGoalBox.get(id);
    if (existing == null) {
      return;
    }

    final double normalizedProgress = progress.clamp(0.0, 1.0);
    final bool willComplete = normalizedProgress >= 1.0;
    final DateTime now = DateTime.now();

    await _subGoalBox.put(
      id,
      existing.copyWith(
        progress: normalizedProgress,
        isCompleted: willComplete,
        completedAt: willComplete ? (existing.completedAt ?? now) : null,
        status: willComplete ? SubGoalStatus.completed : SubGoalStatus.active,
        updatedAt: now,
        clearCompletedAt: !willComplete,
      ),
    );
  }

  Future<void> updateSubGoalXp(String id, int xpDelta) async {
    final SubGoalModel? existing = _subGoalBox.get(id);
    if (existing == null) {
      return;
    }

    await _subGoalBox.put(
      id,
      existing.copyWith(
        xp: (existing.xp + xpDelta).clamp(0, double.maxFinite).toInt(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> updateSubGoalStreak(String id, int streak) async {
    final SubGoalModel? existing = _subGoalBox.get(id);
    if (existing == null) {
      return;
    }

    await _subGoalBox.put(
      id,
      existing.copyWith(
        streak: streak,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> addTaskIdToSubGoal(String subGoalId, String taskId) async {
    final SubGoalModel? existing = _subGoalBox.get(subGoalId);
    if (existing == null) {
      return;
    }

    final updatedTaskIds = List<String>.from(existing.taskIds)
      ..add(taskId);

    await _subGoalBox.put(
      subGoalId,
      existing.copyWith(
        taskIds: updatedTaskIds,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> removeTaskIdFromSubGoal(
      String subGoalId, String taskId) async {
    final SubGoalModel? existing = _subGoalBox.get(subGoalId);
    if (existing == null) {
      return;
    }

    final updatedTaskIds = List<String>.from(existing.taskIds)
      ..remove(taskId);

    await _subGoalBox.put(
      subGoalId,
      existing.copyWith(
        taskIds: updatedTaskIds,
        updatedAt: DateTime.now(),
      ),
    );
  }
}
