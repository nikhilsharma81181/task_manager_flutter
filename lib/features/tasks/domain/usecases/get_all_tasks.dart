import 'package:fpdart/fpdart.dart';
import 'package:task_manager_flutter/core/errors/failures.dart';
import 'package:task_manager_flutter/features/tasks/domain/entities/task.dart';

import '../repositories/task_repository.dart';
import '../../../../core/usecase/usecase.dart';

class GetAllTasks implements UseCase<List<TaskEntity>, NoParams> {
  final TaskRepository repository;

  GetAllTasks(this.repository);

  @override
  Future<Either<Failure, List<TaskEntity>>> call(NoParams params) async {
    final result = await repository.getAllTasks();
    return result.fold(
      (failure) => Left(failure),
      (tasks) => Right(tasks),
    );
  }
}
