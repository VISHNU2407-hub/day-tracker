import 'dart:async';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the custom alarm sound selection and persistence.
///
/// Stores the absolute file path of a user-selected audio file in:
/// 1. Dart [SharedPreferences] under [kCustomSoundPathKey].
/// 2. Android native [SharedPreferences] (via method channel) so that
///    [AlarmReceiver] can read the custom sound URI when auto-rescheduling
///    the bedtime alarm — ensuring the sound preference survives app restarts
///    and works in the Kotlin-only auto-reschedule path.
class AlarmSoundService {
  AlarmSoundService._();

  static final AlarmSoundService instance = AlarmSoundService._();

  static const String kCustomSoundPathKey = 'custom_alarm_sound_path';
  static const MethodChannel _channel = MethodChannel(
    'com.example.habit_up/permissions',
  );

  /// Returns the stored custom alarm sound file path, or `null` if none set.
  Future<String?> getCustomSoundPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kCustomSoundPathKey);
  }

  /// Persists the chosen audio file path.
  ///
  /// Saves to both Dart [SharedPreferences] and Android native
  /// [SharedPreferences] so the Kotlin [AlarmReceiver] can access it when
  /// auto-rescheduling bedtime alarms without involving the Dart isolate.
  Future<void> setCustomSoundPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kCustomSoundPathKey, path);
    await _syncToNative(path);
  }

  /// Clears the custom alarm sound preference.
  Future<void> clearCustomSoundPath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kCustomSoundPathKey);
    await _syncToNative(null);
  }

  /// Returns `true` if a custom alarm sound path is stored.
  Future<bool> hasCustomSound() async {
    final path = await getCustomSoundPath();
    return path != null && path.isNotEmpty;
  }

  /// Syncs the custom sound URI to the Android native SharedPreferences so
  /// [AlarmReceiver] can read it when auto-rescheduling in pure Kotlin code.
  Future<void> _syncToNative(String? uri) async {
    try {
      await _channel.invokeMethod('saveCustomSoundUri', {'uri': uri ?? ''});
    } catch (_) {
    }
  }
}
