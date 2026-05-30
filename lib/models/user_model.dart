import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

part 'user_model.g.dart';

@immutable
@HiveType(typeId: 5)
class UserModel {
  const UserModel({
    required this.id,
    required this.username,
    required this.xp,
    required this.level,
    required this.currentStreak,
    required this.longestStreak,
    required this.avatarLetter,
    required this.createdAt,
    required this.lastActiveAt,
    this.bedtime,
    this.preferences = const <String, dynamic>{},
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String username;

  /// Preferred bedtime used by reminders/scheduling layers.
  @HiveField(2)
  final DateTime? bedtime;

  @HiveField(3)
  final int xp;

  @HiveField(4)
  final int level;

  @HiveField(5)
  final int currentStreak;

  @HiveField(6)
  final int longestStreak;

  /// Single-letter profile avatar fallback (for example: A).
  @HiveField(7)
  final String avatarLetter;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime lastActiveAt;

  /// Extensible settings/preferences storage for future options.
  @HiveField(10)
  final Map<String, dynamic> preferences;

  UserModel copyWith({
    String? id,
    String? username,
    DateTime? bedtime,
    int? xp,
    int? level,
    int? currentStreak,
    int? longestStreak,
    String? avatarLetter,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    Map<String, dynamic>? preferences,
    bool clearBedtime = false,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      bedtime: clearBedtime ? null : (bedtime ?? this.bedtime),
      xp: xp ?? this.xp,
      level: level ?? this.level,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      avatarLetter: avatarLetter ?? this.avatarLetter,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      preferences: preferences ?? this.preferences,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'bedtime': bedtime?.toIso8601String(),
      'xp': xp,
      'level': level,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'avatarLetter': avatarLetter,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
      'preferences': preferences,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      username: map['username'] as String,
      bedtime: map['bedtime'] != null
          ? DateTime.parse(map['bedtime'] as String)
          : null,
      xp: map['xp'] as int? ?? 0,
      level: map['level'] as int? ?? 1,
      currentStreak: map['currentStreak'] as int? ?? 0,
      longestStreak: map['longestStreak'] as int? ?? 0,
      avatarLetter: map['avatarLetter'] as String? ?? 'U',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      lastActiveAt: map['lastActiveAt'] != null
          ? DateTime.parse(map['lastActiveAt'] as String)
          : DateTime.now(),
      preferences: (map['preferences'] as Map<dynamic, dynamic>?)?.map(
            (key, value) => MapEntry(key.toString(), value),
          ) ??
          const <String, dynamic>{},
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is UserModel &&
        other.id == id &&
        other.username == username &&
        other.bedtime == bedtime &&
        other.xp == xp &&
        other.level == level &&
        other.currentStreak == currentStreak &&
        other.longestStreak == longestStreak &&
        other.avatarLetter == avatarLetter &&
        other.createdAt == createdAt &&
        other.lastActiveAt == lastActiveAt &&
        mapEquals(other.preferences, preferences);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      username,
      bedtime,
      xp,
      level,
      currentStreak,
      longestStreak,
      avatarLetter,
      createdAt,
      lastActiveAt,
      Object.hashAll(
        preferences.entries.map((entry) => Object.hash(entry.key, entry.value)),
      ),
    );
  }
}
