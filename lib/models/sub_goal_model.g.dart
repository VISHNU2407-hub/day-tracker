// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sub_goal_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubGoalModelAdapter extends TypeAdapter<SubGoalModel> {
  @override
  final int typeId = 4;

  @override
  SubGoalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubGoalModel(
      id: fields[0] as String,
      goalId: fields[1] as String,
      title: fields[2] as String,
      progress: fields[4] as double,
      isCompleted: fields[5] as bool,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[9] as DateTime,
      description: fields[3] as String?,
      completedAt: fields[8] as DateTime?,
      taskIds: (fields[6] as List).cast<String>(),
      status: fields[10] as SubGoalStatus,
      deadline: fields[11] as DateTime?,
      motivationalSubtitle: fields[12] as String?,
      xp: fields[13] as int,
      streak: fields[14] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SubGoalModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.goalId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.progress)
      ..writeByte(5)
      ..write(obj.isCompleted)
      ..writeByte(6)
      ..write(obj.taskIds)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.completedAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.status)
      ..writeByte(11)
      ..write(obj.deadline)
      ..writeByte(12)
      ..write(obj.motivationalSubtitle)
      ..writeByte(13)
      ..write(obj.xp)
      ..writeByte(14)
      ..write(obj.streak);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubGoalModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SubGoalStatusAdapter extends TypeAdapter<SubGoalStatus> {
  @override
  final int typeId = 15;

  @override
  SubGoalStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SubGoalStatus.active;
      case 1:
        return SubGoalStatus.completed;
      case 2:
        return SubGoalStatus.paused;
      case 3:
        return SubGoalStatus.overdue;
      case 4:
        return SubGoalStatus.archived;
      default:
        return SubGoalStatus.active;
    }
  }

  @override
  void write(BinaryWriter writer, SubGoalStatus obj) {
    switch (obj) {
      case SubGoalStatus.active:
        writer.writeByte(0);
        break;
      case SubGoalStatus.completed:
        writer.writeByte(1);
        break;
      case SubGoalStatus.paused:
        writer.writeByte(2);
        break;
      case SubGoalStatus.overdue:
        writer.writeByte(3);
        break;
      case SubGoalStatus.archived:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubGoalStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
