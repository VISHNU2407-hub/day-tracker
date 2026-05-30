import 'package:flutter/material.dart';
import 'package:habit_up/providers/goal_provider.dart';
import 'package:habit_up/providers/sub_goal_provider.dart';
import 'package:habit_up/providers/task_provider.dart';
import 'package:habit_up/services/alarm_manager_service.dart';
import 'package:habit_up/services/hierarchy_cascade_service.dart';
import 'package:habit_up/services/user_storage_service.dart';
import 'package:habit_up/services/xp_streak_service.dart';
import 'package:habit_up/storage/hive_bootstrap.dart';
import 'package:provider/provider.dart' as provider_pkg;

/// Thin, non-visual widget that initialises the [HierarchyCascadeService]
/// and the [XpStreakService] after all ChangeNotifier providers are available
/// in the widget tree.
///
/// Must be placed as a descendant of the [MultiProvider] that provides
/// [TaskProvider], [SubGoalProvider], and [GoalProvider].
///
/// Also provides [XpStreakService] as a [ChangeNotifierProvider] so widgets
/// throughout the app can watch XP, streak, and momentum state.
class HierarchyCascadeInitializer extends StatefulWidget {
  const HierarchyCascadeInitializer({required this.child, super.key});

  final Widget child;

  @override
  State<HierarchyCascadeInitializer> createState() =>
      _HierarchyCascadeInitializerState();
}

class _HierarchyCascadeInitializerState
    extends State<HierarchyCascadeInitializer> {
  /// Created immediately so [XpStreakService] is always available in the
  /// widget tree from the first frame. Initialization happens in the
  /// post-frame callback and will notify listeners when done.
  late final XpStreakService _xpStreakService;

  /// Cached provider references captured synchronously in [initState] so they
  /// can be used safely after async gaps without triggering
  /// use_build_context_synchronously lint warnings.
  late final TaskProvider _taskProvider;
  late final SubGoalProvider _subGoalProvider;
  late final GoalProvider _goalProvider;

  @override
  void initState() {
    super.initState();
    // Read providers synchronously — guaranteed available because this widget
    // is a descendant of the MultiProvider in main.dart.
    _taskProvider = context.read<TaskProvider>();
    _subGoalProvider = context.read<SubGoalProvider>();
    _goalProvider = context.read<GoalProvider>();

    _xpStreakService = XpStreakService(
      taskProvider: _taskProvider,
      goalProvider: _goalProvider,
      userStorageService: const UserStorageService(),
    );

    // Initialize and wire services asynchronously.
    WidgetsBinding.instance.addPostFrameCallback((_) => _wireServices());
  }

  Future<void> _wireServices() async {
    if (!mounted) return;

    await _xpStreakService.initialize();

    // Wire the hierarchy cascade, passing XpStreakService so task
    // completion hooks also update XP and streaks at the user level.
    HierarchyCascadeService(
      _taskProvider,
      _subGoalProvider,
      _goalProvider,
      xpStreakService: _xpStreakService,
    );

    // Wire level-up callback to set pendingLevelUp so the UI can show popups.
    _xpStreakService.onLevelUp = (level) {
      // pendingLevelUp is already set by XpStreakService._checkForLevelUp
    };

    // Detect if we're in the secondary alarm engine (AlarmActivity).
    // If there's an initial alarm payload, this is the alarm engine — mark
    // it as secondary so we skip Hive writes that could corrupt the primary
    // engine's data.
    final isAlarmEngine = AlarmManagerService.instance.currentPayload != null;
    if (isAlarmEngine) {
      HiveBootstrap.markAsSecondaryEngine();
    }

    // Only evaluate daily streak in the primary engine to avoid Hive
    // write conflicts from the secondary Flutter engine (AlarmActivity).
    if (HiveBootstrap.isPrimaryEngine) {
      await _xpStreakService.updateDailyStreak();
    }
  }

  @override
  Widget build(BuildContext context) {
    // XpStreakService is ALWAYS provided — from the very first frame.
    return provider_pkg.ChangeNotifierProvider<XpStreakService>.value(
      value: _xpStreakService,
      child: widget.child,
    );
  }
}
