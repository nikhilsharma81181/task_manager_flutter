import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager_flutter/features/tasks/presentation/providers/home_state.dart';
import '../../domain/entities/task.dart';
import 'task_providers.dart';
import 'filter_providers.dart';

// COMPUTED/DERIVED STATE PROVIDERS

/// Computed provider for task statistics
final taskStatsProvider = Provider<TaskStats>((ref) {
  final tasksAsync = ref.watch(homeNotifierProvider);

  return tasksAsync.when(
    data: (tasks) {
      final total = tasks.length;
      final completed =
          tasks.where((t) => t.status == TaskStatus.completed).length;
      final inProgress =
          tasks.where((t) => t.status == TaskStatus.inProgress).length;
      final pending = tasks.where((t) => t.status == TaskStatus.pending).length;
      final overdue = tasks.where((t) {
        if (t.dueDate == null) return false;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final dueDate =
            DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
        return dueDate.isBefore(today) && t.status != TaskStatus.completed;
      }).length;

      return TaskStats(
        total: total,
        completed: completed,
        inProgress: inProgress,
        pending: pending,
        overdue: overdue,
        completionRate: total > 0 ? completed / total : 0.0,
      );
    },
    loading: () => const TaskStats.empty(),
    error: (_, __) => const TaskStats.empty(),
  );
});

/// Computed provider for tasks grouped by category
final tasksByCategoryProvider = Provider<Map<String, List<TaskEntity>>>((ref) {
  final tasksAsync = ref.watch(homeNotifierProvider);

  return tasksAsync.when(
    data: (tasks) {
      final grouped = <String, List<TaskEntity>>{};
      for (final task in tasks) {
        final category = task.categoryId;
        grouped.putIfAbsent(category, () => []).add(task);
      }
      return grouped;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

/// Computed provider for high priority tasks
final highPriorityTasksProvider = Provider<List<TaskEntity>>((ref) {
  final tasksAsync = ref.watch(homeNotifierProvider);

  return tasksAsync.when(
    data: (tasks) =>
        tasks.where((t) => t.priority == TaskPriority.high).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Computed provider for filtered tasks based on search and filters
final filteredTasksProvider = Provider<AsyncValue<List<TaskEntity>>>((ref) {
  final searchQuery = ref.watch(searchQueryProvider);
  final statusFilter = ref.watch(statusFilterProvider);
  final priorityFilter = ref.watch(priorityFilterProvider);
  final dateFilter = ref.watch(dateFilterProvider);
  final customStartDate = ref.watch(customStartDateProvider);
  final customEndDate = ref.watch(customEndDateProvider);
  final homeTasksAsync = ref.watch(homeNotifierProvider);

  return homeTasksAsync.when(
    data: (tasks) {
      var filtered = tasks;

      // Apply search filter
      if (searchQuery.isNotEmpty) {
        filtered = filtered.where((task) {
          return task.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
              task.description
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase());
        }).toList();
      }

      // Apply status filter
      if (statusFilter != null) {
        filtered =
            filtered.where((task) => task.status == statusFilter).toList();
      }

      // Apply priority filter
      if (priorityFilter != null) {
        filtered =
            filtered.where((task) => task.priority == priorityFilter).toList();
      }

      // Apply date filter
      if (dateFilter != DateFilter.all) {
        filtered = _applyDateFilter(
            filtered, dateFilter, customStartDate, customEndDate);
      }

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Helper function to apply date filtering
List<TaskEntity> _applyDateFilter(
  List<TaskEntity> tasks,
  DateFilter filter,
  DateTime? customStart,
  DateTime? customEnd,
) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final weekStart = today.subtract(Duration(days: today.weekday - 1));
  final weekEnd = weekStart.add(const Duration(days: 6));

  switch (filter) {
    case DateFilter.today:
      return tasks.where((task) {
        if (task.dueDate == null) return false;
        final dueDate = DateTime(
            task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
        return dueDate.isAtSameMomentAs(today);
      }).toList();

    case DateFilter.tomorrow:
      return tasks.where((task) {
        if (task.dueDate == null) return false;
        final dueDate = DateTime(
            task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
        return dueDate.isAtSameMomentAs(tomorrow);
      }).toList();

    case DateFilter.thisWeek:
      return tasks.where((task) {
        if (task.dueDate == null) return false;
        final dueDate = DateTime(
            task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
        return dueDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
            dueDate.isBefore(weekEnd.add(const Duration(days: 1)));
      }).toList();

    case DateFilter.overdue:
      return tasks.where((task) {
        if (task.dueDate == null) return false;
        final dueDate = DateTime(
            task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
        return dueDate.isBefore(today) && task.status != TaskStatus.completed;
      }).toList();

    case DateFilter.custom:
      if (customStart == null || customEnd == null) return tasks;
      return tasks.where((task) {
        if (task.dueDate == null) return false;
        final dueDate = DateTime(
            task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
        final start =
            DateTime(customStart.year, customStart.month, customStart.day);
        final end = DateTime(customEnd.year, customEnd.month, customEnd.day);
        return dueDate.isAfter(start.subtract(const Duration(days: 1))) &&
            dueDate.isBefore(end.add(const Duration(days: 1)));
      }).toList();

    case DateFilter.all:
    default:
      return tasks;
  }
}

// HELPER CLASSES

class TaskStats {
  final int total;
  final int completed;
  final int inProgress;
  final int pending;
  final int overdue;
  final double completionRate;

  const TaskStats({
    required this.total,
    required this.completed,
    required this.inProgress,
    required this.pending,
    required this.overdue,
    required this.completionRate,
  });

  const TaskStats.empty()
      : total = 0,
        completed = 0,
        inProgress = 0,
        pending = 0,
        overdue = 0,
        completionRate = 0.0;
}