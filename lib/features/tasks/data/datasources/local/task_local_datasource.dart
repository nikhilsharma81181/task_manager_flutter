import 'package:task_manager_flutter/features/tasks/data/models/task_model.dart';
import 'package:task_manager_flutter/features/tasks/domain/entities/task.dart';

abstract class TaskLocalDatasource {
  Future<List<TaskModel>> getAllTasks();
  Future<List<TaskModel>> getTasksByCategory(String categoryId);
  Future<List<TaskModel>> getTasksByStatus(TaskStatus status);
  Future<List<TaskModel>> searchTasks(String query);
  Future<TaskModel?> getTaskById(String id);
  Future<String> createTask(TaskModel task);
  Future<bool> updateTask(TaskModel task);
  Future<bool> deleteTask(String id);
  Future<List<TaskModel>> getOverdueTasks();
  Future<List<TaskModel>> getTasksDueToday();
  Future<int> getTaskCount();
  Future<void> clearAllTasks();
}
