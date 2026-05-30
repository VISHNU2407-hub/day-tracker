import 'package:habit_up/models/task_model.dart';
import 'package:habit_up/storage/hive_boxes.dart';

class TaskStorageService {
  const TaskStorageService();

  Future<void> saveTask(TaskModel task) async {
    await HiveBoxManager.taskBox.put(task.id, task);
  }

  Future<List<TaskModel>> getAllTasks() async {
    final tasks = HiveBoxManager.taskBox.values.toList(growable: false);
    tasks.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return tasks;
  }

  Future<TaskModel?> getTaskById(String id) async {
    return HiveBoxManager.taskBox.get(id);
  }

  Future<void> updateTask(TaskModel task) async {
    await HiveBoxManager.taskBox.put(task.id, task);
  }

  Future<void> deleteTask(String id) async {
    await HiveBoxManager.taskBox.delete(id);
  }

  Future<void> clearAllTasks() async {
    await HiveBoxManager.taskBox.clear();
  }

  Future<void> saveAllTasks(List<TaskModel> tasks) async {
    if (tasks.isEmpty) {
      return;
    }
    final entries = <String, TaskModel>{
      for (final task in tasks) task.id: task,
    };
    await HiveBoxManager.taskBox.putAll(entries);
  }

  Future<bool> taskExists(String id) async {
    return HiveBoxManager.taskBox.containsKey(id);
  }

  /// Returns tasks whose effective date falls within [start]–[end] inclusive.
  Future<List<TaskModel>> getTasksByDateRange(DateTime start, DateTime end) async {
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);
    return HiveBoxManager.taskBox.values.where((task) {
      final taskDate = task.scheduledDate ?? task.dueDate ?? task.startTime;
      if (taskDate == null) {
        return false;
      }
      final normalized = DateTime(taskDate.year, taskDate.month, taskDate.day);
      return !normalized.isBefore(normalizedStart) && !normalized.isAfter(normalizedEnd);
    }).toList(growable: false);
  }

  /// Returns all tasks scheduled for a specific [date] (day-level).
  Future<List<TaskModel>> getTasksByScheduledDate(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    return HiveBoxManager.taskBox.values.where((task) {
      final taskDate = task.scheduledDate ?? task.dueDate ?? task.startTime;
      if (taskDate == null) {
        return false;
      }
      return DateTime(taskDate.year, taskDate.month, taskDate.day) == normalized;
    }).toList(growable: false);
  }

  /// Bulk-update scheduled dates for a set of tasks (used by recurring engine prep).
  Future<void> rescheduleAll(Map<String, DateTime> idDateMap) async {
    if (idDateMap.isEmpty) {
      return;
    }
    final now = DateTime.now();
    final entries = <String, TaskModel>{};
    for (final entry in idDateMap.entries) {
      final existing = HiveBoxManager.taskBox.get(entry.key);
      if (existing == null) {
        continue;
      }
      final normalizedDate = DateTime(
        entry.value.year,
        entry.value.month,
        entry.value.day,
      );
      entries[entry.key] = existing.copyWith(
        scheduledDate: normalizedDate,
        status: TaskStatus.scheduled,
        updatedAt: now,
      );
    }
    if (entries.isNotEmpty) {
      await HiveBoxManager.taskBox.putAll(entries);
    }
  }
}
