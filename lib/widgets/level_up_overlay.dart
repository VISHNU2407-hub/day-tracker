import 'package:flutter/material.dart';
import 'package:habit_up/providers/goal_provider.dart';
import 'package:habit_up/services/user_storage_service.dart';
import 'package:habit_up/services/xp_streak_service.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/widgets/user_avatar.dart';
import 'package:provider/provider.dart';

/// Non-visual overlay widget that watches [XpStreakService] for level-up
/// events and shows an immersive celebration dialog when the user levels up.
///
/// Must be placed as a descendant of the [XpStreakService] provider so it
/// can listen for changes.
class LevelUpOverlay extends StatefulWidget {
  const LevelUpOverlay({required this.child, super.key});

  final Widget child;

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay> {
  int _lastCheckedLevel = 1;

  @override
  Widget build(BuildContext context) {
    final xpService = context.watch<XpStreakService>();
    final pendingLevel = xpService.consumePendingLevelUp();

    // Schedule the popup to show after the current frame, so the provider
    // state is fully settled and no "setState during build" errors occur.
    if (pendingLevel != null && pendingLevel > _lastCheckedLevel) {
      _lastCheckedLevel = pendingLevel;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showLevelUpDialog(pendingLevel);
        }
      });
    }

    return widget.child;
  }

  void _showLevelUpDialog(int newLevel) {
    // Load user prefs for avatar display
    UserStorageService().getCurrentUser().then((user) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return _LevelUpDialogContent(
            newLevel: newLevel,
            levelTitle: _levelTitle(newLevel),
            preferences: user?.preferences,
            username: user?.username ?? 'User',
          );
        },
      );
    });
  }

  String _levelTitle(int level) {
    if (level >= 50) return 'Grandmaster';
    if (level >= 30) return 'Master';
    if (level >= 20) return 'Veteran';
    if (level >= 10) return 'Elite';
    if (level >= 5) return 'Advanced';
    return 'Rising Star';
  }
}

class _LevelUpDialogContent extends StatefulWidget {
  const _LevelUpDialogContent({
    required this.newLevel,
    required this.levelTitle,
    this.preferences,
    this.username = 'User',
  });

  final int newLevel;
  final String levelTitle;
  final Map<String, dynamic>? preferences;
  final String username;

  @override
  State<_LevelUpDialogContent> createState() => _LevelUpDialogContentState();
}

class _LevelUpDialogContentState extends State<_LevelUpDialogContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final goalProvider = context.watch<GoalProvider>();
    final pinned = goalProvider.pinnedGoal;

    return PopScope(
      canPop: false,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Opacity(
            opacity: _opacityAnim.value,
            child: Material(
              color: Colors.black54,
              child: Stack(
                children: [
                  // Animated background glow
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: const <Color>[
                              Color(0x30FFD700),
                              Color(0x0A00E5FF),
                              Color(0x00000000),
                            ],
                            stops: const <double>[0.3, 0.6, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Centered content
                  Center(
                    child: Transform.scale(
                      scale: _scaleAnim.value,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              Color(0xFF1A2645),
                              Color(0xFF0F172B),
                            ],
                          ),
                          border: Border.all(
                            color: AppColors.neonCyan.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x404D7CFF),
                              blurRadius: 40,
                              spreadRadius: -10,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Avatar or fallback level icon
                            SizedBox(
                              width: 72,
                              height: 72,
                              child: UserAvatar(
                                preferences: widget.preferences,
                                fallbackLetter: widget.username.isNotEmpty ? widget.username[0] : 'U',
                                size: 72,
                                glowColor: const Color(0xFFFFD700),
                                borderColor: const Color(0xFFFFD700).withValues(alpha: 0.4),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Level up text
                            Text(
                              'LEVEL UP!',
                              style: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppColors.neonCyan,
                                letterSpacing: 2,
                                fontSize: 28,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'You reached Level ${widget.newLevel}',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(99),
                                gradient: const LinearGradient(
                                  colors: <Color>[
                                    Color(0x30FFD700),
                                    Color(0x30FF8C00),
                                  ],
                                ),
                                border: Border.all(
                                  color: const Color(0x60FFD700),
                                ),
                              ),
                              child: Text(
                                widget.levelTitle,
                                style: textTheme.labelLarge?.copyWith(
                                  color: const Color(0xFFFFD700),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (pinned != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                'Keep pushing toward\n"${pinned.title}"',
                                textAlign: TextAlign.center,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.neonCyan.withValues(alpha: 0.15),
                                  foregroundColor: AppColors.neonCyan,
                                  side: BorderSide(
                                    color: AppColors.neonCyan.withValues(alpha: 0.4),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text(
                                  'LET\'S GO',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
