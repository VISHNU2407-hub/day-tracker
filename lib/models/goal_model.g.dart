// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GoalModelAdapter extends TypeAdapter<GoalModel> {
  @override
  final int typeId = 3;

  @override
  GoalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GoalModel(
      id: fields[0] as String,
      title: fields[1] as String,
      progress: fields[5] as double,
      isPinned: fields[6] as bool,
      isCompleted: fields[7] as bool,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[11] as DateTime,
      description: fields[2] as String?,
      colorHex: fields[3] as String?,
      themeKey: fields[4] as String?,
      completedAt: fields[9] as DateTime?,
      subGoalIds: (fields[10] as List).cast<String>(),
      status: fields[12] as GoalStatus,
      deadline: fields[13] as DateTime?,
      targetCompletionDate: fields[14] as DateTime?,
      motivationalSubtitle: fields[15] as String?,
      xp: fields[16] as int,
      streak: fields[17] as int,
    );
  }

  @override
  void write(BinaryWriter writer, GoalModel obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.colorHex)
      ..writeByte(4)
      ..write(obj.themeKey)
      ..writeByte(5)
      ..write(obj.progress)
      ..writeByte(6)
      ..write(obj.isPinned)
      ..writeByte(7)
      ..write(obj.isCompleted)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.completedAt)
      ..writeByte(10)
      ..write(obj.subGoalIds)
      ..writeByte(11)
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj.status)
      ..writeByte(13)
      ..write(obj.deadline)
      ..writeByte(14)
      ..write(obj.targetCompletionDate)
      ..writeByte(15)
      ..write(obj.motivationalSubtitle)
      ..writeByte(16)
      ..write(obj.xp)
      ..writeByte(17)
      ..write(obj.streak);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GoalStatusAdapter extends TypeAdapter<GoalStatus> {
  @override
  final int typeId = 14;

  @override
  GoalStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GoalStatus.active;
      case 1:
        return GoalStatus.completed;
      case 2:
        return GoalStatus.paused;
      case 3:
        return GoalStatus.archived;
      default:
        return GoalStatus.active;
    }
  }

  @override
  void write(BinaryWriter writer, GoalStatus obj) {
    switch (obj) {
      case GoalStatus.active:
        writer.writeByte(0);
        break;
      case GoalStatus.completed:
        writer.writeByte(1);
        break;
      case GoalStatus.paused:
        writer.writeByte(2);
        break;
      case GoalStatus.archived:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
