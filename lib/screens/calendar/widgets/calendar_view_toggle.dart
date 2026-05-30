import 'package:flutter/material.dart';
import 'package:habit_up/providers/calendar_provider.dart';
/// Futuristic segmented toggle for switching between Month, Week, and Day views.
class CalendarViewToggle extends StatelessWidget {
  const CalendarViewToggle({
    required this.viewMode,
    required this.onViewModeChanged,
    super.key,
  });

  final CalendarViewMode viewMode;
  final ValueChanged<CalendarViewMode> onViewModeChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: colorScheme.surface.withValues(alpha: 0.09),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.19),
        ),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleOption(
            label: 'Month',
            isActive: viewMode == CalendarViewMode.month,
            onTap: () => onViewModeChanged(CalendarViewMode.month),
          ),
          const SizedBox(width: 2),
          _ToggleOption(
            label: 'Week',
            isActive: viewMode == CalendarViewMode.week,
            onTap: () => onViewModeChanged(CalendarViewMode.week),
          ),
          const SizedBox(width: 2),
          _ToggleOption(
            label: 'Day',
            isActive: viewMode == CalendarViewMode.day,
            onTap: () => onViewModeChanged(CalendarViewMode.day),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          color: isActive ? colorScheme.primary.withValues(alpha: 0.15) : Colors.transparent,
          border: isActive
              ? Border.all(color: colorScheme.primary.withValues(alpha: 0.35))
              : null,
        ),
        child: Text(
          label,
          style: textTheme.labelLarge?.copyWith(
            color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
