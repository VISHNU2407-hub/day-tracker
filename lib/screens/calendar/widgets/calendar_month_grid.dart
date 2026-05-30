import 'package:flutter/material.dart';
import 'package:habit_up/motion/motion.dart';
import 'package:habit_up/providers/calendar_provider.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:habit_up/theme/app_spacing.dart';

/// Compact premium month grid showing day cells with task-density indicators.
///
/// Displays:
/// - Day-of-week header row (Mon–Sun)
/// - Date cells with task-dot indicators
/// - Overdue (red) and completion (green) visual cues
/// - Selected-date highlight ring
/// - Faded text for days outside the focused month
class CalendarMonthGrid extends StatelessWidget {
  const CalendarMonthGrid({
    required this.provider,
    required this.onDateSelected,
    super.key,
  });

  final CalendarProvider provider;
  final ValueChanged<DateTime> onDateSelected;

  static const List<String> _dayHeaders = <String>[
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dateInfos = provider.getMonthDateInfo();

    // Build a map for quick lookup
    final infoMap = <int, CalendarDateInfo>{};
    for (final info in dateInfos) {
      infoMap[info.date.day] = info;
    }

    // Calculate grid start and number of days
    final firstDay = DateTime(provider.focusedMonth.year, provider.focusedMonth.month, 1);
    // Start from Monday of the week containing the 1st
    final startDate = provider.weekStart(firstDay);
    final lastDay = DateTime(provider.focusedMonth.year, provider.focusedMonth.month + 1, 0);
    final endDate = provider.weekEnd(lastDay);
    final totalDays = endDate.difference(startDate).inDays + 1;
    // Calculate number of rows
    final rowCount = (totalDays / 7).ceil();

    return AnimatedSwitcher(
      duration: MotionDurations.fast,
      switchInCurve: MotionCurves.enter,
      switchOutCurve: MotionCurves.exit,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: Column(
        key: ValueKey<String>('${provider.focusedMonth.month}-${provider.focusedMonth.year}'),
        children: [
          // Day-of-week header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: List<Widget>.generate(7, (i) {
                return Expanded(
                  child: Center(
                    child: Text(
                      _dayHeaders[i],
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          // Day cells
          ...List<Widget>.generate(rowCount, (rowIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: List<Widget>.generate(7, (colIndex) {
                  final dayIndex = rowIndex * 7 + colIndex;
                  final date = startDate.add(Duration(days: dayIndex));
                  final isInMonth = provider.isInFocusedMonth(date);
                  final isSelected = date == provider.selectedDate;
                  final isToday = provider.isToday(date);
                  final info = infoMap[date.day];
                  final hasTasks = info?.hasTasks ?? false;
                  final allCompleted = info?.allCompleted ?? false;
                  final hasOverdue = info?.hasOverdue ?? false;

                  final score = info?.productivityScore ?? 0.0;
                  final hasActivity = info?.hasActivity ?? false;
                  final density = info?.productivityColor ?? AppColors.transparent;

                  return Expanded(
                    child: _DayCell(
                      date: date,
                      day: date.day,
                      isInMonth: isInMonth,
                      isSelected: isSelected,
                      isToday: isToday,
                      hasTasks: hasTasks,
                      allCompleted: allCompleted,
                      hasOverdue: hasOverdue,
                      hasActivity: hasActivity,
                      productivityScore: score,
                      productivityColor: density,
                      onTap: () => onDateSelected(date),
                      textTheme: textTheme,
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.day,
    required this.isInMonth,
    required this.isSelected,
    required this.isToday,
    required this.hasTasks,
    required this.allCompleted,
    required this.hasOverdue,
    required this.hasActivity,
    required this.productivityScore,
    required this.productivityColor,
    required this.onTap,
    required this.textTheme,
  });

  final DateTime date;
  final int day;
  final bool isInMonth;
  final bool isSelected;
  final bool isToday;
  final bool hasTasks;
  final bool allCompleted;
  final bool hasOverdue;
  final bool hasActivity;
  final double productivityScore;
  final Color productivityColor;
  final VoidCallback onTap;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        margin: const EdgeInsets.all(1.5),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.12)
              : (isToday && !isSelected
                  ? colorScheme.primary.withValues(alpha: 0.06)
                  : _backgroundColor),
          border: isSelected
              ? Border.all(color: colorScheme.primary.withValues(alpha: 0.5), width: 1.2)
              : (isToday
                  ? Border.all(color: colorScheme.primary.withValues(alpha: 0.25))
                  : (hasActivity
                      ? Border.all(color: productivityColor.withValues(alpha: 0.15))
                      : null)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Day number
            Text(
              day.toString(),
              style: textTheme.labelMedium?.copyWith(
                color: isInMonth
                    ? (isSelected
                        ? colorScheme.primary
                        : _dayTextColor(colorScheme))
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
                fontWeight: isSelected || isToday
                    ? FontWeight.w800
                    : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 3),
            // Productivity dot / indicator
            if (hasTasks && hasActivity)
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasOverdue
                      ? AppColors.error
                      : (allCompleted
                          ? AppColors.success
                          : productivityColor.withValues(alpha: 0.8)),
                ),
              )
            else
              const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  Color get _backgroundColor {
    if (!hasActivity || !isInMonth) return Colors.transparent;
    // Productivity heatmap: subtle tinted background
    final base = productivityColor;
    if (productivityScore >= 0.9) return base.withValues(alpha: 0.18);
    if (productivityScore >= 0.5) return base.withValues(alpha: 0.12);
    return base.withValues(alpha: 0.10);
  }

  Color _dayTextColor(ColorScheme colorScheme) {
    if (!hasActivity || !isInMonth) return colorScheme.onSurface;
    if (productivityScore >= 0.9) return const Color(0xFF3DDC97); // bright green
    if (productivityScore >= 0.5) return colorScheme.onSurface;
    return colorScheme.error.withValues(alpha: 0.85);
  }
}
