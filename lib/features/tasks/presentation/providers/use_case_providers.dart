import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/service_locator.dart';
import '../../domain/usecases/get_all_tasks.dart';
import '../../domain/usecases/delete_task.dart';
import '../../domain/usecases/update_task.dart';
import '../../domain/usecases/create_task.dart';

// USE CASE PROVIDERS - Foundation layer

final getAllTasksUseCaseProvider = Provider<GetAllTasks>((ref) {
  return GetAllTasks(serviceLocator.taskRepository);
});

final deleteTaskUseCaseProvider = Provider<DeleteTask>((ref) {
  return DeleteTask(serviceLocator.taskRepository);
});

final updateTaskUseCaseProvider = Provider<UpdateTask>((ref) {
  return UpdateTask(serviceLocator.taskRepository);
});

final createTaskUseCaseProvider = Provider<CreateTask>((ref) {
  return CreateTask(serviceLocator.taskRepository);
});