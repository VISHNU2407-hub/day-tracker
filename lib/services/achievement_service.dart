import 'package:flutter/foundation.dart';
import 'package:habit_up/models/achievement_model.dart';
import 'package:habit_up/providers/goal_provider.dart';
import 'package:habit_up/providers/task_provider.dart';
import 'package:habit_up/services/achievement_storage_service.dart';
import 'package:habit_up/services/xp_streak_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Achievement Template Definitions
// ═══════════════════════════════════════════════════════════════════════════════

/// Lightweight descriptor used to seed achievements into Hive.
class _AchievementTemplate {
  const _AchievementTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.iconKey,
    required this.threshold,
    this.xpReward = 25,
  });

  final String id;
  final String title;
  final String description;
  final AchievementCategory category;
  final String iconKey;
  final int threshold;
  final int xpReward;
}

/// All 19 achievement definitions.
const List<_AchievementTemplate> _templates = [
  // ── Streak Achievements ────────────────────────────────────────────────
  _AchievementTemplate(
    id: 'streak_1',
    title: 'First Spark',
    description: 'Maintain a 1-day streak',
    category: AchievementCategory.streak,
    iconKey: 'spark',
    threshold: 1,
    xpReward: 10,
  ),
  _AchievementTemplate(
    id: 'streak_7',
    title: 'Consistent',
    description: 'Maintain a 7-day streak',
    category: AchievementCategory.streak,
    iconKey: 'whatshot',
    threshold: 7,
    xpReward: 50,
  ),
  _AchievementTemplate(
    id: 'streak_30',
    title: 'Unstoppable',
    description: 'Maintain a 30-day streak',
    category: AchievementCategory.streak,
    iconKey: 'bolt',
    threshold: 30,
    xpReward: 100,
  ),
  _AchievementTemplate(
    id: 'streak_100',
    title: 'Iron Discipline',
    description: 'Maintain a 100-day streak',
    category: AchievementCategory.streak,
    iconKey: 'military_tech',
    threshold: 100,
    xpReward: 250,
  ),
  _AchievementTemplate(
    id: 'streak_365',
    title: 'Legend',
    description: 'Maintain a 365-day streak',
    category: AchievementCategory.streak,
    iconKey: 'diamond',
    threshold: 365,
    xpReward: 500,
  ),

  // ── Task Achievements ──────────────────────────────────────────────────
  _AchievementTemplate(
    id: 'task_1',
    title: 'First Win',
    description: 'Complete 1 task',
    category: AchievementCategory.task,
    iconKey: 'check_circle',
    threshold: 1,
    xpReward: 10,
  ),
  _AchievementTemplate(
    id: 'task_25',
    title: 'Getting Started',
    description: 'Complete 25 tasks',
    category: AchievementCategory.task,
    iconKey: 'trending_up',
    threshold: 25,
    xpReward: 50,
  ),
  _AchievementTemplate(
    id: 'task_100',
    title: 'Productive',
    description: 'Complete 100 tasks',
    category: AchievementCategory.task,
    iconKey: 'star',
    threshold: 100,
    xpReward: 100,
  ),
  _AchievementTemplate(
    id: 'task_500',
    title: 'Task Crusher',
    description: 'Complete 500 tasks',
    category: AchievementCategory.task,
    iconKey: 'auto_awesome',
    threshold: 500,
    xpReward: 250,
  ),
  _AchievementTemplate(
    id: 'task_1000',
    title: 'Completion King',
    description: 'Complete 1000 tasks',
    category: AchievementCategory.task,
    iconKey: 'emoji_events',
    threshold: 1000,
    xpReward: 500,
  ),

  // ── XP Achievements ────────────────────────────────────────────────────
  _AchievementTemplate(
    id: 'xp_100',
    title: 'Rookie',
    description: 'Earn 100 XP',
    category: AchievementCategory.xp,
    iconKey: 'local_fire_department',
    threshold: 100,
    xpReward: 10,
  ),
  _AchievementTemplate(
    id: 'xp_500',
    title: 'Dedicated',
    description: 'Earn 500 XP',
    category: AchievementCategory.xp,
    iconKey: 'whatshot',
    threshold: 500,
    xpReward: 50,
  ),
  _AchievementTemplate(
    id: 'xp_1000',
    title: 'Achiever',
    description: 'Earn 1000 XP',
    category: AchievementCategory.xp,
    iconKey: 'star',
    threshold: 1000,
    xpReward: 100,
  ),
  _AchievementTemplate(
    id: 'xp_5000',
    title: 'Elite',
    description: 'Earn 5000 XP',
    category: AchievementCategory.xp,
    iconKey: 'military_tech',
    threshold: 5000,
    xpReward: 250,
  ),
  _AchievementTemplate(
    id: 'xp_10000',
    title: 'Master Tracker',
    description: 'Earn 10000 XP',
    category: AchievementCategory.xp,
    iconKey: 'diamond',
    threshold: 10000,
    xpReward: 500,
  ),

  // ── Goal Achievements ──────────────────────────────────────────────────
  _AchievementTemplate(
    id: 'goal_1',
    title: 'Goal Setter',
    description: 'Create 1 goal',
    category: AchievementCategory.goalCompletion,
    iconKey: 'flag',
    threshold: 1,
    xpReward: 10,
  ),
  _AchievementTemplate(
    id: 'goal_10',
    title: 'Mission Control',
    description: 'Create 10 goals',
    category: AchievementCategory.goalCompletion,
    iconKey: 'rocket_launch',
    threshold: 10,
    xpReward: 50,
  ),
  _AchievementTemplate(
    id: 'goal_5_completed',
    title: 'Goal Hunter',
    description: 'Complete 5 goals',
    category: AchievementCategory.goalCompletion,
    iconKey: 'checklist',
    threshold: 5,
    xpReward: 100,
  ),
  _AchievementTemplate(
    id: 'goal_25_completed',
    title: 'Goal Champion',
    description: 'Complete 25 goals',
    category: AchievementCategory.goalCompletion,
    iconKey: 'emoji_events',
    threshold: 25,
    xpReward: 250,
  ),
];

// ═══════════════════════════════════════════════════════════════════════════════
// Public View Model for the UI
// ═══════════════════════════════════════════════════════════════════════════════

enum AchievementStatus { locked, inProgress, unlocked }

class AchievementViewModel {
  const AchievementViewModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.iconKey,
    required this.xpReward,
    required this.progress,
    required this.progressLabel,
    required this.isUnlocked,
    required this.status,
    required this.threshold,
  });

  final String id;
  final String title;
  final String description;
  final AchievementCategory category;
  final String iconKey;
  final int xpReward;
  final double progress;
  final String progressLabel;
  final bool isUnlocked;
  final AchievementStatus status;
  final int threshold;

  String get progressPercent => '${(progress * 100).toInt()}%';
}

// ═══════════════════════════════════════════════════════════════════════════════
// AchievementService — Reactive Achievement Engine
// ═══════════════════════════════════════════════════════════════════════════════

/// Reactive service that:
/// 1. Seeds all 19 achievement definitions into Hive on first run.
/// 2. Computes progress for every achievement from live data (tasks, XP, streaks, goals).
/// 3. Auto-unlocks achievements when thresholds are crossed.
/// 4. Exposes a cached list of [AchievementViewModel] for the UI.
class AchievementService extends ChangeNotifier {
  AchievementService({
    required TaskProvider taskProvider,
    required GoalProvider goalProvider,
    required XpStreakService xpStreakService,
    AchievementStorageService? storageService,
  })  : _taskProvider = taskProvider,
        _goalProvider = goalProvider,
        _xpStreakService = xpStreakService,
        _storageService = storageService ?? const AchievementStorageService();

  final TaskProvider _taskProvider;
  final GoalProvider _goalProvider;
  final XpStreakService _xpStreakService;
  final AchievementStorageService _storageService;

  bool _initialized = false;

  bool _disposed = false;

  bool get isInitialized => _initialized;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Seed achievements (if empty) and wire reactive listeners.
  Future<void> initialize() async {
    if (_initialized) return;

    await _seedIfEmpty();
    _wireListeners();

    _initialized = true;
    await _recomputeAll();
    notifyListeners();
  }

  Future<void> _seedIfEmpty() async {
    final existing = await _storageService.getAllAchievements();
    if (existing.isNotEmpty) return;

    final now = DateTime.now();
    for (final t in _templates) {
      await _storageService.saveAchievement(
        AchievementModel(
          id: t.id,
          title: t.title,
          description: t.description,
          category: t.category,
          xpReward: t.xpReward,
          isUnlocked: false,
          progress: 0.0,
          createdAt: now,
          updatedAt: now,
          iconKey: t.iconKey,
          rewardCategory: _rewardCategoryFor(t.category),
        ),
      );
    }
  }

  void _wireListeners() {
    _taskProvider.addListener(_onSourceChanged);
    _goalProvider.addListener(_onSourceChanged);
    _xpStreakService.addListener(_onSourceChanged);
  }

  // ---------------------------------------------------------------------------
  // Reactivity
  // ---------------------------------------------------------------------------

  void _onSourceChanged() {
    if (_disposed) return;
    _recomputeAll();
  }

  Future<void> _recomputeAll() async {
    if (!_initialized) return;

    final all = await _storageService.getAllAchievements();
    if (all.isEmpty) return;

    final currentStreak = _xpStreakService.snapshot.currentStreak;
    final totalXp = _xpStreakService.snapshot.totalXp;
    final completedTasks = _taskProvider.completedTasks.length;
    final totalGoals = _goalProvider.allGoals.length;
    final completedGoals = _goalProvider.completedGoals.length;

    var changed = false;

    for (final achievement in all) {
      final template = _templateIndex[achievement.id];
      if (template == null) continue;

      final double rawProgress;

      switch (template.category) {
        case AchievementCategory.streak:
          rawProgress = (currentStreak / template.threshold).clamp(0.0, 1.0);
        case AchievementCategory.task:
          rawProgress = (completedTasks / template.threshold).clamp(0.0, 1.0);
        case AchievementCategory.xp:
          rawProgress = (totalXp / template.threshold).clamp(0.0, 1.0);
        case AchievementCategory.goalCompletion:
          if (template.id == 'goal_5_completed' ||
              template.id == 'goal_25_completed') {
            rawProgress =
                (completedGoals / template.threshold).clamp(0.0, 1.0);
          } else {
            rawProgress =
                (totalGoals / template.threshold).clamp(0.0, 1.0);
          }
        case AchievementCategory.monthly:
        case AchievementCategory.productivity:
          rawProgress = achievement.progress;
      }

      final shouldUnlock = rawProgress >= 1.0 && !achievement.isUnlocked;
      final progressChanged =
          (rawProgress - achievement.progress).abs() > 0.001;

      if (shouldUnlock || progressChanged) {
        changed = true;
        await _storageService.updateAchievementProgress(
          achievement.id,
          rawProgress,
        );
      }
    }

    if (changed) {
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns all achievements as view models for the UI.
  /// Computed from Hive storage (which is kept in sync by [_recomputeAll]).
  Future<List<AchievementViewModel>> getAchievements() async {
    final all = await _storageService.getAllAchievements();
    return all.map(_toViewModel).toList(growable: false);
  }

  /// Returns only unlocked achievements (for the profile strip).
  Future<List<AchievementViewModel>> getUnlockedAchievements() async {
    final all = await _storageService.getAllAchievements();
    return all
        .where((a) => a.isUnlocked)
        .map(_toViewModel)
        .toList(growable: false);
  }

  /// Returns a quick preview: up to 6 achievements for the profile strip,
  /// prioritizing the most recently unlocked, then highest progress.
  Future<List<AchievementViewModel>> getPreviewAchievements() async {
    final all = await _storageService.getAllAchievements();

    // Sort: unlocked (by unlockedAt desc) → in-progress (by progress desc) → locked
    all.sort((a, b) {
      if (a.isUnlocked && !b.isUnlocked) return -1;
      if (!a.isUnlocked && b.isUnlocked) return 1;
      if (a.isUnlocked && b.isUnlocked) {
        return -(a.unlockedAt ?? a.updatedAt)
            .compareTo(b.unlockedAt ?? b.updatedAt);
      }
      return b.progress.compareTo(a.progress);
    });

    return all.take(6).map(_toViewModel).toList(growable: false);
  }

  /// Total unlocked count.
  Future<int> getUnlockedCount() async {
    final all = await _storageService.getAllAchievements();
    return all.where((a) => a.isUnlocked).length;
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _disposed = true;
    _taskProvider.removeListener(_onSourceChanged);
    _goalProvider.removeListener(_onSourceChanged);
    _xpStreakService.removeListener(_onSourceChanged);
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  AchievementViewModel _toViewModel(AchievementModel m) {
    final template = _templateIndex[m.id];
    final threshold = template?.threshold ?? 1;
    final status = m.isUnlocked
        ? AchievementStatus.unlocked
        : m.progress > 0.0
            ? AchievementStatus.inProgress
            : AchievementStatus.locked;

    final label = _progressLabel(m.id, m, threshold);

    return AchievementViewModel(
      id: m.id,
      title: m.title,
      description: m.description ?? '',
      category: m.category,
      iconKey: m.iconKey ?? 'star',
      xpReward: m.xpReward,
      progress: m.progress,
      progressLabel: label,
      isUnlocked: m.isUnlocked,
      status: status,
      threshold: threshold,
    );
  }

  String _progressLabel(
    String id,
    AchievementModel model,
    int threshold,
  ) {
    if (model.isUnlocked) return 'Complete!';
    if (model.progress <= 0.0) return 'Not started';

    final current = _currentValue(id);
    return '$current / $threshold';
  }

  int _currentValue(String id) {
    switch (id) {
      case 'streak_1':
      case 'streak_7':
      case 'streak_30':
      case 'streak_100':
      case 'streak_365':
        return _xpStreakService.snapshot.currentStreak;
      case 'task_1':
      case 'task_25':
      case 'task_100':
      case 'task_500':
      case 'task_1000':
        return _taskProvider.completedTasks.length;
      case 'xp_100':
      case 'xp_500':
      case 'xp_1000':
      case 'xp_5000':
      case 'xp_10000':
        return _xpStreakService.snapshot.totalXp;
      case 'goal_1':
      case 'goal_10':
        return _goalProvider.allGoals.length;
      case 'goal_5_completed':
      case 'goal_25_completed':
        return _goalProvider.completedGoals.length;
      default:
        return 0;
    }
  }

  RewardCategory _rewardCategoryFor(AchievementCategory cat) {
    switch (cat) {
      case AchievementCategory.streak:
        return RewardCategory.streakReward;
      case AchievementCategory.task:
        return RewardCategory.xpReward;
      case AchievementCategory.xp:
        return RewardCategory.xpReward;
      case AchievementCategory.goalCompletion:
        return RewardCategory.goalCompletionReward;
      case AchievementCategory.monthly:
        return RewardCategory.monthlyReward;
      case AchievementCategory.productivity:
        return RewardCategory.streakReward;
    }
  }
}

/// Template lookup by ID — built once.
final Map<String, _AchievementTemplate> _templateIndex =
    Map<String, _AchievementTemplate>.fromIterable(
  _templates,
  key: (t) => (t as _AchievementTemplate).id,
  value: (t) => t as _AchievementTemplate,
);
