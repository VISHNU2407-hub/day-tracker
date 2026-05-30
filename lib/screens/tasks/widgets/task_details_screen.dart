import 'package:flutter/material.dart';
import 'package:habit_up/screens/tasks/widgets/task_details_actions_section.dart';
import 'package:habit_up/screens/tasks/widgets/task_details_completion_section.dart';
import 'package:habit_up/screens/tasks/widgets/task_details_fallback_panel.dart';
import 'package:habit_up/screens/tasks/widgets/task_details_focus_section.dart';
import 'package:habit_up/screens/tasks/widgets/task_details_models.dart';
import 'package:habit_up/screens/tasks/widgets/task_details_notes_section.dart';
import 'package:habit_up/screens/tasks/widgets/task_details_overview_card.dart';
import 'package:habit_up/screens/tasks/widgets/task_details_reminder_section.dart';
import 'package:habit_up/screens/tasks/widgets/task_details_rewards_section.dart';
import 'package:habit_up/screens/tasks/widgets/task_details_surface.dart';
import 'package:habit_up/screens/tasks/widgets/task_details_timeline_section.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/theme/app_spacing.dart';

class TaskDetailsScreen extends StatelessWidget {
  const TaskDetailsScreen({
    required this.viewModel,
    this.onEditTask,
    this.onMarkComplete,
    this.onReschedule,
    this.onDeleteTask,
    this.onPushToday,
    this.onPushTomorrow,
    this.onPickDate,
    super.key,
  });

  final TaskDetailsViewModel viewModel;
  final VoidCallback? onEditTask;
  final VoidCallback? onMarkComplete;
  final VoidCallback? onReschedule;
  final VoidCallback? onDeleteTask;
  final VoidCallback? onPushToday;
  final VoidCallback? onPushTomorrow;
  final VoidCallback? onPickDate;

  bool get _isCompleted => viewModel.status == TaskExecutionStatus.completed;
  bool get _hasReminder => viewModel.reminderLabel.trim().isNotEmpty;
  bool get _hasSchedule => viewModel.timelineEvents.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _TaskDetailsBackground()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                10,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              children: [
                _TaskDetailsHeader(
                  title: viewModel.title,
                  subGoalLabel: viewModel.subGoalLabel,
                  onEditTask: onEditTask,
                ),
                const SizedBox(height: AppSpacing.md),
                TaskDetailsOverviewCard(viewModel: viewModel),
                const SizedBox(height: AppSpacing.sm),
                TaskDetailsCompletionSection(
                  isCompleted: _isCompleted,
                  xpReward: viewModel.xpReward,
                  streakDays: viewModel.focusStreakDays,
                  onToggleCompleted: onMarkComplete,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (_hasReminder)
                  TaskDetailsReminderSection(
                    reminderLabel: viewModel.reminderLabel,
                    dueLabel: viewModel.dueDateLabel,
                    recurringLabel: viewModel.recurringLabel,
                    focusDurationLabel: viewModel.focusDurationLabel,
                  )
                else
                  const TaskDetailsFallbackPanel(
                    title: 'No reminder set',
                    message:
                        'Add a reminder to protect execution timing for this task.',
                    icon: Icons.notifications_off_outlined,
                  ),
                const SizedBox(height: AppSpacing.sm),
                TaskDetailsFocusSection(
                  focusDurationLabel: viewModel.focusDurationLabel,
                  focusStreakDays: viewModel.focusStreakDays,
                  intensityLabel: viewModel.intensityLabel,
                ),
                const SizedBox(height: AppSpacing.sm),
                TaskDetailsNotesSection(notes: viewModel.description),
                const SizedBox(height: AppSpacing.sm),
                TaskDetailsRewardsSection(
                  xpReward: viewModel.xpReward,
                  streakBonusXp: viewModel.streakBonusXp,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (_hasSchedule)
                  TaskDetailsTimelineSection(events: viewModel.timelineEvents)
                else
                  const TaskDetailsFallbackPanel(
                    title: 'No schedule blocks',
                    message:
                        'Create work blocks to reduce drift and improve completion reliability.',
                    icon: Icons.timeline_outlined,
                  ),
                const SizedBox(height: AppSpacing.sm),
                TaskDetailsSurface(
                  child: TaskDetailsActionsSection(
                    onMarkComplete: onMarkComplete,
                    onReschedule: onReschedule,
                    onEditTask: onEditTask,
                    onDeleteTask: onDeleteTask,
                    onPushToday: onPushToday,
                    onPushTomorrow: onPushTomorrow,
                    onPickDate: onPickDate,
                  ),
                ),
                if (_isCompleted) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const TaskDetailsFallbackPanel(
                    title: 'Completed task state',
                    message:
                        'Execution closed. Keep momentum by planning the next focused action.',
                    icon: Icons.verified_rounded,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskDetailsHeader extends StatelessWidget {
  const _TaskDetailsHeader({
    required this.title,
    required this.subGoalLabel,
    required this.onEditTask,
  });

  final String title;
  final String subGoalLabel;
  final VoidCallback? onEditTask;

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
                  subGoalLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.88),
                    height: 1.3,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          onPressed: onEditTask,
          style: IconButton.styleFrom(
            minimumSize: const Size(40, 40),
            backgroundColor: const Color(0xE016213C),
            side: const BorderSide(color: AppColors.border),
            foregroundColor: AppColors.neonCyan,
          ),
          icon: const Icon(Icons.edit_rounded),
        ),
      ],
    );
  }
}

class _TaskDetailsBackground extends StatelessWidget {
  const _TaskDetailsBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF0A1020), AppColors.background],
        ),
      ),
      child: Stack(
        children: const [
          Positioned(
            top: -58,
            right: -30,
            child: _GlowBlob(size: 138, color: Color(0x103E62F2)),
          ),
          Positioned(
            top: 270,
            left: -40,
            child: _GlowBlob(size: 100, color: Color(0x0900E5FF)),
          ),
          Positioned(
            bottom: 120,
            right: -45,
            child: _GlowBlob(size: 100, color: Color(0x0800F5A0)),
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
