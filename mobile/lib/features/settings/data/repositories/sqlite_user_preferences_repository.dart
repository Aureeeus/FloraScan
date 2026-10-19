import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/repositories/user_preferences_repository.dart';

/// SQLite-backed implementation of [UserPreferencesRepository].
///
/// Ensures durable, offline-first persistence without introducing external
/// key-value cache dependencies.
class SqliteUserPreferencesRepository implements UserPreferencesRepository {
  SqliteUserPreferencesRepository({this.appDatabase});

  final AppDatabase? appDatabase;

  static const String _tableName = 'user_preferences';
  static const String _keyThemeMode = 'theme_mode';

  ThemeMode _cachedThemeMode = ThemeMode.system;

  @override
  Future<ThemeMode> getThemeMode() async {
    final appDb = appDatabase;
    if (appDb == null) return _cachedThemeMode;

    try {
      final db = await appDb.database;
      final rows = await db.query(
        _tableName,
        where: 'key = ?',
        whereArgs: [_keyThemeMode],
        limit: 1,
      );

      if (rows.isNotEmpty) {
        final rawValue = rows.first['value'] as String?;
        _cachedThemeMode = _parseThemeMode(rawValue);
      }
    } catch (_) {
      // Graceful fallback to memory state during offline faults or test runs
    }

    return _cachedThemeMode;
  }

  @override
  Future<void> setThemeMode(ThemeMode themeMode) async {
    _cachedThemeMode = themeMode;
    await setPreference(_keyThemeMode, themeMode.name);
  }

  @override
  Future<String?> getPreference(String key) async {
    final appDb = appDatabase;
    if (appDb == null) return null;

    try {
      final db = await appDb.database;
      final rows = await db.query(
        _tableName,
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );

      if (rows.isNotEmpty) {
        return rows.first['value'] as String?;
      }
    } catch (_) {
      // Retain defensive tolerance
    }

    return null;
  }

  @override
  Future<void> setPreference(String key, String value) async {
    final appDb = appDatabase;
    if (appDb == null) return;

    try {
      final db = await appDb.database;
      await db.insert(
        _tableName,
        {
          'key': key,
          'value': value,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {
      // Defensive handling
    }
  }

  static ThemeMode _parseThemeMode(String? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}
