import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

part 'goal_model.g.dart';

@HiveType(typeId: 14)
enum GoalStatus {
  @HiveField(0)
  active,
  @HiveField(1)
  completed,
  @HiveField(2)
  paused,
  @HiveField(3)
  archived,
}

@immutable
@HiveType(typeId: 3)
class GoalModel {
  const GoalModel({
    required this.id,
    required this.title,
    required this.progress,
    required this.isPinned,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.colorHex,
    this.themeKey,
    this.completedAt,
    this.subGoalIds = const <String>[],
    this.status = GoalStatus.active,
    this.deadline,
    this.targetCompletionDate,
    this.motivationalSubtitle,
    this.xp = 0,
    this.streak = 0,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? description;

  /// Hex color string used by UI layers (for example: #4CAF50).
  @HiveField(3)
  final String? colorHex;

  /// Optional key for predefined app goal themes.
  @HiveField(4)
  final String? themeKey;

  /// Goal progress ratio. Expected range: 0.0 to 1.0.
  @HiveField(5)
  final double progress;

  @HiveField(6)
  final bool isPinned;

  @HiveField(7)
  final bool isCompleted;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime? completedAt;

  @HiveField(10)
  final List<String> subGoalIds;

  @HiveField(11)
  final DateTime updatedAt;

  /// Current lifecycle status of the goal.
  @HiveField(12)
  final GoalStatus status;

  /// Hard deadline for goal completion.
  @HiveField(13)
  final DateTime? deadline;

  /// User's target date for completing the goal.
  @HiveField(14)
  final DateTime? targetCompletionDate;

  /// Short motivational subtitle displayed on cards.
  @HiveField(15)
  final String? motivationalSubtitle;

  /// Cumulative XP earned for this goal.
  @HiveField(16)
  final int xp;

  /// Current streak days for this goal.
  @HiveField(17)
  final int streak;

  GoalModel copyWith({
    String? id,
    String? title,
    String? description,
    String? colorHex,
    String? themeKey,
    double? progress,
    bool? isPinned,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    List<String>? subGoalIds,
    DateTime? updatedAt,
    GoalStatus? status,
    DateTime? deadline,
    DateTime? targetCompletionDate,
    String? motivationalSubtitle,
    int? xp,
    int? streak,
    bool clearDescription = false,
    bool clearColorHex = false,
    bool clearThemeKey = false,
    bool clearCompletedAt = false,
    bool clearDeadline = false,
    bool clearTargetCompletionDate = false,
    bool clearMotivationalSubtitle = false,
  }) {
    return GoalModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      colorHex: clearColorHex ? null : (colorHex ?? this.colorHex),
      themeKey: clearThemeKey ? null : (themeKey ?? this.themeKey),
      progress: progress ?? this.progress,
      isPinned: isPinned ?? this.isPinned,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      subGoalIds: subGoalIds ?? this.subGoalIds,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      targetCompletionDate: clearTargetCompletionDate
          ? null
          : (targetCompletionDate ?? this.targetCompletionDate),
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
      'title': title,
      'description': description,
      'colorHex': colorHex,
      'themeKey': themeKey,
      'progress': progress,
      'isPinned': isPinned,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'subGoalIds': subGoalIds,
      'updatedAt': updatedAt.toIso8601String(),
      'status': status.name,
      'deadline': deadline?.toIso8601String(),
      'targetCompletionDate': targetCompletionDate?.toIso8601String(),
      'motivationalSubtitle': motivationalSubtitle,
      'xp': xp,
      'streak': streak,
    };
  }

  factory GoalModel.fromMap(Map<String, dynamic> map) {
    return GoalModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      colorHex: map['colorHex'] as String?,
      themeKey: map['themeKey'] as String?,
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      isPinned: map['isPinned'] as bool? ?? false,
      isCompleted: map['isCompleted'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      subGoalIds: (map['subGoalIds'] as List<dynamic>?)
              ?.map((value) => value as String)
              .toList() ??
          const <String>[],
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
      status: map['status'] != null
          ? GoalStatus.values.firstWhere(
              (value) => value.name == map['status'],
              orElse: () => GoalStatus.active,
            )
          : GoalStatus.active,
      deadline: map['deadline'] != null
          ? DateTime.parse(map['deadline'] as String)
          : null,
      targetCompletionDate: map['targetCompletionDate'] != null
          ? DateTime.parse(map['targetCompletionDate'] as String)
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

    return other is GoalModel &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.colorHex == colorHex &&
        other.themeKey == themeKey &&
        other.progress == progress &&
        other.isPinned == isPinned &&
        other.isCompleted == isCompleted &&
        other.createdAt == createdAt &&
        other.completedAt == completedAt &&
        listEquals(other.subGoalIds, subGoalIds) &&
        other.updatedAt == updatedAt &&
        other.status == status &&
        other.deadline == deadline &&
        other.targetCompletionDate == targetCompletionDate &&
        other.motivationalSubtitle == motivationalSubtitle &&
        other.xp == xp &&
        other.streak == streak;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      colorHex,
      themeKey,
      progress,
      isPinned,
      isCompleted,
      createdAt,
      completedAt,
      Object.hashAll(subGoalIds),
      updatedAt,
      status,
      deadline,
      targetCompletionDate,
      motivationalSubtitle,
      xp,
      streak,
    );
  }
}
