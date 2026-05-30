import 'package:flutter/material.dart';
import 'package:habit_up/motion/motion.dart';
import 'package:habit_up/routes/app_routes.dart';
import 'package:habit_up/screens/navigation/main_navigation_screen.dart';
import 'package:habit_up/screens/onboarding/onboarding_screen.dart';
import 'package:habit_up/screens/profile/profile_hub_screen.dart';

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name ?? AppRoutes.initial;

    switch (routeName) {
      case AppRoutes.tasks:
      case AppRoutes.goals:
      case AppRoutes.calendar:
      case AppRoutes.friends:
        return smoothPageRoute<void>(
          MainNavigationScreen(currentRoute: routeName),
        );
      case AppRoutes.profileHub:
        return smoothPageRoute<void>(const ProfileHubScreen());
      case AppRoutes.onboarding:
        return smoothPageRoute<void>(const OnboardingScreen());
      default:
        return smoothPageRoute<void>(
          const MainNavigationScreen(currentRoute: AppRoutes.tasks),
        );
    }
  }
}
