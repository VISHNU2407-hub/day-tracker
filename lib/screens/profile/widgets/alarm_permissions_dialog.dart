import 'package:flutter/material.dart';
import 'package:habit_up/services/notification_permission_service.dart';
import 'package:habit_up/theme/app_text_styles.dart';

/// A single permission row used in the alarm permissions dialog.
class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isGranted,
    required this.onRequest,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isGranted;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isGranted
            ? const Color(0xFF00B894).withValues(alpha: 0.06)
            : const Color(0xFFFF5D73).withValues(alpha: 0.06),
        border: Border.all(
          color: isGranted
              ? const Color(0xFF00B894).withValues(alpha: 0.15)
              : const Color(0xFFFF5D73).withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isGranted
                  ? const Color(0xFF00B894).withValues(alpha: 0.1)
                  : const Color(0xFFFF5D73).withValues(alpha: 0.1),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 16,
              color: isGranted
                  ? const Color(0xFF00B894)
                  : const Color(0xFFFF5D73),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF2F5FF),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFFB7C0DD).withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          isGranted
              ? const Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: Color(0xFF00B894),
                )
              : SizedBox(
                  height: 28,
                  child: TextButton(
                    onPressed: onRequest,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 0,
                      ),
                      minimumSize: Size.zero,
                      backgroundColor:
                          const Color(0xFF00E5FF).withValues(alpha: 0.1),
                      foregroundColor: const Color(0xFF00E5FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Enable',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

/// Lifecycle-aware alarm permissions dialog.
///
/// Fixes the race condition where opening system settings instantly refreshes
/// stale permission state before the user has toggled anything. Instead, this
/// dialog uses [WidgetsBindingObserver] to automatically refresh all
/// permission statuses when the app returns to the foreground.
class AlarmPermissionsDialog extends StatefulWidget {
  const AlarmPermissionsDialog({super.key});

  @override
  State<AlarmPermissionsDialog> createState() => _AlarmPermissionsDialogState();
}

class _AlarmPermissionsDialogState extends State<AlarmPermissionsDialog>
    with WidgetsBindingObserver {
  final NotificationPermissionService _permService =
      NotificationPermissionService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissions();
    }
  }

  Future<void> _refreshPermissions() async {
    await _permService.refreshAllStatuses();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF121734),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text(
        'Alarm Permissions',
        style: TextStyle(
          color: Color(0xFFF2F5FF),
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Habit Up requires these permissions to deliver reliable, '
            'real system alarms — even when the app is closed or the '
            'device is locked.',
            style: TextStyle(
              color: const Color(0xFFB7C0DD).withValues(alpha: 0.9),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _PermissionRow(
            icon: Icons.notifications_rounded,
            title: 'Notifications',
            subtitle: 'Show alarm alerts & reminders',
            isGranted: _permService.postNotificationsGranted,
            onRequest: () async {
              await _permService.requestPostNotifications();
              if (mounted) setState(() {});
            },
          ),
          const SizedBox(height: 8),
          _PermissionRow(
            icon: Icons.alarm_rounded,
            title: 'Exact Alarms',
            subtitle: 'Schedule alarms at precise times',
            isGranted: _permService.exactAlarmGranted,
            onRequest: () async {
              // Opens system settings — no stale refresh here.
              // The WidgetsBindingObserver will refresh on resume.
              await _permService.requestExactAlarm();
            },
          ),
          const SizedBox(height: 8),
          _PermissionRow(
            icon: Icons.fullscreen_rounded,
            title: 'Full-Screen Overlay',
            subtitle: 'Show alarms over the lock screen',
            isGranted: _permService.fullScreenIntentGranted,
            onRequest: () async {
              // Opens system settings — no stale refresh here.
              // The WidgetsBindingObserver will refresh on resume.
              await _permService.requestFullScreenIntent();
            },
          ),
          const SizedBox(height: 8),
          _PermissionRow(
            icon: Icons.battery_charging_full_rounded,
            title: 'Battery Optimisation',
            subtitle: 'Prevent the system from killing alarm service',
            isGranted: _permService.batteryOptimizationDisabled,
            onRequest: () async {
              // Opens system settings — no stale refresh here.
              // The WidgetsBindingObserver will refresh on resume.
              await _permService.requestBatteryOptimization();
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(
            'Done',
            style: TextStyle(
              color: Color(0xFF00E5FF),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// Shows the lifecycle-aware alarm permissions dialog.
///
/// After the dialog closes, refreshes all permission statuses one final time
/// to ensure the caller's state is up-to-date.
Future<void> showAlarmPermissionsDialog(BuildContext context) async {
  await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const AlarmPermissionsDialog(),
  );
}
