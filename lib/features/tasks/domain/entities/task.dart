import 'package:equatable/equatable.dart';

enum TaskPriority { low, medium, high, urgent }

enum TaskStatus { pending, inProgress, completed }

class TaskEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime? dueDate;
  final TaskPriority priority;
  final TaskStatus status;
  final String categoryId;
  final bool isDeleted;
  final DateTime lastModified;

  const TaskEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.dueDate,
    required this.priority,
    required this.status,
    required this.categoryId,
    this.isDeleted = false,
    required this.lastModified,
  });

  factory TaskEntity.fromModel(dynamic model) {
    return TaskEntity(
      id: model.id,
      title: model.title,
      description: model.description,
      createdAt: model.createdAt,
      dueDate: model.dueDate,
      priority: model.priority,
      status: model.status,
      categoryId: model.categoryId,
      isDeleted: model.isDeleted,
      lastModified: model.lastModified,
    );
  }

  TaskEntity copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskStatus? status,
    String? categoryId,
    bool? isDeleted,
    DateTime? lastModified,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      categoryId: categoryId ?? this.categoryId,
      isDeleted: isDeleted ?? this.isDeleted,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        createdAt,
        dueDate,
        priority,
        status,
        categoryId,
        isDeleted,
        lastModified,
      ];
}
