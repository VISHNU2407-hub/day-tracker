import 'dart:convert';

import 'package:habit_up/models/notification_model.dart';
import 'package:habit_up/models/task_model.dart';
import 'package:habit_up/providers/task_provider.dart';
import 'package:habit_up/services/alarm_manager_service.dart';
import 'package:habit_up/services/alarm_sound_service.dart';
import 'package:habit_up/storage/hive_boxes.dart';

class ReminderSchedulingService {
  ReminderSchedulingService._();

  static final ReminderSchedulingService instance =
      ReminderSchedulingService._();

  final AlarmManagerService _alarmManager = AlarmManagerService.instance;

  void attach(TaskProvider provider) {
    provider.onTaskReminderCreated = scheduleForTask;
    provider.onTaskReminderCancelled = cancelForTaskId;
  }

  Future<void> syncAll(Iterable<TaskModel> tasks) async {
    for (final task in tasks) {
      try {
        await scheduleForTask(task);
      } catch (_) {
      }
    }
  }

  Future<void> scheduleForTask(TaskModel task) async {
    await cancelForTaskId(task.id);

    final reminderTime = task.reminderTime;
    if (reminderTime == null || task.isCompleted) {
      return;
    }

    if (!reminderTime.isAfter(DateTime.now())) {
      return;
    }

    final payload = await _resolvePayloadWithSound(task);

    await _alarmManager.scheduleAlarm(
      payload: payload,
      triggerAtMillis: reminderTime.millisecondsSinceEpoch,
    );

    await _upsertNotificationRecord(task, reminderTime);
  }

  Future<void> cancelForTaskId(String taskId) async {
    final payload = jsonEncode(<String, dynamic>{
      'type': 'task',
      'alarmId': _alarmIdForTask(taskId),
      'taskId': taskId,
    });

    await _alarmManager.cancelAlarm(payload: payload);
    await _removeNotificationRecord(taskId);
  }

  /// Resolves the custom sound URI and embeds it into the payload JSON.
  ///
  /// Also attaches [customSoundUri] so the native AlarmForegroundService can
  /// play the user's selected sound when the alarm fires.
  Future<String> _resolvePayloadWithSound(TaskModel task) async {
    final soundPath = await AlarmSoundService.instance.getCustomSoundPath();
    final basePayload = <String, dynamic>{
      'type': 'task',
      'alarmId': _alarmIdForTask(task.id),
      'taskId': task.id,
      'taskName': task.title,
      'title': task.title,
      'description': task.description?.trim().isNotEmpty == true
          ? task.description!.trim()
          : 'Time to focus on this task.',
      'notificationId': task.id.hashCode.abs() % 2147483647,
    };
    if (soundPath != null && soundPath.isNotEmpty) {
      basePayload['customSoundUri'] = soundPath;
    }
    return jsonEncode(basePayload);
  }

  String _alarmIdForTask(String taskId) => 'task_reminder_$taskId';

  Future<void> _upsertNotificationRecord(
    TaskModel task,
    DateTime reminderTime,
  ) async {
    try {
      final box = HiveBoxManager.notificationBox;
      final id = _alarmIdForTask(task.id);
      await box.put(
        id,
        NotificationModel(
          id: id,
          title: task.title,
          description: task.description,
          scheduledTime: reminderTime,
          category: NotificationCategory.task,
          priority: _priorityFor(task.difficulty),
          taskId: task.id,
          metadata: <String, dynamic>{
            'alarmId': id,
            'source': 'native_alarm_manager',
          },
        ),
      );
    } catch (_) {
    }
  }

  Future<void> _removeNotificationRecord(String taskId) async {
    try {
      await HiveBoxManager.notificationBox.delete(_alarmIdForTask(taskId));
    } catch (_) {
    }
  }

  ReminderPriority _priorityFor(TaskDifficulty difficulty) {
    return switch (difficulty) {
      TaskDifficulty.easy => ReminderPriority.low,
      TaskDifficulty.medium => ReminderPriority.medium,
      TaskDifficulty.hard => ReminderPriority.high,
    };
  }
}
