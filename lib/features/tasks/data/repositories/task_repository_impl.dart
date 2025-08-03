import 'package:fpdart/fpdart.dart';
import 'package:task_manager_flutter/core/errors/exceptions.dart';
import 'package:task_manager_flutter/core/errors/failures.dart';
import 'package:task_manager_flutter/features/tasks/data/datasources/local/task_local_datasource.dart';
import 'package:task_manager_flutter/features/tasks/data/datasources/remote/task_remote_datasource.dart';
import 'package:task_manager_flutter/features/tasks/domain/entities/task.dart';

import '../models/task_model.dart';
import '../../domain/repositories/task_repository.dart';

/// Task Repository Implementation - Clean Architecture Data Layer
/// 
/// This repository implements the Repository pattern, serving as the single source
/// of truth for task data operations. It coordinates between local and remote data
/// sources while maintaining offline-first architecture principles.
/// 
/// **Key Responsibilities:**
/// - Orchestrate data flow between domain and data layers
/// - Implement offline-first strategy (local storage as primary source)
/// - Handle error mapping from data layer to domain layer
/// - Coordinate sync operations for eventual consistency
/// - Maintain data consistency and integrity
/// 
/// **Offline-First Strategy:**
/// - All operations save to local SQLite database immediately
/// - Background sync queues operations for remote persistence
/// - Users never wait for network operations
/// - Conflicts resolved through timestamp-based last-write-wins
/// 
/// **Error Handling:**
/// Uses functional programming approach with Either<Failure, Success>
/// to provide type-safe error handling without exceptions.
class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDatasource _localDatasource;
  final TaskRemoteDatasource? _remoteDatasource;

  TaskRepositoryImpl(
    this._localDatasource, {
    TaskRemoteDatasource? remoteDatasource,
  }) : _remoteDatasource = remoteDatasource;

  @override
  Future<Either<Failure, List<TaskEntity>>> getAllTasks() async {
    try {
      final tasks = await _localDatasource.getAllTasks();
      final entities = tasks.map((task) => TaskEntity.fromModel(task)).toList();
      return Right(entities);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } on Exception catch (e) {
      return Left(
          DatabaseFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, TaskEntity>> getTaskById(String id) async {
    try {
      final task = await _localDatasource.getTaskById(id);
      if (task != null) {
        return Right(TaskEntity.fromModel(task));
      } else {
        return const Left(NotFoundFailure('Task not found'));
      }
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } on Exception catch (e) {
      return Left(
          DatabaseFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> createTask(TaskEntity task) async {
    try {
      final taskModel = TaskModel.fromEntity(task);
      final taskId = await _localDatasource.createTask(taskModel);
      return Right(taskId);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } on Exception catch (e) {
      return Left(
          DatabaseFailure('Failed to create task: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateTask(TaskEntity task) async {
    try {
      final taskModel = TaskModel.fromEntity(task);
      final success = await _localDatasource.updateTask(taskModel);
      return Right(success);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } on Exception catch (e) {
      return Left(
          DatabaseFailure('Failed to update task: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteTask(String id) async {
    try {
      final success = await _localDatasource.deleteTask(id);
      return Right(success);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } on Exception catch (e) {
      return Left(
          DatabaseFailure('Failed to delete task: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<TaskEntity>>> searchTasks(String query) async {
    try {
      final tasks = await _localDatasource.searchTasks(query);
      final entities = tasks.map((task) => TaskEntity.fromModel(task)).toList();
      return Right(entities);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } on Exception catch (e) {
      return Left(DatabaseFailure('Search failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<TaskEntity>>> getTasksByStatus(
      TaskStatus status) async {
    try {
      final tasks = await _localDatasource.getTasksByStatus(status);
      final entities = tasks.map((task) => TaskEntity.fromModel(task)).toList();
      return Right(entities);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } on Exception catch (e) {
      return Left(
          DatabaseFailure('Failed to fetch tasks: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<TaskEntity>>> getTasksByCategory(
      String categoryId) async {
    try {
      final tasks = await _localDatasource.getTasksByCategory(categoryId);
      final entities = tasks.map((task) => TaskEntity.fromModel(task)).toList();
      return Right(entities);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } on Exception catch (e) {
      return Left(
          DatabaseFailure('Failed to fetch tasks: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> markTaskAsCompleted(String id) async {
    try {
      final taskResult = await getTaskById(id);
      return taskResult.fold(
        (failure) => Left(failure),
        (task) async {
          final completedTask = task.copyWith(
            status: TaskStatus.completed,
            lastModified: DateTime.now(),
          );
          return await updateTask(completedTask);
        },
      );
    } catch (e) {
      return Left(DatabaseFailure(
          'Failed to mark task as completed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<TaskEntity>>> getOverdueTasks() async {
    try {
      final tasks = await _localDatasource.getOverdueTasks();
      final entities = tasks.map((task) => TaskEntity.fromModel(task)).toList();
      return Right(entities);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } on Exception catch (e) {
      return Left(DatabaseFailure(
          'Failed to fetch overdue tasks: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<TaskEntity>>> getTasksDueToday() async {
    try {
      final tasks = await _localDatasource.getTasksDueToday();
      final entities = tasks.map((task) => TaskEntity.fromModel(task)).toList();
      return Right(entities);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } on Exception catch (e) {
      return Left(DatabaseFailure(
          'Failed to fetch tasks due today: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<TaskEntity>>> getAllCompletedTasks() async {
    try {
      final tasks = await _localDatasource.getTasksByStatus(TaskStatus.completed);
      final entities = tasks.map((task) => TaskEntity.fromModel(task)).toList();
      return Right(entities);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } on Exception catch (e) {
      return Left(DatabaseFailure(
          'Failed to fetch completed tasks: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> getTaskCount() async {
    try {
      final count = await _localDatasource.getTaskCount();
      return Right(count);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } on Exception catch (e) {
      return Left(DatabaseFailure(
          'Failed to get task count: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> clearAllTasks() async {
    try {
      await _localDatasource.clearAllTasks();
      return Right(null);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } on Exception catch (e) {
      return Left(
          DatabaseFailure('Failed to clear tasks: ${e.toString()}'));
    }
  }
}
