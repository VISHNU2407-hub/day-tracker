import 'package:habit_up/models/achievement_model.dart';
import 'package:habit_up/models/goal_model.dart';
import 'package:habit_up/models/notification_model.dart';
import 'package:habit_up/models/sub_goal_model.dart';
import 'package:habit_up/models/task_model.dart';
import 'package:habit_up/models/user_model.dart';
import 'package:hive/hive.dart';

class HiveBoxNames {
  const HiveBoxNames._();

  static const String taskBox = 'taskBox';
  static const String goalBox = 'goalBox';
  static const String subGoalBox = 'subGoalBox';
  static const String userBox = 'userBox';
  static const String achievementBox = 'achievementBox';
  static const String notificationBox = 'notificationBox';
}

class HiveBoxManager {
  const HiveBoxManager._();

  static Future<void> openAllBoxes() async {
    await Future.wait(<Future<void>>[
      _openBox<TaskModel>(HiveBoxNames.taskBox),
      _openBox<GoalModel>(HiveBoxNames.goalBox),
      _openBox<SubGoalModel>(HiveBoxNames.subGoalBox),
      _openBox<UserModel>(HiveBoxNames.userBox),
      _openBox<AchievementModel>(HiveBoxNames.achievementBox),
      _openBox<NotificationModel>(HiveBoxNames.notificationBox),
    ]);
  }

  static Future<void> _openBox<T>(String name) async {
    if (!Hive.isBoxOpen(name)) {
      await Hive.openBox<T>(name);
    }
  }

  static Box<TaskModel> get taskBox => Hive.box<TaskModel>(HiveBoxNames.taskBox);

  static Box<GoalModel> get goalBox => Hive.box<GoalModel>(HiveBoxNames.goalBox);

  static Box<SubGoalModel> get subGoalBox =>
      Hive.box<SubGoalModel>(HiveBoxNames.subGoalBox);

  static Box<UserModel> get userBox => Hive.box<UserModel>(HiveBoxNames.userBox);

  static Box<AchievementModel> get achievementBox =>
      Hive.box<AchievementModel>(HiveBoxNames.achievementBox);

  static Box<NotificationModel> get notificationBox =>
      Hive.box<NotificationModel>(HiveBoxNames.notificationBox);
}
