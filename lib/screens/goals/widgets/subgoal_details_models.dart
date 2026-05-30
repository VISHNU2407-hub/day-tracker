import 'package:flutter/material.dart';

enum SubGoalTaskPriority { low, medium, high, critical }

enum SubGoalTaskState { active, completed, overdue }

@immutable
class SubGoalDetailsViewModel {
  const SubGoalDetailsViewModel({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.completedTasks,
    required this.totalTasks,
    required this.activeStreakDays,
    required this.timelineSummary,
    required this.xpEarned,
    required this.focusConsistency,
    required this.tasks,
  });

  final String title;
  final String subtitle;
  final double progress;
  final int completedTasks;
  final int totalTasks;
  final int activeStreakDays;
  final String timelineSummary;
  final int xpEarned;
  final int focusConsistency;
  final List<SubGoalTaskItemViewModel> tasks;
}

@immutable
class SubGoalTaskItemViewModel {
  const SubGoalTaskItemViewModel({
    required this.title,
    required this.subtitle,
    required this.priority,
    required this.xpReward,
    required this.dueLabel,
    required this.state,
    required this.progress,
    required this.hasReminder,
  });

  final String title;
  final String subtitle;
  final SubGoalTaskPriority priority;
  final int xpReward;
  final String dueLabel;
  final SubGoalTaskState state;
  final double progress;
  final bool hasReminder;
}

