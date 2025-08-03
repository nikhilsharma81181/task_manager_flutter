import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:task_manager_flutter/core/errors/failures.dart';

import 'package:task_manager_flutter/features/tasks/domain/entities/task.dart';
import 'package:uuid/uuid.dart';

import '../repositories/task_repository.dart';
import '../../../../core/usecase/usecase.dart';

class CreateTaskParams extends Equatable {
  final String title;
  final String description;
  final DateTime? dueDate;
  final TaskPriority priority;
  final String categoryId;

  const CreateTaskParams({
    required this.title,
    required this.description,
    this.dueDate,
    required this.priority,
    required this.categoryId,
  });

  @override
  List<Object?> get props =>
      [title, description, dueDate, priority, categoryId];
}

class CreateTask implements UseCase<TaskEntity, CreateTaskParams> {
  final TaskRepository repository;
  final Uuid _uuid = const Uuid();

  CreateTask(this.repository);

  @override
  Future<Either<Failure, TaskEntity>> call(CreateTaskParams params) async {
    // Business validation
    final validationResult = _validateTaskData(params);
    if (validationResult != null) {
      return Left(ValidationFailure(validationResult));
    }

    // Create task entity
    final now = DateTime.now();
    final task = TaskEntity(
      id: _uuid.v4(),
      title: params.title.trim(),
      description: params.description.trim(),
      createdAt: now,
      dueDate: params.dueDate,
      priority: params.priority,
      status: TaskStatus.pending,
      categoryId: params.categoryId,
      lastModified: now,
    );

    // Save to repository
    final createResult = await repository.createTask(task);
    return createResult.fold(
      (failure) => Left(failure),
      (taskId) async {
        // Get the created task
        final getResult = await repository.getTaskById(taskId);
        return getResult.fold(
          (failure) => Left(failure),
          (task) => Right(task),
        );
      },
    );
  }

  String? _validateTaskData(CreateTaskParams params) {
    // Title validation
    if (params.title.trim().isEmpty) {
      return 'Task title cannot be empty';
    }

    if (params.title.trim().length < 3) {
      return 'Task title must be at least 3 characters';
    }

    if (params.title.length > 100) {
      return 'Task title cannot exceed 100 characters';
    }

    // Description validation
    if (params.description.length > 500) {
      return 'Task description cannot exceed 500 characters';
    }

    // Due date validation
    if (params.dueDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dueDate = DateTime(
        params.dueDate!.year,
        params.dueDate!.month,
        params.dueDate!.day,
      );

      if (dueDate.isBefore(today)) {
        return 'Due date cannot be in the past';
      }
    }

    // Category validation
    if (params.categoryId.trim().isEmpty) {
      return 'Category is required';
    }

    return null; // No validation errors
  }
}
