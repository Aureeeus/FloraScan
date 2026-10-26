import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../data/repositories/sqlite_user_preferences_repository.dart';
import '../../domain/repositories/user_preferences_repository.dart';

/// Dependency injection provider for [UserPreferencesRepository].
final userPreferencesRepositoryProvider = Provider<UserPreferencesRepository>((ref) {
  final appDb = ref.watch(appDatabaseProvider);
  return SqliteUserPreferencesRepository(appDatabase: appDb);
});

/// Riverpod Notifier managing reactive [ThemeMode] across the application.
///
/// Acts as an ultra-fast in-memory cache synchronized with SQLite for zero-latency UI reactivity.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final repo = ref.watch(userPreferencesRepositoryProvider);

    // Asynchronously synchronize in-memory cache with persisted SQLite preference
    Future.microtask(() async {
      try {
        final savedMode = await repo.getThemeMode();
        if (state != savedMode) {
          state = savedMode;
        }
      } catch (_) {
        // Fallback gracefully
      }
    });

    return ThemeMode.system;
  }

  /// Sets the application theme mode immediately and asynchronously persists to SQLite.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) return;

    // 0ms instant UI update via in-memory cache
    state = mode;

    // Asynchronous background persistence to SQLite
    final repo = ref.read(userPreferencesRepositoryProvider);
    await repo.setThemeMode(mode);
  }
}

/// Provider exposing reactive [ThemeMode].
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// Generic persistent boolean preference notifier with zero-latency in-memory reactivity.
class BoolPreferenceNotifier extends Notifier<bool> {
  BoolPreferenceNotifier(this.key, this.defaultValue);

  final String key;
  final bool defaultValue;

  @override
  bool build() {
    final repo = ref.watch(userPreferencesRepositoryProvider);

    Future.microtask(() async {
      try {
        final saved = await repo.getPreference(key);
        if (saved != null) {
          final parsed = saved.toLowerCase() == 'true';
          if (state != parsed) {
            state = parsed;
          }
        }
      } catch (_) {
        // Graceful fallback
      }
    });

    return defaultValue;
  }

  /// Sets the boolean preference immediately and persists asynchronously to SQLite.
  Future<void> set(bool value) async {
    if (state == value) return;
    state = value;
    final repo = ref.read(userPreferencesRepositoryProvider);
    await repo.setPreference(key, value.toString());
  }
}

/// Operating scale: true = Home Garden (Pots & Balcony), false = Farm Scale (Zones & Rows).
final isHomeGardenScaleProvider = NotifierProvider<BoolPreferenceNotifier, bool>(
  () => BoolPreferenceNotifier('is_home_garden_scale', true),
);

/// Language preference: true = English, false = Filipino.
final isEnglishLanguageProvider = NotifierProvider<BoolPreferenceNotifier, bool>(
  () => BoolPreferenceNotifier('is_english_language', true),
);

/// Temperature metric: true = Celsius (°C), false = Fahrenheit (°F).
final isCelsiusMetricProvider = NotifierProvider<BoolPreferenceNotifier, bool>(
  () => BoolPreferenceNotifier('is_celsius_metric', true),
);

/// Daily morning soil inspection alert toggle.
final dailyInspectionEnabledProvider = NotifierProvider<BoolPreferenceNotifier, bool>(
  () => BoolPreferenceNotifier('daily_inspection_enabled', true),
);
