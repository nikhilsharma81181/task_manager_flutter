import 'dart:io';
import 'package:dio/dio.dart';
import '../../models/task_model.dart';
import 'task_remote_datasource.dart';

class TaskRemoteDatasourceImpl implements TaskRemoteDatasource {
  final Dio _dio;

  TaskRemoteDatasourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<String> createTask(TaskModel task) async {
    try {
      final response = await _dio.post(
        '/tasks',
        data: task.toJson(),
      );

      if (response.statusCode == 201) {
        final data = response.data;
        return data['id'] ?? task.id;
      } else {
        throw HttpException('Failed to create task: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error creating task: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error creating task: $e');
    }
  }

  @override
  Future<bool> updateTask(TaskModel task) async {
    try {
      final response = await _dio.put(
        '/tasks/${task.id}',
        data: task.toJson(),
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception('Network error updating task: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error updating task: $e');
    }
  }

  @override
  Future<bool> deleteTask(String id) async {
    try {
      final response = await _dio.delete('/tasks/$id');

      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      throw Exception('Network error deleting task: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error deleting task: $e');
    }
  }

  @override
  Future<List<TaskModel>> getAllTasks() async {
    try {
      final response = await _dio.get('/tasks');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => TaskModel.fromJson(json)).toList();
      } else {
        throw HttpException('Failed to fetch tasks: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error fetching tasks: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error fetching tasks: $e');
    }
  }

  @override
  Future<TaskModel?> getTaskById(String id) async {
    try {
      final response = await _dio.get('/tasks/$id');

      if (response.statusCode == 200) {
        return TaskModel.fromJson(response.data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw HttpException('Failed to fetch task: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw Exception('Network error fetching task: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error fetching task: $e');
    }
  }
}