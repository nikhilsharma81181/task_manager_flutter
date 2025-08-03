import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;
  static const String _dbName = 'task_manager.db';
  static const int _dbVersion = 1;

  // Tables
  static const String tasksTable = 'tasks';
  static const String categoriesTable = 'categories';
  static const String syncQueueTable = 'sync_queue';

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Tasks table
    await db.execute('''
      CREATE TABLE $tasksTable (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        dueDate TEXT,
        priority INTEGER NOT NULL,
        status INTEGER NOT NULL,
        categoryId TEXT NOT NULL,
        isDeleted INTEGER NOT NULL DEFAULT 0,
        lastModified TEXT NOT NULL
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE $categoriesTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color TEXT NOT NULL,
        icon TEXT NOT NULL,
        isDeleted INTEGER NOT NULL DEFAULT 0,
        lastModified TEXT NOT NULL
      )
    ''');

    // Sync queue table for offline support
    await db.execute('''
      CREATE TABLE $syncQueueTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        tableName TEXT NOT NULL,
        recordId TEXT NOT NULL,
        data TEXT,
        timestamp TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        retryCount INTEGER NOT NULL DEFAULT 0,
        lastError TEXT,
        syncedAt TEXT
      )
    ''');

    // Insert default category
    await db.insert(categoriesTable, {
      'id': 'default',
      'name': 'General',
      'color': '#2196F3',
      'icon': 'task_alt',
      'isDeleted': 0,
      'lastModified': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}