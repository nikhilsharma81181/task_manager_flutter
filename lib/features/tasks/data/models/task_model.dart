import 'package:task_manager_flutter/features/tasks/domain/entities/task.dart';

class TaskModel extends TaskEntity {
  const TaskModel({
    required super.id,
    required super.title,
    required super.description,
    required super.createdAt,
    super.dueDate,
    required super.priority,
    required super.status,
    required super.categoryId,
    super.isDeleted = false,
    required super.lastModified,
  }); 

  @override
  TaskModel copyWith({
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
    return TaskModel(
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority.index,
      'status': status.index,
      'categoryId': categoryId,
      'isDeleted': isDeleted ? 1 : 0,
      'lastModified': lastModified.toIso8601String(),
    };
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      priority: TaskPriority.values[json['priority']],
      status: TaskStatus.values[json['status']],
      categoryId: json['categoryId'],
      isDeleted: json['isDeleted'] == 1,
      lastModified: DateTime.parse(json['lastModified']),
    );
  }

  factory TaskModel.fromEntity(TaskEntity entity) {
    return TaskModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      createdAt: entity.createdAt,
      dueDate: entity.dueDate,
      priority: entity.priority,
      status: entity.status,
      categoryId: entity.categoryId,
      isDeleted: entity.isDeleted,
      lastModified: entity.lastModified,
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
