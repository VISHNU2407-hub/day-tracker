import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:habit_up/models/achievement_model.dart';
import 'package:habit_up/models/goal_model.dart';
import 'package:habit_up/models/notification_model.dart';
import 'package:habit_up/models/sub_goal_model.dart';
import 'package:habit_up/models/task_model.dart';
import 'package:habit_up/models/user_model.dart';
import 'package:habit_up/services/user_storage_service.dart';
import 'package:habit_up/storage/hive_boxes.dart';
import 'package:habit_up/theme/app_theme.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = Directory.systemTemp.createTempSync('habit_up_test_');
    Hive.init(tempDir.path);
    _registerAdapters();
    await HiveBoxManager.openAllBoxes();
  });

  tearDownAll(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  testWidgets('App theme resolves dark theme correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: Center(
            child: Text('Habit Up', style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );

    expect(find.text('Habit Up'), findsOneWidget);
  });

  test('Hive boxes open and can store a user', () async {
    final now = DateTime.now();
    final user = UserModel(
      id: 'test_user',
      username: 'Tester',
      xp: 0,
      level: 1,
      currentStreak: 0,
      longestStreak: 0,
      avatarLetter: 'T',
      createdAt: now,
      lastActiveAt: now,
      preferences: {'onboarding_completed': true},
    );
    await HiveBoxManager.userBox.put(user.id, user);

    final fetched = await const UserStorageService().getCurrentUser();
    expect(fetched, isNotNull);
    expect(fetched!.username, 'Tester');
    expect(fetched.preferences['onboarding_completed'], true);
  });
}

void _registerAdapters() {
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
