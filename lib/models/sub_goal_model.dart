import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

part 'sub_goal_model.g.dart';

@HiveType(typeId: 15)
enum SubGoalStatus {
  @HiveField(0)
  active,
  @HiveField(1)
  completed,
  @HiveField(2)
  paused,
  @HiveField(3)
  overdue,
  @HiveField(4)
  archived,
}

@immutable
@HiveType(typeId: 4)
class SubGoalModel {
  const SubGoalModel({
    required this.id,
    required this.goalId,
    required this.title,
    required this.progress,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.completedAt,
    this.taskIds = const <String>[],
    this.status = SubGoalStatus.active,
    this.deadline,
    this.motivationalSubtitle,
    this.xp = 0,
    this.streak = 0,
  });

  @HiveField(0)
  final String id;

  /// Parent goal linkage.
  @HiveField(1)
  final String goalId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String? description;

  /// Sub-goal progress ratio. Expected range: 0.0 to 1.0.
  @HiveField(4)
  final double progress;

  @HiveField(5)
  final bool isCompleted;

  /// Linked tasks under this sub-goal.
  @HiveField(6)
  final List<String> taskIds;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime? completedAt;

  @HiveField(9)
  final DateTime updatedAt;

  /// Current lifecycle status of the sub-goal.
  @HiveField(10)
  final SubGoalStatus status;

  /// Deadline for this sub-goal.
  @HiveField(11)
  final DateTime? deadline;

  /// Short motivational subtitle displayed on cards.
  @HiveField(12)
  final String? motivationalSubtitle;

  /// Cumulative XP earned for this sub-goal.
  @HiveField(13)
  final int xp;

  /// Current streak days for this sub-goal.
  @HiveField(14)
  final int streak;

  SubGoalModel copyWith({
    String? id,
    String? goalId,
    String? title,
    String? description,
    double? progress,
    bool? isCompleted,
    List<String>? taskIds,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? updatedAt,
    SubGoalStatus? status,
    DateTime? deadline,
    String? motivationalSubtitle,
    int? xp,
    int? streak,
    bool clearDescription = false,
    bool clearCompletedAt = false,
    bool clearDeadline = false,
    bool clearMotivationalSubtitle = false,
  }) {
    return SubGoalModel(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      taskIds: taskIds ?? this.taskIds,
      createdAt: createdAt ?? this.createdAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      motivationalSubtitle: clearMotivationalSubtitle
          ? null
          : (motivationalSubtitle ?? this.motivationalSubtitle),
      xp: xp ?? this.xp,
      streak: streak ?? this.streak,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goalId': goalId,
      'title': title,
      'description': description,
      'progress': progress,
      'isCompleted': isCompleted,
      'taskIds': taskIds,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status.name,
      'deadline': deadline?.toIso8601String(),
      'motivationalSubtitle': motivationalSubtitle,
      'xp': xp,
      'streak': streak,
    };
  }

  factory SubGoalModel.fromMap(Map<String, dynamic> map) {
    return SubGoalModel(
      id: map['id'] as String,
      goalId: map['goalId'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      isCompleted: map['isCompleted'] as bool? ?? false,
      taskIds: (map['taskIds'] as List<dynamic>?)
              ?.map((value) => value as String)
              .toList() ??
          const <String>[],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
      status: map['status'] != null
          ? SubGoalStatus.values.firstWhere(
              (value) => value.name == map['status'],
              orElse: () => SubGoalStatus.active,
            )
          : SubGoalStatus.active,
      deadline: map['deadline'] != null
          ? DateTime.parse(map['deadline'] as String)
          : null,
      motivationalSubtitle: map['motivationalSubtitle'] as String?,
      xp: map['xp'] as int? ?? 0,
      streak: map['streak'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is SubGoalModel &&
        other.id == id &&
        other.goalId == goalId &&
        other.title == title &&
        other.description == description &&
        other.progress == progress &&
        other.isCompleted == isCompleted &&
        listEquals(other.taskIds, taskIds) &&
        other.createdAt == createdAt &&
        other.completedAt == completedAt &&
        other.updatedAt == updatedAt &&
        other.status == status &&
        other.deadline == deadline &&
        other.motivationalSubtitle == motivationalSubtitle &&
        other.xp == xp &&
        other.streak == streak;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      goalId,
      title,
      description,
      progress,
      isCompleted,
      Object.hashAll(taskIds),
      createdAt,
      completedAt,
      updatedAt,
      status,
      deadline,
      motivationalSubtitle,
      xp,
      streak,
    );
  }
}
