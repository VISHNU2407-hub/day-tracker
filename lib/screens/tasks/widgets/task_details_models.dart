import 'package:flutter/material.dart';

enum TaskExecutionPriority { low, medium, high, critical }

enum TaskExecutionStatus { active, completed, overdue, scheduled }

@immutable
class TaskDetailsViewModel {
  const TaskDetailsViewModel({
    required this.title,
    required this.subGoalLabel,
    required this.status,
    required this.priority,
    required this.progress,
    required this.xpReward,
    required this.streakBonusXp,
    required this.dueDateLabel,
    required this.reminderLabel,
    required this.recurringLabel,
    required this.focusDurationLabel,
    required this.focusStreakDays,
    required this.intensityLabel,
    required this.description,
    required this.timelineEvents,
  });

  final String title;
  final String subGoalLabel;
  final TaskExecutionStatus status;
  final TaskExecutionPriority priority;
  final double progress;
  final int xpReward;
  final int streakBonusXp;
  final String dueDateLabel;
  final String reminderLabel;
  final String recurringLabel;
  final String focusDurationLabel;
  final int focusStreakDays;
  final String intensityLabel;
  final String description;
  final List<TaskTimelineEventViewModel> timelineEvents;
}

@immutable
class TaskTimelineEventViewModel {
  const TaskTimelineEventViewModel({
    required this.timeLabel,
    required this.title,
    required this.isCompleted,
  });

  final String timeLabel;
  final String title;
  final bool isCompleted;
}

