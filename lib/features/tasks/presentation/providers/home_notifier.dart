import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager_flutter/features/tasks/presentation/providers/pagination_providers.dart';
import '../../domain/entities/task.dart';
import '../../domain/usecases/get_all_tasks.dart';
import '../../domain/usecases/delete_task.dart';
import '../../domain/usecases/update_task.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/services/user_analytics_service.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/utils/task_sorter.dart';
import 'filter_providers.dart';

class HomeNotifier extends AsyncNotifier<List<TaskEntity>> {
  final GetAllTasks getAllTasks;
  final DeleteTask deleteTask;
  final UpdateTask updateTask;
  final UserAnalyticsService analyticsService;
  final SettingsService settingsService;

  HomeNotifier({
    required this.getAllTasks,
    required this.deleteTask,
    required this.updateTask,
    required this.analyticsService,
    required this.settingsService,
  });

  @override
  Future<List<TaskEntity>> build() async {
    final result = await getAllTasks(NoParams());

    return await result.fold(
      (failure) => throw Exception(failure.message),
      (tasks) async {
        return TaskSorter.sortByDateAndPriority(tasks);
      },
    );
  }

  Future<void> refreshTasks() async {
    ref.invalidateSelf();
  }

  Future<void> loadTasks() async {
    ref.invalidateSelf();
    await future;
  }

  void addTaskOptimistically(TaskEntity newTask) {
    final currentTasks = state.valueOrNull ?? [];
    final updatedTasks = [newTask, ...currentTasks];
    state = AsyncValue.data(updatedTasks);
  }

  void searchTasks(String query) {
    ref.read(searchQueryProvider.notifier).state = query;
  }

  void filterByStatus(TaskStatus? status) {
    ref.read(statusFilterProvider.notifier).state = status;
  }

  void filterByPriority(TaskPriority? priority) {
    ref.read(priorityFilterProvider.notifier).state = priority;
  }

  void clearAllFilters() {
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(statusFilterProvider.notifier).state = null;
    ref.read(priorityFilterProvider.notifier).state = null;
    ref.read(currentPageProvider.notifier).state = 1;
  }

  void loadMoreTasks() {
    ref.read(isLoadingMoreProvider.notifier).state = true;
    Future.delayed(const Duration(milliseconds: 150), () {
      ref.read(currentPageProvider.notifier).state++;
      ref.read(isLoadingMoreProvider.notifier).state = false;
    });
  }

  void filterByDate(dynamic dateFilter,
      {DateTime? startDate, DateTime? endDate}) {}

  void filterByCategory(String? category) {}

  List<TaskEntity> getFilteredTasks(String query) {
    final tasks = state.valueOrNull ?? [];
    if (query.isEmpty) return tasks;

    return tasks.where((task) {
      return task.title.toLowerCase().contains(query.toLowerCase()) ||
          task.description.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  List<TaskEntity> getTasksByStatus(TaskStatus? status) {
    final tasks = state.valueOrNull ?? [];
    if (status == null) return tasks;
    return tasks.where((task) => task.status == status).toList();
  }

  List<TaskEntity> getTasksByPriority(TaskPriority? priority) {
    final tasks = state.valueOrNull ?? [];
    if (priority == null) return tasks;
    return tasks.where((task) => task.priority == priority).toList();
  }

  List<TaskEntity> getOverdueTasks() {
    final tasks = state.valueOrNull ?? [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return tasks.where((task) {
      if (task.dueDate == null) return false;
      final dueDate =
          DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      return dueDate.isBefore(today) && task.status != TaskStatus.completed;
    }).toList();
  }

  List<TaskEntity> getTodayTasks() {
    final tasks = state.valueOrNull ?? [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return tasks.where((task) {
      if (task.dueDate == null) return false;
      final dueDate =
          DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      return dueDate.isAtSameMomentAs(today);
    }).toList();
  }

  Future<bool> deleteTaskById(String taskId) async {
    final currentTasks = state.valueOrNull ?? [];

    state = AsyncValue.data(
      currentTasks.where((task) => task.id != taskId).toList(),
    );

    final result = await deleteTask(DeleteTaskParams(id: taskId));

    return result.fold(
      (failure) {
        state = AsyncValue.data(currentTasks);
        return false;
      },
      (success) => true,
    );
  }

  Future<bool> updateTaskStatus(TaskEntity task, TaskStatus newStatus) async {
    final currentTasks = state.valueOrNull ?? [];

    final updatedTask = task.copyWith(
      status: newStatus,
      lastModified: DateTime.now(),
    );

    final optimisticTasks = currentTasks.map((t) {
      return t.id == task.id ? updatedTask : t;
    }).toList();

    state = AsyncValue.data(optimisticTasks);

    final result = await updateTask(UpdateTaskParams(
      id: task.id,
      status: newStatus,
    ));

    return await result.fold(
      (failure) {
        state = AsyncValue.data(currentTasks);
        return false;
      },
      (serverUpdatedTask) async {
        final finalTasks = currentTasks.map((t) {
          return t.id == task.id ? serverUpdatedTask : t;
        }).toList();

        state = AsyncValue.data(finalTasks);

        if (newStatus == TaskStatus.completed) {
          await analyticsService.recordTaskCompletion(serverUpdatedTask);
        }

        return true;
      },
    );
  }

  Future<bool> toggleTaskStatus(TaskEntity task) async {
    TaskStatus newStatus;
    switch (task.status) {
      case TaskStatus.pending:
        newStatus = TaskStatus.inProgress;
        break;
      case TaskStatus.inProgress:
        newStatus = TaskStatus.completed;
        break;
      case TaskStatus.completed:
        newStatus = TaskStatus.pending;
        break;
    }

    return await updateTaskStatus(task, newStatus);
  }

  Future<void> applySortingToCurrentTasks() async {
    final currentTasks = state.valueOrNull ?? [];
    if (currentTasks.isEmpty) return;

    final sortedTasks = TaskSorter.sortByDateAndPriority(currentTasks);
    state = AsyncValue.data(sortedTasks);
  }

  Future<bool> updateTaskPriority(
      TaskEntity task, TaskPriority newPriority) async {
    final currentTasks = state.valueOrNull ?? [];

    final updatedTask = task.copyWith(
      priority: newPriority,
      lastModified: DateTime.now(),
    );

    final optimisticTasks = currentTasks.map((t) {
      return t.id == task.id ? updatedTask : t;
    }).toList();

    state = AsyncValue.data(optimisticTasks);

    final result = await updateTask(UpdateTaskParams(
      id: task.id,
      priority: newPriority,
    ));

    return result.fold(
      (failure) {
        state = AsyncValue.data(currentTasks);
        return false;
      },
      (serverUpdatedTask) {
        final finalTasks = currentTasks.map((t) {
          return t.id == task.id ? serverUpdatedTask : t;
        }).toList();

        state = AsyncValue.data(finalTasks);
        return true;
      },
    );
  }

  Future<Map<String, dynamic>> getAnalyticsSummary() async {
    return await analyticsService.getAnalyticsSummary();
  }
}
