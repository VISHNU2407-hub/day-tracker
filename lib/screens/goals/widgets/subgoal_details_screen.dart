import 'package:flutter/material.dart';
import 'package:habit_up/models/sub_goal_model.dart';
import 'package:habit_up/models/task_model.dart';
import 'package:habit_up/providers/sub_goal_provider.dart';
import 'package:habit_up/providers/task_provider.dart';
import 'package:habit_up/screens/goals/widgets/subgoal_details_models.dart';

import 'package:habit_up/screens/goals/widgets/subgoal_progress_overview_section.dart';
import 'package:habit_up/screens/goals/widgets/subgoal_task_card.dart';
import 'package:habit_up/screens/goals/widgets/subgoal_tasks_empty_state.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/theme/app_spacing.dart';
import 'package:provider/provider.dart';

class SubGoalDetailsScreen extends StatefulWidget {
  const SubGoalDetailsScreen({
    required this.subGoalId,
    required this.goalId,
    this.goalAccent = const Color(0xFFB18BFF),
    super.key,
  });

  final String subGoalId;
  final String goalId;
  final Color goalAccent;

  @override
  State<SubGoalDetailsScreen> createState() => _SubGoalDetailsScreenState();
}

class _SubGoalDetailsScreenState extends State<SubGoalDetailsScreen> {
  void _showCreateTaskDialog(
    BuildContext context,
    SubGoalModel subGoal,
    TaskProvider taskProvider,
  ) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    TaskDifficulty difficulty = TaskDifficulty.medium;
    int xpReward = 5;
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF121734),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Create Task',
            style: TextStyle(color: AppColors.textPrimary),
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
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Task title *',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF11172B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Description (optional)',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF11172B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Time picker — mandatory
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppColors.neonCyan,
                              onPrimary: Colors.black,
                              surface: Color(0xFF121734),
                              onSurface: AppColors.textPrimary,
                            ),
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
                        color: const Color(0xFF11172B),
                        border: Border.all(color: const Color(0x4D4D7CFF)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 18,
                            color: AppColors.neonCyan,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Time: ${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Difficulty:',
                        style: TextStyle(
                          color: AppColors.textSecondary,
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
                                    ? AppColors.neonCyan
                                    : AppColors.textSecondary,
                              ),
                            ),
                            selected: selected,
                            selectedColor: AppColors.neonCyan.withValues(
                              alpha: 0.15,
                            ),
                            backgroundColor: const Color(0xFF11172B),
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
                      const Text(
                        'XP Reward:',
                        style: TextStyle(
                          color: AppColors.textSecondary,
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
                          '$xpReward XP',
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) return;
                final nowMs = DateTime.now().millisecondsSinceEpoch;
                final taskId = 'task_$nowMs';
                final now = DateTime.now();
                final scheduledDate = DateTime(
                  now.year,
                  now.month,
                  now.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );
                // Capture provider reference BEFORE async gap
                final sp = ctx.read<SubGoalProvider>();
                await taskProvider.createTask(
                  id: taskId,
                  title: title,
                  difficulty: difficulty,
                  xpReward: xpReward,
                  description: descController.text.trim(),
                  startTime: scheduledDate,
                  scheduledDate: scheduledDate,
                  goalId: widget.goalId,
                  subGoalId: widget.subGoalId,
                );
                // Link task to subgoal
                await sp.addTaskToSubGoal(widget.subGoalId, taskId);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text(
                'Create',
                style: TextStyle(color: AppColors.neonCyan),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subGoalProvider = context.watch<SubGoalProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final subGoal = subGoalProvider.getSubGoalById(widget.subGoalId);
    final textTheme = Theme.of(context).textTheme;

    if (subGoal == null) {
      return Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: _SubGoalDetailsBackground()),
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.widgets_outlined,
                      size: 48,
                      color: Color(0x44FFFFFF),
                    ),
                    const SizedBox(height: 16),
                    Text('Sub-goal not found', style: textTheme.titleMedium),
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

    final tasks = taskProvider.getTasksForSubGoal(widget.subGoalId);
    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final pendingTasks = tasks.where((t) => !t.isCompleted).length;
    final totalXp = tasks.fold<int>(
      0,
      (sum, t) => sum + (t.isCompleted ? t.xpReward : 0),
    );
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _SubGoalDetailsBackground()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                8,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              children: [
                _SubGoalDetailsHeader(
                  title: subGoal.title,
                  subtitle:
                      subGoal.description ??
                      subGoal.motivationalSubtitle ??
                      'Execute with precision.',
                  onEdit: () =>
                      _showEditSubGoalDialog(context, subGoal, subGoalProvider),
                  onDelete: () =>
                      _confirmDeleteSubGoal(context, subGoal, subGoalProvider),
                ),
                const SizedBox(height: AppSpacing.md),
                SubGoalProgressOverviewSection(
                  progress: subGoal.progress,
                  completedTasks: completedTasks,
                  totalTasks: tasks.length,
                  activeStreakDays: subGoal.streak,
                  timelineSummary: subGoal.deadline != null
                      ? 'Deadline: ${subGoal.deadline!.day}/${subGoal.deadline!.month}'
                      : 'No deadline set',
                ),
                const SizedBox(height: 10),
                // Compact 4-card analytics row
                _CompactSubGoalStats(
                  totalTasks: tasks.length,
                  completedTasks: completedTasks,
                  pendingTasks: pendingTasks,
                  totalXp: totalXp,
                ),
                const SizedBox(height: 12),
                _TaskSectionHeader(
                  completedTasks: completedTasks,
                  totalTasks: tasks.length,
                  onAddTask: () =>
                      _showCreateTaskDialog(context, subGoal, taskProvider),
                ),
                const SizedBox(height: 8),
                if (tasks.isEmpty)
                  SubGoalTasksEmptyState(
                    onCreateFirstTask: () =>
                        _showCreateTaskDialog(context, subGoal, taskProvider),
                  )
                else
                  ...tasks.map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Column(
                        children: [
                          SubGoalTaskCard(
                            task: _toSubGoalTaskViewModel(task),
                            onToggleComplete: () async {
                              await taskProvider.toggleTaskCompletion(task.id);
                              final updatedTasks = taskProvider
                                  .getTasksForSubGoal(widget.subGoalId);
                              final completedCount = updatedTasks
                                  .where((t) => t.isCompleted)
                                  .length;
                              await subGoalProvider.calculateProgressFromTasks(
                                subGoalId: widget.subGoalId,
                                completedTaskCount: completedCount,
                                totalTaskCount: updatedTasks.length,
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          // Scheduling action row
                          _ScheduleActionsRow(
                            onPushToday: () async {
                              await taskProvider.scheduleTaskForToday(task.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Task scheduled for today'),
                                    behavior: SnackBarBehavior.floating,
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                            onPushTomorrow: () async {
                              await taskProvider.scheduleTaskForTomorrow(
                                task.id,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Task scheduled for tomorrow',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                            onPickDate: () => _showDatePickerForTask(
                              context,
                              task,
                              taskProvider,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ],
      ),
    );
  }

  SubGoalTaskItemViewModel _toSubGoalTaskViewModel(TaskModel task) {
    final state = task.isCompleted
        ? SubGoalTaskState.completed
        : (task.status == TaskStatus.overdue
              ? SubGoalTaskState.overdue
              : SubGoalTaskState.active);
    final priority = task.difficulty == TaskDifficulty.hard
        ? SubGoalTaskPriority.critical
        : (task.difficulty == TaskDifficulty.medium
              ? SubGoalTaskPriority.high
              : SubGoalTaskPriority.medium);
    return SubGoalTaskItemViewModel(
      title: task.title,
      subtitle: task.description ?? '',
      priority: priority,
      xpReward: task.xpReward,
      dueLabel: task.dueDate != null
          ? '${task.dueDate!.hour}:${task.dueDate!.minute.toString().padLeft(2, '0')}'
          : (task.scheduledDate != null
                ? '${task.scheduledDate!.day}/${task.scheduledDate!.month}'
                : 'No date'),
      state: state,
      progress: task.isCompleted ? 1.0 : 0.0,
      hasReminder: task.reminderTime != null,
    );
  }

  void _showEditSubGoalDialog(
    BuildContext context,
    SubGoalModel subGoal,
    SubGoalProvider provider,
  ) {
    final titleController = TextEditingController(text: subGoal.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF121734),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Edit Sub-Goal',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: titleController,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF11172B),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              await provider.updateSubGoal(id: subGoal.id, title: title);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text(
              'Save',
              style: TextStyle(color: AppColors.neonCyan),
            ),
          ),
        ],
      ),
    );
  }

  void _showDatePickerForTask(
    BuildContext context,
    TaskModel task,
    TaskProvider taskProvider,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: task.scheduledDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.neonCyan,
            onPrimary: Colors.black,
            surface: Color(0xFF121734),
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && context.mounted) {
      await taskProvider.scheduleTaskForDate(task.id, picked);
    }
  }

  void _confirmDeleteSubGoal(
    BuildContext context,
    SubGoalModel subGoal,
    SubGoalProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF121734),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Sub-Goal',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Delete "${subGoal.title}"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              await provider.deleteSubGoal(subGoal.id);
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                Navigator.of(context).maybePop();
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.neonPink),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubGoalDetailsHeader extends StatelessWidget {
  const _SubGoalDetailsHeader({
    required this.title,
    required this.subtitle,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final String subtitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.88),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: AppColors.neonCyan),
          color: const Color(0xFF121734),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(
                  Icons.edit_rounded,
                  color: AppColors.neonCyan,
                  size: 20,
                ),
                title: Text(
                  'Edit',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(
                  Icons.delete_rounded,
                  color: AppColors.neonPink,
                  size: 20,
                ),
                title: Text(
                  'Delete',
                  style: TextStyle(color: AppColors.neonPink),
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

class _TaskSectionHeader extends StatelessWidget {
  const _TaskSectionHeader({
    required this.completedTasks,
    required this.totalTasks,
    required this.onAddTask,
  });

  final int completedTasks;
  final int totalTasks;
  final VoidCallback? onAddTask;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tasks',
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$completedTasks of $totalTasks completed',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: onAddTask,
          borderRadius: BorderRadius.circular(11),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0x2A3B63D9), Color(0x1400CFFF)],
              ),
              border: Border.all(color: const Color(0x4D4D7CFF)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add_rounded,
                  size: 14,
                  color: AppColors.neonCyan,
                ),
                const SizedBox(width: 4),
                Text(
                  'Add Task',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.neonCyan,
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

class _SubGoalDetailsBackground extends StatelessWidget {
  const _SubGoalDetailsBackground();

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
            top: -60,
            right: -35,
            child: _GlowBlob(size: 150, color: Color(0x143E62F2)),
          ),
          Positioned(
            top: 280,
            left: -45,
            child: _GlowBlob(size: 120, color: Color(0x0D00E5FF)),
          ),
          Positioned(
            bottom: 90,
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

/// Compact 4-card analytics row for subgoal details.
class _CompactSubGoalStats extends StatelessWidget {
  const _CompactSubGoalStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.totalXp,
  });

  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int totalXp;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _MiniStat(
            label: 'Total',
            value: '$totalTasks',
            accent: AppColors.neonBlue,
            textTheme: textTheme,
          ),
          const SizedBox(width: 6),
          _MiniStat(
            label: 'Done',
            value: '$completedTasks',
            accent: AppColors.success,
            textTheme: textTheme,
          ),
          const SizedBox(width: 6),
          _MiniStat(
            label: 'Left',
            value: '$pendingTasks',
            accent: AppColors.warning,
            textTheme: textTheme,
          ),
          const SizedBox(width: 6),
          _MiniStat(
            label: 'XP',
            value: '$totalXp',
            accent: AppColors.neonCyan,
            textTheme: textTheme,
          ),
        ],
      ),
    );
  }
}

class _ScheduleActionsRow extends StatelessWidget {
  const _ScheduleActionsRow({
    required this.onPushToday,
    required this.onPushTomorrow,
    required this.onPickDate,
  });

  final VoidCallback onPushToday;
  final VoidCallback onPushTomorrow;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ScheduleChip(
              icon: Icons.wb_sunny_outlined,
              label: 'Today',
              color: AppColors.neonCyan,
              onTap: onPushToday,
              textTheme: textTheme,
            ),
            const SizedBox(width: 6),
            _ScheduleChip(
              icon: Icons.nightlight_round,
              label: 'Tomorrow',
              color: AppColors.neonBlue,
              onTap: onPushTomorrow,
              textTheme: textTheme,
            ),
            const SizedBox(width: 6),
            _ScheduleChip(
              icon: Icons.calendar_today_rounded,
              label: 'Pick Date',
              color: AppColors.warning,
              onTap: onPickDate,
              textTheme: textTheme,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleChip extends StatelessWidget {
  const _ScheduleChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.textTheme,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          color: color.withValues(alpha: 0.06),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.accent,
    required this.textTheme,
  });

  final String label;
  final String value;
  final Color accent;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
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
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
