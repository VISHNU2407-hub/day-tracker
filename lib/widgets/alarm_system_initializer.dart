import 'package:flutter/material.dart';
import 'package:habit_up/services/alarm_manager_service.dart';

/// Wires the [AlarmManagerService] into the widget tree so it can receive
/// alarm payloads from native code via its [MethodChannel].
///
/// The actual [AlarmManagerService.initialize] is already called in [main]
/// with the global navigator key. This widget ensures the service is fully
/// wired before any child widgets attempt to listen for alarm events.
class AlarmSystemInitializer extends StatefulWidget {
  final Widget child;

  const AlarmSystemInitializer({super.key, required this.child});

  @override
  State<AlarmSystemInitializer> createState() => _AlarmSystemInitializerState();
}

class _AlarmSystemInitializerState extends State<AlarmSystemInitializer> {
  @override
  void initState() {
    super.initState();
    _ensureAlarmSystemReady();
  }

  Future<void> _ensureAlarmSystemReady() async {
    try {
      if (!AlarmManagerService.instance.isInitialized) {
        await AlarmManagerService.instance.initialize();
      }
    } catch (_) {
      // Non-critical — alarm system will initialize on next use
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
