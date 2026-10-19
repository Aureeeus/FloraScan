import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florascan_1/features/settings/domain/repositories/user_preferences_repository.dart';
import 'package:florascan_1/features/settings/presentation/providers/settings_providers.dart';

class FakeUserPreferencesRepository implements UserPreferencesRepository {
  ThemeMode _mode = ThemeMode.system;

  @override
  Future<ThemeMode> getThemeMode() async => _mode;

  @override
  Future<void> setThemeMode(ThemeMode themeMode) async {
    _mode = themeMode;
  }

  @override
  Future<String?> getPreference(String key) async => null;

  @override
  Future<void> setPreference(String key, String value) async {}
}

void main() {
  group('ThemeModeNotifier Unit Tests', () {
    test('initializes with ThemeMode.system and updates on setThemeMode', () async {
      final fakeRepo = FakeUserPreferencesRepository();
      final container = ProviderContainer(
        overrides: [
          userPreferencesRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), equals(ThemeMode.system));

      await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), equals(ThemeMode.dark));
      expect(await fakeRepo.getThemeMode(), equals(ThemeMode.dark));

      await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
      expect(container.read(themeModeProvider), equals(ThemeMode.light));
      expect(await fakeRepo.getThemeMode(), equals(ThemeMode.light));
    });
  });
}
