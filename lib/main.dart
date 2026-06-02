import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';import 'package:habit_up/models/user_model.dart';
import 'package:habit_up/providers/goal_provider.dart';
import 'package:habit_up/providers/sub_goal_provider.dart';
import 'package:habit_up/providers/task_provider.dart';
import 'package:habit_up/routes/app_router.dart';
import 'package:habit_up/routes/app_routes.dart';
import 'package:habit_up/screens/splash/splash_screen.dart';
import 'package:habit_up/services/alarm_manager_service.dart';
import 'package:habit_up/services/bedtime_alarm_scheduler.dart';
import 'package:habit_up/services/reminder_scheduling_service.dart';
import 'package:habit_up/services/user_storage_service.dart';
import 'package:habit_up/storage/hive_bootstrap.dart';
import 'package:habit_up/theme/app_theme.dart';
import 'package:habit_up/widgets/alarm_system_initializer.dart';
import 'package:habit_up/widgets/bedtime_planner_initializer.dart';
import 'package:habit_up/widgets/fullscreen_loading_overlay.dart';
import 'package:habit_up/widgets/hierarchy_cascade_initializer.dart';
import 'package:habit_up/widgets/level_up_overlay.dart';
import 'package:habit_up/widgets/native_alarm_overlay.dart';
import 'package:provider/provider.dart' as provider_pkg;

/// Global navigator key so [main] and widgets in the [MaterialApp.builder]
/// (which sit above the Navigator) can access the Navigator state.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Published by [main] to drive the splash screen's loading stage display.
final ValueNotifier<int> _splashProgress = ValueNotifier<int>(0);

/// Global loading state for root-level fullscreen loading overlay.
final ValueNotifier<bool> _globalLoading = ValueNotifier<bool>(false);

/// Global loading message for root-level fullscreen loading overlay.
final ValueNotifier<String?> _globalLoadingMessage = ValueNotifier<String?>(
  null,
);

/// Completer that resolves when the splash screen's crossfade-out animation
/// finishes, allowing [main] to navigate to the destination route smoothly.
final Completer<void> _splashTransitionCompleter = Completer<void>();

Future<void> main() async {
  // ---------------------------------------------------------------------------
  // Global error handlers — production crash protection
  // ---------------------------------------------------------------------------

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    return true;
  };

  WidgetsFlutterBinding.ensureInitialized();

  // ── Step 1: CRITICAL - Initialize Hive BEFORE runApp ─────────────────
  // This ensures storage is ready before providers try to hydrate data.
  // Fixes the bug where tasks disappear on app restart.
  await HiveBootstrap.initialize();

  // ── Step 2: Render the splash screen immediately ─────────────────────
  // Call runApp() AFTER Hive is initialized so providers can safely hydrate.
  runApp(
    ProviderScope(
      child: provider_pkg.MultiProvider(
        providers: [
          provider_pkg.ChangeNotifierProvider<TaskProvider>(
            create: (_) {
              final provider = TaskProvider();
              ReminderSchedulingService.instance.attach(provider);
              unawaited(
                provider.initialize().then((_) {
                  return ReminderSchedulingService.instance.syncAll(
                    provider.allTasks,
                  );
                }),
              );
              return provider;
            },
          ),
          provider_pkg.ChangeNotifierProvider<GoalProvider>(
            create: (_) => GoalProvider()..initialize(),
          ),
          provider_pkg.ChangeNotifierProvider<SubGoalProvider>(
            create: (_) => SubGoalProvider()..initialize(),
          ),
        ],
        child: HabitUpApp(
          navigatorKey: navigatorKey,
          splashProgress: _splashProgress,
          onSplashTransitionComplete: _splashTransitionCompleter.complete,
        ),
      ),
    ),
  );

  unawaited(AlarmManagerService.instance.initialize());

  // ── Step 3: Async initialization with splash stage updates ──────────
  // Each stage advances the progress notifier so the SplashScreen crossfades
  // to the next loading message.
  try {
    // Stage 0 "Opening the app" is the initial value — let it breathe.
    // We spread the delays across stages so the "DAY TRACKER" branding is
    // visible for at least ~3s before the crossfade-out animation starts.
    await Future<void>.delayed(const Duration(milliseconds: 800));
    _splashProgress.value = 1; // "Loading your data"

    await Future<void>.delayed(const Duration(milliseconds: 700));
    _splashProgress.value = 2; // "Preparing notifications"

    // Read user profile while storage is hot.
    UserModel? user;
    try {
      user = await const UserStorageService().getCurrentUser();
    } catch (_) {
      user = null;
    }

    await Future<void>.delayed(const Duration(milliseconds: 600));
    _splashProgress.value = 3; // "Almost ready"

    await Future<void>.delayed(const Duration(milliseconds: 700));
    _splashProgress.value = 4; // Crossfade-out starts (~2800ms total delay)

    // ── Step 3: Ensure the daily bedtime alarm is scheduled ───────────
    // This happens during the 600ms crossfade-out so the user sees the
    // DAY TRACKER branding fades smoothly while background work completes.
    try {
      final bedtimeReminderEnabled =
          user?.preferences['bedtime_reminder_enabled'] != false;
      if (bedtimeReminderEnabled) {
        await BedtimeAlarmScheduler().schedule(bedtimeOverride: user?.bedtime);
      } else {
        await BedtimeAlarmScheduler().cancel();
      }
    } catch (_) {
    }

    // ── Step 4: Wait for the splash crossfade-out animation ────────────
    // The animation was started when progress reached 4. Wait for it
    // to finish before navigating so the transition is smooth.
    await _splashTransitionCompleter.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {/* timeout — navigate anyway */},
    );

    // ── Step 5: Navigate away from splash ───────────────────────────────
    final onboardingCompleted =
        user?.preferences['onboarding_completed'] == true;
    final destination = onboardingCompleted
        ? AppRoutes.initial
        : AppRoutes.onboarding;

    await navigatorKey.currentState?.pushNamedAndRemoveUntil(
      destination,
      (_) => false,
    );
  } catch (_) {
    // Ensure the splash transition doesn't hang if initialization fails.
    if (!_splashTransitionCompleter.isCompleted) {
      _splashTransitionCompleter.complete();
    }
    // Navigate to onboarding as safe fallback even on error.
    try {
      await navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.onboarding,
        (_) => false,
      );
    } catch (_) {}
  }
}

class HabitUpApp extends ConsumerStatefulWidget {
  const HabitUpApp({
    required this.navigatorKey,
    required this.splashProgress,
    this.onSplashTransitionComplete,
    super.key,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final ValueNotifier<int> splashProgress;
  final VoidCallback? onSplashTransitionComplete;

  @override
  ConsumerState<HabitUpApp> createState() => _HabitUpAppState();
}

class _HabitUpAppState extends ConsumerState<HabitUpApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: widget.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Habit Up',
      theme: AppTheme.dark, // Always dark mode
      home: SplashScreen(
        progress: widget.splashProgress,
        onTransitionComplete: widget.onSplashTransitionComplete,
      ),
      onGenerateRoute: AppRouter.onGenerateRoute,
      // ---- Runtime-safe error boundary ----
      builder: (context, child) {
        return FullscreenLoadingOverlay(
          isLoading: _globalLoading.value,
          message: _globalLoadingMessage.value,
          child: _RuntimeSafeApp(
            child: NativeAlarmOverlay(
              service: AlarmManagerService.instance,
              child: HierarchyCascadeInitializer(
                child: AlarmSystemInitializer(
                  child: BedtimePlannerInitializer(
                    child: LevelUpOverlay(child: child!),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Thin wrapper that replaces Flutter's default red error screen with a
/// safe fallback so the app stays running even if a widget throws during
/// build.
class _RuntimeSafeApp extends StatefulWidget {
  const _RuntimeSafeApp({required this.child});
  final Widget child;

  @override
  State<_RuntimeSafeApp> createState() => _RuntimeSafeAppState();
}

class _RuntimeSafeAppState extends State<_RuntimeSafeApp> {
  @override
  void initState() {
    super.initState();
    // Replace the default ErrorWidget (red screen) with a subtle fallback.
    ErrorWidget.builder = (FlutterErrorDetails details) {
      // In debug mode, still show the error for development visibility.
      if (kDebugMode) {
        return ErrorWidget(details.exception);
      }
      // In release, show a non-intrusive dark fallback so the app keeps
      // running and the user can navigate away from the broken screen.
      return Material(
        color: const Color(0xFF060810),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: Color(0x44FFFFFF),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Something went wrong',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This screen couldn\'t be loaded. Try restarting the app.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    };
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
