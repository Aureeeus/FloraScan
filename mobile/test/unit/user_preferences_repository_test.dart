import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:florascan_1/core/database/app_database.dart';
import 'package:florascan_1/features/settings/data/repositories/sqlite_user_preferences_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('SqliteUserPreferencesRepository Unit Tests', () {
    late AppDatabase appDatabase;
    late SqliteUserPreferencesRepository repository;

    setUp(() async {
      appDatabase = await AppDatabase.inMemory(factory: databaseFactoryFfi);
      repository = SqliteUserPreferencesRepository(appDatabase: appDatabase);
    });

    tearDown(() async {
      await appDatabase.close();
    });

    test('getThemeMode returns ThemeMode.system by default on fresh SQLite database', () async {
      final themeMode = await repository.getThemeMode();
      expect(themeMode, equals(ThemeMode.system));
    });

    test('setThemeMode persists ThemeMode.dark to SQLite and retrieves it correctly', () async {
      await repository.setThemeMode(ThemeMode.dark);

      final retrieved = await repository.getThemeMode();
      expect(retrieved, equals(ThemeMode.dark));

      // Direct verification against SQLite table
      final db = await appDatabase.database;
      final rows = await db.query(
        'user_preferences',
        where: 'key = ?',
        whereArgs: ['theme_mode'],
      );
      expect(rows, hasLength(1));
      expect(rows.first['value'], equals('dark'));
    });

    test('setThemeMode updates existing record when changing to ThemeMode.light', () async {
      await repository.setThemeMode(ThemeMode.dark);
      await repository.setThemeMode(ThemeMode.light);

      final retrieved = await repository.getThemeMode();
      expect(retrieved, equals(ThemeMode.light));

      final db = await appDatabase.database;
      final rows = await db.query(
        'user_preferences',
        where: 'key = ?',
        whereArgs: ['theme_mode'],
      );
      expect(rows, hasLength(1));
      expect(rows.first['value'], equals('light'));
    });

    test('setPreference and getPreference persist and retrieve arbitrary key-value pairs', () async {
      await repository.setPreference('temperature_metric', 'celsius');
      final value = await repository.getPreference('temperature_metric');

      expect(value, equals('celsius'));
    });

    test('functions safely with in-memory fallback when appDatabase is null', () async {
      final fallbackRepo = SqliteUserPreferencesRepository(appDatabase: null);

      expect(await fallbackRepo.getThemeMode(), equals(ThemeMode.system));
      await fallbackRepo.setThemeMode(ThemeMode.dark);
      expect(await fallbackRepo.getThemeMode(), equals(ThemeMode.dark));
    });
  });
}
