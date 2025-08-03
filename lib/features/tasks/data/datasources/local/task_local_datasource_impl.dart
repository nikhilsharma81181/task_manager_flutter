import 'package:sqflite/sqflite.dart';
import 'package:task_manager_flutter/features/tasks/data/models/task_model.dart';
import 'package:task_manager_flutter/core/services/database_service.dart';
import 'package:task_manager_flutter/features/tasks/domain/entities/task.dart';
import 'task_local_datasource.dart';
 
class TaskLocalDatasourceImpl implements TaskLocalDatasource {
  final DatabaseService _databaseService;

  TaskLocalDatasourceImpl(this._databaseService);

  @override
  Future<List<TaskModel>> getAllTasks() async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.tasksTable,
        where: 'isDeleted = ?',
        whereArgs: [0],
        orderBy: 'createdAt DESC',
      );

      return List.generate(maps.length, (i) {
        return TaskModel.fromJson(maps[i]);
      });
    } catch (e) {
      throw Exception('Failed to fetch tasks: $e');
    }
  }

  @override
  Future<List<TaskModel>> getTasksByCategory(String categoryId) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.tasksTable,
        where: 'categoryId = ? AND isDeleted = ?',
        whereArgs: [categoryId, 0],
        orderBy: 'createdAt DESC',
      );

      return List.generate(maps.length, (i) {
        return TaskModel.fromJson(maps[i]);
      });
    } catch (e) {
      throw Exception('Failed to fetch tasks by category: $e');
    }
  }

  @override
  Future<List<TaskModel>> getTasksByStatus(TaskStatus status) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.tasksTable,
        where: 'status = ? AND isDeleted = ?',
        whereArgs: [status.index, 0],
        orderBy: 'createdAt DESC',
      );

      return List.generate(maps.length, (i) {
        return TaskModel.fromJson(maps[i]);
      });
    } catch (e) {
      throw Exception('Failed to fetch tasks by status: $e');
    }
  }

  @override
  Future<List<TaskModel>> searchTasks(String query) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.tasksTable,
        where: '(title LIKE ? OR description LIKE ?) AND isDeleted = ?',
        whereArgs: ['%$query%', '%$query%', 0],
        orderBy: 'createdAt DESC',
      );

      return List.generate(maps.length, (i) {
        return TaskModel.fromJson(maps[i]);
      });
    } catch (e) {
      throw Exception('Failed to search tasks: $e');
    }
  }

  @override
  Future<TaskModel?> getTaskById(String id) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.tasksTable,
        where: 'id = ? AND isDeleted = ?',
        whereArgs: [id, 0],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return TaskModel.fromJson(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch task by id: $e');
    }
  }

  @override
  Future<String> createTask(TaskModel task) async {
    try {
      final db = await _databaseService.database;

      final taskWithTimestamp = task.copyWith(
        lastModified: DateTime.now(),
      );

      await db.insert(
        DatabaseService.tasksTable,
        taskWithTimestamp.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Add to sync queue for offline support
      await _addToSyncQueue(db, 'CREATE', task.id, taskWithTimestamp.toJson());

      return task.id;
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  @override
  Future<bool> updateTask(TaskModel task) async {
    try {
      final db = await _databaseService.database;

      final taskWithTimestamp = task.copyWith(
        lastModified: DateTime.now(),
      );

      final result = await db.update(
        DatabaseService.tasksTable,
        taskWithTimestamp.toJson(),
        where: 'id = ?',
        whereArgs: [task.id],
      );

      if (result > 0) {
        await _addToSyncQueue(
            db, 'UPDATE', task.id, taskWithTimestamp.toJson());
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  @override
  Future<bool> deleteTask(String id) async {
    try {
      final db = await _databaseService.database;

      final result = await db.update(
        DatabaseService.tasksTable,
        {
          'isDeleted': 1,
          'lastModified': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      if (result > 0) {
        await _addToSyncQueue(db, 'DELETE', id, null);
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  @override
  Future<List<TaskModel>> getOverdueTasks() async {
    try {
      final db = await _databaseService.database;
      final now = DateTime.now().toIso8601String();

      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.tasksTable,
        where: 'dueDate < ? AND status != ? AND isDeleted = ?',
        whereArgs: [now, TaskStatus.completed.index, 0],
        orderBy: 'dueDate ASC',
      );

      return List.generate(maps.length, (i) {
        return TaskModel.fromJson(maps[i]);
      });
    } catch (e) {
      throw Exception('Failed to fetch overdue tasks: $e');
    }
  }

  @override
  Future<List<TaskModel>> getTasksDueToday() async {
    try {
      final db = await _databaseService.database;
      final now = DateTime.now();
      final startOfDay =
          DateTime(now.year, now.month, now.day).toIso8601String();
      final endOfDay =
          DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseService.tasksTable,
        where: 'dueDate >= ? AND dueDate <= ? AND isDeleted = ?',
        whereArgs: [startOfDay, endOfDay, 0],
        orderBy: 'dueDate ASC',
      );

      return List.generate(maps.length, (i) {
        return TaskModel.fromJson(maps[i]);
      });
    } catch (e) {
      throw Exception('Failed to fetch tasks due today: $e');
    }
  }

  @override
  Future<int> getTaskCount() async {
    try {
      final db = await _databaseService.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseService.tasksTable} WHERE isDeleted = ?',
        [0],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('Failed to get task count: $e');
    }
  }

  @override
  Future<void> clearAllTasks() async {
    try {
      final db = await _databaseService.database;
      await db.update(
        DatabaseService.tasksTable,
        {
          'isDeleted': 1,
          'lastModified': DateTime.now().toIso8601String(),
        },
        where: 'isDeleted = ?',
        whereArgs: [0],
      );
    } catch (e) {
      throw Exception('Failed to clear all tasks: $e');
    }
  }

  // Method to populate sample data for demo/testing purposes
  Future<void> populateSampleData() async {
    try {
      final db = await _databaseService.database;

      // Check if data already exists
      final count = await getTaskCount();
      if (count > 0) return; // Don't add sample data if tasks already exist

      // Sample data removed - populate manually if needed for testing
    } catch (e) {
      // Silently fail for sample data - this is not critical
      print('Failed to populate sample data: $e');
    }
  }

  // Method to add sample data on demand (for testing/demo)
  Future<void> addSampleDataForDemo() async {
    // Sample data removed - implement if needed for testing
    final db = await _databaseService.database;
    // Add custom test data here if needed
  }

  // Helper method for sync queue
  Future<void> _addToSyncQueue(Database db, String action, String recordId,
      Map<String, dynamic>? data) async {
    await db.insert(DatabaseService.syncQueueTable, {
      'action': action,
      'tableName': DatabaseService.tasksTable,
      'recordId': recordId,
      'data': data?.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }
}
