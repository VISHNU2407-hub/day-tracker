import 'package:flutter/material.dart';
import 'package:habit_up/models/sub_goal_model.dart';
import 'package:habit_up/models/goal_model.dart';
import 'package:habit_up/providers/goal_provider.dart';
import 'package:habit_up/providers/sub_goal_provider.dart';
import 'package:habit_up/providers/task_provider.dart';
import 'package:habit_up/screens/goals/widgets/subgoal_details_screen.dart';
import 'package:habit_up/screens/goals/widgets/subgoal_item_card.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/theme/app_spacing.dart';
import 'package:provider/provider.dart';

class GoalDetailsScreen extends StatefulWidget {
  const GoalDetailsScreen({required this.goalId, super.key});

  final String goalId;

  @override
  State<GoalDetailsScreen> createState() => _GoalDetailsScreenState();
}

class _GoalDetailsScreenState extends State<GoalDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final goalProvider = context.watch<GoalProvider>();
    final subGoalProvider = context.watch<SubGoalProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final goal = goalProvider.getGoalById(widget.goalId);
    final subGoals = subGoalProvider.getSubGoalsByGoalId(widget.goalId);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    if (goal == null) {
      return Scaffold(
        body: Stack(
          children: [
            Positioned.fill(child: _GoalDetailsBackground()),
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 48,
                      color: colorScheme.onSurface.withValues(alpha: 0.27),
                    ),
                    const SizedBox(height: 16),
                    Text('Goal not found', style: textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final accentColor = _accentFromColorHex(goal.colorHex);
    final completedSubGoals = subGoals
        .where((sg) => sg.status == SubGoalStatus.completed)
        .length;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _GoalDetailsBackground()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                8,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              children: [
                _GoalDetailsHeader(
                  goal: goal,
                  accentColor: accentColor,
                  onEdit: () =>
                      _showEditGoalDialog(context, goal, goalProvider),
                  onDelete: () =>
                      _confirmDeleteGoal(context, goal, goalProvider),
                  onTogglePin: () async {
                    if (goal.isPinned) {
                      await goalProvider.unpinGoal(goal.id);
                    } else {
                      await goalProvider.pinGoal(goal.id);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _GoalProgressSection(goal: goal, accentColor: accentColor),
                const SizedBox(height: 12),
                _CompactStatsRow(
                  subGoalCount: subGoals.length,
                  completedSubGoals: completedSubGoals,
                  totalTasks: subGoals.fold<int>(
                    0,
                    (sum, sg) =>
                        sum + taskProvider.getTasksForSubGoal(sg.id).length,
                  ),
                  completedTasks: subGoals.fold<int>(
                    0,
                    (sum, sg) =>
                        sum +
                        taskProvider
                            .getTasksForSubGoal(sg.id)
                            .where((t) => t.isCompleted)
                            .length,
                  ),
                  accentColor: accentColor,
                ),
                const SizedBox(height: 16),
                _SubGoalSectionHeader(
                  textTheme: textTheme,
                  subGoalCount: subGoals.length,
                  onAddSubGoal: () =>
                      _showCreateSubGoalDialog(context, goal, subGoalProvider),
                ),
                const SizedBox(height: 7),
                if (subGoals.isEmpty)
                  _SubGoalsEmptyState(
                    onAddSubGoal: () => _showCreateSubGoalDialog(
                      context,
                      goal,
                      subGoalProvider,
                    ),
                  )
                else
                  ...subGoals.map(
                    (subGoal) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: SubGoalItemCard(
                        item: _toSubGoalItemViewModel(subGoal),
                        accent: accentColor,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => SubGoalDetailsScreen(
                                subGoalId: subGoal.id,
                                goalId: goal.id,
                                goalAccent: accentColor,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _accentFromColorHex(String? hex) {
    if (hex != null && hex.length >= 6) {
      try {
        return Color(int.parse(hex.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }
    return const Color(0xFFB18BFF);
  }

  SubGoalItemViewModel _toSubGoalItemViewModel(SubGoalModel subGoal) {
    return SubGoalItemViewModel(
      title: subGoal.title,
      subtitle:
          subGoal.description ??
          subGoal.motivationalSubtitle ??
          'No description',
      progress: subGoal.progress,
      taskCount: subGoal.taskIds.length,
      timeline: subGoal.deadline != null
          ? '${subGoal.deadline!.day}/${subGoal.deadline!.month}'
          : 'No deadline',
      isCompleted: subGoal.isCompleted,
    );
  }

  void _showCreateSubGoalDialog(
    BuildContext context,
    GoalModel goal,
    SubGoalProvider subGoalProvider,
  ) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Create Sub-Goal',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Sub-goal title',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Description (optional)',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              await subGoalProvider.createSubGoal(
                id: 'subgoal_${DateTime.now().millisecondsSinceEpoch}',
                goalId: goal.id,
                title: title,
                description: descController.text.trim(),
              );
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: Text(
              'Create',
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditGoalDialog(
    BuildContext context,
    GoalModel goal,
    GoalProvider goalProvider,
  ) {
    final titleController = TextEditingController(text: goal.title);
    final descController = TextEditingController(text: goal.description ?? '');
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Goal',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Goal title',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Description',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              await goalProvider.updateGoal(
                id: goal.id,
                title: title,
                description: descController.text.trim(),
              );
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: Text(
              'Save',
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteGoal(
    BuildContext context,
    GoalModel goal,
    GoalProvider goalProvider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Goal',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: Text(
          'Are you sure you want to delete "${goal.title}"?',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () async {
              await goalProvider.deleteGoal(goal.id);
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                Navigator.of(context).maybePop();
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalDetailsHeader extends StatelessWidget {
  const _GoalDetailsHeader({
    required this.goal,
    required this.accentColor,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePin,
  });

  final GoalModel goal;
  final Color accentColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          style: IconButton.styleFrom(
            minimumSize: const Size(40, 40),
            backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.88),
            side: BorderSide(color: colorScheme.outline),
            foregroundColor: colorScheme.onSurface,
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
                  goal.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  goal.motivationalSubtitle ??
                      'Command your momentum with daily precision.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.86),
                    fontSize: 12.6,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, color: colorScheme.primary),
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) {
            if (value == 'pin') onTogglePin();
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'pin',
              child: ListTile(
                leading: Icon(
                  goal.isPinned
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                  color: goal.isPinned
                      ? const Color(0xFFFFB15A)
                      : colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                title: Text(
                  goal.isPinned ? 'Unpin' : 'Pin to Dashboard',
                  style: TextStyle(
                    color: goal.isPinned
                        ? const Color(0xFFFFB15A)
                        : colorScheme.onSurface,
                  ),
                ),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(
                  Icons.edit_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
                title: Text(
                  'Edit',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(
                  Icons.delete_rounded,
                  color: colorScheme.error,
                  size: 20,
                ),
                title: Text(
                  'Delete',
                  style: TextStyle(color: colorScheme.error),
                ),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SubGoalSectionHeader extends StatelessWidget {
  const _SubGoalSectionHeader({
    required this.textTheme,
    required this.subGoalCount,
    required this.onAddSubGoal,
  });

  final TextTheme textTheme;
  final int subGoalCount;
  final VoidCallback onAddSubGoal;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sub Goals',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$subGoalCount sub-goals',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: onAddSubGoal,
          borderRadius: BorderRadius.circular(11),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  colorScheme.primary.withValues(alpha: 0.17),
                  colorScheme.primary.withValues(alpha: 0.09),
                ],
              ),
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.31)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 14,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Add SubGoal',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 10.8,
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

class _GoalDetailsBackground extends StatelessWidget {
  const _GoalDetailsBackground();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[colorScheme.surface, colorScheme.surface],
        ),
      ),
      child: Stack(
        children: const [
          Positioned(
            top: -60,
            right: -35,
            child: _GlowBlob(size: 150, color: Color(0x143E62F2)),
          ),
          Positioned(
            top: 260,
            left: -45,
            child: _GlowBlob(size: 120, color: Color(0x0D00E5FF)),
          ),
          Positioned(
            bottom: 100,
            right: -40,
            child: _GlowBlob(size: 105, color: Color(0x0B00F5A0)),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.color});
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
            colors: <Color>[color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Missing section classes referenced in the build method
// ---------------------------------------------------------------------------

class _GoalProgressSection extends StatelessWidget {
  const _GoalProgressSection({required this.goal, required this.accentColor});

  final GoalModel goal;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final progressPercent = (goal.progress * 100).round();
    return Row(
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: goal.progress.clamp(0.0, 1.0),
                  strokeWidth: 5,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              ),
              Text(
                '$progressPercent%',
                style: textTheme.labelLarge?.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                goal.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                goal.motivationalSubtitle ?? 'Track your mission progress',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactStatsRow extends StatelessWidget {
  const _CompactStatsRow({
    required this.subGoalCount,
    required this.completedSubGoals,
    required this.totalTasks,
    required this.completedTasks,
    required this.accentColor,
  });

  final int subGoalCount;
  final int completedSubGoals;
  final int totalTasks;
  final int completedTasks;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: _CompactStatChip(
              label: 'SubGoals',
              value: '$subGoalCount',
              accent: accentColor,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 80,
            child: _CompactStatChip(
              label: 'Done',
              value: '$completedSubGoals',
              accent: AppColors.success,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 80,
            child: _CompactStatChip(
              label: 'Tasks',
              value: '$totalTasks',
              accent: AppColors.neonBlue,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 80,
            child: _CompactStatChip(
              label: 'Done',
              value: '$completedTasks',
              accent: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactStatChip extends StatelessWidget {
  const _CompactStatChip({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: accent.withValues(alpha: 0.07),
        border: Border.all(color: accent.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: textTheme.titleSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubGoalsEmptyState extends StatelessWidget {
  const _SubGoalsEmptyState({required this.onAddSubGoal});

  final VoidCallback onAddSubGoal;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.19)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            colorScheme.surface.withValues(alpha: 0.69),
            colorScheme.surface.withValues(alpha: 0.66),
          ],
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.layers_outlined, size: 32, color: colorScheme.onSurface.withValues(alpha: 0.27)),
          const SizedBox(height: 8),
          Text(
            'No sub-goals yet',
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Break your goal into smaller sub-goals.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onAddSubGoal,
              borderRadius: BorderRadius.circular(10),
              child: Ink(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: <Color>[
                      colorScheme.primary.withValues(alpha: 0.17),
                      colorScheme.primary.withValues(alpha: 0.09),
                    ],
                  ),
                  border: Border.all(color: colorScheme.primary.withValues(alpha: 0.31)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Create SubGoal',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
