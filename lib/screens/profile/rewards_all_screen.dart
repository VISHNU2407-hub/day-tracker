import 'package:flutter/material.dart';
import 'package:habit_up/models/achievement_model.dart';
import 'package:habit_up/services/achievement_service.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/theme/app_spacing.dart';
import 'package:habit_up/theme/app_text_styles.dart';

/// Full-screen view of all achievements with progress bars, percentages,
/// and lock/unlock status.
class RewardsAllScreen extends StatefulWidget {
  const RewardsAllScreen({super.key, required this.achievementService});

  final AchievementService achievementService;

  @override
  State<RewardsAllScreen> createState() => _RewardsAllScreenState();
}

class _RewardsAllScreenState extends State<RewardsAllScreen> {
  List<AchievementViewModel> _achievements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    widget.achievementService.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.achievementService.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    _load();
  }

  Future<void> _load() async {
    final results = await widget.achievementService.getAchievements();
    if (!mounted) return;
    setState(() {
      _achievements = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Group by category
    final grouped = <String, List<AchievementViewModel>>{};
    for (final a in _achievements) {
      final cat = _categoryLabel(a.category);
      grouped.putIfAbsent(cat, () => []).add(a);
    }

    final sortedKeys = ['Streak', 'Tasks', 'XP', 'Goals']
        .where((k) => grouped.containsKey(k))
        .toList();

    final unlockedCount = _achievements.where((a) => a.isUnlocked).length;
    final totalCount = _achievements.length;

    return Scaffold(
      backgroundColor: const Color(0xFF060810),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'All Rewards',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Summary header ──────────────────────────────────
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              AppColors.neonCyan,
                              Color(0xFF0984E3),
                            ],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$unlockedCount / $totalCount Unlocked',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: totalCount > 0
                                    ? unlockedCount / totalCount
                                    : 0.0,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.08),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        AppColors.neonCyan),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // ── Achievement list ────────────────────────────────
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    itemCount: sortedKeys.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final key = sortedKeys[index];
                      final items = grouped[key]!;
                      return _CategorySection(
                        categoryLabel: key,
                        items: items,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  String _categoryLabel(AchievementCategory cat) {
    switch (cat) {
      case AchievementCategory.streak:
        return 'Streak';
      case AchievementCategory.task:
        return 'Tasks';
      case AchievementCategory.xp:
        return 'XP';
      case AchievementCategory.goalCompletion:
        return 'Goals';
      case AchievementCategory.monthly:
        return 'Monthly';
      case AchievementCategory.productivity:
        return 'Productivity';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Category Section
// ═══════════════════════════════════════════════════════════════════════════════

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.categoryLabel,
    required this.items,
  });

  final String categoryLabel;
  final List<AchievementViewModel> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final unlockedInCat = items.where((a) => a.isUnlocked).length;
    final totalInCat = items.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Text(
              categoryLabel,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.neonCyan.withValues(alpha: 0.12),
              ),
              child: Text(
                '$unlockedInCat / $totalInCat',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neonCyan,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _AchievementTile(viewModel: item),
            )),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Single Achievement Tile
// ═══════════════════════════════════════════════════════════════════════════════

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.viewModel});

  final AchievementViewModel viewModel;

  IconData _iconForKey(String key) {
    switch (key) {
      case 'spark':
        return Icons.auto_awesome;
      case 'whatshot':
        return Icons.whatshot;
      case 'bolt':
        return Icons.bolt;
      case 'military_tech':
        return Icons.military_tech;
      case 'diamond':
        return Icons.diamond;
      case 'check_circle':
        return Icons.check_circle;
      case 'trending_up':
        return Icons.trending_up;
      case 'star':
        return Icons.star;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'flag':
        return Icons.flag;
      case 'rocket_launch':
        return Icons.rocket_launch;
      case 'checklist':
        return Icons.checklist;
      default:
        return Icons.star;
    }
  }

  Color _colorForCategory(AchievementCategory cat) {
    switch (cat) {
      case AchievementCategory.streak:
        return const Color(0xFFFF6B35);
      case AchievementCategory.task:
        return const Color(0xFF00B894);
      case AchievementCategory.xp:
        return const Color(0xFFFDCB6E);
      case AchievementCategory.goalCompletion:
        return const Color(0xFF6C5CE7);
      case AchievementCategory.monthly:
        return const Color(0xFF0984E3);
      case AchievementCategory.productivity:
        return AppColors.neonCyan;
    }
  }

  String _statusLabel() {
    switch (viewModel.status) {
      case AchievementStatus.locked:
        return 'Locked';
      case AchievementStatus.inProgress:
        return 'In Progress';
      case AchievementStatus.unlocked:
        return 'Unlocked';
    }
  }

  Color _statusColor() {
    switch (viewModel.status) {
      case AchievementStatus.locked:
        return AppColors.textSecondary.withValues(alpha: 0.5);
      case AchievementStatus.inProgress:
        return AppColors.neonCyan;
      case AchievementStatus.unlocked:
        return const Color(0xFF00B894);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accent = _colorForCategory(viewModel.category);
    final isUnlocked = viewModel.isUnlocked;
    final opacity = isUnlocked ? 1.0 : 0.6;

    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF11172B), Color(0xFF0D1320)],
          ),
          border: Border.all(
            color: isUnlocked
                ? accent.withValues(alpha: 0.3)
                : AppColors.border,
          ),
        ),
        child: Column(
          children: [
            // Top row: icon, title, status chip
            Row(
              children: [
                // Icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isUnlocked
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              accent,
                              accent.withValues(alpha: 0.6),
                            ],
                          )
                        : null,
                    color: isUnlocked ? null : const Color(0xFF1E2740),
                    border: Border.all(
                      color: isUnlocked
                          ? accent.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.08),
                      width: isUnlocked ? 1.5 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _iconForKey(viewModel.iconKey),
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),

                // Title + description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        viewModel.title,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isUnlocked
                              ? AppColors.textPrimary
                              : AppColors.textPrimary.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        viewModel.description,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: _statusColor().withValues(alpha: 0.12),
                  ),
                  child: Text(
                    _statusLabel(),
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(),
                    ),
                  ),
                ),
              ],
            ),

            // Bottom row: progress bar + percentage
            if (viewModel.status != AchievementStatus.unlocked) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: viewModel.progress,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    child: Text(
                      viewModel.progressPercent,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
