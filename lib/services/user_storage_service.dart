import 'package:habit_up/models/user_model.dart';
import 'package:habit_up/storage/hive_boxes.dart';
import 'package:hive/hive.dart';

class UserStorageService {
  const UserStorageService();

  Box<UserModel> get _userBox => HiveBoxManager.userBox;

  Future<void> saveUserProfile(UserModel user) async {
    await _userBox.put(user.id, user);
  }

  Future<UserModel?> getCurrentUser() async {
    if (_userBox.isEmpty) {
      return null;
    }

    return _userBox.values.first;
  }

  Future<void> updateUserProfile(UserModel user) async {
    await _userBox.put(user.id, user);
  }

  Future<bool> updateXp(int xp) async {
    return _updateCurrentUser((UserModel user) {
      return user.copyWith(
        xp: xp,
        lastActiveAt: DateTime.now(),
      );
    });
  }

  Future<bool> updateLevel(int level) async {
    return _updateCurrentUser((UserModel user) {
      return user.copyWith(
        level: level,
        lastActiveAt: DateTime.now(),
      );
    });
  }

  Future<bool> updateStreaks({
    required int currentStreak,
    required int longestStreak,
  }) async {
    return _updateCurrentUser((UserModel user) {
      return user.copyWith(
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        lastActiveAt: DateTime.now(),
      );
    });
  }

  Future<bool> updateBedtime(DateTime? bedtime) async {
    return _updateCurrentUser((UserModel user) {
      return user.copyWith(
        bedtime: bedtime,
        clearBedtime: bedtime == null,
        lastActiveAt: DateTime.now(),
      );
    });
  }

  Future<bool> updatePreferences(Map<String, dynamic> preferences) async {
    return _updateCurrentUser((UserModel user) {
      final Map<String, dynamic> mergedPreferences = <String, dynamic>{
        ...user.preferences,
        ...preferences,
      };

      return user.copyWith(
        preferences: mergedPreferences,
        lastActiveAt: DateTime.now(),
      );
    });
  }

  Future<bool> updateSettings(Map<String, dynamic> settings) async {
    return updatePreferences(settings);
  }

  Future<void> deleteUserProfile(String id) async {
    await _userBox.delete(id);
  }

  Future<void> clearUserData() async {
    await _userBox.clear();
  }

  Future<bool> userExists(String id) async {
    return _userBox.containsKey(id);
  }

  Future<bool> _updateCurrentUser(
    UserModel Function(UserModel currentUser) update,
  ) async {
    final UserModel? currentUser = await getCurrentUser();
    if (currentUser == null) {
      return false;
    }

    final UserModel updatedUser = update(currentUser);
    await _userBox.put(updatedUser.id, updatedUser);
    return true;
  }
}
