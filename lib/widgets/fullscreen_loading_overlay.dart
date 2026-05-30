import 'package:flutter/material.dart';
import 'package:habit_up/theme/app_colors.dart';

/// Root-level fullscreen loading overlay that covers the entire screen.
///
/// This widget should be placed at the ROOT of the widget tree (above MaterialApp)
/// to ensure it covers the entire screen regardless of child layout constraints.
///
/// Features:
///   - Covers ENTIRE screen (not constrained by child layouts)
///   - Centered animated loader
///   - Dark translucent background
///   - Blocks interactions when visible
///   - Scales responsively
///
/// Usage:
/// ```dart
/// FullscreenLoadingOverlay(
///   isLoading: true,
///   child: MaterialApp(...),
/// )
/// ```
class FullscreenLoadingOverlay extends StatelessWidget {
  const FullscreenLoadingOverlay({
    required this.isLoading,
    required this.child,
    super.key,
    this.message,
    this.backgroundColor = const Color(0xCC060810),
  });

  final bool isLoading;
  final Widget child;
  final String? message;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Material(
              color: backgroundColor,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _AnimatedLoader(),
                    if (message != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        message!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AnimatedLoader extends StatefulWidget {
  const _AnimatedLoader();

  @override
  State<_AnimatedLoader> createState() => _AnimatedLoaderState();
}

class _AnimatedLoaderState extends State<_AnimatedLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
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
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: child,
          ),
        );
      },
      child: const SizedBox(
        width: 48,
        height: 48,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.neonCyan),
        ),
      ),
    );
  }
}
