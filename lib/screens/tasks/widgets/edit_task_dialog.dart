import 'package:flutter/material.dart';
import 'package:habit_up/models/task_model.dart';
import 'package:habit_up/providers/task_provider.dart';
import 'package:habit_up/theme/app_colors.dart';

/// Shows the reusable Edit Task dialog.
///
/// Pre-fills all fields from [task], allows the user to change title,
/// description, date/time, and difficulty. On save, calls
/// [taskProvider.updateTask] which automatically triggers the
/// [ReminderSchedulingService] to cancel the old alarm and schedule a new one.
Future<void> showEditTaskDialog(
  BuildContext context,
  TaskModel task,
  TaskProvider taskProvider,
) async {
  final colorScheme = Theme.of(context).colorScheme;
  final titleController = TextEditingController(text: task.title);
  final descController = TextEditingController(text: task.description ?? '');
  TaskDifficulty difficulty = task.difficulty;
  int xpReward = task.xpReward;
  final initialTime = task.startTime ?? task.scheduledDate;
  TimeOfDay selectedTime = initialTime != null
      ? TimeOfDay(hour: initialTime.hour, minute: initialTime.minute)
      : TimeOfDay.now();

  await showDialog<void>(
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
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
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
                      color: colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.5),
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
                      color: colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.5),
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
                          colorScheme:
                              Theme.of(pickerCtx).colorScheme,
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
                        color: colorScheme.primary
                            .withValues(alpha: 0.3),
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
                          selectedColor: colorScheme.primary
                              .withValues(alpha: 0.15),
                          backgroundColor:
                              colorScheme.surfaceContainerHighest,
                          onSelected: (v) {
                            if (v) {
                              setDialogState(() {
                                difficulty = d;
                                xpReward = d == TaskDifficulty.easy
                                    ? 3
                                    : (d == TaskDifficulty.hard
                                        ? 7
                                        : 5);
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
  // Not disposing controllers here: they are local variables captured by
  // closures inside the dialog builder. During the dialog's exit animation
  // the overlay entry is still in the tree with an active TextInputConnection.
  // If a late text-input update from the platform arrives after dispose() but
  // before the overlay is removed, it hits a disposed controller -> crash.
  // The controllers are released when the route cleans up after the overlay
  // entry is fully removed (~1 frame later).
}
