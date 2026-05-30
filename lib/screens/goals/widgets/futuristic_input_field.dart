import 'package:flutter/material.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/theme/app_spacing.dart';

class FuturisticInputField extends StatefulWidget {
  const FuturisticInputField({
    required this.label,
    required this.hintText,
    required this.controller,
    this.textInputAction,
    this.minLines = 1,
    this.maxLines = 1,
    this.onChanged,
    super.key,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final TextInputAction? textInputAction;
  final int minLines;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  State<FuturisticInputField> createState() => _FuturisticInputFieldState();
}

class _FuturisticInputFieldState extends State<FuturisticInputField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isFocused = _focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: textTheme.labelMedium?.copyWith(
            color: isFocused ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 7),
        AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                isFocused ? const Color(0xF41B2748) : const Color(0xEB19233F),
                isFocused ? const Color(0xE1131C34) : const Color(0xD910182C),
              ],
            ),
            border: Border.all(
              color: isFocused ? AppColors.neonBlue.withValues(alpha: 0.5) : AppColors.border,
              width: isFocused ? 1.2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isFocused
                    ? AppColors.neonBlue.withValues(alpha: 0.2)
                    : const Color(0x1100E5FF),
                blurRadius: isFocused ? 14 : 10,
                spreadRadius: -8,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            focusNode: _focusNode,
            controller: widget.controller,
            minLines: widget.minLines,
            maxLines: widget.maxLines,
            onChanged: widget.onChanged,
            textInputAction: widget.textInputAction,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: widget.hintText,
              isDense: true,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 13,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
