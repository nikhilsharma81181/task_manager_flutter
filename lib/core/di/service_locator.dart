import 'package:task_manager_flutter/features/tasks/data/datasources/local/task_local_datasource.dart';
import 'package:task_manager_flutter/features/tasks/data/datasources/local/task_local_datasource_impl.dart';
import 'package:task_manager_flutter/core/services/network_service.dart';

import '../../features/tasks/domain/repositories/task_repository.dart';
import '../services/database_service.dart';
import '../../features/tasks/data/repositories/task_repository_impl.dart';
import '../services/user_analytics_service.dart';
import '../services/settings_service.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  // Core services
  late final DatabaseService _databaseService;
  late final NetworkService _networkService;
  // Note: SyncService now available via Riverpod syncServiceProvider
  late final SettingsService _settingsService;
  late final UserAnalyticsService _userAnalyticsService;

  // Feature-specific dependencies
  late final TaskLocalDatasource _taskLocalDatasource;
  late final TaskRepository _taskRepository;

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize core services
    _databaseService = DatabaseService();
    _networkService = NetworkServiceImpl();
    _settingsService = SettingsService();
    await _settingsService.initialize();

    _userAnalyticsService = UserAnalyticsService();

    // Initialize task feature dependencies
    // Note: Remote datasource now uses Riverpod dioProvider for Dio instance
    _taskLocalDatasource = TaskLocalDatasourceImpl(_databaseService);
    _taskRepository = TaskRepositoryImpl(_taskLocalDatasource);

    // Note: SyncService and TaskRemoteDatasource now available via Riverpod providers
    // - taskRemoteDatasourceProvider (uses dioInstanceProvider)
    // - syncServiceProvider (uses taskRemoteDatasourceProvider)

    // Note: Sample data removed - users start with empty state
    // To add sample data for testing, call:
    // await (_taskLocalDatasource as TaskLocalDatasourceImpl).populateSampleData();

    _isInitialized = true;
  }

  // Getters
  // Note: Dio instance now available via Riverpod dioInstanceProvider

  DatabaseService get databaseService {
    _ensureInitialized();
    return _databaseService;
  }

  NetworkService get networkService {
    _ensureInitialized();
    return _networkService;
  }

  TaskRepository get taskRepository {
    _ensureInitialized();
    return _taskRepository;
  }

  SettingsService get settingsService {
    _ensureInitialized();
    return _settingsService;
  }

  UserAnalyticsService get userAnalyticsService {
    _ensureInitialized();
    return _userAnalyticsService;
  }

  TaskLocalDatasource get taskLocalDataSource {
    _ensureInitialized();
    return _taskLocalDatasource;
  }

  // Note: TaskRemoteDatasource now created with Riverpod Dio provider

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception('ServiceLocator not initialized. Call init() first.');
    }
  }

  Future<void> dispose() async {
    if (_isInitialized) {
      await _databaseService.closeDatabase();
      _isInitialized = false;
    }
  }
}

// Global instance
final serviceLocator = ServiceLocator();
