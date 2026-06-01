import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AlarmManagerService {
  static const MethodChannel _channel = MethodChannel('com.app.alarm/bridge');

  static final AlarmManagerService _instance = AlarmManagerService._internal();
  static AlarmManagerService get instance => _instance;
  factory AlarmManagerService() => _instance;
  AlarmManagerService._internal();

  bool _isInitialized = false;
  String? _currentPayload;
  final _payloadController = StreamController<String>.broadcast();

  Stream<String> get alarmPayloadStream => _payloadController.stream;
  bool get isInitialized => _isInitialized;
  String? get currentPayload => _currentPayload;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _channel.setMethodCallHandler(_handleMethodCall);
    _isInitialized = true;
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onAlarmPayload':
        final payload = call.arguments as String;
        _currentPayload = payload;
        _payloadController.add(payload);
        break;
      default:
        break;
    }
  }

  Future<String?> getInitialAlarmPayload() async {
    try {
      final result = await _channel.invokeMethod('getInitialAlarmPayload');
      return result as String?;
    } catch (e) {
      debugPrint('[AlarmManagerService] getInitialAlarmPayload failed: $e');
      return null;
    }
  }

  Future<void> dismissCurrentAlarm() async {
    try {
      final nextPayload =
          await _channel.invokeMethod<String?>('dismissCurrentAlarm');
      _currentPayload = nextPayload;
      if (nextPayload != null) {
        _payloadController.add(nextPayload);
      }
    } catch (e) {
      debugPrint('[AlarmManagerService] dismissCurrentAlarm failed: $e');
    }
  }

  Future<void> stopAlarmAudio() async {
    try {
      await _channel.invokeMethod('stopAlarmAudio');
    } catch (e) {
      debugPrint('[AlarmManagerService] stopAlarmAudio failed: $e');
    }
  }

  Future<void> scheduleAlarm({
    required String payload,
    required int triggerAtMillis,
  }) async {
    try {
      debugPrint(
        '[AlarmManagerService] scheduleAlarm: $triggerAtMillis payload=${payload.length}chars',
      );
      await _channel.invokeMethod('scheduleAlarmPayload', {
        'payload': payload,
        'triggerAtMillis': triggerAtMillis,
      });
    } catch (e) {
      debugPrint('[AlarmManagerService] scheduleAlarm failed: $e');
    }
  }

  Future<void> cancelAlarm({required String payload}) async {
    try {
      await _channel.invokeMethod('cancelAlarmPayload', {'payload': payload});
    } catch (e) {
      debugPrint('[AlarmManagerService] cancelAlarm failed: $e');
    }
  }

  /// Syncs the bedtime reminder enabled preference to native SharedPreferences
  /// so [AlarmReceiver.rescheduleNextBedtime] can honour the setting when
  /// auto-rescheduling bedtime alarms in pure Kotlin code.
  Future<void> syncBedtimeReminderEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod('saveBedtimeReminderEnabled', {
        'enabled': enabled,
      });
    } catch (e) {
      debugPrint('[AlarmManagerService] syncBedtimeReminderEnabled failed: $e');
    }
  }

  /// Persists the user's preferred bedtime time (hour/minute) to native
  /// SharedPreferences so [AlarmReceiver.rescheduleNextBedtime] and
  /// [AlarmScheduler.reschedulePersisted] can schedule the next alarm at the
  /// correct time of day — even when the phone is rebooted.
  Future<void> syncBedtimeTime(int hour, int minute) async {
    try {
      await _channel.invokeMethod('saveBedtimeTime', {
        'hour': hour,
        'minute': minute,
      });
    } catch (e) {
      debugPrint('[AlarmManagerService] syncBedtimeTime failed: $e');
    }
  }

  void dispose() {
    _payloadController.close();
    _channel.setMethodCallHandler(null);
  }
}
