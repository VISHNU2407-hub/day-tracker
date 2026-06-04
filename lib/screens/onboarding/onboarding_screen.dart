import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habit_up/models/user_model.dart';
import 'package:habit_up/motion/motion.dart';
import 'package:habit_up/screens/profile/widgets/avatar_options.dart';
import 'package:habit_up/services/notification_permission_service.dart';
import 'package:habit_up/services/user_storage_service.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/theme/app_spacing.dart';
import 'package:habit_up/theme/app_text_styles.dart';

// ---------------------------------------------------------------------------
// Onboarding Screen — Premium Single-Screen Identity Setup
// ---------------------------------------------------------------------------
// Sections: Welcome → Name Input → Avatar Grid → Bedtime Picker → Continue
// ---------------------------------------------------------------------------

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();
  String _selectedAvatarId = avatarOptions.first.id;
  TimeOfDay _bedtime = const TimeOfDay(hour: 22, minute: 30);
  bool _isSubmitting = false;
  String? _nameError;

  // ── Premium Avatar Catalog ──────────────────────────────────────────────
  // 12 premium image-backed avatars from shared avatar_options.dart.
  List<AvatarOption> get _avatarOptions => avatarOptions;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_clearNameError);
  }

  void _clearNameError() {
    if (_nameError != null) {
      setState(() => _nameError = null);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  // ── Validation ──────────────────────────────────────────────────────────

  bool _validate() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Please enter your name to continue.');
      return false;
    }
    return true;
  }

  // ── Completion ───────────────────────────────────────────────────────────

  Future<void> _completeOnboarding() async {
    if (!_validate()) return;
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final name = _nameController.text.trim();
    final now = DateTime.now();

    final user = UserModel(
      id: 'user_001',
      username: name,
      xp: 0,
      level: 1,
      currentStreak: 0,
      longestStreak: 0,
      avatarLetter: name.isNotEmpty ? name[0].toUpperCase() : 'U',
      createdAt: now,
      lastActiveAt: now,
      bedtime: DateTime(
        now.year,
        now.month,
        now.day,
        _bedtime.hour,
        _bedtime.minute,
      ),
      preferences: {
        'onboarding_completed': true,
        'onboarding_completed_at': now.toIso8601String(),
        'avatar_id': _selectedAvatarId,
        'avatar_label': avatarLabelForId(_selectedAvatarId),
        'bedtime_hour': _bedtime.hour,
        'bedtime_minute': _bedtime.minute,
      },
    );

    await const UserStorageService().saveUserProfile(user);

    if (!mounted) return;

    await NotificationPermissionService().requestAllCriticalPermissions();

    if (!mounted) return;

    HapticUtil.success();

    // Navigate to main app, clearing the stack so onboarding never returns.
    Navigator.of(context).pushNamedAndRemoveUntil('/tasks', (_) => false);
  }

  // ── Bedtime Picker ──────────────────────────────────────────────────────

  Future<void> _pickBedtime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _bedtime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.neonCyan),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _bedtime) {
      setState(() => _bedtime = picked);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF0A0F22),
              Color(0xFF080A12),
              Color(0xFF060810),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              top: AppSpacing.lg,
              bottom: bottomInset > 0
                  ? bottomInset + AppSpacing.lg
                  : AppSpacing.xxl,
            ),
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Section 1: Welcome ──────────────────────────────
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: _WelcomeHeader(),
                ),

                SizedBox(height: AppSpacing.xxl),

                // ── Section 2: Name Input ───────────────────────────
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: _NameInputSection(
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    error: _nameError,
                  ),
                ),

                SizedBox(height: AppSpacing.xxl),

                // ── Section 3: Avatar Grid ──────────────────────────
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: _AvatarSection(
                    options: _avatarOptions,
                    selectedId: _selectedAvatarId,
                    onSelect: (id) => setState(() => _selectedAvatarId = id),
                  ),
                ),

                SizedBox(height: AppSpacing.xxl),

                // ── Section 4: Bedtime Picker ───────────────────────
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: _BedtimeSection(
                    bedtime: _bedtime,
                    onTap: _pickBedtime,
                  ),
                ),

                SizedBox(height: AppSpacing.lg),

                // ── Section 5: Continue Button ──────────────────────
                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  child: _ContinueButton(
                    isSubmitting: _isSubmitting,
                    onPressed: _completeOnboarding,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Section Widgets
// ═══════════════════════════════════════════════════════════════════════════════

/// Pulsing logo with a subtle breathing scale animation.
class _PulsingLogo extends StatefulWidget {
  const _PulsingLogo();

  @override
  State<_PulsingLogo> createState() => _PulsingLogoState();
}

class _PulsingLogoState extends State<_PulsingLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(curved);
    _glowAnimation = Tween<double>(begin: 0.08, end: 0.38).animate(curved);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        final glow = _glowAnimation.value;
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0x3300E5FF), Color(0x1A004D7C)],
              ),
              border: Border.all(
                color: AppColors.neonCyan.withValues(alpha: glow),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonCyan.withValues(alpha: glow * 0.45),
                  blurRadius: 24,
                  spreadRadius: -2,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: ClipOval(
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Welcome header with logo and tagline.
class _WelcomeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // App logo with subtle pulse
        const _PulsingLogo(),
        const SizedBox(height: AppSpacing.lg),
        // Title
        const Text(
          'Welcome to Habit Up',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: 0.2,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        // Subtitle
        Text(
          'Build your productivity identity.',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary.withValues(alpha: 0.85),
            letterSpacing: 0.1,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Name input with validation.
class _NameInputSection extends StatelessWidget {
  const _NameInputSection({
    required this.controller,
    required this.focusNode,
    this.error,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: AppSpacing.sm),
          child: Text(
            'What should we call you?',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary.withValues(alpha: 0.9),
              letterSpacing: 0.4,
            ),
          ),
        ),
        TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
            letterSpacing: 0.2,
          ),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.4),
              fontSize: 17,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 16, right: 8),
              child: Icon(
                Icons.person_outline_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
            filled: true,
            fillColor: const Color(0xFF11172B),
            errorText: error,
            errorStyle: TextStyle(
              color: AppColors.error.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.error.withValues(alpha: 0.5),
                width: 1.2,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.neonCyan,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
          ),
          onSubmitted: (_) {
            // Allow keyboard "Done" to dismiss
            focusNode.unfocus();
          },
        ),
      ],
    );
  }
}

/// Premium avatar selection grid — shows real image assets.
class _AvatarSection extends StatelessWidget {
  const _AvatarSection({
    required this.options,
    required this.selectedId,
    required this.onSelect,
  });

  final List<AvatarOption> options;
  final String selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: AppSpacing.md),
          child: Text(
            'Choose Your Identity',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary.withValues(alpha: 0.9),
              letterSpacing: 0.4,
            ),
          ),
        ),
        // Responsive grid — 4 columns on wider screens, 3 on narrow
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 360 ? 4 : 3;
            final childAspectRatio = 1.0;
            final spacing = 10.0;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: options.length,
              itemBuilder: (context, index) {
                final avatar = options[index];
                final isSelected = avatar.id == selectedId;
                return _AvatarCell(
                  avatar: avatar,
                  isSelected: isSelected,
                  onTap: () => onSelect(avatar.id),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

/// Individual premium avatar cell with real image and glowing selection.
class _AvatarCell extends StatelessWidget {
  const _AvatarCell({
    required this.avatar,
    required this.isSelected,
    required this.onTap,
  });

  final AvatarOption avatar;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? AppColors.neonCyan
                : Colors.white.withValues(alpha: 0.12),
            width: isSelected ? 2.5 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.neonCyan.withValues(alpha: 0.35),
                    blurRadius: 14,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: avatar.fallbackColorA.withValues(alpha: 0.25),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6,
                    spreadRadius: 0,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar image (PNG/SVG) inside the circular cell
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: ClipOval(child: _buildAvatarImage()),
              ),
            ),
            // Label below the image
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                avatar.label,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: Colors.white.withValues(alpha: isSelected ? 1.0 : 0.7),
                  letterSpacing: 0.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Renders the avatar image (PNG via Image.asset, SVG via SvgPicture).
  Widget _buildAvatarImage() {
    if (avatar.assetPath.endsWith('.svg')) {
      return SvgPicture.asset(
        avatar.assetPath,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }
    return Image.asset(
      avatar.assetPath,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildGradientFallback(),
    );
  }

  /// Gradient fallback shown while loading or on asset error.
  Widget _buildGradientFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[avatar.fallbackColorA, avatar.fallbackColorB],
        ),
      ),
    );
  }
}

/// Bedtime picker section.
class _BedtimeSection extends StatelessWidget {
  const _BedtimeSection({required this.bedtime, required this.onTap});

  final TimeOfDay bedtime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final minute = bedtime.minute.toString().padLeft(2, '0');
    final period = bedtime.period == DayPeriod.am ? 'AM' : 'PM';
    final displayHour = bedtime.hourOfPeriod == 0 ? 12 : bedtime.hourOfPeriod;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: AppSpacing.sm),
          child: Text(
            'Bedtime Reminder',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary.withValues(alpha: 0.9),
              letterSpacing: 0.4,
            ),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                color: const Color(0xFF11172B),
              ),
              child: Row(
                children: [
                  // Bedtime icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[Color(0x334D7CFF), Color(0x1A1E2A50)],
                      ),
                      border: Border.all(
                        color: AppColors.neonBlue.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.nightlight_round,
                      size: 22,
                      color: AppColors.neonBlue,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Remind me at bedtime',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Plan tomorrow & wrap up today',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Time display
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          AppColors.neonBlue.withValues(alpha: 0.12),
                          AppColors.neonCyan.withValues(alpha: 0.06),
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.neonBlue.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$displayHour:$minute',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.neonBlue,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          period,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.neonBlue.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.edit_calendar_rounded,
                    size: 16,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Large futuristic continue button.
class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.isSubmitting, required this.onPressed});

  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonCyan,
          foregroundColor: AppColors.background,
          disabledBackgroundColor: AppColors.surfaceHighest,
          disabledForegroundColor: AppColors.textSecondary,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: AppColors.neonCyan.withValues(alpha: 0.4),
        ),
        child: isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.background,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Start Your Journey',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(Icons.arrow_forward_rounded, size: 22),
                ],
              ),
      ),
    );
  }
}
