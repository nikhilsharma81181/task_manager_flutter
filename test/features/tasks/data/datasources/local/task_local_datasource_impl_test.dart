import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:task_manager_flutter/core/services/database_service.dart';
import 'package:task_manager_flutter/features/tasks/data/datasources/local/task_local_datasource_impl.dart';
import 'package:task_manager_flutter/features/tasks/data/models/task_model.dart';
import 'package:task_manager_flutter/features/tasks/domain/entities/task.dart';

class MockDatabaseService extends Mock implements DatabaseService {}
class MockDatabase extends Mock implements Database {}

void main() {
  group('TaskLocalDatasourceImpl', () {
    late TaskLocalDatasourceImpl datasource;
    late MockDatabaseService mockDatabaseService;
    late MockDatabase mockDatabase;

    setUp(() {
      mockDatabaseService = MockDatabaseService();
      mockDatabase = MockDatabase();
      datasource = TaskLocalDatasourceImpl(mockDatabaseService);

      // Setup database service to return mock database
      when(() => mockDatabaseService.database)
          .thenAnswer((_) async => mockDatabase);
    });

    // Test data
    final testTaskMap = {
      'id': 'test-id',
      'title': 'Test Task',
      'description': 'Test Description',
      'createdAt': DateTime(2023, 1, 1).toIso8601String(),
      'dueDate': DateTime(2023, 1, 2).toIso8601String(),
      'priority': TaskPriority.high.index,
      'status': TaskStatus.pending.index,
      'categoryId': 'cat-1',
      'isDeleted': 0,
      'lastModified': DateTime(2023, 1, 1).toIso8601String(),
    };

    final testTaskModel = TaskModel.fromJson(testTaskMap);

    group('getAllTasks', () {
      test('should return all non-deleted tasks ordered by creation date', () async {
        // Arrange
        when(() => mockDatabase.query(
              DatabaseService.tasksTable,
              where: 'isDeleted = ?',
              whereArgs: [0],
              orderBy: 'createdAt DESC',
            )).thenAnswer((_) async => [testTaskMap]);

        // Act
        final result = await datasource.getAllTasks();

        // Assert
        expect(result, hasLength(1));
        expect(result.first.id, equals('test-id'));
        expect(result.first.title, equals('Test Task'));
      });

      test('should throw exception when database query fails', () async {
        // Arrange
        when(() => mockDatabase.query(
              DatabaseService.tasksTable,
              where: 'isDeleted = ?',
              whereArgs: [0],
              orderBy: 'createdAt DESC',
            )).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () async => await datasource.getAllTasks(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('searchTasks', () {
      test('should return tasks matching search query', () async {
        // Arrange
        when(() => mockDatabase.query(
              DatabaseService.tasksTable,
              where: '(title LIKE ? OR description LIKE ?) AND isDeleted = ?',
              whereArgs: ['%test%', '%test%', 0],
              orderBy: 'createdAt DESC',
            )).thenAnswer((_) async => [testTaskMap]);

        // Act
        final result = await datasource.searchTasks('test');

        // Assert
        expect(result, hasLength(1));
        expect(result.first.title.toLowerCase(), contains('test'));
      });
    });

    group('getTaskById', () {
      test('should return task when found', () async {
        // Arrange
        when(() => mockDatabase.query(
              DatabaseService.tasksTable,
              where: 'id = ? AND isDeleted = ?',
              whereArgs: ['test-id', 0],
              limit: 1,
            )).thenAnswer((_) async => [testTaskMap]);

        // Act
        final result = await datasource.getTaskById('test-id');

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals('test-id'));
      });

      test('should return null when task not found', () async {
        // Arrange
        when(() => mockDatabase.query(
              DatabaseService.tasksTable,
              where: 'id = ? AND isDeleted = ?',
              whereArgs: ['non-existent', 0],
              limit: 1,
            )).thenAnswer((_) async => []);

        // Act
        final result = await datasource.getTaskById('non-existent');

        // Assert
        expect(result, isNull);
      });
    });

    group('createTask', () {
      test('should create task successfully and return task ID', () async {
        // Arrange
        when(() => mockDatabase.insert(
              DatabaseService.tasksTable,
              any(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            )).thenAnswer((_) async => 1);

        when(() => mockDatabase.insert(
              DatabaseService.syncQueueTable,
              any(),
            )).thenAnswer((_) async => 1);

        // Act
        final result = await datasource.createTask(testTaskModel);

        // Assert
        expect(result, equals('test-id'));
      });

      test('should throw exception when insert fails', () async {
        // Arrange
        when(() => mockDatabase.insert(
              DatabaseService.tasksTable,
              any(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            )).thenThrow(Exception('Insert failed'));

        // Act & Assert
        expect(
          () async => await datasource.createTask(testTaskModel),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('updateTask', () {
      test('should update task successfully and return true', () async {
        // Arrange
        when(() => mockDatabase.update(
              DatabaseService.tasksTable,
              any(),
              where: 'id = ?',
              whereArgs: ['test-id'],
            )).thenAnswer((_) async => 1);

        when(() => mockDatabase.insert(
              DatabaseService.syncQueueTable,
              any(),
            )).thenAnswer((_) async => 1);

        // Act
        final result = await datasource.updateTask(testTaskModel);

        // Assert
        expect(result, isTrue);
      });
    });

    group('deleteTask', () {
      test('should soft delete task and return true', () async {
        // Arrange
        when(() => mockDatabase.update(
              DatabaseService.tasksTable,
              any(),
              where: 'id = ?',
              whereArgs: ['test-id'],
            )).thenAnswer((_) async => 1);

        when(() => mockDatabase.insert(
              DatabaseService.syncQueueTable,
              any(),
            )).thenAnswer((_) async => 1);

        // Act
        final result = await datasource.deleteTask('test-id');

        // Assert
        expect(result, isTrue);
      });
    });

    group('Error Handling', () {
      test('should handle database service errors', () async {
        // Arrange
        when(() => mockDatabaseService.database)
            .thenThrow(Exception('Database initialization failed'));

        // Act & Assert
        expect(
          () async => await datasource.getAllTasks(),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}