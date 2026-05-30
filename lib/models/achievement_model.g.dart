// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AchievementModelAdapter extends TypeAdapter<AchievementModel> {
  @override
  final int typeId = 8;

  @override
  AchievementModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AchievementModel(
      id: fields[0] as String,
      title: fields[1] as String,
      category: fields[3] as AchievementCategory,
      xpReward: fields[4] as int,
      isUnlocked: fields[5] as bool,
      progress: fields[9] as double,
      createdAt: fields[10] as DateTime,
      updatedAt: fields[11] as DateTime,
      description: fields[2] as String?,
      unlockedAt: fields[6] as DateTime?,
      iconKey: fields[7] as String?,
      rewardCategory: fields[8] as RewardCategory?,
    );
  }

  @override
  void write(BinaryWriter writer, AchievementModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.xpReward)
      ..writeByte(5)
      ..write(obj.isUnlocked)
      ..writeByte(6)
      ..write(obj.unlockedAt)
      ..writeByte(7)
      ..write(obj.iconKey)
      ..writeByte(8)
      ..write(obj.rewardCategory)
      ..writeByte(9)
      ..write(obj.progress)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AchievementCategoryAdapter extends TypeAdapter<AchievementCategory> {
  @override
  final int typeId = 6;

  @override
  AchievementCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AchievementCategory.streak;
      case 1:
        return AchievementCategory.xp;
      case 2:
        return AchievementCategory.monthly;
      case 3:
        return AchievementCategory.goalCompletion;
      case 4:
        return AchievementCategory.productivity;
      default:
        return AchievementCategory.streak;
    }
  }

  @override
  void write(BinaryWriter writer, AchievementCategory obj) {
    switch (obj) {
      case AchievementCategory.streak:
        writer.writeByte(0);
        break;
      case AchievementCategory.xp:
        writer.writeByte(1);
        break;
      case AchievementCategory.monthly:
        writer.writeByte(2);
        break;
      case AchievementCategory.goalCompletion:
        writer.writeByte(3);
        break;
      case AchievementCategory.productivity:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RewardCategoryAdapter extends TypeAdapter<RewardCategory> {
  @override
  final int typeId = 7;

  @override
  RewardCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RewardCategory.streakReward;
      case 1:
        return RewardCategory.xpReward;
      case 2:
        return RewardCategory.monthlyReward;
      case 3:
        return RewardCategory.goalCompletionReward;
      default:
        return RewardCategory.streakReward;
    }
  }

  @override
  void write(BinaryWriter writer, RewardCategory obj) {
    switch (obj) {
      case RewardCategory.streakReward:
        writer.writeByte(0);
        break;
      case RewardCategory.xpReward:
        writer.writeByte(1);
        break;
      case RewardCategory.monthlyReward:
        writer.writeByte(2);
        break;
      case RewardCategory.goalCompletionReward:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RewardCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
