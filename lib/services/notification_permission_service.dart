import 'package:flutter/services.dart';

class NotificationPermissionService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.habit_up/permissions',
  );

  bool _postNotificationsGranted = false;
  bool _exactAlarmGranted = false;
  bool _fullScreenIntentGranted = false;
  bool _audioPermissionGranted = false;
  bool _batteryOptimizationDisabled = false;

  bool get postNotificationsGranted => _postNotificationsGranted;
  bool get exactAlarmGranted => _exactAlarmGranted;
  bool get fullScreenIntentGranted => _fullScreenIntentGranted;
  bool get audioPermissionGranted => _audioPermissionGranted;
  bool get batteryOptimizationDisabled => _batteryOptimizationDisabled;

  Future<void> refreshAllStatuses() async {
    await refreshPostNotificationsStatus();
    await refreshExactAlarmStatus();
    await refreshFullScreenIntentStatus();
    await refreshAudioPermissionStatus();
    await refreshBatteryOptimizationStatus();
  }

  Future<void> refreshPostNotificationsStatus() async {
    try {
      _postNotificationsGranted =
          await _channel.invokeMethod<bool>('checkPostNotifications') ?? false;
    } catch (e) {
      _postNotificationsGranted = false;
    }
  }

  Future<void> refreshExactAlarmStatus() async {
    try {
      _exactAlarmGranted =
          await _channel.invokeMethod<bool>('checkExactAlarm') ?? false;
    } catch (e) {
      _exactAlarmGranted = false;
    }
  }

  Future<void> refreshFullScreenIntentStatus() async {
    try {
      _fullScreenIntentGranted =
          await _channel.invokeMethod<bool>('checkFullScreenIntent') ?? false;
    } catch (e) {
      _fullScreenIntentGranted = false;
    }
  }

  /// Checks the READ_MEDIA_AUDIO permission status (Android 13+).
  /// Returns true on older Android versions where the permission is implicit.
  Future<bool> refreshAudioPermissionStatus() async {
    try {
      _audioPermissionGranted =
          await _channel.invokeMethod<bool>('checkAudioPermission') ?? true;
    } catch (e) {
      _audioPermissionGranted = true; // assume granted on error (pre-API 33)
    }
    return _audioPermissionGranted;
  }

  /// Requests the READ_MEDIA_AUDIO runtime permission (Android 13+).
  /// Returns true immediately on older versions.
  Future<bool> requestAudioPermission() async {
    try {
      _audioPermissionGranted =
          await _channel.invokeMethod<bool>('requestAudioPermission') ?? true;
    } catch (e) {
      _audioPermissionGranted = true;
    }
    return _audioPermissionGranted;
  }

  /// Opens the app's system settings page so the user can manually grant
  /// the audio permission if it was permanently denied.
  Future<void> openAudioPermissionSettings() async {
    try {
      await _channel.invokeMethod<void>('openAudioPermissionSettings');
    } catch (_) {
    }
  }

  Future<void> refreshBatteryOptimizationStatus() async {
    try {
      _batteryOptimizationDisabled =
          await _channel.invokeMethod<bool>('checkBatteryOptimization') ?? false;
    } catch (_) {
      _batteryOptimizationDisabled = false;
    }
  }

  Future<void> requestPostNotifications() async {
    try {
      _postNotificationsGranted =
          await _channel.invokeMethod<bool>('requestPostNotifications') ??
              false;
    } catch (_) {
      _postNotificationsGranted = false;
    }
  }

  /// Opens system settings for the exact alarm permission.
  ///
  /// NOTE: Does NOT refresh permission status immediately, because the user
  /// hasn't had time to toggle the setting yet. Instead, the caller should
  /// use [refreshAllStatuses] when the app returns to the foreground.
  Future<void> requestExactAlarm() async {
    try {
      await _channel.invokeMethod<void>('openExactAlarmSettings');
    } catch (_) {
      _exactAlarmGranted = false;
    }
  }

  /// Opens system settings for the full-screen intent permission.
  ///
  /// NOTE: Does NOT refresh permission status immediately, because the user
  /// hasn't had time to toggle the setting yet. Instead, the caller should
  /// use [refreshAllStatuses] when the app returns to the foreground.
  Future<void> requestFullScreenIntent() async {
    try {
      await _channel.invokeMethod<void>('openFullScreenIntentSettings');
    } catch (_) {
      _fullScreenIntentGranted = false;
    }
  }

  /// Opens system settings to request disabling battery optimization.
  ///
  /// NOTE: Does NOT refresh permission status immediately. The caller should
  /// use [refreshAllStatuses] when the app returns to the foreground.
  Future<void> requestBatteryOptimization() async {
    try {
      await _channel.invokeMethod<void>('openBatteryOptimizationSettings');
    } catch (_) {
    }
  }

  Future<void> requestAllCriticalPermissions() async {
    await requestPostNotifications();
    await requestExactAlarm();
    await requestFullScreenIntent();
    // Battery optimization is not strictly a permission — we mention it in
    // the dialog but don't auto-request it since it requires a manual toggle.
  }
}
