import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:task_manager_flutter/core/errors/failures.dart';
import 'package:task_manager_flutter/features/tasks/domain/entities/task.dart';
import '../repositories/task_repository.dart';
import '../../../../core/usecase/usecase.dart';

class UpdateTaskParams extends Equatable {
  final String id;
  final String? title;
  final String? description;
  final DateTime? dueDate;
  final TaskPriority? priority;
  final TaskStatus? status;
  final String? categoryId;

  const UpdateTaskParams({
    required this.id,
    this.title,
    this.description,
    this.dueDate,
    this.priority,
    this.status,
    this.categoryId,
  });

  @override
  List<Object?> get props =>
      [id, title, description, dueDate, priority, status, categoryId];
}

class UpdateTask implements UseCase<TaskEntity, UpdateTaskParams> {
  final TaskRepository repository;

  UpdateTask(this.repository);

  @override
  Future<Either<Failure, TaskEntity>> call(UpdateTaskParams params) async {
    // Get existing task
    final getResult = await repository.getTaskById(params.id);
    return getResult.fold(
      (failure) => Left(failure),
      (existingTask) async {
        // Business validation
        final validationResult = _validateUpdateData(params);
        if (validationResult != null) {
          return Left(ValidationFailure(validationResult));
        }

        // Create updated task
        final updatedTask = existingTask.copyWith(
          title: params.title?.trim() ?? existingTask.title,
          description: params.description?.trim() ?? existingTask.description,
          dueDate: params.dueDate ?? existingTask.dueDate,
          priority: params.priority ?? existingTask.priority,
          status: params.status ?? existingTask.status,
          categoryId: params.categoryId ?? existingTask.categoryId,
          lastModified: DateTime.now(),
        );

        // Update in repository
        final updateResult = await repository.updateTask(updatedTask);
        return updateResult.fold(
          (failure) => Left(failure),
          (success) => Right(TaskEntity.fromModel(updatedTask)),
        );
      },
    );
  }

  String? _validateUpdateData(UpdateTaskParams params) {
    // Title validation (if provided)
    if (params.title != null) {
      if (params.title!.trim().isEmpty) {
        return 'Task title cannot be empty';
      }

      if (params.title!.trim().length < 3) {
        return 'Task title must be at least 3 characters';
      }

      if (params.title!.length > 100) {
        return 'Task title cannot exceed 100 characters';
      }
    }

    // Description validation (if provided)
    if (params.description != null && params.description!.length > 500) {
      return 'Task description cannot exceed 500 characters';
    }

    // Due date validation (if provided)
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

    // Category validation (if provided)
    if (params.categoryId != null && params.categoryId!.trim().isEmpty) {
      return 'Category cannot be empty';
    }

    return null; // No validation errors
  }
}
