import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/task.dart';
import '../../domain/usecases/get_all_tasks.dart';
import '../../domain/usecases/delete_task.dart';
import '../../domain/usecases/update_task.dart';
import '../../../../core/usecase/usecase.dart';


class TaskDetailNotifier extends AsyncNotifier<TaskEntity> {
  final String taskId;
  final GetAllTasks getAllTasks;
  final DeleteTask deleteTask;
  final UpdateTask updateTask;

  TaskDetailNotifier({
    required this.taskId,
    required this.getAllTasks,
    required this.deleteTask,
    required this.updateTask,
  });

  @override
  Future<TaskEntity> build() async {
    // AsyncNotifier automatically handles loading and error states
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
  }

  /// Refresh task - AsyncNotifier handles the state transitions automatically
  Future<void> refreshTask() async {
    ref.invalidateSelf();
  }

  /// Delete task and return success status
  Future<bool> deleteTaskById() async {
    final result = await deleteTask(DeleteTaskParams(id: taskId));
    
    return result.fold(
      (failure) {
        // Update state to show error
        state = AsyncValue.error(Exception(failure.message), StackTrace.current);
        return false;
      },
      (success) {
        // Task deleted successfully
        return true;
      },
    );
  }

  /// Toggle task status with optimistic updates
  Future<bool> toggleTaskStatus() async {
    final currentTask = state.valueOrNull;
    if (currentTask == null) return false;

    TaskStatus newStatus;
    switch (currentTask.status) {
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

    return await updateTaskStatus(newStatus);
  }

  /// Update task status with optimistic updates
  Future<bool> updateTaskStatus(TaskStatus newStatus) async {
    final currentTask = state.valueOrNull;
    if (currentTask == null) return false;

    // Create updated task for optimistic update
    final updatedTask = TaskEntity(
      id: currentTask.id,
      title: currentTask.title,
      description: currentTask.description,
      status: newStatus,
      priority: currentTask.priority,
      dueDate: currentTask.dueDate,
      categoryId: currentTask.categoryId,
      createdAt: currentTask.createdAt,
      isDeleted: currentTask.isDeleted,
      lastModified: DateTime.now(),
    );

    // Optimistic update
    state = AsyncValue.data(updatedTask);

    final result = await updateTask(UpdateTaskParams(
      id: currentTask.id,
      status: newStatus,
    ));

    return result.fold(
      (failure) {
        // Revert on failure
        state = AsyncValue.data(currentTask);
        return false;
      },
      (serverUpdatedTask) {
        // Update with server response
        state = AsyncValue.data(serverUpdatedTask);
        return true;
      },
    );
  }

  /// Update task priority with optimistic updates
  Future<bool> updateTaskPriority(TaskPriority newPriority) async {
    final currentTask = state.valueOrNull;
    if (currentTask == null) return false;

    // Create updated task for optimistic update
    final updatedTask = TaskEntity(
      id: currentTask.id,
      title: currentTask.title,
      description: currentTask.description,
      status: currentTask.status,
      priority: newPriority,
      dueDate: currentTask.dueDate,
      categoryId: currentTask.categoryId,
      createdAt: currentTask.createdAt,
      isDeleted: currentTask.isDeleted,
      lastModified: DateTime.now(),
    );

    // Optimistic update
    state = AsyncValue.data(updatedTask);

    final result = await updateTask(UpdateTaskParams(
      id: currentTask.id,
      priority: newPriority,
    ));

    return result.fold(
      (failure) {
        // Revert on failure
        state = AsyncValue.data(currentTask);
        return false;
      },
      (serverUpdatedTask) {
        // Update with server response
        state = AsyncValue.data(serverUpdatedTask);
        return true;
      },
    );
  }
}