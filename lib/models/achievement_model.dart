import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

part 'achievement_model.g.dart';

@HiveType(typeId: 6)
enum AchievementCategory {
  @HiveField(0)
  streak,
  @HiveField(1)
  xp,
  @HiveField(2)
  monthly,
  @HiveField(3)
  goalCompletion,
  @HiveField(4)
  productivity,
}

@HiveType(typeId: 7)
enum RewardCategory {
  @HiveField(0)
  streakReward,
  @HiveField(1)
  xpReward,
  @HiveField(2)
  monthlyReward,
  @HiveField(3)
  goalCompletionReward,
}

@immutable
@HiveType(typeId: 8)
class AchievementModel {
  const AchievementModel({
    required this.id,
    required this.title,
    required this.category,
    required this.xpReward,
    required this.isUnlocked,
    required this.progress,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.unlockedAt,
    this.iconKey,
    this.rewardCategory,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final AchievementCategory category;

  @HiveField(4)
  final int xpReward;

  @HiveField(5)
  final bool isUnlocked;

  @HiveField(6)
  final DateTime? unlockedAt;

  /// Icon token/key used by UI/icon registry layers.
  @HiveField(7)
  final String? iconKey;

  @HiveField(8)
  final RewardCategory? rewardCategory;

  /// Achievement progress ratio. Expected range: 0.0 to 1.0.
  @HiveField(9)
  final double progress;

  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  final DateTime updatedAt;

  AchievementModel copyWith({
    String? id,
    String? title,
    String? description,
    AchievementCategory? category,
    int? xpReward,
    bool? isUnlocked,
    DateTime? unlockedAt,
    String? iconKey,
    RewardCategory? rewardCategory,
    double? progress,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearDescription = false,
    bool clearUnlockedAt = false,
    bool clearIconKey = false,
    bool clearRewardCategory = false,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      category: category ?? this.category,
      xpReward: xpReward ?? this.xpReward,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: clearUnlockedAt ? null : (unlockedAt ?? this.unlockedAt),
      iconKey: clearIconKey ? null : (iconKey ?? this.iconKey),
      rewardCategory: clearRewardCategory
          ? null
          : (rewardCategory ?? this.rewardCategory),
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'xpReward': xpReward,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'iconKey': iconKey,
      'rewardCategory': rewardCategory?.name,
      'progress': progress,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AchievementModel.fromMap(Map<String, dynamic> map) {
    return AchievementModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      category: AchievementCategory.values.firstWhere(
        (value) => value.name == map['category'],
        orElse: () => AchievementCategory.productivity,
      ),
      xpReward: map['xpReward'] as int? ?? 0,
      isUnlocked: map['isUnlocked'] as bool? ?? false,
      unlockedAt: map['unlockedAt'] != null
          ? DateTime.parse(map['unlockedAt'] as String)
          : null,
      iconKey: map['iconKey'] as String?,
      rewardCategory: map['rewardCategory'] != null
          ? RewardCategory.values.firstWhere(
              (value) => value.name == map['rewardCategory'],
              orElse: () => RewardCategory.xpReward,
            )
          : null,
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
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

    return other is AchievementModel &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.category == category &&
        other.xpReward == xpReward &&
        other.isUnlocked == isUnlocked &&
        other.unlockedAt == unlockedAt &&
        other.iconKey == iconKey &&
        other.rewardCategory == rewardCategory &&
        other.progress == progress &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      category,
      xpReward,
      isUnlocked,
      unlockedAt,
      iconKey,
      rewardCategory,
      progress,
      createdAt,
      updatedAt,
    );
  }
}
