import 'package:flutter/material.dart';
import 'package:habit_up/models/task_model.dart';
import 'package:habit_up/providers/calendar_provider.dart';
import 'package:habit_up/providers/task_provider.dart';
import 'package:habit_up/screens/calendar/widgets/calendar_day_agenda.dart';
import 'package:habit_up/screens/calendar/widgets/calendar_month_grid.dart';
import 'package:habit_up/screens/calendar/widgets/calendar_view_toggle.dart';
import 'package:habit_up/screens/calendar/widgets/calendar_week_bar.dart';
import 'package:habit_up/screens/tasks/widgets/task_details_screen.dart';
import 'package:habit_up/screens/tasks/widgets/task_details_models.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/theme/app_spacing.dart';
import 'package:habit_up/widgets/app_gaps.dart';
import 'package:provider/provider.dart';

/// The production-ready calendar screen for Habit Up.
///
/// Integrates with the existing scheduling engine, recurring task engine,
/// and provider hierarchy to deliver a real productivity timeline experience.
///
/// View modes:
/// - **Month**: Grid showing 5–6 weeks, task-dot density indicators
/// - **Week**: Day-by-day agenda for the selected week
/// - **Day**: Full agenda for the selected date
///
/// Synchronisation:
/// - Listens to [TaskProvider] for automatic refreshes
/// - All queries delegate to `TaskProvider` (no duplicate scheduling logic)
/// - Recurring tasks appear correctly on their effective dates
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final CalendarProvider _calendarProvider = CalendarProvider();

  @override
  void initState() {
    super.initState();
    // Connect to TaskProvider after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectProvider();
    });
  }

  void _connectProvider() {
    final taskProvider = context.read<TaskProvider>();
    _calendarProvider.connectTaskProvider(taskProvider);
  }

  @override
  void dispose() {
    _calendarProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _calendarProvider,
      builder: (context, _) {
        return Scaffold(
          body: _CalendarScreenContent(
            provider: _calendarProvider,
            onTaskTap: _openTaskDetails,
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddTaskDialog(context),
            backgroundColor: AppColors.neonCyan,
            child: const Icon(Icons.add, color: Colors.black),
          ),
        );
      },
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final titleController = TextEditingController();
    final descController = TextEditingController();
    TaskDifficulty difficulty = TaskDifficulty.medium;
    int xpReward = 5;
    TimeOfDay selectedTime = TimeOfDay.now();
    String? errorMessage;
    final selectedDate = _calendarProvider.selectedDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),            title: Text(
              'Add Task for ${_formatDateForDialog(selectedDate)}',
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
                if (title.isEmpty) {
                  setDialogState(() {
                    errorMessage = 'Please enter a task title';
                  });
                  return;
                }
                final taskProvider = context.read<TaskProvider>();
                final scheduledDate = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );
                await taskProvider.createTask(
                  id: 'task_${DateTime.now().millisecondsSinceEpoch}',
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
                'Add Task',
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateForDialog(DateTime date) {
    final months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final days = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  void _openTaskDetails(TaskModel task) {
    // Convert TaskModel to TaskDetailsViewModel for the detail screen
    final viewModel = _buildTaskDetailsViewModel(task);
    final taskProvider = context.read<TaskProvider>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TaskDetailsScreen(
          viewModel: viewModel,
          onEditTask: () => _showEditTaskDialog(task),
          onMarkComplete: () async {
            final isRecurring = task.repeatType != TaskRepeatType.none;
            if (isRecurring) {
              await taskProvider.completeRecurringTask(task.id);
            } else {
              await taskProvider.toggleTaskCompletion(task.id);
            }
            if (mounted) Navigator.of(context).maybePop();
          },
          onReschedule: () => _showRescheduleDialog(task),
          onDeleteTask: () {
            if (!mounted) return;
            taskProvider.deleteTask(task.id);
            Navigator.of(context).maybePop();
          },
          onPushToday: () async {
            await taskProvider.scheduleTaskForToday(task.id);
            if (mounted) Navigator.of(context).maybePop();
          },
          onPushTomorrow: () async {
            await taskProvider.scheduleTaskForTomorrow(task.id);
            if (mounted) Navigator.of(context).maybePop();
          },
          onPickDate: () => _showSchedulingDatePicker(task, taskProvider),
        ),
      ),
    );
  }

  void _showEditTaskDialog(TaskModel task) {
    final colorScheme = Theme.of(context).colorScheme;
    final titleController = TextEditingController(text: task.title);
    final descController = TextEditingController(text: task.description ?? '');
    TaskDifficulty difficulty = task.difficulty;
    int xpReward = task.xpReward;

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
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 2,
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
                  const SizedBox(height: 16),
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
              child: Text(
                'Cancel',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
            TextButton(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) return;
                final taskProvider = context.read<TaskProvider>();
                await taskProvider.updateTask(
                  id: task.id,
                  title: title,
                  description: descController.text.trim(),
                  difficulty: difficulty,
                  xpReward: xpReward,
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
      ),
    );
  }

  void _showSchedulingDatePicker(TaskModel task, TaskProvider taskProvider) {
    showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (pickerCtx, child) {
        return Theme(
          data: Theme.of(pickerCtx).copyWith(
            colorScheme: Theme.of(pickerCtx).colorScheme,
          ),
          child: child!,
        );
      },
    ).then((selectedDate) async {
      if (selectedDate == null || !mounted) return;
      await taskProvider.scheduleTaskForDate(task.id, selectedDate);
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  void _showRescheduleDialog(TaskModel task) {
    // Capture provider reference before the async gap
    final taskProvider = context.read<TaskProvider>();
    showDatePicker(
      context: context,
      initialDate: task.scheduledDate ?? task.dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (pickerCtx, child) {
        return Theme(
          data: Theme.of(pickerCtx).copyWith(
            colorScheme: Theme.of(pickerCtx).colorScheme,
          ),
          child: child!,
        );
      },
    ).then((selectedDate) {
      if (selectedDate == null) return;
      taskProvider.rescheduleTask(task.id, selectedDate);
    });
  }

  TaskDetailsViewModel _buildTaskDetailsViewModel(TaskModel task) {
    final timeString = task.startTime ?? task.scheduledDate;
    final formattedTime = timeString != null
        ? '${timeString.hour.toString().padLeft(2, '0')}:${timeString.minute.toString().padLeft(2, '0')}'
        : 'No time';

    final status = task.isCompleted
        ? TaskExecutionStatus.completed
        : (task.status == TaskStatus.overdue
              ? TaskExecutionStatus.overdue
              : (task.status == TaskStatus.scheduled
                    ? TaskExecutionStatus.scheduled
                    : TaskExecutionStatus.active));

    return TaskDetailsViewModel(
      title: task.title,
      subGoalLabel: task.description ?? 'No description',
      status: status,
      priority: task.difficulty == TaskDifficulty.hard
          ? TaskExecutionPriority.high
          : TaskExecutionPriority.medium,
      progress: task.isCompleted ? 1.0 : 0.0,
      xpReward: task.xpReward,
      streakBonusXp: 0,
      dueDateLabel: task.dueDate?.toIso8601String() ?? 'No due date',
      reminderLabel: task.reminderTime != null ? formattedTime : '',
      recurringLabel: _recurringLabel(task.repeatType),
      focusDurationLabel: task.estimatedFocusDurationMinutes != null
          ? '${task.estimatedFocusDurationMinutes} min'
          : 'No focus time',
      focusStreakDays: 0,
      intensityLabel: task.difficulty == TaskDifficulty.hard
          ? 'High'
          : (task.difficulty == TaskDifficulty.medium ? 'Medium' : 'Low'),
      description: task.description ?? '',
      timelineEvents: const [],
    );
  }

  String _recurringLabel(TaskRepeatType repeatType) {
    switch (repeatType) {
      case TaskRepeatType.daily:
        return 'Daily';
      case TaskRepeatType.weekly:
        return 'Weekly';
      case TaskRepeatType.monthly:
        return 'Monthly';
      case TaskRepeatType.custom:
        return 'Custom';
      case TaskRepeatType.none:
        return '';
    }
  }
}

class _CalendarScreenContent extends StatelessWidget {
  const _CalendarScreenContent({
    required this.provider,
    required this.onTaskTap,
  });

  final CalendarProvider provider;
  final ValueChanged<TaskModel> onTaskTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: _CalendarBackground()),
        SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              10,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            children: [
              // Top bar: month/year + today button
              _CalendarTopBar(provider: provider),
              AppGaps.v12,
              // View toggle
              Center(
                child: CalendarViewToggle(
                  viewMode: provider.viewMode,
                  onViewModeChanged: provider.setViewMode,
                ),
              ),
              AppGaps.v16,
              // Week bar (always visible for date navigation)
              CalendarWeekBar(
                provider: provider,
                onDateSelected: provider.selectDate,
              ),
              AppGaps.v16,
              // Active view
              _ActiveView(provider: provider, onTaskTap: onTaskTap),
            ],
          ),
        ),
      ],
    );
  }
}

class _CalendarTopBar extends StatelessWidget {
  const _CalendarTopBar({required this.provider});

  final CalendarProvider provider;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final monthLabel = months[provider.focusedMonth.month - 1];
    final yearLabel = provider.focusedMonth.year.toString();

    return Row(
      children: [
        // Navigation arrows
        _NavArrow(
          icon: Icons.chevron_left_rounded,
          onTap: provider.viewMode == CalendarViewMode.day
              ? provider.goToPreviousDay
              : (provider.viewMode == CalendarViewMode.week
                    ? provider.goToPreviousWeek
                    : provider.goToPreviousMonth),
        ),
        AppGaps.h8,
        // Month/Year label
        Expanded(
          child: GestureDetector(
            onTap: provider.goToToday,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monthLabel,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  yearLabel,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Today button
        GestureDetector(
          onTap: provider.goToToday,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
              ),
              color: colorScheme.primary.withValues(alpha: 0.08),
            ),
            child: Text(
              'Today',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
        ),
        AppGaps.h8,
        _NavArrow(
          icon: Icons.chevron_right_rounded,
          onTap: provider.viewMode == CalendarViewMode.day
              ? provider.goToNextDay
              : (provider.viewMode == CalendarViewMode.week
                    ? provider.goToNextWeek
                    : provider.goToNextMonth),
        ),
      ],
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.19),
          ),
          color: colorScheme.surface.withValues(alpha: 0.08),
        ),
        child: Icon(
          icon,
          size: 20,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

class _ActiveView extends StatelessWidget {
  const _ActiveView({required this.provider, required this.onTaskTap});

  final CalendarProvider provider;
  final ValueChanged<TaskModel> onTaskTap;

  @override
  Widget build(BuildContext context) {
    switch (provider.viewMode) {
      case CalendarViewMode.month:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CalendarMonthGrid(
              provider: provider,
              onDateSelected: (date) {
                provider.selectDate(date);
                // Show agenda below the grid when a date is tapped
              },
            ),
            AppGaps.v16,
            // Show the agenda for the selected date below the grid
            CalendarDayAgenda(provider: provider, onTaskTap: onTaskTap),
          ],
        );
      case CalendarViewMode.week:
        return CalendarDayAgenda(provider: provider, onTaskTap: onTaskTap);
      case CalendarViewMode.day:
        return CalendarDayAgenda(provider: provider, onTaskTap: onTaskTap);
    }
  }
}class _CalendarBackground extends StatelessWidget {
  const _CalendarBackground();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
      ),
      child: Stack(
        children: const [
          Positioned(
            top: -80,
            right: -50,
            child: _GlowBlob(size: 200, color: Color(0x123D6AFF)),
          ),
          Positioned(
            top: 200,
            left: -60,
            child: _GlowBlob(size: 160, color: Color(0x0C00E5FF)),
          ),
          Positioned(
            bottom: 100,
            right: -40,
            child: _GlowBlob(size: 140, color: Color(0x0800F5A0)),
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
            colors: <Color>[color, color.withValues(alpha: 0.0)],
          ),
        ),
      ),
    );
  }
}
