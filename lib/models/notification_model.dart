import 'package:hive/hive.dart';

part 'notification_model.g.dart';

@HiveType(typeId: 20)
enum NotificationCategory {
  @HiveField(0)
  task,
  @HiveField(1)
  goal,
  @HiveField(2)
  bedtime,
  @HiveField(3)
  reminder,
}

@HiveType(typeId: 21)
enum ReminderPriority {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
  @HiveField(3)
  urgent,
}

@HiveType(typeId: 22)
class NotificationModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime scheduledTime;

  @HiveField(4)
  NotificationCategory category;

  @HiveField(5)
  ReminderPriority priority;

  @HiveField(6)
  bool isDismissed;

  @HiveField(7)
  DateTime? dismissedAt;

  @HiveField(8)
  String? taskId;

  @HiveField(9)
  String? goalId;

  @HiveField(10)
  Map<String, dynamic>? metadata;

  NotificationModel({
    required this.id,
    required this.title,
    this.description,
    required this.scheduledTime,
    required this.category,
    required this.priority,
    this.isDismissed = false,
    this.dismissedAt,
    this.taskId,
    this.goalId,
    this.metadata,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? scheduledTime,
    NotificationCategory? category,
    ReminderPriority? priority,
    bool? isDismissed,
    DateTime? dismissedAt,
    String? taskId,
    String? goalId,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      isDismissed: isDismissed ?? this.isDismissed,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      taskId: taskId ?? this.taskId,
      goalId: goalId ?? this.goalId,
      metadata: metadata ?? this.metadata,
    );
  }
}
