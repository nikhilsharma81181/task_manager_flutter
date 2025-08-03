import 'package:equatable/equatable.dart';
import '../../domain/entities/task.dart';

abstract class TaskDetailState extends Equatable {
  const TaskDetailState();
}

class TaskDetailInitial extends TaskDetailState {
  @override
  List<Object> get props => [];
}

class TaskDetailLoading extends TaskDetailState {
  @override
  List<Object> get props => [];
}

class TaskDetailLoaded extends TaskDetailState {
  final TaskEntity task;

  const TaskDetailLoaded({required this.task});

  TaskDetailLoaded copyWith({TaskEntity? task}) {
    return TaskDetailLoaded(task: task ?? this.task);
  }

  @override
  List<Object> get props => [task];
}

class TaskDetailError extends TaskDetailState {
  final String message;

  const TaskDetailError({required this.message});

  @override
  List<Object> get props => [message];
}

class TaskDetailDeleting extends TaskDetailState {
  final TaskEntity task;

  const TaskDetailDeleting({required this.task});

  @override
  List<Object> get props => [task];
}
