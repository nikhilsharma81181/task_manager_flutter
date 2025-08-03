import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:task_manager_flutter/core/services/database_service.dart';
import 'package:task_manager_flutter/core/services/network_service.dart';
import 'package:task_manager_flutter/features/tasks/data/datasources/remote/task_remote_datasource.dart';
import 'package:task_manager_flutter/features/tasks/data/models/task_model.dart';

abstract class SyncService {
  Future<void> initialize();
  Future<void> processSyncQueue();
  Future<void> startSyncListener();
  void stopSyncListener();
  void dispose();
}

class SyncServiceImpl implements SyncService {
  final DatabaseService _databaseService;
  final NetworkService _networkService;
  final TaskRemoteDatasource _remoteDatasource;

  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _retryTimer;
  bool _isProcessing = false;

  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(minutes: 5);

  SyncServiceImpl({
    required DatabaseService databaseService,
    required NetworkService networkService,
    required TaskRemoteDatasource remoteDatasource,
  })  : _databaseService = databaseService,
        _networkService = networkService,
        _remoteDatasource = remoteDatasource;

  @override
  Future<void> initialize() async {
    await startSyncListener();

    // Process any pending sync items on startup if online
    if (await _networkService.isConnected) {
      unawaited(processSyncQueue());
    }
  }

  @override
  Future<void> startSyncListener() async {
    stopSyncListener();

    // Listen to connectivity changes
    _connectivitySubscription =
        _networkService.connectivityStream.listen((isConnected) {
      if (isConnected && !_isProcessing) {
        unawaited(processSyncQueue());
      }
    });
  }

  @override
  void stopSyncListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  @override
  Future<void> processSyncQueue() async {
    if (_isProcessing || !await _networkService.isConnected) {
      return;
    }

    _isProcessing = true;

    try {
      final db = await _databaseService.database;
      final pendingItems = await _getPendingSyncItems(db);

      if (pendingItems.isEmpty) {
        _isProcessing = false;
        return;
      }

      print('Processing ${pendingItems.length} sync items...');

      for (final item in pendingItems) {
        await _processSyncItem(db, item);
      }

      print('Sync queue processing completed');
    } catch (e) {
      print('Error processing sync queue: $e');
      _scheduleRetry();
    } finally {
      _isProcessing = false;
    }
  }

  Future<List<Map<String, dynamic>>> _getPendingSyncItems(Database db) async {
    return await db.query(
      DatabaseService.syncQueueTable,
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'timestamp ASC',
      limit: 50, // Process in batches
    );
  }

  Future<void> _processSyncItem(Database db, Map<String, dynamic> item) async {
    try {
      final String action = item['action'];
      final String tableName = item['tableName'];
      final String recordId = item['recordId'];
      final String? dataString = item['data'];

      if (tableName != DatabaseService.tasksTable) {
        // Skip non-task items for now
        await _markItemAsSynced(db, item['id']);
        return;
      }

      bool success = false;

      switch (action) {
        case 'CREATE':
          if (dataString != null) {
            final taskData = jsonDecode(dataString);
            final task = TaskModel.fromJson(taskData);
            await _remoteDatasource.createTask(task);
            success = true;
          }
          break;

        case 'UPDATE':
          if (dataString != null) {
            final taskData = jsonDecode(dataString);
            final task = TaskModel.fromJson(taskData);
            success = await _remoteDatasource.updateTask(task);
          }
          break;

        case 'DELETE':
          success = await _remoteDatasource.deleteTask(recordId);
          break;
      }

      if (success) {
        await _markItemAsSynced(db, item['id']);
        print('Synced $action for $recordId');
      } else {
        await _incrementRetryCount(db, item['id']);
        print('Failed to sync $action for $recordId');
      }
    } catch (e) {
      print('Error processing sync item ${item['id']}: $e');
      await _incrementRetryCount(db, item['id']);
    }
  }

  Future<void> _markItemAsSynced(Database db, int itemId) async {
    await db.update(
      DatabaseService.syncQueueTable,
      {
        'synced': 1,
        'syncedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<void> _incrementRetryCount(Database db, int itemId) async {
    final currentItem = await db.query(
      DatabaseService.syncQueueTable,
      where: 'id = ?',
      whereArgs: [itemId],
    );

    if (currentItem.isNotEmpty) {
      final retryCount = (currentItem.first['retryCount'] as int? ?? 0) + 1;

      if (retryCount >= _maxRetries) {
        // Mark as failed after max retries
        await db.update(
          DatabaseService.syncQueueTable,
          {
            'synced': -1, // -1 indicates failed
            'retryCount': retryCount,
            'lastError': 'Max retries exceeded',
          },
          where: 'id = ?',
          whereArgs: [itemId],
        );
      } else {
        await db.update(
          DatabaseService.syncQueueTable,
          {'retryCount': retryCount},
          where: 'id = ?',
          whereArgs: [itemId],
        );
      }
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(_retryDelay, () {
      if (!_isProcessing) {
        unawaited(processSyncQueue());
      }
    });
  }

  @override
  void dispose() {
    stopSyncListener();
    _isProcessing = false;
  }

  // Helper method for fire-and-forget async calls
  void unawaited(Future<void> future) {
    future.catchError((error) {
      print('Unawaited future error: $error');
    });
  }
}
