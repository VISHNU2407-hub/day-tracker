// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskModelAdapter extends TypeAdapter<TaskModel> {
  @override
  final int typeId = 2;

  @override
  TaskModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskModel(
      id: fields[0] as String,
      title: fields[1] as String,
      isCompleted: fields[3] as bool,
      status: fields[4] as TaskStatus,
      difficulty: fields[5] as TaskDifficulty,
      xpReward: fields[6] as int,
      createdAt: fields[15] as DateTime,
      updatedAt: fields[17] as DateTime,
      description: fields[2] as String?,
      startTime: fields[7] as DateTime?,
      scheduledDate: fields[8] as DateTime?,
      dueDate: fields[9] as DateTime?,
      reminderTime: fields[10] as DateTime?,
      repeatType: fields[11] as TaskRepeatType,
      estimatedFocusDurationMinutes: fields[12] as int?,
      goalId: fields[13] as String?,
      subGoalId: fields[14] as String?,
      completedAt: fields[16] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.isCompleted)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.difficulty)
      ..writeByte(6)
      ..write(obj.xpReward)
      ..writeByte(7)
      ..write(obj.startTime)
      ..writeByte(8)
      ..write(obj.scheduledDate)
      ..writeByte(9)
      ..write(obj.dueDate)
      ..writeByte(10)
      ..write(obj.reminderTime)
      ..writeByte(11)
      ..write(obj.repeatType)
      ..writeByte(12)
      ..write(obj.estimatedFocusDurationMinutes)
      ..writeByte(13)
      ..write(obj.goalId)
      ..writeByte(14)
      ..write(obj.subGoalId)
      ..writeByte(15)
      ..write(obj.createdAt)
      ..writeByte(16)
      ..write(obj.completedAt)
      ..writeByte(17)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskDifficultyAdapter extends TypeAdapter<TaskDifficulty> {
  @override
  final int typeId = 1;

  @override
  TaskDifficulty read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskDifficulty.easy;
      case 1:
        return TaskDifficulty.medium;
      case 2:
        return TaskDifficulty.hard;
      default:
        return TaskDifficulty.easy;
    }
  }

  @override
  void write(BinaryWriter writer, TaskDifficulty obj) {
    switch (obj) {
      case TaskDifficulty.easy:
        writer.writeByte(0);
        break;
      case TaskDifficulty.medium:
        writer.writeByte(1);
        break;
      case TaskDifficulty.hard:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskDifficultyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskStatusAdapter extends TypeAdapter<TaskStatus> {
  @override
  final int typeId = 12;

  @override
  TaskStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskStatus.active;
      case 1:
        return TaskStatus.completed;
      case 2:
        return TaskStatus.scheduled;
      case 3:
        return TaskStatus.overdue;
      default:
        return TaskStatus.active;
    }
  }

  @override
  void write(BinaryWriter writer, TaskStatus obj) {
    switch (obj) {
      case TaskStatus.active:
        writer.writeByte(0);
        break;
      case TaskStatus.completed:
        writer.writeByte(1);
        break;
      case TaskStatus.scheduled:
        writer.writeByte(2);
        break;
      case TaskStatus.overdue:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskRepeatTypeAdapter extends TypeAdapter<TaskRepeatType> {
  @override
  final int typeId = 13;

  @override
  TaskRepeatType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskRepeatType.none;
      case 1:
        return TaskRepeatType.daily;
      case 2:
        return TaskRepeatType.weekly;
      case 3:
        return TaskRepeatType.monthly;
      case 4:
        return TaskRepeatType.custom;
      default:
        return TaskRepeatType.none;
    }
  }

  @override
  void write(BinaryWriter writer, TaskRepeatType obj) {
    switch (obj) {
      case TaskRepeatType.none:
        writer.writeByte(0);
        break;
      case TaskRepeatType.daily:
        writer.writeByte(1);
        break;
      case TaskRepeatType.weekly:
        writer.writeByte(2);
        break;
      case TaskRepeatType.monthly:
        writer.writeByte(3);
        break;
      case TaskRepeatType.custom:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskRepeatTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
