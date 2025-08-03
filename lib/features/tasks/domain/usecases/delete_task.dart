import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:task_manager_flutter/core/errors/failures.dart';
import 'package:task_manager_flutter/features/tasks/domain/entities/task.dart';

import '../repositories/task_repository.dart';
import '../../../../core/usecase/usecase.dart';

class DeleteTaskParams extends Equatable {
  final String id;

  const DeleteTaskParams({required this.id});

  @override
  List<Object?> get props => [id];
}

class DeleteTask implements UseCase<bool, DeleteTaskParams> {
  final TaskRepository repository;

  DeleteTask(this.repository);

  @override
  Future<Either<Failure, bool>> call(DeleteTaskParams params) async {
    // Check if task exists
    final getResult = await repository.getTaskById(params.id);
    return getResult.fold(
      (failure) => Left(failure),
      (existingTask) async {
        // Business rule: Cannot delete completed tasks older than 30 days
        if (existingTask.status == TaskStatus.completed) {
          final daysSinceCompletion =
              DateTime.now().difference(existingTask.lastModified).inDays;
          if (daysSinceCompletion > 30) {
            return Left(ValidationFailure(
              'Cannot delete completed tasks older than 30 days',
            ));
          }
        }

        // Delete from repository
        return await repository.deleteTask(params.id);
      },
    );
  }
}
