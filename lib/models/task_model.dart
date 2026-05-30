import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 1)
enum TaskDifficulty {
  @HiveField(0)
  easy,
  @HiveField(1)
  medium,
  @HiveField(2)
  hard,
}

@HiveType(typeId: 12)
enum TaskStatus {
  @HiveField(0)
  active,
  @HiveField(1)
  completed,
  @HiveField(2)
  scheduled,
  @HiveField(3)
  overdue,
}

@HiveType(typeId: 13)
enum TaskRepeatType {
  @HiveField(0)
  none,
  @HiveField(1)
  daily,
  @HiveField(2)
  weekly,
  @HiveField(3)
  monthly,
  @HiveField(4)
  custom,
}

@immutable
@HiveType(typeId: 2)
class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.status,
    required this.difficulty,
    required this.xpReward,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.startTime,
    this.scheduledDate,
    this.dueDate,
    this.reminderTime,
    this.repeatType = TaskRepeatType.none,
    this.estimatedFocusDurationMinutes,
    this.goalId,
    this.subGoalId,
    this.completedAt,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final bool isCompleted;

  @HiveField(4)
  final TaskStatus status;

  @HiveField(5)
  final TaskDifficulty difficulty;

  @HiveField(6)
  final int xpReward;

  /// Specific start date-time for a task if it is time-bound.
  @HiveField(7)
  final DateTime? startTime;

  /// Date bucket used for calendar scheduling.
  @HiveField(8)
  final DateTime? scheduledDate;

  @HiveField(9)
  final DateTime? dueDate;

  @HiveField(10)
  final DateTime? reminderTime;

  @HiveField(11)
  final TaskRepeatType repeatType;

  @HiveField(12)
  final int? estimatedFocusDurationMinutes;

  @HiveField(13)
  final String? goalId;

  @HiveField(14)
  final String? subGoalId;

  @HiveField(15)
  final DateTime createdAt;

  @HiveField(16)
  final DateTime? completedAt;

  @HiveField(17)
  final DateTime updatedAt;

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    TaskStatus? status,
    TaskDifficulty? difficulty,
    int? xpReward,
    DateTime? startTime,
    DateTime? scheduledDate,
    DateTime? dueDate,
    DateTime? reminderTime,
    TaskRepeatType? repeatType,
    int? estimatedFocusDurationMinutes,
    String? goalId,
    String? subGoalId,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? updatedAt,
    bool clearDescription = false,
    bool clearStartTime = false,
    bool clearScheduledDate = false,
    bool clearDueDate = false,
    bool clearReminderTime = false,
    bool clearEstimatedFocusDuration = false,
    bool clearGoalId = false,
    bool clearSubGoalId = false,
    bool clearCompletedAt = false,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      isCompleted: isCompleted ?? this.isCompleted,
      status: status ?? this.status,
      difficulty: difficulty ?? this.difficulty,
      xpReward: xpReward ?? this.xpReward,
      startTime: clearStartTime ? null : (startTime ?? this.startTime),
      scheduledDate:
          clearScheduledDate ? null : (scheduledDate ?? this.scheduledDate),
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      reminderTime:
          clearReminderTime ? null : (reminderTime ?? this.reminderTime),
      repeatType: repeatType ?? this.repeatType,
      estimatedFocusDurationMinutes: clearEstimatedFocusDuration
          ? null
          : (estimatedFocusDurationMinutes ?? this.estimatedFocusDurationMinutes),
      goalId: clearGoalId ? null : (goalId ?? this.goalId),
      subGoalId: clearSubGoalId ? null : (subGoalId ?? this.subGoalId),
      createdAt: createdAt ?? this.createdAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'status': status.name,
      'difficulty': difficulty.name,
      'xpReward': xpReward,
      'startTime': startTime?.toIso8601String(),
      'scheduledDate': scheduledDate?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'reminderTime': reminderTime?.toIso8601String(),
      'repeatType': repeatType.name,
      'estimatedFocusDurationMinutes': estimatedFocusDurationMinutes,
      'goalId': goalId,
      'subGoalId': subGoalId,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      isCompleted: map['isCompleted'] as bool? ?? false,
      status: TaskStatus.values.firstWhere(
        (value) => value.name == map['status'],
        orElse: () => (map['isCompleted'] as bool? ?? false)
            ? TaskStatus.completed
            : TaskStatus.active,
      ),
      difficulty: TaskDifficulty.values.firstWhere(
        (value) => value.name == map['difficulty'],
        orElse: () => TaskDifficulty.medium,
      ),
      xpReward: map['xpReward'] as int? ?? 0,
      startTime: map['startTime'] != null
          ? DateTime.parse(map['startTime'] as String)
          : null,
      scheduledDate: map['scheduledDate'] != null
          ? DateTime.parse(map['scheduledDate'] as String)
          : null,
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'] as String)
          : null,
      reminderTime: map['reminderTime'] != null
          ? DateTime.parse(map['reminderTime'] as String)
          : null,
      repeatType: TaskRepeatType.values.firstWhere(
        (value) => value.name == map['repeatType'],
        orElse: () => TaskRepeatType.none,
      ),
      estimatedFocusDurationMinutes:
          map['estimatedFocusDurationMinutes'] as int?,
      goalId: map['goalId'] as String?,
      subGoalId: map['subGoalId'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is TaskModel &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.isCompleted == isCompleted &&
        other.status == status &&
        other.difficulty == difficulty &&
        other.xpReward == xpReward &&
        other.startTime == startTime &&
        other.scheduledDate == scheduledDate &&
        other.dueDate == dueDate &&
        other.reminderTime == reminderTime &&
        other.repeatType == repeatType &&
        other.estimatedFocusDurationMinutes == estimatedFocusDurationMinutes &&
        other.goalId == goalId &&
        other.subGoalId == subGoalId &&
        other.createdAt == createdAt &&
        other.completedAt == completedAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      isCompleted,
      status,
      difficulty,
      xpReward,
      startTime,
      scheduledDate,
      dueDate,
      reminderTime,
      repeatType,
      estimatedFocusDurationMinutes,
      goalId,
      subGoalId,
      createdAt,
      completedAt,
      updatedAt,
    );
  }
}
