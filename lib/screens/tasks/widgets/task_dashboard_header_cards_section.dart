import 'package:flutter/material.dart';
import 'package:habit_up/motion/motion.dart';
import 'package:habit_up/providers/goal_provider.dart';
import 'package:habit_up/providers/task_provider.dart';
import 'package:habit_up/routes/app_routes.dart';
import 'package:habit_up/screens/profile/profile_hub_screen.dart';
import 'package:habit_up/screens/tasks/widgets/today_tasks_section.dart';
import 'package:habit_up/screens/tasks/widgets/dashboard_visual_tokens.dart';
import 'package:habit_up/services/user_storage_service.dart';
import 'package:habit_up/services/xp_streak_service.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/theme/app_spacing.dart';
import 'package:habit_up/widgets/app_gaps.dart';
import 'package:habit_up/widgets/user_avatar.dart';
import 'package:provider/provider.dart';

class TaskDashboardHeaderCardsSection extends StatelessWidget {
  const TaskDashboardHeaderCardsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: DashboardVisualTokens.headerGlow,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          _GreetingHeader(textTheme: textTheme),
          AppGaps.v12,
          const _PremiumDashboardRow(),
          AppGaps.v10,
          const _CompactXpRow(),
          AppGaps.v12,
          const TodayTasksSection(),
          AppGaps.v16,
        ],
      ),
    );
  }
}

class _GreetingMeta {
  const _GreetingMeta({required this.salutation, required this.emoji});

  final String salutation;
  final String emoji;

  static _GreetingMeta fromHour(int hour) {
    if (hour < 12) {
      return const _GreetingMeta(salutation: 'Good Morning', emoji: '👋');
    }
    if (hour < 18) {
      return const _GreetingMeta(salutation: 'Good Afternoon', emoji: '👋');
    }
    return const _GreetingMeta(salutation: 'Good Evening', emoji: '👋');
  }
}

class _GreetingHeader extends StatefulWidget {
  const _GreetingHeader({required this.textTheme});

  final TextTheme textTheme;

  @override
  State<_GreetingHeader> createState() => _GreetingHeaderState();
}

class _GreetingHeaderState extends State<_GreetingHeader> {
  String _userName = 'User';
  Map<String, dynamic>? _preferences;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await const UserStorageService().getCurrentUser();
    if (!mounted) return;
    setState(() {
      final name = user?.username ?? 'User';
      _userName = name;
      _preferences = user?.preferences;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = _GreetingMeta.fromHour(now.hour);

    return Row(
      children: [
        Expanded(
          child: ShimmerLoading(
            isLoading: !_loaded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInUp(
                  delay: const Duration(milliseconds: 80),
                  offset: 4,
                  child: Text(
                    greeting.salutation,
                    style: widget.textTheme.bodyMedium?.copyWith(
                      color: DashboardVisualTokens.mutedText.withValues(
                        alpha: 0.86,
                      ),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                AppGaps.v4,
                FadeInUp(
                  delay: const Duration(milliseconds: 150),
                  offset: 6,
                  child: Text(
                    '${_loaded ? _userName : '...'}, ${greeting.emoji}',
                    style: widget.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ShimmerLoading(
          isLoading: !_loaded,
          child: UserAvatar(
            preferences: _preferences,
            fallbackLetter: _userName.isNotEmpty ? _userName[0] : 'U',
            size: 40,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ProfileHubScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PREMIUM DASHBOARD ROW — wider cards, stronger hierarchy
// ═══════════════════════════════════════════════════════════════════════════════

class _PremiumDashboardRow extends StatelessWidget {
  const _PremiumDashboardRow();

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(flex: 1, child: _CombinedPerformanceCard()),
          const SizedBox(width: 6),
          const Expanded(flex: 2, child: _WidePinnedGoalCard()),
        ],
      ),
    );
  }
}

/// Premium inner surface for dashboard cards with stronger visual hierarchy.
class _PremiumInnerSurface extends StatelessWidget {
  const _PremiumInnerSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            colorScheme.surface.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: child,
    );
  }
}

/// Animated fire emoji widget with flickering effect.
class _AnimatedFire extends StatefulWidget {
  const _AnimatedFire();

  @override
  State<_AnimatedFire> createState() => _AnimatedFireState();
}

class _AnimatedFireState extends State<_AnimatedFire>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _rotationAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _rotationAnim = Tween<double>(
      begin: -0.05,
      end: 0.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: Transform.rotate(angle: _rotationAnim.value, child: child),
        );
      },
      child: const Text('🔥', style: TextStyle(fontSize: 16)),
    );
  }
}

/// Combined performance card with streak and today's tasks.
class _CombinedPerformanceCard extends StatelessWidget {
  const _CombinedPerformanceCard();

  @override
  Widget build(BuildContext context) {
    final xpService = context.watch<XpStreakService>();
    final taskProvider = context.watch<TaskProvider>();
    final snapshot = xpService.snapshot;
    final summary = taskProvider.dashboardSummary;
    final streak = snapshot.currentStreak;
    final longestStreak = snapshot.longestStreak;

    // Calculate progress based on streak vs longest streak (or a target of 30 days)
    final streakProgress = longestStreak > 0
        ? (streak / longestStreak).clamp(0.0, 1.0)
        : (streak / 30).clamp(0.0, 1.0);

    // Calculate progress based on completed vs total tasks
    final taskProgress = summary.todayCount > 0
        ? (summary.todayCompletedCount / summary.todayCount).clamp(0.0, 1.0)
        : 0.0;

    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Streak section - centered
          Text(
            'STREAK',
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _DashboardCircularProgress(
                progress: streakProgress,
                accent: colorScheme.primary,
                size: 32,
                child: const _AnimatedFire(),
              ),
              const SizedBox(width: 4),
              Text(
                '$streak days',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.3), thickness: 1, height: 1),
          const SizedBox(height: 8),
          // Today's tasks section
          Text(
            'TODAY\'S TASKS',
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w800,
              fontSize: 9,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _DashboardCircularProgress(
                progress: taskProgress,
                accent: colorScheme.primary,
                size: 32,
                child: Text(
                  '${summary.todayCompletedCount}/${summary.todayCount}',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${summary.todayCompletedCount}/${summary.todayCount}',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Wide pinned goal card with stronger visual hierarchy.
class _WidePinnedGoalCard extends StatelessWidget {
  const _WidePinnedGoalCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final goalProvider = context.watch<GoalProvider>();
    final pinned = goalProvider.pinnedGoalDetails;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(AppRoutes.goals);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: DashboardVisualTokens.panelDecoration(
          borderColor: const Color(0x66FFB066),
          glowColor: const Color(0xFFFFB15A),
          colorScheme: colorScheme,
        ),
        child: _PremiumInnerSurface(
          child: pinned != null
              ? _WidePinnedGoalContent(pinned: pinned)
              : _WideNoPinnedGoalContent(),
        ),
      ),
    );
  }
}

class _WidePinnedGoalContent extends StatelessWidget {
  const _WidePinnedGoalContent({required this.pinned});

  final PinnedGoalDetails pinned;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        _DashboardCircularProgress(
          progress: pinned.progress,
          accent: const Color(0xFFFFB15A),
          size: 48,
          child: Text(
            '${(pinned.progress * 100).round()}%',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(
                    'GOAL',
                    style: TextStyle(
                      color: Color(0xFFFFB15A),
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      // Navigate to goal edit
                    },
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: Color(0xFFFFB15A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                pinned.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                pinned.motivationalSubtitle ?? 'Stay focused',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WideNoPinnedGoalContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        _DashboardCircularProgress(
          progress: 0.0,
          accent: const Color(0xFFFFB15A),
          size: 48,
          child: Text(
            '0%',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'GOAL',
                style: TextStyle(
                  color: Color(0xFFFFB15A),
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'No Pinned Goal',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'Pin from Goals',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Circular progress indicator for dashboard cards.
class _DashboardCircularProgress extends StatelessWidget {
  const _DashboardCircularProgress({
    required this.progress,
    required this.accent,
    required this.child,
    this.size = 56,
  });

  final double progress;
  final Color accent;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalized = progress.clamp(0.0, 1.0);
    final stroke = size * 0.1;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[
            accent.withValues(alpha: 0.1),
            const Color(0x00000000),
          ],
          stops: const <double>[0.3, 1.0],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: stroke,
              valueColor: AlwaysStoppedAnimation<Color>(
                colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: normalized,
              strokeWidth: stroke,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
              backgroundColor: Colors.transparent,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Compact XP row with cleaner hierarchy.
class _CompactXpRow extends StatelessWidget {
  const _CompactXpRow();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final xpService = context.watch<XpStreakService>();
    final snapshot = xpService.snapshot;

    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        color: colorScheme.surface,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              color: colorScheme.primary.withValues(alpha: 0.15),
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              'LV ${snapshot.level}',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 5,
                value: snapshot.levelProgress,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.neonBlue,
                ),
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Total XP: ${snapshot.totalXp}',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
