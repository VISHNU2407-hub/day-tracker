import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/theme/app_text_styles.dart';

// ---------------------------------------------------------------------------
// Splash Screen — Animated Loading Screen
// ---------------------------------------------------------------------------
//
// Features:
//   • Looping vertical hover float on the rocket icon (easeInOut, ~10px)
//   • Tap-to-boost micro-interaction (quick jump up + elastic settle)
//   • Branding below the rocket in a single centered Column:
//     "MADE WITH ♥ BY" / "A PRODUCT BY DAY TRACKER"
// ---------------------------------------------------------------------------

class SplashScreen extends StatefulWidget {
  const SplashScreen({required this.progress, this.onTransitionComplete, super.key});

  /// Progress notifier (kept for compatibility, not used for visuals)
  final ValueNotifier<int> progress;

  /// Called after the crossfade-out transition animation completes when the
  /// splash screen is ready to dismiss.
  final VoidCallback? onTransitionComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Hover float animation ─────────────────────────────────────────────
  late final AnimationController _hoverController;
  late final Animation<double> _hoverAnimation;

  // ── Tap boost animation ───────────────────────────────────────────────
  late final AnimationController _boostController;
  late final Animation<double> _boostVerticalAnimation;
  late final Animation<double> _boostRotationAnimation;

  // ── Crossfade-out transition (triggered when progress reaches 4) ────────
  late final AnimationController _transitionController;
  late final Animation<double> _transitionOpacity;
  late final Animation<double> _transitionScale;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();

    // ── Hover: continuous sine-like float ──
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _hoverAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(
        parent: _hoverController,
        curve: Curves.easeInOut,
      ),
    );
    _hoverController.repeat(reverse: true);

    // ── Boost: quick upward jump then elastic settle ──
    _boostController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Vertical offset: 0 → boost up → elastic back to 0
    _boostVerticalAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -22.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -22.0, end: 0.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ]).animate(_boostController);

    // Slight rotation shake during the boost for extra playfulness
    _boostRotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.04),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.04, end: -0.03),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.03, end: 0.02),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.02, end: 0.0),
        weight: 50,
      ),
    ]).animate(_boostController);

    // ── Crossfade-out transition controller ──
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _transitionOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: Curves.easeOutCubic,
      ),
    );
    _transitionScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Listen for progress reaching the final stage to trigger transition.
    widget.progress.addListener(_onProgressChanged);
  }

  void _onProgressChanged() {
    if (widget.progress.value >= 4 && !_isTransitioning) {
      _startCrossfadeOut();
    }
  }

  void _startCrossfadeOut() {
    _isTransitioning = true;
    _transitionController.forward().then((_) {
      widget.onTransitionComplete?.call();
    });
  }

  /// Triggers the boost micro-interaction.
  void _onRocketTap() {
    if (_boostController.isAnimating) return;
    _boostController.forward(from: 0.0);
  }

  @override
  void dispose() {
    widget.progress.removeListener(_onProgressChanged);
    _hoverController.dispose();
    _boostController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _transitionController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xFF0A0F22).withValues(
                    alpha: _transitionOpacity.value,
                  ),
                  Color(0xFF080A12).withValues(
                    alpha: _transitionOpacity.value,
                  ),
                  Color(0xFF060810).withValues(
                    alpha: _transitionOpacity.value,
                  ),
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Opacity(
                  opacity: _transitionOpacity.value,
                  child: Transform.scale(
                    scale: _transitionScale.value,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildAnimatedRocket(),
                        const SizedBox(height: 40),
                        const _LoadingText(),
                        const SizedBox(height: 32),
                        _buildBrandingFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        child: const SizedBox.expand(),
      ),
    );
  }

  // ── Rocket ───────────────────────────────────────────────────────────

  Widget _buildAnimatedRocket() {
    return GestureDetector(
      onTap: _onRocketTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([_hoverController, _boostController]),
        builder: (context, child) {
          // Compose hover float + boost jump
          final hoverOffset = _hoverAnimation.value;
          final boostOffset = _boostVerticalAnimation.value;
          final rotation = _boostRotationAnimation.value;

          // Scale — subtle pulse during boost
          final boostProgress = _boostController.value;
          final scale = 1.0 + (boostProgress * 0.04 * (1.0 - boostProgress));

          return Transform.translate(
            offset: Offset(0, hoverOffset + boostOffset),
            child: Transform.rotate(
              angle: rotation * math.pi,
              child: Transform.scale(
                scale: scale,
                child: child!,
              ),
            ),
          );
        },
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0x3300E5FF), Color(0x1A004D7C)],
            ),
            border: Border.all(
              color: AppColors.neonCyan.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.neonCyan.withValues(alpha: 0.15),
                blurRadius: 24,
                spreadRadius: -4,
              ),
              BoxShadow(
                color: AppColors.neonBlue.withValues(alpha: 0.1),
                blurRadius: 36,
                spreadRadius: 2,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.rocket_launch_rounded,
            size: 42,
            color: AppColors.neonCyan,
          ),
        ),
      ),
    );
  }

  // ── Branding Footer ──────────────────────────────────────────────────

  Widget _buildBrandingFooter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // "MADE WITH ♥ BY" (heart in purple)
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary.withValues(alpha: 0.45),
              letterSpacing: 2.0,
              height: 1.3,
            ),
            children: [
              const TextSpan(text: 'MADE WITH '),
              TextSpan(
                text: '♥',
                style: TextStyle(color: AppColors.neonPink),
              ),
              const TextSpan(text: ' BY'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),

        // "A PRODUCT BY VerSo"
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary.withValues(alpha: 0.85),
              letterSpacing: 0.4,
              height: 1.3,
            ),
            children: [
              const TextSpan(text: 'A PRODUCT BY '),
              TextSpan(
                text: 'VerSo',
                style: TextStyle(color: AppColors.neonCyan),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),

        // Subtle decorative line
        const SizedBox(height: 10),
        SizedBox(
          width: 40,
          child: Divider(
            color: AppColors.neonCyan.withValues(alpha: 0.2),
            thickness: 0.5,
            height: 0,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Branded Loading — "DAY TRACKER" hero text with neon gradient
// ═══════════════════════════════════════════════════════════════════════════

class _LoadingText extends StatefulWidget {
  const _LoadingText();

  @override
  State<_LoadingText> createState() => _LoadingTextState();
}

class _LoadingTextState extends State<_LoadingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Opacity(
          opacity: _pulseAnimation.value,
          child: child,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── "DAY TRACKER" hero branding — neon glow ────────────────
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.neonCyan,
                AppColors.neonGreen,
              ],
            ).createShader(bounds),
            child: const Text(
              'DAY TRACKER',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 4.5,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          // ── Loading subtitle ────────────────────────────────────────
          const Text(
            'Loading...',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
