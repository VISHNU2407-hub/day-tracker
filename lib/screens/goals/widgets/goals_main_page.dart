import 'package:flutter/material.dart';
import 'package:habit_up/providers/goal_provider.dart';
import 'package:habit_up/providers/sub_goal_provider.dart';
import 'package:habit_up/providers/task_provider.dart';
import 'package:habit_up/screens/goals/widgets/create_goal_screen.dart';
import 'package:habit_up/screens/goals/widgets/goal_card.dart';
import 'package:habit_up/screens/goals/widgets/goal_details_screen.dart';
import 'package:habit_up/screens/goals/widgets/goals_action_button.dart';
import 'package:habit_up/screens/goals/widgets/goals_section_header.dart';
import 'package:habit_up/screens/profile/profile_hub_screen.dart';
import 'package:habit_up/services/user_storage_service.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/theme/app_spacing.dart';
import 'package:habit_up/widgets/app_gaps.dart';
import 'package:habit_up/widgets/user_avatar.dart';
import 'package:provider/provider.dart';

class GoalsMainPage extends StatefulWidget {
  const GoalsMainPage({super.key});

  @override
  State<GoalsMainPage> createState() => _GoalsMainPageState();
}

class _GoalsMainPageState extends State<GoalsMainPage> {
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
    final goalProvider = context.watch<GoalProvider>();
    final subGoalProvider = context.watch<SubGoalProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final goals = goalProvider.allGoals;
    final textTheme = Theme.of(context);
    final greeting = _GreetingMeta.fromHour(DateTime.now().hour);

    return Stack(
      children: [
        const Positioned.fill(child: _GoalsBackgroundLayer()),
        ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl,
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting.salutation,
                        style: textTheme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary.withValues(alpha: 0.88),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AppGaps.v4,
                      Text(
                        '${_loaded ? _userName : '...'}, ${greeting.emoji}',
                        style: textTheme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                        ),
                      ),
                    ],
                  ),
                ),
                UserAvatar(
                  preferences: _preferences,
                  fallbackLetter: _userName.isNotEmpty ? _userName[0] : 'U',
                  size: 44,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ProfileHubScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            AppGaps.v20,
            Row(
              children: [
                Expanded(
                  child: GoalsSectionHeader(
                    title: 'Your Goals',
                    subtitle: goals.isEmpty
                        ? 'No goals yet'
                        : '${goals.length} goal${goals.length == 1 ? '' : 's'} in progress',
                  ),
                ),
                GoalsActionButton(
                  label: 'New Goal',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CreateGoalScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            AppGaps.v12,
            if (goals.isEmpty)
              _GoalsEmptyState(textTheme: textTheme.textTheme)
            else
              ...goals.map(
                (goal) {
                  final subGoals = subGoalProvider.getSubGoalsByGoalId(goal.id);
                  final taskCount = subGoals.fold<int>(
                    0,
                    (sum, sg) => sum + taskProvider.getTasksForSubGoal(sg.id).length,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: RepaintBoundary(child: GoalCard(
                      goal: GoalViewData.fromGoalModel(
                        goal,
                        subGoalCount: subGoals.length,
                        taskCount: taskCount,
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => GoalDetailsScreen(goalId: goal.id),
                          ),
                        );
                      },
                      onPinToggle: () {
                        if (goal.isPinned) {
                          goalProvider.unpinGoal(goal.id);
                        } else {
                          goalProvider.pinGoal(goal.id);
                        }
                      },
                    ),),
                  );
                },
              ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ],
    );
  }
}

class _GoalsEmptyState extends StatelessWidget {
  const _GoalsEmptyState({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x40364D80)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xB0131A30), Color(0xA8101628)],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.15)),
              gradient: RadialGradient(
                colors: <Color>[
                  AppColors.neonCyan.withValues(alpha: 0.08),
                  AppColors.neonCyan.withValues(alpha: 0.0),
                ],
              ),
            ),
            child: const Icon(
              Icons.flag_outlined,
              color: AppColors.neonCyan,
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No goals defined yet',
            style: textTheme.titleSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create your first goal to start tracking\nmeaningful progress.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.8),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CreateGoalScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0x2C3B63D9), Color(0x1800CFFF)],
                  ),
                  border: Border.all(color: const Color(0x4F4D7CFF)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: AppColors.neonCyan),
                    SizedBox(width: 6),
                    Text(
                      'Create Goal',
                      style: TextStyle(
                        color: AppColors.neonCyan,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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

class _GoalsBackgroundLayer extends StatelessWidget {
  const _GoalsBackgroundLayer();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF0A0F1E), AppColors.background],
        ),
      ),
      child: Stack(
        children: const [
          Positioned(
            top: -120,
            right: -40,
            child: _GlowOrb(size: 220, color: Color(0x223B64FF)),
          ),
          Positioned(
            top: 320,
            left: -70,
            child: _GlowOrb(size: 190, color: Color(0x1C00D8FF)),
          ),
          Positioned(
            bottom: 80,
            right: -60,
            child: _GlowOrb(size: 180, color: Color(0x1800DCA8)),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});
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
            colors: <Color>[color, color.withValues(alpha: 0.0)],
          ),
        ),
      ),
    );
  }
}
