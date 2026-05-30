import 'dart:async';

import 'package:flutter/material.dart';
import 'package:habit_up/services/bedtime_alarm_scheduler.dart';
import 'package:habit_up/services/user_storage_service.dart';

/// Ensures the daily bedtime planning alarm is scheduled or cancelled
/// based on the user's preference when the app first renders.
///
/// This is the widget-tree counterpart to the bedtime scheduling logic
/// that already runs in [main]. It provides a safety net in case the
/// [main] scheduling fails or the widget tree is re-created (e.g. in the
/// AlarmActivity multi-engine scenario).
class BedtimePlannerInitializer extends StatefulWidget {
  final Widget child;

  const BedtimePlannerInitializer({super.key, required this.child});

  @override
  State<BedtimePlannerInitializer> createState() =>
      _BedtimePlannerInitializerState();
}

class _BedtimePlannerInitializerState extends State<BedtimePlannerInitializer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initBedtime());
  }

  Future<void> _initBedtime() async {
    try {
      final user = await const UserStorageService().getCurrentUser();
      if (!mounted) return;

      final bedtimeReminderEnabled =
          user?.preferences['bedtime_reminder_enabled'] != false;

      if (bedtimeReminderEnabled) {
        await BedtimeAlarmScheduler().schedule(bedtimeOverride: user?.bedtime);
      } else {
        await BedtimeAlarmScheduler().cancel();
      }
    } catch (_) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
