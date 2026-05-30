// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationModelAdapter extends TypeAdapter<NotificationModel> {
  @override
  final int typeId = 22;

  @override
  NotificationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      scheduledTime: fields[3] as DateTime,
      category: fields[4] as NotificationCategory,
      priority: fields[5] as ReminderPriority,
      isDismissed: fields[6] as bool,
      dismissedAt: fields[7] as DateTime?,
      taskId: fields[8] as String?,
      goalId: fields[9] as String?,
      metadata: (fields[10] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, NotificationModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.scheduledTime)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.priority)
      ..writeByte(6)
      ..write(obj.isDismissed)
      ..writeByte(7)
      ..write(obj.dismissedAt)
      ..writeByte(8)
      ..write(obj.taskId)
      ..writeByte(9)
      ..write(obj.goalId)
      ..writeByte(10)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NotificationCategoryAdapter extends TypeAdapter<NotificationCategory> {
  @override
  final int typeId = 20;

  @override
  NotificationCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return NotificationCategory.task;
      case 1:
        return NotificationCategory.goal;
      case 2:
        return NotificationCategory.bedtime;
      case 3:
        return NotificationCategory.reminder;
      default:
        return NotificationCategory.task;
    }
  }

  @override
  void write(BinaryWriter writer, NotificationCategory obj) {
    switch (obj) {
      case NotificationCategory.task:
        writer.writeByte(0);
        break;
      case NotificationCategory.goal:
        writer.writeByte(1);
        break;
      case NotificationCategory.bedtime:
        writer.writeByte(2);
        break;
      case NotificationCategory.reminder:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReminderPriorityAdapter extends TypeAdapter<ReminderPriority> {
  @override
  final int typeId = 21;

  @override
  ReminderPriority read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ReminderPriority.low;
      case 1:
        return ReminderPriority.medium;
      case 2:
        return ReminderPriority.high;
      case 3:
        return ReminderPriority.urgent;
      default:
        return ReminderPriority.low;
    }
  }

  @override
  void write(BinaryWriter writer, ReminderPriority obj) {
    switch (obj) {
      case ReminderPriority.low:
        writer.writeByte(0);
        break;
      case ReminderPriority.medium:
        writer.writeByte(1);
        break;
      case ReminderPriority.high:
        writer.writeByte(2);
        break;
      case ReminderPriority.urgent:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderPriorityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
