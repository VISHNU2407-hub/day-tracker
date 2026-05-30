import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habit_up/providers/task_provider.dart';
import 'package:habit_up/providers/theme_mode_provider.dart';
import 'package:habit_up/providers/user_provider.dart';
import 'package:habit_up/screens/profile/widgets/achievement_badge.dart';
import 'package:habit_up/screens/profile/widgets/avatar_options.dart';
import 'package:habit_up/screens/profile/widgets/profile_hero.dart';
import 'package:habit_up/screens/profile/widgets/profile_stat_card.dart';
import 'package:habit_up/screens/profile/widgets/settings_tile.dart';
import 'package:habit_up/services/alarm_sound_service.dart';
import 'package:habit_up/services/bedtime_alarm_scheduler.dart';
import 'package:habit_up/screens/profile/widgets/alarm_permissions_dialog.dart';
import 'package:habit_up/services/productivity_quality_service.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/theme/app_spacing.dart';
import 'package:habit_up/theme/app_text_styles.dart';
import 'package:provider/provider.dart' as pkg;
import 'package:file_picker/file_picker.dart';
import 'package:habit_up/services/notification_permission_service.dart';

// ─── Achievement Badge Presets ─────────────────────────────────────────────

const List<_BadgePreset> _badgePresets = [
  _BadgePreset(
    icon: Icons.local_fire_department,
    label: '7-Day',
    color: Color(0xFFFF6B35),
  ),
  _BadgePreset(icon: Icons.whatshot, label: '30-Day', color: Color(0xFFE17055)),
  _BadgePreset(
    icon: Icons.auto_awesome,
    label: '100 XP',
    color: Color(0xFFFDCB6E),
  ),
  _BadgePreset(icon: Icons.star, label: '500 XP', color: Color(0xFF6C5CE7)),
  _BadgePreset(
    icon: Icons.military_tech,
    label: 'Veteran',
    color: Color(0xFF00B894),
  ),
  _BadgePreset(icon: Icons.diamond, label: 'Elite', color: Color(0xFF0984E3)),
];

class _BadgePreset {
  const _BadgePreset({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Profile Screen
// ═══════════════════════════════════════════════════════════════════════════════

class ProfileHubScreen extends ConsumerWidget {
  const ProfileHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final user = userAsync.valueOrNull;
    final taskProvider = pkg.Provider.of<TaskProvider>(context);
    final summary = taskProvider.dashboardSummary;

    return Scaffold(
      body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Header ────────────────────────────────────────
                _Header(),
                const SizedBox(height: AppSpacing.sm),

                // ── 2. Profile Hero Card ─────────────────────────────
                ProfileHero(),
                const SizedBox(height: AppSpacing.xs),

                // ── 3. Compact Stats Row ────────────────────────────
                _CompactStatsRow(
                  streak: user?.currentStreak ?? 0,
                  level: user?.level ?? 1,
                  xp: user?.xp ?? 0,
                  taskCount: summary.todayCompletedCount,
                  totalToday: summary.todayCount,
                ),
                const SizedBox(height: AppSpacing.xs),

                // ── 4. Progress Section ─────────────────────────────
                _ProgressSection(taskProvider: taskProvider),
                const SizedBox(height: AppSpacing.xs),

                // ── 5. Rewards / Achievements Preview ───────────────
                _AchievementsPreview(),
                const SizedBox(height: AppSpacing.xs),

                // ── 6. Settings Section ─────────────────────────────
                _SettingsSection(),
              ],
            ),
          ),
        ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 1. Header
// ═══════════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Profile',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: 0.3,
          ),
        ),
        const Spacer(),
        // Small settings gear (opens settings / edit profile)
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _showEditProfileDialog(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
                color: const Color(0xFF11172B),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.edit_rounded,
                size: 18,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 3. Compact Stats Row
// ═══════════════════════════════════════════════════════════════════════════════

class _CompactStatsRow extends StatelessWidget {
  const _CompactStatsRow({
    required this.streak,
    required this.level,
    required this.xp,
    required this.taskCount,
    required this.totalToday,
  });

  final int streak;
  final int level;
  final int xp;
  final int taskCount;
  final int totalToday;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ProfileStatCard(
            icon: Icons.local_fire_department,
            value: '$streak',
            label: 'Streak',
            iconColor: const Color(0xFFFF6B35),
          ),
          const SizedBox(width: AppSpacing.sm),
          ProfileStatCard(
            icon: Icons.trending_up,
            value: '$level',
            label: 'Level',
            iconColor: const Color(0xFF6C5CE7),
          ),
          const SizedBox(width: AppSpacing.sm),
          ProfileStatCard(
            icon: Icons.auto_awesome,
            value: '$xp',
            label: 'XP',
            iconColor: const Color(0xFFFDCB6E),
          ),
          const SizedBox(width: AppSpacing.sm),
          ProfileStatCard(
            icon: Icons.check_circle_outline,
            value: totalToday > 0 ? '$taskCount/$totalToday' : '$taskCount',
            label: 'Done',
            iconColor: const Color(0xFF00B894),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 4. Progress Section
// ═══════════════════════════════════════════════════════════════════════════════

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({required this.taskProvider});

  final TaskProvider taskProvider;

  @override
  Widget build(BuildContext context) {
    final summary = taskProvider.dashboardSummary;
    final completionRate = summary.todayCount > 0
        ? (summary.todayCompletedCount / summary.todayCount * 100)
              .toStringAsFixed(0)
        : '0';
    final productivityScore = _calculateProductivityScore(taskProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'Progress'),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: _ProgressMiniCard(
                  icon: Icons.speed_rounded,
                  label: 'Productivity',
                  value: '${productivityScore.toStringAsFixed(0)}%',
                  color: const Color(0xFF4D7CFF),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: _ProgressMiniCard(
                  icon: Icons.calendar_view_week_rounded,
                  label: 'Today Tasks',
                  value: '$completionRate%',
                  color: const Color(0xFF00B894),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: _ProgressMiniCard(
                  icon: Icons.flag_rounded,
                  label: 'Goals',
                  value: '${summary.todayCount}',
                  color: const Color(0xFF6C5CE7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _calculateProductivityScore(TaskProvider taskProvider) {
    try {
      const qualityService = ProductivityQualityService();
      return qualityService.calculateDailyProductivityScore(
            DateTime.now(),
            taskProvider,
          ) *
          100;
    } catch (_) {
      return 0.0;
    }
  }
}

class _ProgressMiniCard extends StatelessWidget {
  const _ProgressMiniCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF11172B), Color(0xFF0D1320)],
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.10),
              border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 5. Rewards / Achievements Preview
// ═══════════════════════════════════════════════════════════════════════════════

class _AchievementsPreview extends StatelessWidget {
  const _AchievementsPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Rewards',
          trailing: Text(
            'View All',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.neonCyan.withValues(alpha: 0.75),
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFF11172B), Color(0xFF0D1320)],
            ),
            border: Border.all(color: AppColors.border),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_badgePresets.length, (index) {
                final badge = _badgePresets[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < _badgePresets.length - 1 ? 8 : 0,
                  ),
                  child: AchievementBadge(
                    icon: badge.icon,
                    label: badge.label,
                    isUnlocked:
                        false, // TODO: Replace with real achievement logic
                    color: badge.color,
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 6. Settings Section
// ═══════════════════════════════════════════════════════════════════════════════

class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'Settings'),
        const SizedBox(height: 8),
        SettingsTile(
          icon: Icons.bedtime_rounded,
          title: 'Bedtime & Schedule',
          subtitle: 'Manage your wind-down routine',
          onTap: () => _showEditProfileDialog(context),
        ),
        const SizedBox(height: 6),
        SettingsTile(
          icon: Icons.notifications_active_rounded,
          title: 'Alarm Permissions',
          subtitle: 'Full-screen alerts, exact scheduling & notifications',
          onTap: () => _showAlarmPermissionsDialog(context),
        ),
        const SizedBox(height: 6),
        SettingsTile(
          icon: Icons.palette_outlined,
          title: 'Appearance',
          subtitle: 'Theme & display options',
          onTap: () => _showAppearanceSettings(context),
        ),
        const SizedBox(height: 6),
        _AlarmSoundSettingsTile(),
        const SizedBox(height: 6),
        _AboutAppTile(),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Custom Alarm Sound Settings Tile
// ═══════════════════════════════════════════════════════════════════════════════

class _AlarmSoundSettingsTile extends StatefulWidget {
  @override
  State<_AlarmSoundSettingsTile> createState() =>
      _AlarmSoundSettingsTileState();
}

class _AlarmSoundSettingsTileState extends State<_AlarmSoundSettingsTile> {
  String? _currentPath;
  String? _fileName;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentPath();
  }

  Future<void> _loadCurrentPath() async {
    final path = await AlarmSoundService.instance.getCustomSoundPath();
    if (mounted) {
      setState(() {
        _currentPath = path;
        _fileName = path?.split('\\').last.split('/').last;
        _loading = false;
      });
    }
  }

  Future<void> _pickAudioFile() async {
    // ── Check READ_MEDIA_AUDIO permission (Android 13+) ──────────
    final permService = NotificationPermissionService();
    final hasAudioPerm = await permService.requestAudioPermission();

    if (!hasAudioPerm) {
      if (mounted) {
        _showAudioPermissionDeniedDialog();
      }
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['mp3', 'wav', 'ogg', 'm4a', 'aac', 'flac'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final path = file.path;
        if (path != null && path.isNotEmpty) {
          await AlarmSoundService.instance.setCustomSoundPath(path);
          if (mounted) {
            setState(() {
              _currentPath = path;
              _fileName = file.name;
            });
            _showSnackBar('Custom alarm sound set: ${file.name}');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to pick audio file: $e');
      }
    }
  }

  void _showAudioPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF11172B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          title: const Row(
            children: [
              Icon(Icons.audiotrack_rounded,
                  size: 22, color: AppColors.neonCyan),
              SizedBox(width: 10),
              Text(
                'Audio Permission Needed',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: const Text(
            'To select a custom alarm sound, Habit Up needs permission to access your audio files.',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Not Now',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                NotificationPermissionService().openAudioPermissionSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonCyan,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Open Settings',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearCustomSound() async {
    await AlarmSoundService.instance.clearCustomSoundPath();
    if (mounted) {
      setState(() {
        _currentPath = null;
        _fileName = null;
      });
      _showSnackBar('Custom alarm sound cleared — using default');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(_buildSnackBar(message));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox.shrink();
    }

    return SettingsTile(
      icon: Icons.audiotrack_rounded,
      title: 'Custom Alarm Sound',
      subtitle:
          _fileName ?? 'Pick an audio file (.mp3, .wav, .ogg)',
      trailing: _buildTrailing(),
      onTap: _currentPath != null ? _showSoundOptions : _pickAudioFile,
    );
  }

  Widget? _buildTrailing() {
    if (_currentPath == null) {
      return Icon(
        Icons.add_circle_outline_rounded,
        size: 20,
        color: AppColors.neonCyan.withValues(alpha: 0.7),
      );
    }
    return Icon(
      Icons.check_circle_rounded,
      size: 20,
      color: AppColors.neonCyan,
    );
  }

  void _showSoundOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Theme.of(context).brightness == Brightness.light
        ? Colors.black.withValues(alpha: 0.15)
        : Colors.black54,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0xFF11172B), Color(0xFF080A12)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Alarm Sound',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _fileName ?? 'Custom sound',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 13,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _pickAudioFile();
                      },
                      icon: const Icon(Icons.music_note_rounded, size: 20),
                      label: const Text('Change Sound'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonCyan,
                        foregroundColor: AppColors.background,
                        elevation: 4,
                        shadowColor:
                            AppColors.neonCyan.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _clearCustomSound();
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      label: const Text('Reset to Default'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: BorderSide(
                          color: AppColors.border,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Thin snackbar that wraps text in the dark theme's style.
SnackBar _buildSnackBar(String message) {
  return SnackBar(
    content: Text(message),
    backgroundColor: const Color(0xFF1E2740),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// About App Tile
// ═══════════════════════════════════════════════════════════════════════════════

class _AboutAppTile extends StatelessWidget {
  const _AboutAppTile();

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.neonCyan.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppColors.neonCyan.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppColors.neonCyan,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'DAY TRACKER',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.neonCyan,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'A PRODUCT BY VerSo',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Version 1.0.0',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shared Section Title
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary.withValues(alpha: 0.9),
            letterSpacing: 0.3,
          ),
        ),
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Edit Profile Dialog
// ═══════════════════════════════════════════════════════════════════════════════

/// Renders an avatar image asset (PNG via Image.asset, SVG via SvgPicture)
/// with a gradient fallback on error.
Widget _buildAvatarImage(AvatarOption option) {
  if (option.assetPath.endsWith('.svg')) {
    return SvgPicture.asset(
      option.assetPath,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
    );
  }
  return Image.asset(
    option.assetPath,
    width: double.infinity,
    height: double.infinity,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) =>
        _buildGradientFallback(option),
  );
}

/// Gradient fallback shown while loading or on asset error.
Widget _buildGradientFallback(AvatarOption option) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[option.fallbackColorA, option.fallbackColorB],
      ),
    ),
  );
}

/// Shows a bottom sheet for editing username, avatar, and bedtime.
Future<void> _showEditProfileDialog(BuildContext context) async {
  // Grab current user data
  final container = ProviderScope.containerOf(context);
  final userAsync = container.read(userProvider);
  final user = userAsync.valueOrNull;
  if (user == null) return;

  final nameController = TextEditingController(text: user.username);
  String selectedAvatarId =
      (user.preferences['avatar_id'] as String?) ?? avatarOptions.first.id;
  TimeOfDay bedtime = user.bedtime != null
      ? TimeOfDay(hour: user.bedtime!.hour, minute: user.bedtime!.minute)
      : const TimeOfDay(hour: 22, minute: 30);
  bool bedtimeReminderEnabled =
      user.preferences['bedtime_reminder_enabled'] ?? true;

  await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Theme.of(context).brightness == Brightness.light
        ? Colors.black.withValues(alpha: 0.15)
        : Colors.black54,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final theme = Theme.of(ctx);
          final colorScheme = theme.colorScheme;
          return Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              color: colorScheme.surface,
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.lg,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Username
                      Text(
                        'Username',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameController,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outline,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outline,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.neonCyan,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Avatar selector
                      Text(
                        'Avatar',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 80,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: avatarOptions.length,
                          separatorBuilder: (_, a) => const SizedBox(width: 10),
                          itemBuilder: (ctx, index) {
                            final a = avatarOptions[index];
                            final isSelected = a.id == selectedAvatarId;
                            return GestureDetector(
                              onTap: () =>
                                  setSheetState(() => selectedAvatarId = a.id),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 64,
                                height: 78,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: isSelected
                                      ? AppColors.neonCyan.withValues(
                                          alpha: 0.08,
                                        )
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.neonCyan.withValues(
                                            alpha: 0.4,
                                          )
                                        : colorScheme.outline.withValues(alpha: 0.3),
                                    width: isSelected ? 1.5 : 0.8,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppColors.neonCyan
                                                .withValues(alpha: 0.15),
                                            blurRadius: 8,
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Avatar image
                                    SizedBox(
                                      width: 44,
                                      height: 44,
                                      child: ClipOval(
                                        child: _buildAvatarImage(a),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      a.label,
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 8,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: colorScheme.onSurface.withValues(
                                          alpha: isSelected ? 1 : 0.7,
                                        ),
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Bedtime
                      Text(
                        'Bedtime',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: colorScheme.surfaceContainerHighest,
                          border: Border.all(color: colorScheme.outline),
                        ),
                        child: InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: ctx,
                              initialTime: bedtime,
                              builder: (context, child) => Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: Theme.of(context).colorScheme
                                      .copyWith(primary: AppColors.neonCyan),
                                ),
                                child: child!,
                              ),
                            );
                            if (picked != null) {
                              setSheetState(() => bedtime = picked);
                            }
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.nightlight_round,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${bedtime.hourOfPeriod == 0 ? 12 : bedtime.hourOfPeriod}:${bedtime.minute.toString().padLeft(2, '0')} ${bedtime.period == DayPeriod.am ? 'AM' : 'PM'}',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.edit_calendar_rounded,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Bedtime Reminder Toggle
                      Text(
                        'Bedtime Reminder',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: colorScheme.surfaceContainerHighest,
                          border: Border.all(color: colorScheme.outline),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.notifications_active_rounded,
                              size: 18,
                              color: AppColors.neonCyan,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Daily planning reminder',
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.9,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Gentle nudge to plan tomorrow',
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w400,
                                      color: colorScheme.onSurfaceVariant.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 28,
                              child: Switch.adaptive(
                                value: bedtimeReminderEnabled,
                                onChanged: (v) => setSheetState(
                                  () => bedtimeReminderEnabled = v,
                                ),
                                activeTrackColor: AppColors.neonCyan.withValues(
                                  alpha: 0.3,
                                ),
                                activeThumbColor: AppColors.neonCyan,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg + 4),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            final name = nameController.text.trim();
                            if (name.isEmpty) return;

                            final now = DateTime.now();
                            final updatedUser = user.copyWith(
                              username: name,
                              bedtime: DateTime(
                                now.year,
                                now.month,
                                now.day,
                                bedtime.hour,
                                bedtime.minute,
                              ),
                              preferences: {
                                ...user.preferences,
                                'avatar_id': selectedAvatarId,
                                'avatar_label': avatarOptionById(
                                  selectedAvatarId,
                                ).label,
                                'bedtime_hour': bedtime.hour,
                                'bedtime_minute': bedtime.minute,
                                'bedtime_reminder_enabled':
                                    bedtimeReminderEnabled,
                              },
                            );

                            // Use the provider directly via the context
                            final container = ProviderScope.containerOf(
                              context,
                            );
                            await container
                                .read(userProvider.notifier)
                                .updateUserProfile(updatedUser);

                            // Schedule or cancel the full-screen bedtime alarm
                            // based on the bedtime reminder toggle.
                            if (bedtimeReminderEnabled) {
                              unawaited(
                                BedtimeAlarmScheduler().schedule(
                                  bedtimeOverride: DateTime(
                                    now.year,
                                    now.month,
                                    now.day,
                                    bedtime.hour,
                                    bedtime.minute,
                                  ),
                                ),
                              );
                            } else {
                              unawaited(BedtimeAlarmScheduler().cancel());
                            }

                            if (ctx.mounted) Navigator.of(ctx).pop(true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.neonCyan,
                            foregroundColor: colorScheme.onPrimary,
                            elevation: 4,
                            shadowColor: AppColors.neonCyan.withValues(
                              alpha: 0.4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Save Changes',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              letterSpacing: 0.4,
                              color: colorScheme.onPrimary,
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
        },
      );
    },
  );

  nameController.dispose();
}

/// Shows a dialog explaining the three critical alarm permissions and
/// allowing the user to grant or enable each one.
///
/// Uses [AlarmPermissionsDialog] — a lifecycle-aware widget that
/// automatically refreshes permission statuses when the app resumes from
/// system settings, fixing the race condition where stale state was shown.
Future<void> _showAlarmPermissionsDialog(BuildContext context) async {
  await showAlarmPermissionsDialog(context);
}

// ═══════════════════════════════════════════════════════════════════════════════
// Appearance Settings Sheet
// ═══════════════════════════════════════════════════════════════════════════════

/// Shows a bottom sheet with theme switching options.
void _showAppearanceSettings(BuildContext context) {
  final container = ProviderScope.containerOf(context);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: false,
    backgroundColor: Colors.transparent,
    barrierColor: Theme.of(context).brightness == Brightness.light
        ? Colors.black.withValues(alpha: 0.15)
        : Colors.black54,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final theme = Theme.of(ctx);
          final colorScheme = theme.colorScheme;
          var selectedMode =
              container.read(themeModeProvider);

          return Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              color: colorScheme.surface,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Icon(
                          Icons.palette_outlined,
                          size: 22,
                          color: AppColors.neonCyan,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Appearance',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose your preferred theme',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Theme mode options
                    _ThemeOptionTile(
                      icon: Icons.dark_mode_rounded,
                      title: 'Dark',
                      subtitle: 'Easy on the eyes, day & night',
                      isSelected: selectedMode == ThemeMode.dark,
                      iconColor: const Color(0xFF6C5CE7),
                      onTap: () {
                        setSheetState(() {
                          selectedMode = ThemeMode.dark;
                        });
                        container
                            .read(themeModeProvider.notifier)
                            .setThemeMode(ThemeMode.dark);
                        _persistThemePreference(context, ThemeMode.dark);
                      },
                    ),
                    const SizedBox(height: 8),
                    _ThemeOptionTile(
                      icon: Icons.light_mode_rounded,
                      title: 'Light',
                      subtitle: 'Bright and clean interface',
                      isSelected: selectedMode == ThemeMode.light,
                      iconColor: const Color(0xFFFFC857),
                      onTap: () {
                        setSheetState(() {
                          selectedMode = ThemeMode.light;
                        });
                        container
                            .read(themeModeProvider.notifier)
                            .setThemeMode(ThemeMode.light);
                        _persistThemePreference(context, ThemeMode.light);
                      },
                    ),
                    const SizedBox(height: 8),
                    _ThemeOptionTile(
                      icon: Icons.settings_brightness_rounded,
                      title: 'System',
                      subtitle: 'Follow your device theme',
                      isSelected: selectedMode == ThemeMode.system,
                      iconColor: AppColors.neonCyan,
                      onTap: () {
                        setSheetState(() {
                          selectedMode = ThemeMode.system;
                        });
                        container
                            .read(themeModeProvider.notifier)
                            .setThemeMode(ThemeMode.system);
                        _persistThemePreference(context, ThemeMode.system);
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Close button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.onSurfaceVariant,
                          side: BorderSide(color: colorScheme.outline),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Done',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

/// Persists the selected [themeMode] to the user's preferences.
Future<void> _persistThemePreference(
  BuildContext context,
  ThemeMode themeMode,
) async {
  try {
    final container = ProviderScope.containerOf(context);
    final userAsync = container.read(userProvider);
    final user = userAsync.valueOrNull;
    if (user == null) return;

    final updatedPrefs = Map<String, dynamic>.from(user.preferences)
      ..[themeModePrefKey] = themeModeToString(themeMode);

    await container
        .read(userProvider.notifier)
        .updatePreferences(updatedPrefs);
  } catch (_) {
    // Silently fail — the in-memory setting is already applied.
  }
}

/// A selectable option tile used in the Appearance settings sheet.
class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? iconColor.withValues(alpha: 0.5)
                : colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1.0,
          ),
          color: isSelected
              ? iconColor.withValues(alpha: 0.06)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.1),
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.2),
                ),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? iconColor
                          : colorScheme.onSurface,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: 0.15),
                  border: Border.all(color: iconColor, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: iconColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}


