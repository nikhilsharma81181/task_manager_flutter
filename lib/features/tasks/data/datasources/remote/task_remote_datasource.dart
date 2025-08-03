import '../../models/task_model.dart';

abstract class TaskRemoteDatasource {
  Future<String> createTask(TaskModel task);
  Future<bool> updateTask(TaskModel task);
  Future<bool> deleteTask(String id);
  Future<List<TaskModel>> getAllTasks();
  Future<TaskModel?> getTaskById(String id);
}