import 'package:habit_up/models/achievement_model.dart';
import 'package:habit_up/models/goal_model.dart';
import 'package:habit_up/models/notification_model.dart';
import 'package:habit_up/models/sub_goal_model.dart';
import 'package:habit_up/models/task_model.dart';
import 'package:habit_up/models/user_model.dart';
import 'package:habit_up/storage/hive_boxes.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveBootstrap {
  const HiveBootstrap._();

  static bool _initialized = false;

  /// `true` for the primary (main) Flutter engine; `false` for secondary
  /// engines like AlarmActivity. Used to guard writes to shared Hive boxes.
  /// Set by [markAsPrimaryEngine] or [markAsSecondaryEngine].
  static bool isPrimaryEngine = true;

  /// Call when the app determines this engine is the primary/main one.
  static void markAsPrimaryEngine() {
    isPrimaryEngine = true;
  }

  /// Call when the app determines this engine is a secondary/alarm one.
  static void markAsSecondaryEngine() {
    isPrimaryEngine = false;
  }

  /// Returns `true` if Hive was initialized in this call, `false` if it
  /// was already initialized (safe to call multiple times).
  static Future<bool> initialize() async {
    if (_initialized) {
      return false;
    }

    // Hive.initFlutter() can throw if called twice in the same isolate.
    // Guard with try-catch for multi-engine scenarios (AlarmActivity).
    try {
      await Hive.initFlutter();
    } catch (_) {
      // Multi-engine re-entry — continuing
    }

    _registerAdapters();

    // Guard against multi-engine scenarios where boxes may already be open
    // in another Dart isolate. Each isolate has its own Hive in-memory state,
    // but they share the same filesystem.
    try {
      await HiveBoxManager.openAllBoxes();
    } catch (_) {
      // Multi-engine box collision — continuing with partial state
    }

    _initialized = true;
    return true;
  }

  /// Reset the initialized flag (useful for testing).
  static void reset() {
    _initialized = false;
    isPrimaryEngine = true;
  }

  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TaskDifficultyAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(TaskModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(GoalModelAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(SubGoalModelAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(AchievementCategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(RewardCategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(AchievementModelAdapter());
    }
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(NotificationCategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(21)) {
      Hive.registerAdapter(ReminderPriorityAdapter());
    }
    if (!Hive.isAdapterRegistered(22)) {
      Hive.registerAdapter(NotificationModelAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(TaskStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(TaskRepeatTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(GoalStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(15)) {
      Hive.registerAdapter(SubGoalStatusAdapter());
    }
  }
}
