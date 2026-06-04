import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:habit_up/providers/task_provider.dart';
import 'package:habit_up/screens/tasks/widgets/edit_task_dialog.dart';
import 'package:habit_up/services/alarm_manager_service.dart';
import 'package:provider/provider.dart';

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
    final isBedtime = payloadData?['type'] == 'bedtime';
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
                // Reschedule button — shown only for task alarms.
                // Bedtime alarms are not backed by a TaskModel, so Reschedule
                // is not supported (getTaskById('bedtime') returns null).
                if (!isBedtime) ...[
                  const SizedBox(height: 64),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _onReschedule,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6D00),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Reschedule',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (isBedtime) const SizedBox(height: 64),
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

  Future<void> _onReschedule() async {
    final data = _getPayloadData();
    final taskId = data?['taskId'] as String?;
    if (taskId == null) return;

    await _alarmService.dismissCurrentAlarm();
    if (!mounted) return;

    // Show edit dialog directly from inside the alarm screen (which has a
    // proper BuildContext inside the Navigator). This avoids navigating to
    // the main page first (Issue A) and prevents the InheritedWidget
    // _dependents assertion (Issue B).
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final task = await taskProvider.getTaskById(taskId);
    if (task == null || !mounted) return;

    await showEditTaskDialog(context, task, taskProvider);

    // After the dialog is dismissed, pop the alarm screen.
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _onDismiss() async {
    await _alarmService.dismissCurrentAlarm();
    if (mounted) {
      Navigator.of(context).pop('dismiss');
    }
  }
}
