import 'package:flutter/material.dart';
import 'package:habit_up/motion/motion.dart';
import 'package:habit_up/models/task_model.dart';
import 'package:habit_up/providers/task_provider.dart';
import 'package:habit_up/routes/app_routes.dart';
import 'package:habit_up/screens/calendar/calendar_screen.dart';
import 'package:habit_up/screens/goals/widgets/goals_main_page.dart';
import 'package:habit_up/screens/tasks/widgets/task_dashboard_header_cards_section.dart';
import 'package:habit_up/theme/app_colors.dart';
import 'package:provider/provider.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({required this.currentRoute, super.key});

  final String currentRoute;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  static const List<_NavItem> _items = [
    _NavItem(
      route: AppRoutes.tasks,
      label: 'Tasks',
      icon: Icons.checklist_rounded,
      subtitle: 'Track habits and stay on pace.',
    ),
    _NavItem(
      route: AppRoutes.goals,
      label: 'Goals',
      icon: Icons.flag_circle_rounded,
      subtitle: 'Define measurable outcomes.',
    ),
    _NavItem(
      route: AppRoutes.calendar,
      label: 'Calendar',
      icon: Icons.calendar_month_rounded,
      subtitle: 'Plan consistency day by day.',
    ),
    _NavItem(
      route: AppRoutes.friends,
      label: 'Friends',
      icon: Icons.groups_2_rounded,
      subtitle: 'Stay accountable with your crew.',
    ),
  ];

  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = _indexFromRoute(widget.currentRoute);
  }

  @override
  void didUpdateWidget(covariant MainNavigationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentRoute != widget.currentRoute) {
      _currentIndex = _indexFromRoute(widget.currentRoute);
    }
  }

  int _indexFromRoute(String route) {
    final index = _items.indexWhere((item) => item.route == route);
    return index >= 0 ? index : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedTabTransition(
          keyValue: _currentIndex,
          child: IndexedStack(
            index: _currentIndex,
            children: List<Widget>.generate(_items.length, (index) {
              if (index == 0) {
                // Tasks tab — show real live dashboard
                return const TaskDashboardHeaderCardsSection();
              }
              if (index == 1) {
                // Goals tab — show real goals page
                return const GoalsMainPage();
              }
              if (index == 2) {
                // Calendar tab — show real calendar
                return const CalendarScreen();
              }
              // Friends tab — placeholder (future feature)
              final item = _items[index];
              return _FriendsPlaceholder(item: item);
            }),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        backgroundColor: AppColors.neonCyan,
        elevation: 8,
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _PremiumDockedNavBar(
        currentIndex: _currentIndex,
        items: _items,
        onTap: (index) {
          if (index == _currentIndex) {
            return;
          }
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final taskProvider = context.read<TaskProvider>();
    _showInlineCreateTaskDialog(context, taskProvider);
  }

  void _showInlineCreateTaskDialog(
    BuildContext context,
    TaskProvider taskProvider,
  ) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    TaskDifficulty difficulty = TaskDifficulty.medium;
    int xpReward = 5;
    TimeOfDay selectedTime = TimeOfDay.now();
    String? errorMessage;

    final colorScheme = Theme.of(context).colorScheme;
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
                          return                        ChoiceChip(
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
                final now = DateTime.now();
                // Default to today's date
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
}

/// Simple inline placeholder for the Friends tab — avoids importing
/// the generic PlaceholderTabScreen that was used for Goals too.
class _FriendsPlaceholder extends StatelessWidget {
  const _FriendsPlaceholder({required this.item});

  final _NavItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              item.subtitle,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumDockedNavBar extends StatelessWidget {
  const _PremiumDockedNavBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      elevation: 12,
      color: colorScheme.surface,
      child: Container(
        height: 65,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              // Left side: Tasks and Goals
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _BottomNavItem(
                        item: items[0],
                        isActive: currentIndex == 0,
                        onTap: () => onTap(0),
                      ),
                    ),
                    Expanded(
                      child: _BottomNavItem(
                        item: items[1],
                        isActive: currentIndex == 1,
                        onTap: () => onTap(1),
                      ),
                    ),
                  ],
                ),
              ),
              // Spacer for FAB
              const SizedBox(width: 56),
              // Right side: Calendar and Friends
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _BottomNavItem(
                        item: items[2],
                        isActive: currentIndex == 2,
                        onTap: () => onTap(2),
                      ),
                    ),
                    Expanded(
                      child: _BottomNavItem(
                        item: items[3],
                        isActive: currentIndex == 3,
                        onTap: () => onTap(3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = colorScheme.primary;
    final inactiveColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.78);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isActive ? colorScheme.primary.withValues(alpha: 0.13) : Colors.transparent,
          border: isActive ? Border.all(color: colorScheme.primary.withValues(alpha: 0.26)) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 20,
              color: isActive ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                color: isActive ? activeColor : inactiveColor,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.route,
    required this.label,
    required this.icon,
    required this.subtitle,
  });

  final String route;
  final String label;
  final IconData icon;
  final String subtitle;
}
