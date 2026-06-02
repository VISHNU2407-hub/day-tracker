import 'package:flutter/material.dart';
import 'package:habit_up/services/notification_permission_service.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/theme/app_spacing.dart';
import 'package:habit_up/theme/app_text_styles.dart';

// ---------------------------------------------------------------------------
// Permission status enum
// ---------------------------------------------------------------------------

enum _PermissionStatus {
  granted,
  missing,
  recommended;

  String get label {
    return switch (this) {
      _PermissionStatus.granted => 'Granted',
      _PermissionStatus.missing => 'Missing',
      _PermissionStatus.recommended => 'Recommended',
    };
  }

  Color get color {
    return switch (this) {
      _PermissionStatus.granted => const Color(0xFF00B894),
      _PermissionStatus.missing => const Color(0xFFFF5D73),
      _PermissionStatus.recommended => const Color(0xFFFFB84D),
    };
  }

  IconData get icon {
    return switch (this) {
      _PermissionStatus.granted => Icons.check_circle_rounded,
      _PermissionStatus.missing => Icons.cancel_rounded,
      _PermissionStatus.recommended => Icons.info_rounded,
    };
  }
}

// ---------------------------------------------------------------------------
// Permission item model
// ---------------------------------------------------------------------------

class _PermissionItem {
  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onOpenSettings,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final _PermissionStatus status;
  final VoidCallback onOpenSettings;
}

// ---------------------------------------------------------------------------
// Main Screen
// ---------------------------------------------------------------------------

class PermissionsDeviceSetupScreen extends StatefulWidget {
  const PermissionsDeviceSetupScreen({super.key});

  @override
  State<PermissionsDeviceSetupScreen> createState() =>
      _PermissionsDeviceSetupScreenState();
}

class _PermissionsDeviceSetupScreenState
    extends State<PermissionsDeviceSetupScreen>
    with WidgetsBindingObserver {
  final NotificationPermissionService _permService =
      NotificationPermissionService();

  bool _isLoading = true;

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
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = <_PermissionItem>[
      _PermissionItem(
        icon: Icons.notifications_rounded,
        title: 'Notifications',
        subtitle: 'Show alarm alerts & reminders',
        status: _permService.postNotificationsGranted
            ? _PermissionStatus.granted
            : _PermissionStatus.missing,
        onOpenSettings: () => _permService.requestPostNotifications().then((_) {
          // Refresh immediately since this uses a system dialog
          _refreshPermissions();
        }),
      ),
      _PermissionItem(
        icon: Icons.alarm_rounded,
        title: 'Exact Alarm',
        subtitle: 'Schedule alarms at precise times',
        status: _permService.exactAlarmGranted
            ? _PermissionStatus.granted
            : _PermissionStatus.missing,
        onOpenSettings: () => _permService.requestExactAlarm(),
      ),
      _PermissionItem(
        icon: Icons.battery_charging_full_rounded,
        title: 'Battery Optimization',
        subtitle: 'Prevent system from killing alarm service',
        status: _permService.batteryOptimizationDisabled
            ? _PermissionStatus.granted
            : _PermissionStatus.missing,
        onOpenSettings: () => _permService.requestBatteryOptimization(),
      ),
      _PermissionItem(
        icon: Icons.fullscreen_rounded,
        title: 'Full-Screen Intent',
        subtitle: 'Show alarms over the lock screen',
        status: _permService.fullScreenIntentGranted
            ? _PermissionStatus.granted
            : _PermissionStatus.missing,
        onOpenSettings: () => _permService.requestFullScreenIntent(),
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _PermissionsBackground()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              children: [
                _Header(),
                const SizedBox(height: AppSpacing.sm),
                _OverviewCard(items: items),
                const SizedBox(height: AppSpacing.md),
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppColors.neonCyan,
                      ),
                    ),
                  )
                else ...[
                  ...items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _PermissionStatusCard(item: item),
                      )),
                  const SizedBox(height: AppSpacing.sm),
                  const _AutoStartSection(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          style: IconButton.styleFrom(
            minimumSize: const Size(40, 40),
            backgroundColor: const Color(0xE01A2340),
            side: const BorderSide(color: AppColors.border),
            foregroundColor: AppColors.textPrimary,
          ),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Permissions & Device Setup',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Verify all permissions required for reliable alarms and reminders',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.86),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Overview Card (summary counts)
// ---------------------------------------------------------------------------

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.items});

  final List<_PermissionItem> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final granted =
        items.where((i) => i.status == _PermissionStatus.granted).length;
    final total = items.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF11172B), Color(0xFF0D1320)],
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: <Color>[
                  granted == total
                      ? const Color(0xFF00B894).withValues(alpha: 0.15)
                      : const Color(0xFFFFB84D).withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
              border: Border.all(
                color: granted == total
                    ? const Color(0xFF00B894).withValues(alpha: 0.3)
                    : const Color(0xFFFFB84D).withValues(alpha: 0.3),
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              granted == total
                  ? Icons.shield_rounded
                  : Icons.shield_outlined,
              size: 22,
              color: granted == total
                  ? const Color(0xFF00B894)
                  : const Color(0xFFFFB84D),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  granted == total
                      ? 'All Permissions Granted'
                      : '$granted of $total Permissions Granted',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  granted == total
                      ? 'Your device is ready for reliable alarms'
                      : 'Grant missing permissions for best alarm reliability',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual Permission Status Card
// ---------------------------------------------------------------------------

class _PermissionStatusCard extends StatelessWidget {
  const _PermissionStatusCard({required this.item});

  final _PermissionItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isGranted = item.status == _PermissionStatus.granted;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isGranted
              ? const Color(0xFF00B894).withValues(alpha: 0.15)
              : const Color(0xFFFF5D73).withValues(alpha: 0.15),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            isGranted
                ? const Color(0xFF00B894).withValues(alpha: 0.04)
                : const Color(0xFFFF5D73).withValues(alpha: 0.04),
            const Color(0xFF0D1320),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: icon + title + status badge
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      isGranted
                          ? const Color(0xFF00B894).withValues(alpha: 0.12)
                          : const Color(0xFFFF5D73).withValues(alpha: 0.12),
                      const Color(0xFF0D1320),
                    ],
                  ),
                  border: Border.all(
                    color: isGranted
                        ? const Color(0xFF00B894).withValues(alpha: 0.2)
                        : const Color(0xFFFF5D73).withValues(alpha: 0.2),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  item.icon,
                  size: 18,
                  color: isGranted
                      ? const Color(0xFF00B894)
                      : const Color(0xFFFF5D73),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      item.subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: item.status.color.withValues(alpha: 0.1),
                  border: Border.all(
                    color: item.status.color.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.status.icon,
                      size: 12,
                      color: item.status.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.status.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: item.status.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Open Settings button
          SizedBox(
            width: double.infinity,
            height: 36,
            child: OutlinedButton(
              onPressed: item.onOpenSettings,
              style: OutlinedButton.styleFrom(
                foregroundColor: isGranted
                    ? const Color(0xFF00B894)
                    : AppColors.neonCyan,
                side: BorderSide(
                  color: isGranted
                      ? const Color(0xFF00B894).withValues(alpha: 0.3)
                      : AppColors.neonCyan.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 0),
                backgroundColor: Colors.transparent,
              ),
              child: Text(
                'Open Settings',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Auto Start Guidance Section
// ---------------------------------------------------------------------------

class _AutoStartSection extends StatefulWidget {
  const _AutoStartSection();

  @override
  State<_AutoStartSection> createState() => _AutoStartSectionState();
}

class _AutoStartSectionState extends State<_AutoStartSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFB84D).withValues(alpha: 0.15),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            const Color(0xFFFFB84D).withValues(alpha: 0.04),
            const Color(0xFF0D1320),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          const Color(0xFFFFB84D).withValues(alpha: 0.12),
                          const Color(0xFF0D1320),
                        ],
                      ),
                      border: Border.all(
                        color: const Color(0xFFFFB84D).withValues(alpha: 0.2),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.smartphone_rounded,
                      size: 18,
                      color: Color(0xFFFFB84D),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto Start',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Enable for Xiaomi, HyperOS, Samsung & other OEMs',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status: Recommended badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: const Color(0xFFFFB84D).withValues(alpha: 0.1),
                      border: Border.all(
                        color: const Color(0xFFFFB84D).withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_rounded,
                          size: 12,
                          color: Color(0xFFFFB84D),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Recommended',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFFB84D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),

          // Expandable OEM guidance
          if (_expanded) ...[
            const Divider(
              height: 1,
              color: Color(0x1AFFFFFF),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OemGuideTile(
                    oemName: 'Xiaomi / HyperOS / MIUI',
                    steps: const [
                      'Open Settings → Apps → Manage Apps',
                      'Tap Habit Up → scroll down to "Auto-start"',
                      'Toggle Auto-start ON',
                      'Also enable "Show notifications" in App info',
                    ],
                  ),
                  const SizedBox(height: 8),
                  _OemGuideTile(
                    oemName: 'Samsung (One UI)',
                    steps: const [
                      'Open Settings → Apps → Habit Up',
                      'Tap "Battery" → toggle "Unrestricted"',
                      'Go back → tap "Allow background activity"',
                    ],
                  ),
                  const SizedBox(height: 8),
                  _OemGuideTile(
                    oemName: 'OnePlus / OPPO (ColorOS)',
                    steps: const [
                      'Open Settings → Apps → App List → Habit Up',
                      'Tap "Battery" → select "Unrestricted"',
                      'Enable "Allow background activity"',
                      'Also enable "Auto-launch" if available',
                    ],
                  ),
                  const SizedBox(height: 8),
                  _OemGuideTile(
                    oemName: 'Vivo (Funtouch OS)',
                    steps: const [
                      'Open Settings → Apps → App Management → Habit Up',
                      'Tap "Battery" → select "High background power"',
                      'Enable "Start up" and "Keep running"',
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color(0xFFFFB84D).withValues(alpha: 0.06),
                      border: Border.all(
                        color: const Color(0xFFFFB84D).withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 16,
                          color: Color(0xFFFFB84D),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Auto Start prevents your phone\'s system from '
                            'killing Habit Up\'s background service, ensuring '
                            'alarms fire reliably even after you close the app.',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.75),
                              fontSize: 11,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OemGuideTile extends StatelessWidget {
  const _OemGuideTile({
    required this.oemName,
    required this.steps,
  });

  final String oemName;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFF11172B),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            oemName,
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: const Color(0xFFFFB84D),
            ),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0) const SizedBox(height: 3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFB84D).withValues(alpha: 0.1),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFFB84D).withValues(alpha: 0.8),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    steps[i],
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                      fontSize: 10.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Background
// ---------------------------------------------------------------------------

class _PermissionsBackground extends StatelessWidget {
  const _PermissionsBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF0B1020), AppColors.background],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -30,
            child: _GlowBlob(size: 160, color: Color(0x163E62F2)),
          ),
          Positioned(
            top: 250,
            left: -40,
            child: _GlowBlob(size: 130, color: Color(0x1000E5FF)),
          ),
          Positioned(
            bottom: 110,
            right: -45,
            child: _GlowBlob(size: 120, color: Color(0x0D00F5A0)),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              color,
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
