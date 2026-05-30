import 'package:flutter/material.dart';
import 'package:habit_up/motion/motion.dart';
import 'package:habit_up/providers/calendar_provider.dart';
import 'package:habit_up/theme/app_colors.dart';

/// Compact horizontal week bar showing 7 days with task indicators.
///
/// Used as the primary date navigation in week and day views, and as a
/// supplementary navigation layer in month view.
class CalendarWeekBar extends StatelessWidget {
  const CalendarWeekBar({
    required this.provider,
    required this.onDateSelected,
    super.key,
  });

  final CalendarProvider provider;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final startOfWeek = provider.weekStart(provider.selectedDate);
    final weekDates = provider.getWeekDateInfo(startOfWeek);

    return AnimatedSwitcher(
      duration: MotionDurations.fast,
      switchInCurve: MotionCurves.enter,
      switchOutCurve: MotionCurves.exit,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Container(
        key: ValueKey<String>('week-${startOfWeek.toIso8601String()}'),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: colorScheme.surface.withValues(alpha: 0.07),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
        children: List<Widget>.generate(7, (index) {
          final info = weekDates[index];
          final date = info.date;
          final isSelected = date == provider.selectedDate;
          final isToday = provider.isToday(date);

          // Day-of-week abbreviation
          final dayNames = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];
          final dayName = dayNames[date.weekday - 1];

          return Expanded(
            child: GestureDetector(
              onTap: () => onDateSelected(date),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isSelected
                      ? colorScheme.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  border: isSelected
                      ? Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.4),
                          width: 1,
                        )
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Day name
                    Text(
                      dayName,
                      style: textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? colorScheme.primary
                            : (isToday
                                ? colorScheme.onSurface
                                : colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Day number
                    Text(
                      date.day.toString(),
                      style: textTheme.titleMedium?.copyWith(
                        color: isSelected
                            ? colorScheme.primary
                            : (isToday
                                ? colorScheme.onSurface
                                : colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                        fontWeight:
                            isSelected || isToday ? FontWeight.w800 : FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Task density dot
                    if (info.hasTasks)
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: info.hasOverdue
                              ? AppColors.error
                              : (info.allCompleted
                                  ? AppColors.success
                                  : colorScheme.primary.withValues(alpha: 0.5)),
                        ),
                      )
                    else
                      const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
      ),
    );
  }
}
