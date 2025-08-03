import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager_flutter/features/tasks/domain/entities/task.dart';
import 'package:task_manager_flutter/features/tasks/presentation/providers/home_notifier.dart';
import 'package:task_manager_flutter/features/tasks/presentation/providers/task_form_notifier.dart';
import 'package:task_manager_flutter/features/tasks/presentation/providers/task_form_state.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/get_all_tasks.dart';
import '../../domain/usecases/delete_task.dart';
import '../../domain/usecases/update_task.dart';
import '../../domain/usecases/create_task.dart';

// CORE PROVIDERS - Main data providers

/// FutureProvider for all tasks with automatic caching and invalidation
final allTasksFutureProvider = FutureProvider<List<TaskEntity>>((ref) async {
  final getAllTasks = GetAllTasks(serviceLocator.taskRepository);
  final result = await getAllTasks(NoParams());

  return result.fold(
    (failure) => throw Exception(failure.message),
    (tasks) => tasks,
  );
});

/// Modern AsyncNotifierProvider for home page state management
final homeNotifierProvider =
    AsyncNotifierProvider<HomeNotifier, List<TaskEntity>>(() {
  return HomeNotifier(
    getAllTasks: GetAllTasks(serviceLocator.taskRepository),
    deleteTask: DeleteTask(serviceLocator.taskRepository),
    updateTask: UpdateTask(serviceLocator.taskRepository),
    analyticsService: serviceLocator.userAnalyticsService,
    settingsService: serviceLocator.settingsService,
  );
});

/// FutureProvider.family for task detail - simplified approach
final taskDetailProvider =
    FutureProvider.family<TaskEntity, String>((ref, taskId) async {
  final getAllTasks = GetAllTasks(serviceLocator.taskRepository);
  final result = await getAllTasks(NoParams());

  return result.fold(
    (failure) => throw Exception(failure.message),
    (tasks) {
      try {
        return tasks.firstWhere((task) => task.id == taskId);
      } catch (e) {
        throw Exception('Task with ID $taskId not found');
      }
    },
  );
});

/// StateNotifierProvider.family for task form management - simplified approach
final taskFormNotifierProvider = StateNotifierProvider.family<TaskFormNotifier,
    TaskFormState, TaskFormParams>((ref, params) {
  return TaskFormNotifier(
    createTask: CreateTask(serviceLocator.taskRepository),
    updateTask: UpdateTask(serviceLocator.taskRepository),
    mode: params.mode,
    initialTask: params.initialTask,
  );
});

// HELPER CLASSES

class TaskFormParams {
  final TaskFormMode mode;
  final TaskEntity? initialTask;

  TaskFormParams({
    required this.mode,
    this.initialTask,
  });
}
