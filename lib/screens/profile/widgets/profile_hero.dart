import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habit_up/models/user_model.dart';
import 'package:habit_up/providers/user_provider.dart';
import 'package:habit_up/screens/profile/widgets/avatar_options.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/theme/app_spacing.dart';
import 'package:habit_up/theme/app_text_styles.dart';

/// XP per level constant matching XpStreakService.xpPerLevel.
const int _xpPerLevel = 500;

/// Premium futuristic hero card showing the user's identity, level, and XP.
class ProfileHero extends ConsumerWidget {
  const ProfileHero({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      data: (user) => user != null ? _buildHero(context, user) : _buildEmpty(),
      loading: () => _buildShimmer(),
      error: (err, _) => _buildEmpty(),
    );
  }

  Widget _buildHero(BuildContext context, UserModel user) {
    final avatarId = (user.preferences['avatar_id'] as String?) ?? '';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF11172B),
            Color(0xFF0D1320),
          ],
        ),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonCyan.withValues(alpha: 0.06),
            blurRadius: 20,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Avatar + Name ──────────────────────────────────────────
          Row(
            children: [
              // Premium avatar circle with real image asset
              _buildAvatarCircle(avatarId),
              const SizedBox(width: AppSpacing.md),
              // Name + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Discipline today, success tomorrow.',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary.withValues(alpha: 0.75),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Level Badge ─────────────────────────────────────────────
          Row(
            children: [
              _LevelBadge(level: user.level),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _levelTitle(user.level),
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── XP Progress Bar ─────────────────────────────────────────
          _XpProgressBar(xp: user.xp),
        ],
      ),
    );
  }

  /// Renders the avatar as a real image asset (PNG/SVG) inside a glowing
  /// circular container with gradient fallback on error.
  Widget _buildAvatarCircle(String avatarId) {
    final hasAvatar = avatarId.isNotEmpty;
    final option = hasAvatar ? avatarOptionById(avatarId) : null;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.neonCyan.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonCyan.withValues(alpha: 0.15),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: hasAvatar && option != null
          ? _buildAssetImage(option)
          : _buildFallbackCircle(),
    );
  }

  /// Renders the avatar image (PNG via Image.asset, SVG via SvgPicture).
  Widget _buildAssetImage(AvatarOption option) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradient fallback visible during load
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[option.fallbackColorA, option.fallbackColorB],
            ),
          ),
        ),
        // Actual image
        if (option.assetPath.endsWith('.svg'))
          SvgPicture.asset(
            option.assetPath,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
          )
        else
          Image.asset(
            option.assetPath,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
      ],
    );
  }

  /// Dark fallback circle when no avatar is configured.
  Widget _buildFallbackCircle() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF293353), Color(0xFF1A223E)],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF11172B),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: Text(
          'No profile data',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF11172B),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  String _levelTitle(int level) {
    if (level <= 2) return 'Beginner';
    if (level <= 5) return 'Rising Star';
    if (level <= 8) return 'Focused Achiever';
    if (level <= 12) return 'Productivity Pro';
    if (level <= 16) return 'Elite Performer';
    return 'Grand Master';
  }
}

/// Compact level badge chip.
class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF4D7CFF),
            Color(0xFF6C5CE7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4D7CFF).withValues(alpha: 0.25),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Text(
        'Lv. $level',
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Slim XP progress bar with labels.
class _XpProgressBar extends StatelessWidget {
  const _XpProgressBar({required this.xp});

  final int xp;

  @override
  Widget build(BuildContext context) {
    final progress = _xpPerLevel > 0 ? (xp % _xpPerLevel) / _xpPerLevel : 0.0;
    final currentLevelXp = xp % _xpPerLevel;
    final clamped = progress.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'XP Progress',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
            Text(
              '$currentLevelXp / $_xpPerLevel XP',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.neonCyan.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Progress bar track
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: 6,
            backgroundColor: const Color(0xFF1E2740),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.neonCyan),
          ),
        ),
      ],
    );
  }
}
