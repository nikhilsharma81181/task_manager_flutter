import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager_flutter/core/network/dio_provider.dart';
import 'package:task_manager_flutter/core/services/sync_service.dart';
import 'package:task_manager_flutter/features/tasks/data/datasources/remote/task_remote_datasource.dart';
import 'package:task_manager_flutter/features/tasks/data/datasources/remote/task_remote_datasource_impl.dart';
import 'package:task_manager_flutter/features/tasks/domain/repositories/task_repository.dart';
import 'package:task_manager_flutter/features/tasks/data/repositories/task_repository_impl.dart';
import 'service_locator.dart';

/// Remote datasource provider with Dio dependency injection
final taskRemoteDatasourceProvider = Provider<TaskRemoteDatasource>((ref) {
  final dio = ref.watch(dioInstanceProvider);
  return TaskRemoteDatasourceImpl(dio: dio);
});

/// Repository provider with both local and remote datasources
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final remoteDatasource = ref.watch(taskRemoteDatasourceProvider);

  return TaskRepositoryImpl(
    serviceLocator.taskLocalDataSource,
    remoteDatasource: remoteDatasource,
  );
});

/// Sync service provider with proper dependency injection
final syncServiceProvider = Provider<SyncService>((ref) {
  final remoteDatasource = ref.watch(taskRemoteDatasourceProvider);

  return SyncServiceImpl(
    databaseService: serviceLocator.databaseService,
    networkService: serviceLocator.networkService,
    remoteDatasource: remoteDatasource,
  );
});
