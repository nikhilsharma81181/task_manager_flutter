import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_manager_flutter/core/errors/exceptions.dart';
import 'package:task_manager_flutter/core/errors/failures.dart';
import 'package:task_manager_flutter/features/tasks/data/datasources/local/task_local_datasource.dart';
import 'package:task_manager_flutter/features/tasks/data/datasources/remote/task_remote_datasource.dart';
import 'package:task_manager_flutter/features/tasks/data/models/task_model.dart';
import 'package:task_manager_flutter/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:task_manager_flutter/features/tasks/domain/entities/task.dart';

class MockTaskLocalDatasource extends Mock implements TaskLocalDatasource {}
class MockTaskRemoteDatasource extends Mock implements TaskRemoteDatasource {}

void main() {
  group('TaskRepositoryImpl', () {
    late TaskRepositoryImpl repository;
    late MockTaskLocalDatasource mockLocalDatasource;
    late MockTaskRemoteDatasource mockRemoteDatasource;

    setUpAll(() {
      // Register fallback values for mocktail
      registerFallbackValue(TaskModel(
        id: 'fallback-id',
        title: 'Fallback Task',
        description: 'Fallback Description',
        createdAt: DateTime(2023, 1, 1),
        priority: TaskPriority.medium,
        status: TaskStatus.pending,
        categoryId: 'fallback-cat',
        lastModified: DateTime(2023, 1, 1),
      ));
    });

    setUp(() {
      mockLocalDatasource = MockTaskLocalDatasource();
      mockRemoteDatasource = MockTaskRemoteDatasource();
      repository = TaskRepositoryImpl(
        mockLocalDatasource,
        remoteDatasource: mockRemoteDatasource,
      );
    });

    // Test data
    final testTaskModel = TaskModel(
      id: 'test-id',
      title: 'Test Task',
      description: 'Test Description',
      createdAt: DateTime(2023, 1, 1),
      dueDate: DateTime(2023, 1, 2),
      priority: TaskPriority.high,
      status: TaskStatus.pending,
      categoryId: 'cat-1',
      lastModified: DateTime(2023, 1, 1),
    );

    final testTaskEntity = TaskEntity(
      id: 'test-id',
      title: 'Test Task',
      description: 'Test Description',
      createdAt: DateTime(2023, 1, 1),
      dueDate: DateTime(2023, 1, 2),
      priority: TaskPriority.high,
      status: TaskStatus.pending,
      categoryId: 'cat-1',
      lastModified: DateTime(2023, 1, 1),
    );


    group('getAllTasks', () {
      test('should return list of task entities when successful', () async {
        // Arrange
        when(() => mockLocalDatasource.getAllTasks())
            .thenAnswer((_) async => [testTaskModel]);

        // Act
        final result = await repository.getAllTasks();

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left: $failure'),
          (tasks) {
            expect(tasks, hasLength(1));
            expect(tasks.first.id, equals('test-id'));
          },
        );
      });

      test('should return DatabaseFailure when datasource throws exception', () async {
        // Arrange
        when(() => mockLocalDatasource.getAllTasks())
            .thenThrow(const DatabaseException('Database error'));

        // Act
        final result = await repository.getAllTasks();

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<DatabaseFailure>()),
          (tasks) => fail('Expected Left but got Right'),
        );
      });
    });

    group('getTaskById', () {
      test('should return task entity when task exists', () async {
        // Arrange
        when(() => mockLocalDatasource.getTaskById('test-id'))
            .thenAnswer((_) async => testTaskModel);

        // Act
        final result = await repository.getTaskById('test-id');

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left: $failure'),
          (task) => expect(task.id, equals('test-id')),
        );
      });

      test('should return NotFoundFailure when task does not exist', () async {
        // Arrange
        when(() => mockLocalDatasource.getTaskById('non-existent'))
            .thenAnswer((_) async => null);

        // Act
        final result = await repository.getTaskById('non-existent');

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<NotFoundFailure>()),
          (task) => fail('Expected Left but got Right'),
        );
      });
    });

    group('createTask', () {
      test('should return task ID when creation succeeds', () async {
        // Arrange
        when(() => mockLocalDatasource.createTask(any()))
            .thenAnswer((_) async => 'new-task-id');

        // Act
        final result = await repository.createTask(testTaskEntity);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left: $failure'),
          (taskId) => expect(taskId, equals('new-task-id')),
        );
      });

      test('should return DatabaseFailure when creation fails', () async {
        // Arrange
        when(() => mockLocalDatasource.createTask(any()))
            .thenThrow(const DatabaseException('Creation failed'));

        // Act
        final result = await repository.createTask(testTaskEntity);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<DatabaseFailure>()),
          (taskId) => fail('Expected Left but got Right'),
        );
      });
    });

    group('updateTask', () {
      test('should return true when update succeeds', () async {
        // Arrange
        when(() => mockLocalDatasource.updateTask(any()))
            .thenAnswer((_) async => true);

        // Act
        final result = await repository.updateTask(testTaskEntity);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left: $failure'),
          (success) => expect(success, isTrue),
        );
      });
    });

    group('deleteTask', () {
      test('should return true when deletion succeeds', () async {
        // Arrange
        when(() => mockLocalDatasource.deleteTask('test-id'))
            .thenAnswer((_) async => true);

        // Act
        final result = await repository.deleteTask('test-id');

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left: $failure'),
          (success) => expect(success, isTrue),
        );
      });
    });

    group('searchTasks', () {
      test('should return matching tasks when search succeeds', () async {
        // Arrange
        when(() => mockLocalDatasource.searchTasks('test'))
            .thenAnswer((_) async => [testTaskModel]);

        // Act
        final result = await repository.searchTasks('test');

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left: $failure'),
          (tasks) => expect(tasks, hasLength(1)),
        );
      });
    });

    group('markTaskAsCompleted', () {
      test('should mark task as completed when task exists', () async {
        // Arrange
        when(() => mockLocalDatasource.getTaskById('test-id'))
            .thenAnswer((_) async => testTaskModel);
        when(() => mockLocalDatasource.updateTask(any()))
            .thenAnswer((_) async => true);

        // Act
        final result = await repository.markTaskAsCompleted('test-id');

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left: $failure'),
          (success) => expect(success, isTrue),
        );
        
        // Verify that update was called with completed status
        final capturedTask = verify(() => mockLocalDatasource.updateTask(captureAny())).captured.first as TaskModel;
        expect(capturedTask.status, equals(TaskStatus.completed));
      });
    });

    group('Error Handling', () {
      test('should consistently map DatabaseException to DatabaseFailure', () async {
        // Arrange
        when(() => mockLocalDatasource.getAllTasks())
            .thenThrow(const DatabaseException('DB Error'));

        // Act
        final result = await repository.getAllTasks();

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold((f) => expect(f, isA<DatabaseFailure>()), (_) {});
      });
    });
  });
}