import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Key used to store the theme mode preference in [UserModel.preferences].
const String themeModePrefKey = 'theme_mode';

/// Parses a [ThemeMode] from a stored string value.
///
/// Defaults to [ThemeMode.dark] if the value is null or unknown.
ThemeMode themeModeFromString(String? value) {
  switch (value) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    case 'system':
      return ThemeMode.system;
    default:
      return ThemeMode.dark;
  }
}

/// Converts a [ThemeMode] to its string representation for persistence.
String themeModeToString(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.system:
      return 'system';
  }
}

/// Provider that exposes the current [ThemeMode] and allows changing it.
///
/// The initial value is [ThemeMode.dark]. Call [setThemeMode] to change it
/// at runtime — this will also persist the choice via the user provider.
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark);

  /// Update the theme mode and persist it.
  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}
