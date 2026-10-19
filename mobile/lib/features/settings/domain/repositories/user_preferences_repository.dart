import 'package:flutter/material.dart';

/// Contract for persistent user preferences adhering to Clean Architecture and SSOT.
abstract interface class UserPreferencesRepository {
  /// Retrieves the active [ThemeMode] preference. Defaults to [ThemeMode.system].
  Future<ThemeMode> getThemeMode();

  /// Persists the selected [ThemeMode].
  Future<void> setThemeMode(ThemeMode themeMode);

  /// Retrieves a generic string preference by [key].
  Future<String?> getPreference(String key);

  /// Persists a generic string preference by [key].
  Future<void> setPreference(String key, String value);
}
