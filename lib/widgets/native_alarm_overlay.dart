import 'dart:async';

import 'package:flutter/material.dart';
import 'package:habit_up/main.dart' show navigatorKey;
import 'package:habit_up/services/alarm_manager_service.dart';
import 'package:habit_up/screens/notifications/native_alarm_screen.dart';

class NativeAlarmOverlay extends StatefulWidget {
  final AlarmManagerService service;
  final Widget child;

  const NativeAlarmOverlay({
    super.key,
    required this.service,
    required this.child,
  });

  @override
  State<NativeAlarmOverlay> createState() => _NativeAlarmOverlayState();
}

class _NativeAlarmOverlayState extends State<NativeAlarmOverlay> {
  StreamSubscription<String>? _alarmSubscription;
  bool _isAlarmScreenShowing = false;

  /// Buffered payload for the next alarm that arrived while the alarm screen
  /// was already showing. Restored after the current screen is popped so we
  /// don't drop alarms when multiple fire close together.
  String? _pendingPayload;

  @override
  void initState() {
    super.initState();
    _listenToAlarms();
    _checkInitialPayload();
  }

  Future<void> _checkInitialPayload() async {
    final payload = await widget.service.getInitialAlarmPayload();
    if (payload != null && mounted && !_isAlarmScreenShowing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showAlarmScreen(payload);
      });
    }
  }

  void _listenToAlarms() {
    _alarmSubscription = widget.service.alarmPayloadStream.listen((payload) {
      if (!mounted) return;
      if (_isAlarmScreenShowing) {
        _pendingPayload = payload;
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showAlarmScreen(payload);
      });
    });
  }

  void _showAlarmScreen(String payload) {
    _isAlarmScreenShowing = true;
    _pendingPayload = null;

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      _isAlarmScreenShowing = false;
      return;
    }

    navigator
        .push<String>(
          MaterialPageRoute(
            builder: (context) => const NativeAlarmScreen(),
          ),
        )
        .then((result) {
          _isAlarmScreenShowing = false;

          if (_pendingPayload != null) {
            final nextPayload = _pendingPayload!;
            _pendingPayload = null;
            _showAlarmScreen(nextPayload);
          } else if (result == 'dismiss') {
            _showDismissedSnackBar();
          }
        });
  }

  void _showDismissedSnackBar() {
    final navigator = navigatorKey.currentState;
    if (navigator?.context != null) {
      ScaffoldMessenger.of(navigator!.context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 12),
              Text('Alarm dismissed'),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF1A1A2E),
        ),
      );
    }
  }

  @override
  void dispose() {
    _alarmSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
