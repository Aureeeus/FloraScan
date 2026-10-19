import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/diagnostic_task_model.dart';
import '../../domain/repositories/diagnostic_task_repository.dart';

/// SQLite production repository for persisting diagnostic checklist to-do items.
class SqliteDiagnosticTaskRepository implements DiagnosticTaskRepository {
  SqliteDiagnosticTaskRepository(this._appDatabase);

  final AppDatabase _appDatabase;
  final Map<String, List<DiagnosticTaskModel>> _cache = {};

  List<DiagnosticTaskModel> getCachedTasks(String plantId) =>
      _cache[plantId] ?? const <DiagnosticTaskModel>[];

  @override
  Future<List<DiagnosticTaskModel>> fetchTasksForPlant(String plantId) async {
    final db = await _appDatabase.database;
    final results = await db.query(
      'diagnostic_tasks',
      where: 'plant_id = ?',
      whereArgs: [plantId],
      orderBy: 'tier ASC, rowid ASC',
    );
    if (results.isEmpty) {
      _cache[plantId] = const <DiagnosticTaskModel>[];
      return const <DiagnosticTaskModel>[];
    }
    final tasks = results.map(DiagnosticTaskModel.fromMap).toList();
    _cache[plantId] = tasks;
    return tasks;
  }

  @override
  Future<void> saveTask(DiagnosticTaskModel task) async {
    final db = await _appDatabase.database;
    await db.insert(
      'diagnostic_tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    final existing = List<DiagnosticTaskModel>.from(getCachedTasks(task.plantId));
    final idx = existing.indexWhere((t) => t.id == task.id);
    if (idx >= 0) {
      existing[idx] = task;
    } else {
      existing.add(task);
    }
    _cache[task.plantId] = existing;
  }

  @override
  Future<void> saveTasks(List<DiagnosticTaskModel> tasks) async {
    if (tasks.isEmpty) return;
    final db = await _appDatabase.database;
    final batch = db.batch();
    for (final task in tasks) {
      batch.insert(
        'diagnostic_tasks',
        task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    for (final task in tasks) {
      final existing = List<DiagnosticTaskModel>.from(getCachedTasks(task.plantId));
      final idx = existing.indexWhere((t) => t.id == task.id);
      if (idx >= 0) {
        existing[idx] = task;
      } else {
        existing.add(task);
      }
      _cache[task.plantId] = existing;
    }
  }

  @override
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    final db = await _appDatabase.database;
    final completedAt = isCompleted ? DateTime.now() : null;
    await db.update(
      'diagnostic_tasks',
      {
        'is_completed': isCompleted ? 1 : 0,
        'completed_at': completedAt?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );

    for (final plantId in _cache.keys) {
      final list = _cache[plantId]!;
      final idx = list.indexWhere((t) => t.id == taskId);
      if (idx >= 0) {
        list[idx] = list[idx].copyWith(
          isCompleted: isCompleted,
          completedAt: completedAt,
        );
        break;
      }
    }
  }

  @override
  Future<void> deleteTasksForPlant(String plantId) async {
    final db = await _appDatabase.database;
    await db.delete(
      'diagnostic_tasks',
      where: 'plant_id = ?',
      whereArgs: [plantId],
    );
    _cache.remove(plantId);
  }
}
