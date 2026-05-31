import 'dart:convert';

import 'package:habit_up/services/alarm_manager_service.dart';
import 'package:habit_up/services/alarm_sound_service.dart';

class BedtimeAlarmScheduler {
  final AlarmManagerService _alarmManager;

  BedtimeAlarmScheduler({AlarmManagerService? alarmManager})
      : _alarmManager = alarmManager ?? AlarmManagerService.instance;

  Future<void> schedule({DateTime? bedtimeOverride}) async {
    try {
      final bedtime = _nextBedtimeOccurrence(
        bedtimeOverride ?? _calculateDefaultBedtime(),
      );
      final customSoundUri =
          await AlarmSoundService.instance.getCustomSoundPath();

      final payload = jsonEncode({
        'type': 'bedtime',
        'title': 'Plan Tomorrow',
        'description': 'Time to plan your goals for tomorrow',
        'alarmId': 'bedtime_alarm',
        'taskId': 'bedtime',
        'taskName': 'Plan Tomorrow',
        'notificationId': 9999,
        if (customSoundUri != null && customSoundUri.isNotEmpty)
          'customSoundUri': customSoundUri,
      });

      await _alarmManager.scheduleAlarm(
        payload: payload,
        triggerAtMillis: bedtime.millisecondsSinceEpoch,
      );

      await _alarmManager.syncBedtimeReminderEnabled(true);
      await _alarmManager.syncBedtimeTime(bedtime.hour, bedtime.minute);
    } catch (_) {
    }
  }

  Future<void> cancel() async {
    try {
      final payload = jsonEncode({
        'type': 'bedtime',
        'alarmId': 'bedtime_alarm',
      });
      await _alarmManager.cancelAlarm(payload: payload);
      await _alarmManager.syncBedtimeReminderEnabled(false);
    } catch (_) {
    }
  }

  /// Ensures the bedtime alarm is scheduled. If already scheduled, it will
  /// be re-scheduled (cancelled + re-created) to pick up any config changes.
  Future<void> ensureScheduled() async {
    try {
      await schedule();
    } catch (_) {
    }
  }

  DateTime _calculateDefaultBedtime() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 21, 0); // 9:00 PM
  }

  DateTime _nextBedtimeOccurrence(DateTime bedtime) {
    final now = DateTime.now();
    var next = DateTime(
      now.year,
      now.month,
      now.day,
      bedtime.hour,
      bedtime.minute,
    );
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }
}
