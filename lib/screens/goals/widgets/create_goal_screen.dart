import 'package:flutter/material.dart';
import 'package:habit_up/providers/goal_provider.dart';
import 'package:habit_up/screens/goals/widgets/create_goal_action_button.dart';
import 'package:habit_up/screens/goals/widgets/futuristic_input_field.dart';
import 'package:habit_up/screens/goals/widgets/goal_accent_selector.dart';
import 'package:habit_up/screens/goals/widgets/goal_accent.dart';
import 'package:habit_up/screens/goals/widgets/goal_category_selector.dart';
import 'package:habit_up/screens/goals/widgets/goal_difficulty_selector.dart';
import 'package:habit_up/screens/goals/widgets/goal_timeline_selector.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/theme/app_spacing.dart';
import 'package:provider/provider.dart';

class CreateGoalScreen extends StatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  GoalCategory _category = GoalCategory.productivity;
  GoalDifficulty _difficulty = GoalDifficulty.medium;
  GoalAccent _accent = GoalAccent.purple;
  GoalTimeline _timeline = GoalTimeline.weekly;
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createGoal() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a goal title')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final goalProvider = context.read<GoalProvider>();
      final colorHex = GoalAccentSelector.hexStringForAccent(_accent);

      await goalProvider.createGoal(
        id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        description: _descriptionController.text.trim(),
        colorHex: colorHex,
        themeKey: _category.name,
        motivationalSubtitle: '${_difficulty.label} \u2022 ${_timeline.label}',
      );

      if (mounted) {
        Navigator.of(context).maybePop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$title" goal created'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success.withValues(alpha: 0.9),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _CreateGoalBackground()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                _CreateGoalHeader(textTheme: textTheme),
                const SizedBox(height: AppSpacing.md),
                FuturisticInputField(
                  label: 'Goal Title',
                  hintText: 'Build a stronger coding routine',
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.sm),
                FuturisticInputField(
                  label: 'Description',
                  hintText: 'Describe your desired outcome...',
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 5,
                ),
                const SizedBox(height: AppSpacing.sm),
                GoalCategorySelector(
                  value: _category,
                  onChanged: (value) => setState(() => _category = value),
                ),
                const SizedBox(height: AppSpacing.xs),
                GoalDifficultySelector(
                  value: _difficulty,
                  onChanged: (value) => setState(() => _difficulty = value),
                ),
                const SizedBox(height: AppSpacing.xs),
                GoalAccentSelector(
                  value: _accent,
                  onChanged: (value) => setState(() => _accent = value),
                ),
                const SizedBox(height: AppSpacing.xs),
                GoalTimelineSelector(
                  value: _timeline,
                  onChanged: (value) => setState(() => _timeline = value),
                ),
                const SizedBox(height: AppSpacing.md),
                CreateGoalActionButton(
                  label: _isCreating ? 'Creating...' : 'Create Goal',
                  onPressed: _isCreating ? null : _createGoal,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateGoalHeader extends StatelessWidget {
  const _CreateGoalHeader({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          style: IconButton.styleFrom(
            minimumSize: const Size(40, 40),
            backgroundColor: const Color(0xE01A2340),
            side: const BorderSide(color: AppColors.border),
            foregroundColor: AppColors.textPrimary,
          ),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Goal',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Define a clear mission',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.86),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CreateGoalBackground extends StatelessWidget {
  const _CreateGoalBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF0B1020), AppColors.background],
        ),
      ),
      child: Stack(
        children: const [
          Positioned(
            top: -70,
            right: -30,
            child: _GlowBlob(size: 160, color: Color(0x163E62F2)),
          ),
          Positioned(
            top: 250,
            left: -40,
            child: _GlowBlob(size: 130, color: Color(0x1000E5FF)),
          ),
          Positioned(
            bottom: 110,
            right: -45,
            child: _GlowBlob(size: 120, color: Color(0x0D00F5A0)),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              color,
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
