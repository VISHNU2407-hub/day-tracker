import 'package:flutter/material.dart';
import 'package:habit_up/screens/tasks/widgets/task_details_models.dart';
import 'package:habit_up/screens/tasks/widgets/task_details_surface.dart';
import 'package:habit_up/theme/app_colors.dart';

class TaskDetailsTimelineSection extends StatelessWidget {
  const TaskDetailsTimelineSection({
    required this.events,
    super.key,
  });

  final List<TaskTimelineEventViewModel> events;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return TaskDetailsSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Execution Timeline',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            'Scheduled execution blocks and reminder targets',
            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          if (events.isEmpty)
            Text(
              'No schedule blocks added yet.',
              style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            )
          else
            ...events.asMap().entries.map(
              (entry) => _TimelineItem(
                event: entry.value,
                isLast: entry.key == events.length - 1,
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.event,
    required this.isLast,
  });

  final TaskTimelineEventViewModel event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accent = event.isCompleted ? AppColors.success : AppColors.neonBlue;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(
              event.timeLabel,
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                ),
              ),
              if (!isLast)
                Container(
                  width: 1.5,
                  height: 15,
                  margin: const EdgeInsets.only(top: 2),
                  color: const Color(0x503D4F7C),
                ),
            ],
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 0.2),
              child: Text(
                event.title,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.95),
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
