import 'package:flutter/material.dart';

import 'package:habit_up/models/task_model.dart';
import 'package:habit_up/motion/motion.dart';
import 'package:habit_up/providers/goal_provider.dart';
import 'package:habit_up/providers/sub_goal_provider.dart';
import 'package:habit_up/providers/task_provider.dart';
import 'package:habit_up/screens/tasks/widgets/task_card.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/theme/app_spacing.dart';
import 'package:habit_up/widgets/app_gaps.dart';
import 'package:provider/provider.dart';

class TodayTasksSection extends StatefulWidget {
  const TodayTasksSection({super.key});

  @override
  State<TodayTasksSection> createState() => _TodayTasksSectionState();
}

class _TodayTasksSectionState extends State<TodayTasksSection> {
  // ---------------------------------------------------------------------------
  // Create Task Dialog
  // ---------------------------------------------------------------------------
  void _showCreateTaskDialog(BuildContext context, TaskProvider taskProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    final titleController = TextEditingController();
    final descController = TextEditingController();
    TaskDifficulty difficulty = TaskDifficulty.medium;
    int xpReward = 5;
    TimeOfDay selectedTime = TimeOfDay.now();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Add Today Task',
            style: TextStyle(color: colorScheme.onSurface),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title field
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Task title *',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Description field
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    minLines: 1,
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Time picker — mandatory
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                        builder: (pickerCtx, child) => Theme(
                          data: Theme.of(pickerCtx).copyWith(
                            colorScheme: Theme.of(pickerCtx).colorScheme,
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedTime = picked;
                          errorMessage = null;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: colorScheme.surfaceContainerHighest,
                        border: Border.all(
                          color: errorMessage != null
                              ? colorScheme.error
                              : colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Time: ${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.edit_rounded,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Text(
                        errorMessage!,
                        style: TextStyle(
                          color: colorScheme.error,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Difficulty selector — Wrap to prevent overflow on narrow screens
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Difficulty:',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: TaskDifficulty.values.map((d) {
                          final selected = difficulty == d;
                          return ChoiceChip(
                            label: Text(
                              d.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: selected
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                            selected: selected,
                            selectedColor: colorScheme.primary.withValues(
                              alpha: 0.15,
                            ),
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            onSelected: (v) {
                              if (v) {
                                setDialogState(() {
                                  difficulty = d;
                                  xpReward = d == TaskDifficulty.easy
                                      ? 3
                                      : (d == TaskDifficulty.hard ? 7 : 5);
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // XP reward display
                  Row(
                    children: [
                      Text(
                        'XP Reward:',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.warning.withValues(alpha: 0.1),
                        ),
                        child: Text(
                          '+$xpReward XP',
                          style: const TextStyle(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.only(right: 8, bottom: 8),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
            TextButton(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) {
                  setDialogState(() {
                    errorMessage = 'Please enter a task title';
                  });
                  return;
                }
                final now = DateTime.now();
                final scheduledDate = DateTime(
                  now.year,
                  now.month,
                  now.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );
                await taskProvider.createTask(
                  id: 'task_${now.millisecondsSinceEpoch}',
                  title: title,
                  difficulty: difficulty,
                  xpReward: xpReward,
                  description: descController.text.trim(),
                  startTime: scheduledDate,
                  scheduledDate: scheduledDate,
                );
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              child: Text(
                'Add to Today',
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Edit Task Dialog
  // ---------------------------------------------------------------------------
  void _showEditTaskDialog(
    BuildContext context,
    TaskModel task,
    TaskProvider taskProvider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final titleController = TextEditingController(text: task.title);
    final descController = TextEditingController(text: task.description ?? '');
    TaskDifficulty difficulty = task.difficulty;
    int xpReward = task.xpReward;
    final initialTime = task.startTime ?? task.scheduledDate;
    TimeOfDay selectedTime = initialTime != null
        ? TimeOfDay(hour: initialTime.hour, minute: initialTime.minute)
        : TimeOfDay.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Edit Task',
            style: TextStyle(color: colorScheme.onSurface),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Task title',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    minLines: 1,
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Time picker — mandatory
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                        builder: (pickerCtx, child) => Theme(
                          data: Theme.of(pickerCtx).copyWith(
                            colorScheme: Theme.of(pickerCtx).colorScheme,
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedTime = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: colorScheme.surfaceContainerHighest,
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Time: ${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Difficulty selector — Wrap to prevent overflow
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Difficulty:',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: TaskDifficulty.values.map((d) {
                          final selected = difficulty == d;
                          return ChoiceChip(
                            label: Text(
                              d.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: selected
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                            selected: selected,
                            selectedColor: colorScheme.primary.withValues(
                              alpha: 0.15,
                            ),
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            onSelected: (v) {
                              if (v) {
                                setDialogState(() {
                                  difficulty = d;
                                  xpReward = d == TaskDifficulty.easy
                                      ? 3
                                      : (d == TaskDifficulty.hard ? 7 : 5);
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'XP Reward:',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.warning.withValues(alpha: 0.1),
                        ),
                        child: Text(
                          '+$xpReward XP',
                          style: const TextStyle(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.only(right: 8, bottom: 8),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
            TextButton(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) return;
                final now = DateTime.now();
                final scheduledDate = DateTime(
                  now.year,
                  now.month,
                  now.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );
                await taskProvider.updateTask(
                  id: task.id,
                  title: title,
                  description: descController.text.trim(),
                  difficulty: difficulty,
                  xpReward: xpReward,
                  startTime: scheduledDate,
                  scheduledDate: scheduledDate,
                );
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              child: Text(
                'Save',
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Delete confirmation dialog
  // ---------------------------------------------------------------------------
  void _confirmDeleteTask(
    BuildContext context,
    TaskModel task,
    TaskProvider taskProvider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Task',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: Text(
          'Delete "${task.title}"?',
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
              await taskProvider.deleteTask(task.id);
              if (ctx.mounted) Navigator.of(ctx).pop();
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

  // ---------------------------------------------------------------------------
  // Push Back to Goal Dialog
  // ---------------------------------------------------------------------------
  void _showPushBackToGoalDialog(
    BuildContext context,
    TaskModel task,
    TaskProvider taskProvider,
    GoalProvider goalProvider,
    SubGoalProvider subGoalProvider,
  ) {
    final goals = goalProvider.allGoals;
    if (goals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No goals available. Create a goal first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final colorScheme = Theme.of(context).colorScheme;

    // Step 1: Show goal selection dialog
    showDialog<String>(
      context: context,
      builder: (goalCtx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Select Goal',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: goals.length,
            itemBuilder: (ctx, i) {
              final goal = goals[i];
              return ListTile(
                leading: Icon(Icons.flag_rounded, color: colorScheme.primary),
                title: Text(
                  goal.title,
                  style: TextStyle(color: colorScheme.onSurface),
                ),
                subtitle: Text(
                  goal.title,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                onTap: () {
                  Navigator.of(goalCtx).pop(goal.id);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(goalCtx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    ).then((goalId) {
      if (goalId == null || !context.mounted) return;

      // Step 2: Show subgoal selection dialog for the selected goal
      final subGoals = subGoalProvider.getSubGoalsByGoalId(goalId);
      if (subGoals.isEmpty) {
        // No subgoals - push directly to the goal
        taskProvider
            .updateTask(
              id: task.id,
              goalId: goalId,
              subGoalId: null,
              clearScheduledDate: true,
            )
            .then((_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Task pushed back to ${goals.firstWhere((g) => g.id == goalId).title}',
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.success.withValues(alpha: 0.8),
                  ),
                );
              }
            });
        return;
      }

      // Show subgoal picker
      showDialog<String>(
        context: context,
        builder: (subCtx) => AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Select Sub-Goal',
            style: TextStyle(color: colorScheme.onSurface),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: subGoals.length + 1,
              itemBuilder: (ctx, i) {
                if (i == 0) {
                  return ListTile(
                    leading: const Icon(
                      Icons.flag_rounded,
                      color: AppColors.neonGreen,
                    ),
                    title: Text(
                      'No Sub-Goal (Goal-level)',
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                    onTap: () => Navigator.of(subCtx).pop('__goal_only__'),
                  );
                }
                final sg = subGoals[i - 1];
                return ListTile(
                  leading: Icon(
                    Icons.layers_outlined,
                    color: colorScheme.primary,
                  ),
                  title: Text(
                    sg.title,
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  subtitle: Text(
                    '${(sg.progress * 100).round()}% complete',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  onTap: () => Navigator.of(subCtx).pop(sg.id),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(subCtx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ).then((subGoalId) {
        if (subGoalId == null || !context.mounted) return;

        if (subGoalId == '__goal_only__') {
          taskProvider.updateTask(
            id: task.id,
            goalId: goalId,
            subGoalId: null,
            clearScheduledDate: true,
          );
        } else {
          taskProvider.updateTask(
            id: task.id,
            goalId: goalId,
            subGoalId: subGoalId,
            clearScheduledDate: true,
          );
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Task pushed back to goal'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.success.withValues(alpha: 0.8),
            ),
          );
        }
      });
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final goalProvider = context.watch<GoalProvider>();
    final subGoalProvider = context.watch<SubGoalProvider>();
    final todayTasks = taskProvider.getTodayTasks();
    final viewModels = todayTasks
        .map((t) => TodayTaskViewModel.fromTaskModel(t))
        .toList();
    final completedCount = viewModels.where((t) => t.isCompleted).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInUp(
          delay: const Duration(milliseconds: 100),
          offset: 8,
          child: _TodayTasksHeader(
            completedCount: completedCount,
            totalCount: viewModels.length,
            onAddTask: () => _showCreateTaskDialog(context, taskProvider),
          ),
        ),
        AppGaps.v8,
        if (viewModels.isNotEmpty)
          ...viewModels.asMap().entries.map((entry) {
            final index = entry.key;
            final taskVm = entry.value;
            final taskModel = todayTasks[index];
            return FadeInUp(
              delay: Duration(milliseconds: 60 * index),
              offset: 10,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: RepaintBoundary(
                  child: TaskCard(
                    task: taskVm,
                    onToggle: () {
                      taskProvider.toggleTaskCompletion(taskVm.id);
                    },
                    onEdit: () =>
                        _showEditTaskDialog(context, taskModel, taskProvider),
                    onDelete: () =>
                        _confirmDeleteTask(context, taskModel, taskProvider),
                    onPushBackToGoal: () => _showPushBackToGoalDialog(
                      context,
                      taskModel,
                      taskProvider,
                      goalProvider,
                      subGoalProvider,
                    ),
                  ),
                ),
              ),
            );
          })
        else
          const _TodayTasksEmptyState(),
      ],
    );
  }
}

class _TodayTasksHeader extends StatelessWidget {
  const _TodayTasksHeader({
    required this.completedCount,
    required this.totalCount,
    required this.onAddTask,
  });

  final int completedCount;
  final int totalCount;
  final VoidCallback onAddTask;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
        color: colorScheme.surface,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Tasks',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                AppGaps.v2,
                Text(
                  '$completedCount of $totalCount done',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(progress * 100).round()}%',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                AppGaps.v2,
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    value: progress,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.neonBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppGaps.h10,
          _AddTaskButton(onPressed: onAddTask),
        ],
      ),
    );
  }
}

class _AddTaskButton extends StatelessWidget {
  const _AddTaskButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              colorScheme.primary.withValues(alpha: 0.18),
              colorScheme.primary.withValues(alpha: 0.08),
            ],
          ),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.36),
          ),
        ),
        child: Icon(
          Icons.add_rounded,
          size: 16,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

class _TodayTasksEmptyState extends StatelessWidget {
  const _TodayTasksEmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.25),
        ),
        color: colorScheme.surface,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Icon(
              Icons.wb_sunny_outlined,
              color: colorScheme.primary.withValues(alpha: 0.5),
              size: 18,
            ),
          ),
          AppGaps.v8,
          Text(
            'A fresh day awaits',
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          AppGaps.v2,
          Text(
            'Add a task to get started.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
