import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habit_up/screens/profile/widgets/avatar_options.dart';
import 'package:habit_up/theme/app_colors.dart';

/// Renders the user's premium avatar from stored preferences using the
/// actual image asset (PNG or SVG). Falls back to a gradient circle with
/// the fallback letter if no avatar is configured or the asset fails.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.preferences,
    this.fallbackLetter = 'U',
    this.size = 44,
    this.glowColor,
    this.borderColor,
    this.onTap,
  });

  /// User preferences map (from [UserModel.preferences]).
  final Map<String, dynamic>? preferences;

  /// Letter shown when no avatar_id is configured.
  final String fallbackLetter;

  /// Diameter of the avatar circle.
  final double size;

  /// Optional glow color — defaults to [AppColors.neonCyan].
  final Color? glowColor;

  /// Optional border color — defaults to a semi-transparent neon cyan.
  final Color? borderColor;

  /// Optional tap callback to navigate to profile or similar.
  final VoidCallback? onTap;

  String get _avatarId => (preferences?['avatar_id'] as String?) ?? '';

  bool get _hasAvatar => _avatarId.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final letter = fallbackLetter.isNotEmpty ? fallbackLetter[0].toUpperCase() : 'U';
    final glow = glowColor ?? AppColors.neonCyan;
    final border = borderColor ?? AppColors.neonCyan.withValues(alpha: 0.3);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _hasAvatar ? border : Colors.white.withValues(alpha: 0.15),
              width: _hasAvatar ? 2.0 : 1.0,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: glow.withValues(alpha: _hasAvatar ? 0.20 : 0.10),
                blurRadius: _hasAvatar ? 16 : 12,
                spreadRadius: _hasAvatar ? -2 : -4,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          alignment: Alignment.center,
          child: _hasAvatar ? _buildAvatarImage(glow) : _buildFallbackLetter(letter, glow),
        ),
      ),
    );
  }

  /// Renders the avatar image asset (PNG or SVG) inside the circular clip.
  Widget _buildAvatarImage(Color glow) {
    final option = avatarOptionById(_avatarId);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradient fallback shown behind the image (visible during load)
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                option.fallbackColorA,
                option.fallbackColorB,
              ],
            ),
          ),
        ),
        // Actual image asset
        if (option.assetPath.endsWith('.svg'))
          SvgPicture.asset(
            option.assetPath,
            width: size,
            height: size,
            fit: BoxFit.cover,
          )
        else
          Image.asset(
            option.assetPath,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildFallbackGradient(option),
          ),
      ],
    );
  }

  /// Full gradient fallback — used when the image asset fails to load.
  Widget _buildFallbackGradient(AvatarOption option) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[option.fallbackColorA, option.fallbackColorB],
        ),
      ),
      alignment: Alignment.center,
    );
  }

  /// Fallback letter inside a dark gradient circle (no avatar configured).
  Widget _buildFallbackLetter(String letter, Color glow) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF293353), Color(0xFF1A223E)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: size * 0.45,
          fontWeight: FontWeight.w700,
          color: AppColors.neonCyan,
        ),
      ),
    );
  }
}
