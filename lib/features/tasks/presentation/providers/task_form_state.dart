import 'package:equatable/equatable.dart';
import '../../domain/entities/task.dart';

class TaskFormState extends Equatable {
  final bool isLoading;
  final String? error;
  final bool isValid;
  final TaskEntity? task; // For edit mode

  const TaskFormState({
    this.isLoading = false,
    this.error,
    this.isValid = false,
    this.task,
  });

  TaskFormState copyWith({
    bool? isLoading,
    String? error,
    bool? isValid,
    TaskEntity? task,
    bool clearError = false,
  }) {
    return TaskFormState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isValid: isValid ?? this.isValid,
      task: task ?? this.task,
    );
  }

  @override
  List<Object?> get props => [isLoading, error, isValid, task];
}