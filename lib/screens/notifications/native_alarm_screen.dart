import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:habit_up/services/alarm_manager_service.dart';

class NativeAlarmScreen extends StatefulWidget {
  const NativeAlarmScreen({super.key});

  @override
  State<NativeAlarmScreen> createState() => _NativeAlarmScreenState();
}

class _NativeAlarmScreenState extends State<NativeAlarmScreen> {
  String? _currentPayload;
  final AlarmManagerService _alarmService = AlarmManagerService();

  @override
  void initState() {
    super.initState();
    _loadInitialPayload();
  }

  Future<void> _loadInitialPayload() async {
    final payload = await _alarmService.getInitialAlarmPayload();
    if (mounted) {
      setState(() {
        _currentPayload = payload;
      });
    }
  }

  Map<String, dynamic>? _getPayloadData() {
    if (_currentPayload == null) return null;
    try {
      return jsonDecode(_currentPayload!) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final payloadData = _getPayloadData();
    final title = payloadData?['taskName'] as String? ?? 'Alarm';
    final description = payloadData?['description'] as String? ?? 'Alarm is ringing';

    return Scaffold(
      backgroundColor: const Color(0xFF080C1A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.alarm,
                  size: 120,
                  color: Color(0xFF00D4FF),
                ),
                const SizedBox(height: 48),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFFB0B0B0),
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 64),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _onSnooze,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6D00),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Snooze (5 min)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _onDismiss,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(
                        color: Color(0xFF424242),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Dismiss',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSnooze() async {
    if (_currentPayload != null) {
      await _alarmService.snoozeAlarm(payload: _currentPayload!);
    }
    if (mounted) {
      Navigator.of(context).pop('snooze');
    }
  }

  Future<void> _onDismiss() async {
    await _alarmService.dismissCurrentAlarm();
    if (mounted) {
      Navigator.of(context).pop('dismiss');
    }
  }
}
