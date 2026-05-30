import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Animation Curves & Durations — Premium motion design tokens
// ═══════════════════════════════════════════════════════════════════════════════

abstract final class MotionDurations {
  /// Ultra-fast — 100ms (icon toggles, micro-interactions)
  static const Duration micro = Duration(milliseconds: 100);
  /// Fast — 180ms (button presses, small state changes)
  static const Duration fast = Duration(milliseconds: 180);
  /// Normal — 280ms (page transitions, card animations)
  static const Duration normal = Duration(milliseconds: 280);
  /// Slow — 400ms (large view transitions)
  static const Duration slow = Duration(milliseconds: 400);
  /// Expressive — 600ms (hero animations, modal transitions)
  static const Duration expressive = Duration(milliseconds: 600);
}

abstract final class MotionCurves {
  /// Smooth deceleration for entering elements
  static const Curve enter = Curves.easeOutCubic;
  /// Gentle acceleration for exiting elements
  static const Curve exit = Curves.easeInCubic;
  /// Premium elastic spring for emphasis
  static const Curve spring = Curves.easeOutBack;
  /// Subtle bounce for reward feedback
  static const Curve bounce = Curves.elasticOut;
  /// Standard easing for most UI transitions
  static const Curve standard = Curves.easeInOutCubic;
  /// Smooth sharp for progress indicators
  static const Curve progress = Curves.easeInOut;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Page Transition Builder — smooth slide + fade
// ═══════════════════════════════════════════════════════════════════════════════

PageRouteBuilder<T> smoothPageRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.08, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeOutCubic;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var fadeTween = Tween(begin: 0.0, end: 1.0).chain(
        CurveTween(curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
      );

      return SlideTransition(
        position: animation.drive(tween),
        child: FadeTransition(
          opacity: animation.drive(fadeTween),
          child: child,
        ),
      );
    },
    transitionDuration: MotionDurations.normal,
    reverseTransitionDuration: MotionDurations.fast,
  );
}

/// Vertical slide transition (for modal-like screens)
PageRouteBuilder<T> verticalSlideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 0.06);
      const end = Offset.zero;

      var tween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: Curves.easeOutCubic),
      );
      var fadeTween = Tween(begin: 0.0, end: 1.0).chain(
        CurveTween(curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
      );

      return SlideTransition(
        position: animation.drive(tween),
        child: FadeTransition(
          opacity: animation.drive(fadeTween),
          child: child,
        ),
      );
    },
    transitionDuration: MotionDurations.normal,
    reverseTransitionDuration: MotionDurations.fast,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shimmer Loading — premium skeleton effect
// ═══════════════════════════════════════════════════════════════════════════════

class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({
    required this.child,
    super.key,
    this.isLoading = true,
    this.baseColor = const Color(0x1AFFFFFF),
    this.highlightColor = const Color(0x2AFFFFFF),
  });

  final Widget child;
  final bool isLoading;
  final Color baseColor;
  final Color highlightColor;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: <Color>[
                widget.baseColor,
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
                widget.baseColor,
              ],
              stops: <double>[
                0.0,
                _controller.value - 0.2,
                _controller.value,
                _controller.value + 0.2,
                1.0,
              ],
            ).createShader(bounds);
          },
          child: child!,
        );
      },
      child: widget.child,
    );
  }
}

/// Convenience widget that shows a shimmer placeholder while loading.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
    this.isLoading = true,
  });

  final double? width;
  final double height;
  final double borderRadius;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      isLoading: isLoading,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: const Color(0x1AFFFFFF),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Animated Counter — premium number transitions
// ═══════════════════════════════════════════════════════════════════════════════

class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    required this.value,
    required this.style,
    super.key,
    this.duration = MotionDurations.normal,
    this.zeroPad = 0,
    this.prefix = '',
    this.suffix = '',
  });

  final int value;
  final TextStyle style;
  final Duration duration;
  final int zeroPad;
  final String prefix;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: value, end: value),
      duration: duration,
      curve: MotionCurves.enter,
      builder: (context, val, _) {
        final display = prefix +
            val.toString().padLeft(zeroPad, '0').padLeft(1, '0') +
            suffix;
        return Text(display, style: style);
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Scale Press — subtle press feedback for cards
// ═══════════════════════════════════════════════════════════════════════════════

class ScalePress extends StatefulWidget {
  const ScalePress({
    required this.child,
    required this.onTap,
    super.key,
    this.scaleAmount = 0.97,
  });

  final Widget child;
  final VoidCallback onTap;
  final double scaleAmount;

  @override
  State<ScalePress> createState() => _ScalePressState();
}

class _ScalePressState extends State<ScalePress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MotionDurations.micro,
      upperBound: 1.0,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: widget.scaleAmount).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.reverse();
  void _onTapUp(TapUpDetails details) => _controller.forward();
  void _onTapCancel() => _controller.forward();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onTap,
        child: widget.child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Animated Progress Ring — smooth progress transitions
// ═══════════════════════════════════════════════════════════════════════════════

class AnimatedProgressRing extends StatelessWidget {
  const AnimatedProgressRing({
    required this.progress,
    required this.size,
    required this.accentColor,
    super.key,
    this.strokeWidth = 7,
    this.backgroundColor = const Color(0xFF2A3354),
    this.centerChild,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final Color accentColor;
  final Color backgroundColor;
  final Widget? centerChild;

  @override
  Widget build(BuildContext context) {
    final normalized = progress.clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring (static)
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: strokeWidth,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2A3354)),
            ),
          ),
          // Animated foreground ring
          SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: normalized),
              duration: MotionDurations.slow,
              curve: MotionCurves.progress,
              builder: (context, value, _) {
                return CircularProgressIndicator(
                  value: value == 0 ? 0.001 : value,
                  strokeWidth: strokeWidth,
                  strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  backgroundColor: Colors.transparent,
                );
              },
            ),
          ),
          if (centerChild != null)
            Padding(
              padding: const EdgeInsets.all(4),
              child: centerChild!,
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Haptic Feedback Utility — preparation for subtle haptics
// ═══════════════════════════════════════════════════════════════════════════════

abstract final class HapticUtil {
  /// Light impact for toggles, micro-interactions
  static Future<void> light() =>
      HapticFeedback.lightImpact();

  /// Medium impact for task completion, XP gain
  static Future<void> medium() =>
      HapticFeedback.mediumImpact();

  /// Heavy impact for milestones, level-ups
  static Future<void> heavy() =>
      HapticFeedback.heavyImpact();

  /// Selection click for pickers, switches
  static Future<void> selection() =>
      HapticFeedback.selectionClick();

  /// Success notification for completions
  static Future<void> success() =>
      HapticFeedback.mediumImpact();
}

// ═══════════════════════════════════════════════════════════════════════════════
// Animated Checkmark — smooth completion indicator
// ═══════════════════════════════════════════════════════════════════════════════

class AnimatedCheckmark extends StatefulWidget {
  const AnimatedCheckmark({
    required this.isCompleted,
    super.key,
    this.size = 24,
    this.completedColor = const Color(0xFF21D19F),
    this.incompleteColor = const Color(0xFF4A6092),
    this.strokeWidth = 1.5,
  });

  final bool isCompleted;
  final double size;
  final Color completedColor;
  final Color incompleteColor;
  final double strokeWidth;

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _checkProgress;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MotionDurations.normal,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: MotionCurves.spring),
    );
    _checkProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: MotionCurves.enter),
    );

    if (widget.isCompleted) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedCheckmark oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted != oldWidget.isCompleted) {
      if (widget.isCompleted) {
        _controller.forward();
        HapticUtil.light();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.isCompleted
                    ? widget.completedColor
                    : widget.incompleteColor,
                width: widget.strokeWidth,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.isCompleted
                    ? const <Color>[Color(0x4021D19F), Color(0x1A0F1D2E)]
                    : const <Color>[Color(0x331B2A46), Color(0x12101925)],
              ),
              boxShadow: [
                if (widget.isCompleted)
                  BoxShadow(
                    color: widget.completedColor.withValues(alpha: 0.22),
                    blurRadius: 8,
                    spreadRadius: -4,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            alignment: Alignment.center,
            child: widget.isCompleted
                ? CustomPaint(
                    size: const Size(13, 13),
                    painter: _CheckmarkPainter(
                      progress: _checkProgress.value,
                      color: widget.completedColor,
                    ),
                  )
                : Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.incompleteColor.withValues(alpha: 0.58),
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  const _CheckmarkPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.5);
    path.lineTo(size.width * 0.43, size.height * 0.75);
    path.lineTo(size.width * 0.8, size.height * 0.25);

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      final extractPath = metric.extractPath(
        0.0,
        metric.length * progress.clamp(0.0, 1.0),
      );
      canvas.drawPath(extractPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Animated XP Float — subtle XP earned feedback
// ═══════════════════════════════════════════════════════════════════════════════

class XpFloatUp extends StatefulWidget {
  const XpFloatUp({
    required this.xpAmount,
    required this.child,
    super.key,
  });

  final int xpAmount;
  final Widget child;

  @override
  State<XpFloatUp> createState() => _XpFloatUpState();
}

class _XpFloatUpState extends State<XpFloatUp>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnim;
  late Animation<double> _opacityAnim;
  int _earnedXp = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _floatAnim = Tween<double>(begin: 0, end: -30).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant XpFloatUp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.xpAmount != oldWidget.xpAmount && widget.xpAmount > 0) {
      _earnedXp = widget.xpAmount;
      _controller.forward(from: 0.0);
      HapticUtil.selection();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (_controller.isAnimating || _controller.value > 0)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Transform.translate(
                  offset: Offset(0, _floatAnim.value),
                  child: Opacity(
                    opacity: _opacityAnim.value,
                    child: Text(
                      '+$_earnedXp XP',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF00E5FF),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Animated Streak Badge — pulse on streak increment
// ═══════════════════════════════════════════════════════════════════════════════

class StreakPulse extends StatefulWidget {
  const StreakPulse({
    required this.streak,
    required this.child,
    super.key,
  });

  final int streak;
  final Widget child;

  @override
  State<StreakPulse> createState() => _StreakPulseState();
}

class _StreakPulseState extends State<StreakPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnim;
  int _previousStreak = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: MotionCurves.spring),
    );
    _previousStreak = widget.streak;
  }

  @override
  void didUpdateWidget(covariant StreakPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.streak > _previousStreak) {
      _controller.forward().then((_) => _controller.reverse());
      HapticUtil.light();
    }
    _previousStreak = widget.streak;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnim.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Fade In — staggered entry for list items
// ═══════════════════════════════════════════════════════════════════════════════

class FadeInUp extends StatefulWidget {
  const FadeInUp({
    required this.child,
    super.key,
    this.delay = Duration.zero,
    this.duration = MotionDurations.normal,
    this.offset = 12,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;

  @override
  State<FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<FadeInUp>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;
  late Animation<double> _translateAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: MotionCurves.enter),
    );
    _translateAnim = Tween<double>(begin: widget.offset, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: MotionCurves.enter),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnim.value,
          child: Transform.translate(
            offset: Offset(0, _translateAnim.value),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Animated Between Pages — crossfade for tab switching
// ═══════════════════════════════════════════════════════════════════════════════

class AnimatedTabTransition extends StatelessWidget {
  const AnimatedTabTransition({
    required this.child,
    required this.keyValue,
    super.key,
  });

  final Widget child;
  final int keyValue;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: MotionDurations.fast,
      switchInCurve: MotionCurves.enter,
      switchOutCurve: MotionCurves.exit,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: MotionCurves.enter),
            ),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(keyValue),
        child: child,
      ),
    );
  }
}
