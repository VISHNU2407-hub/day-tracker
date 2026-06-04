import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_up/models/user_model.dart';
import 'package:habit_up/services/user_storage_service.dart';

final Provider<UserStorageService> userStorageServiceProvider =
    Provider<UserStorageService>((Ref ref) {
  return const UserStorageService();
});

final AsyncNotifierProvider<UserNotifier, UserModel?> userProvider =
    AsyncNotifierProvider<UserNotifier, UserModel?>(UserNotifier.new);

class UserNotifier extends AsyncNotifier<UserModel?> {
  UserStorageService get _userStorageService =>
      ref.read(userStorageServiceProvider);

  @override
  Future<UserModel?> build() async {
    return _userStorageService.getCurrentUser();
  }

  Future<void> loadCurrentUser() async {
    await refreshUserData();
  }

  Future<void> refreshUserData() async {
    final previousState = state;
    try {
      state = AsyncValue<UserModel?>.data(
        await _userStorageService.getCurrentUser(),
      );
    } catch (_) {
      state = previousState;
    }
  }

  Future<void> saveUserProfile(UserModel user) async {
    await _runAndRefresh(() => _userStorageService.saveUserProfile(user));
  }

  Future<void> updateUserProfile(UserModel user) async {
    await _runAndRefresh(() => _userStorageService.updateUserProfile(user));
  }

  Future<void> updateXp(int xp) async {
    await _runAndRefresh(() => _userStorageService.updateXp(xp));
  }

  Future<void> updateLevel(int level) async {
    await _runAndRefresh(() => _userStorageService.updateLevel(level));
  }

  Future<void> updateStreaks({
    required int currentStreak,
    required int longestStreak,
  }) async {
    await _runAndRefresh(
      () => _userStorageService.updateStreaks(
        currentStreak: currentStreak,
        longestStreak: longestStreak,
      ),
    );
  }

  Future<void> updateBedtime(DateTime? bedtime) async {
    await _runAndRefresh(() => _userStorageService.updateBedtime(bedtime));
  }

  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    await _runAndRefresh(
      () => _userStorageService.updatePreferences(preferences),
    );
  }

  Future<void> updateSettings(Map<String, dynamic> settings) async {
    await _runAndRefresh(() => _userStorageService.updateSettings(settings));
  }

  Future<void> deleteUserProfile(String id) async {
    await _runAndRefresh(() => _userStorageService.deleteUserProfile(id));
  }

  Future<void> _runAndRefresh(Future<dynamic> Function() action) async {
    // Phase 1: Persist the data. If this fails, keep the current state.
    final previousState = state;
    try {
      await action();
    } catch (_) {
      state = previousState;
      return;
    }

    // Phase 2: Re-read from storage to refresh state.
    // If the persist succeeded, previousState is definitively stale,
    // so never fall back to it here.
    try {
      state = AsyncValue<UserModel?>.data(
        await _userStorageService.getCurrentUser(),
      );
    } catch (_) {
      state = const AsyncValue.loading();
    }
  }
}
