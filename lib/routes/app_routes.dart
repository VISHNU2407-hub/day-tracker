abstract final class AppRoutes {
  static const String tasks = '/tasks';
  static const String goals = '/goals';
  static const String calendar = '/calendar';
  static const String friends = '/friends';

  // Profile & Onboarding routes.
  static const String profileHub = '/profile-hub';
  static const String onboarding = '/onboarding';

  // Backward-compat aliases for previous route names.
  static const String home = tasks;
  static const String profile = friends;

  static const String initial = tasks;
}
