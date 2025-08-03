import 'package:fpdart/fpdart.dart';
import 'package:task_manager_flutter/core/errors/failures.dart';
import 'package:task_manager_flutter/features/tasks/domain/entities/task.dart';

abstract class TaskRepository {
  Future<Either<Failure, List<TaskEntity>>> getAllTasks();
  Future<Either<Failure, List<TaskEntity>>> getTasksByCategory(
      String categoryId);
  Future<Either<Failure, List<TaskEntity>>> getTasksByStatus(TaskStatus status);
  Future<Either<Failure, List<TaskEntity>>> searchTasks(String query);
  Future<Either<Failure, TaskEntity>> getTaskById(String id);
  Future<Either<Failure, String>> createTask(TaskEntity task);
  Future<Either<Failure, bool>> updateTask(TaskEntity task);
  Future<Either<Failure, bool>> deleteTask(String id);
  Future<Either<Failure, bool>> markTaskAsCompleted(String id);
  Future<Either<Failure, List<TaskEntity>>> getOverdueTasks();
  Future<Either<Failure, List<TaskEntity>>> getTasksDueToday();
  Future<Either<Failure, List<TaskEntity>>> getAllCompletedTasks();
  Future<Either<Failure, int>> getTaskCount();
  Future<Either<Failure, void>> clearAllTasks();
}
