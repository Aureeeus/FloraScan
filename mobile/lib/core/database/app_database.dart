import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Central database manager for FloraScan local persistence across Android, iOS, and tablets.
///
/// Implements SQLite schema setup, transactional migrations, and seed data initialization.
class AppDatabase {
  AppDatabase({Database? initialDatabase}) : _database = initialDatabase;

  Database? _database;

  static const String databaseName = 'florascan.db';
  static const int schemaVersion = 6;

  /// Lazy accessor for the underlying [Database].
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  /// Initializes an in-memory database instance (ideal for deterministic unit & widget tests).
  static Future<AppDatabase> inMemory({DatabaseFactory? factory}) async {
    final effectiveFactory = factory ?? _resolvePlatformFactory();
    final db = await effectiveFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onCreate: _onCreate,
      ),
    );
    return AppDatabase(initialDatabase: db);
  }

  static DatabaseFactory _resolvePlatformFactory() {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      return databaseFactoryFfi;
    }
    return databaseFactory;
  }

  Future<Database> _initDatabase() async {
    final factory = _resolvePlatformFactory();

    String path;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      // In desktop/test runner environments, use inMemory or local test path
      path = inMemoryDatabasePath;
    } else {
      final databasesPath = await getDatabasesPath();
      path = join(databasesPath, databaseName);
    }

    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  /// Creates relational schemas and indexes.
  static Future<void> _onCreate(Database db, int version) async {
    // 1. Monitored crop plots table
    await db.execute('''
      CREATE TABLE plants (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        crop_family TEXT NOT NULL,
        variety TEXT NOT NULL,
        stage TEXT NOT NULL,
        health_status TEXT NOT NULL,
        soil_moisture_percent REAL NOT NULL,
        soil_temperature_celsius REAL NOT NULL,
        npk_summary TEXT NOT NULL,
        last_scanned_at TEXT NOT NULL,
        primary_diagnosis TEXT,
        notes TEXT NOT NULL DEFAULT ''
      );
    ''');

    // 2. Optical leaf diagnostics and pathology records table
    await db.execute('''
      CREATE TABLE diagnostic_scans (
        scan_id TEXT PRIMARY KEY,
        target_crop TEXT NOT NULL,
        detected_condition TEXT NOT NULL,
        scientific_pathogen TEXT NOT NULL,
        confidence_percentage REAL NOT NULL,
        severity TEXT NOT NULL,
        inference_latency_ms INTEGER NOT NULL,
        is_offline_inference INTEGER NOT NULL,
        symptoms_json TEXT NOT NULL,
        organic_treatment TEXT NOT NULL,
        chemical_treatment TEXT NOT NULL,
        preventative_action TEXT NOT NULL,
        scanned_at TEXT NOT NULL,
        captured_image_path TEXT
      );
    ''');

    // 3. IoT probe telemetry history
    await db.execute('''
      CREATE TABLE telemetry_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plant_id TEXT,
        soil_moisture_percent REAL NOT NULL,
        soil_temperature_celsius REAL NOT NULL,
        soil_conductivity_ec REAL NOT NULL,
        ambient_humidity_percent REAL NOT NULL,
        solar_radiation_par REAL NOT NULL,
        recorded_at TEXT NOT NULL
      );
    ''');

    // 4. Learning progress records table
    await db.execute('''
      CREATE TABLE lesson_progress (
        lesson_id TEXT PRIMARY KEY,
        is_completed INTEGER NOT NULL DEFAULT 0,
        last_step INTEGER NOT NULL DEFAULT 0,
        total_steps INTEGER NOT NULL DEFAULT 4,
        completed_at TEXT
      );
    ''');

    // 5. Treatment and triage checklist tasks for diagnosed plants
    await db.execute('''
      CREATE TABLE diagnostic_tasks (
        id TEXT PRIMARY KEY,
        plant_id TEXT NOT NULL,
        title TEXT NOT NULL,
        subtitle TEXT NOT NULL DEFAULT '',
        tier INTEGER NOT NULL DEFAULT 1,
        is_completed INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (plant_id) REFERENCES plants(id) ON DELETE CASCADE
      );
    ''');

    // 6. User key-value preferences table (theme mode, offline metrics)
    await db.execute('''
      CREATE TABLE user_preferences (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');

    // Indices for ultra-fast query execution
    await db.execute('CREATE INDEX idx_plants_health ON plants(health_status);');
    await db.execute('CREATE INDEX idx_plants_family ON plants(crop_family);');
    await db.execute('CREATE INDEX idx_scans_date ON diagnostic_scans(scanned_at DESC);');
    await db.execute('CREATE INDEX idx_scans_crop ON diagnostic_scans(target_crop);');
    await db.execute('CREATE INDEX idx_telemetry_date ON telemetry_logs(recorded_at DESC);');
    await db.execute('CREATE INDEX idx_tasks_plant ON diagnostic_tasks(plant_id);');

    // Initialize zero-progress lesson tracking (all steps 0)
    await _initLessonProgress(db);
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS lesson_progress (
          lesson_id TEXT PRIMARY KEY,
          is_completed INTEGER NOT NULL DEFAULT 0,
          last_step INTEGER NOT NULL DEFAULT 0,
          total_steps INTEGER NOT NULL DEFAULT 4,
          completed_at TEXT
        );
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('DELETE FROM lesson_progress;');
      await _initLessonProgress(db);
    }
    if (oldVersion < 4) {
      // Completely purge any legacy mock data on existing device installs
      await db.delete('plants');
      await db.delete('diagnostic_scans');
      await db.delete('telemetry_logs');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS diagnostic_tasks (
          id TEXT PRIMARY KEY,
          plant_id TEXT NOT NULL,
          title TEXT NOT NULL,
          subtitle TEXT NOT NULL DEFAULT '',
          tier INTEGER NOT NULL DEFAULT 1,
          is_completed INTEGER NOT NULL DEFAULT 0,
          completed_at TEXT,
          created_at TEXT NOT NULL
        );
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_tasks_plant ON diagnostic_tasks(plant_id);');
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_preferences (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        );
      ''');
    }
  }

  /// Initializes learning progress records so lesson tracking starts at 0% completed.
  static Future<void> _initLessonProgress(Database db) async {
    final batch = db.batch();
    final freshProgress = [
      {'lesson_id': 'lesson_1', 'is_completed': 0, 'last_step': 0, 'total_steps': 4, 'completed_at': null},
      {'lesson_id': 'lesson_2', 'is_completed': 0, 'last_step': 0, 'total_steps': 4, 'completed_at': null},
      {'lesson_id': 'lesson_3', 'is_completed': 0, 'last_step': 0, 'total_steps': 4, 'completed_at': null},
      {'lesson_id': 'lesson_4', 'is_completed': 0, 'last_step': 0, 'total_steps': 4, 'completed_at': null},
      {'lesson_id': 'lesson_5', 'is_completed': 0, 'last_step': 0, 'total_steps': 4, 'completed_at': null},
      {'lesson_id': 'lesson_6', 'is_completed': 0, 'last_step': 0, 'total_steps': 4, 'completed_at': null},
    ];
    for (final progress in freshProgress) {
      batch.insert('lesson_progress', progress, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Closes database connection cleanly.
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
}

/// Dependency injection provider for [AppDatabase].
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final appDb = AppDatabase();
  ref.onDispose(() {
    appDb.close();
  });
  return appDb;
});
