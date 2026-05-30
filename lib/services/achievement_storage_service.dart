import 'package:habit_up/models/achievement_model.dart';
import 'package:habit_up/storage/hive_boxes.dart';
import 'package:hive/hive.dart';

class AchievementStorageService {
  const AchievementStorageService();

  Box<AchievementModel> get _achievementBox => HiveBoxManager.achievementBox;

  Future<void> saveAchievement(AchievementModel achievement) async {
    await _achievementBox.put(achievement.id, achievement);
  }

  Future<List<AchievementModel>> getAllAchievements() async {
    return _achievementBox.values.toList(growable: false);
  }

  Future<AchievementModel?> getAchievementById(String id) async {
    return _achievementBox.get(id);
  }

  Future<void> updateAchievement(AchievementModel achievement) async {
    await _achievementBox.put(achievement.id, achievement);
  }

  Future<void> deleteAchievement(String id) async {
    await _achievementBox.delete(id);
  }

  Future<void> clearAllAchievements() async {
    await _achievementBox.clear();
  }

  Future<bool> achievementExists(String id) async {
    return _achievementBox.containsKey(id);
  }

  Future<List<AchievementModel>> getUnlockedAchievements() async {
    return _achievementBox.values
        .where((AchievementModel achievement) => achievement.isUnlocked)
        .toList(growable: false);
  }

  Future<List<AchievementModel>> getLockedAchievements() async {
    return _achievementBox.values
        .where((AchievementModel achievement) => !achievement.isUnlocked)
        .toList(growable: false);
  }

  Future<bool> updateAchievementProgress(String id, double progress) async {
    final AchievementModel? existingAchievement = _achievementBox.get(id);
    if (existingAchievement == null) {
      return false;
    }

    final double normalizedProgress = _normalizeProgress(progress);
    final bool shouldUnlock =
        normalizedProgress >= 1.0 || existingAchievement.isUnlocked;

    final AchievementModel updatedAchievement = existingAchievement.copyWith(
      progress: normalizedProgress,
      isUnlocked: shouldUnlock,
      unlockedAt: shouldUnlock
          ? (existingAchievement.unlockedAt ?? DateTime.now())
          : null,
      clearUnlockedAt: !shouldUnlock,
      updatedAt: DateTime.now(),
    );

    await _achievementBox.put(id, updatedAchievement);
    return true;
  }

  Future<bool> unlockAchievement(String id) async {
    final AchievementModel? existingAchievement = _achievementBox.get(id);
    if (existingAchievement == null) {
      return false;
    }

    final AchievementModel updatedAchievement = existingAchievement.copyWith(
      isUnlocked: true,
      progress: 1.0,
      unlockedAt: existingAchievement.unlockedAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _achievementBox.put(id, updatedAchievement);
    return true;
  }

  double _normalizeProgress(double progress) {
    if (progress < 0.0) {
      return 0.0;
    }

    if (progress > 1.0) {
      return 1.0;
    }

    return progress;
  }
}
