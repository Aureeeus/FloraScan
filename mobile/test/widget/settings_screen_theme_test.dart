import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florascan_1/core/theme/app_theme.dart';
import 'package:florascan_1/features/settings/domain/repositories/user_preferences_repository.dart';
import 'package:florascan_1/features/settings/presentation/providers/settings_providers.dart';
import 'package:florascan_1/features/settings/presentation/settings_screen.dart';

class MockUserPreferencesRepository implements UserPreferencesRepository {
  ThemeMode _themeMode = ThemeMode.system;
  final Map<String, String> _storage = {};

  @override
  Future<ThemeMode> getThemeMode() async => _themeMode;

  @override
  Future<void> setThemeMode(ThemeMode themeMode) async {
    _themeMode = themeMode;
  }

  @override
  Future<String?> getPreference(String key) async => _storage[key];

  @override
  Future<void> setPreference(String key, String value) async {
    _storage[key] = value;
  }
}

void main() {
  group('SettingsScreen Theme & UI Elements Widget Tests', () {
    testWidgets('renders Display Theme options and verifies Operating Scale is removed', (tester) async {
      final mockRepo = MockUserPreferencesRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userPreferencesRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Operating Scale is removed from Settings
      expect(find.text('Operating Scale'), findsNothing);
      expect(find.byIcon(Icons.agriculture_rounded), findsNothing);

      // Verify Display Theme options
      expect(find.text('Display Theme'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);

      // Verify PWR pill is removed
      expect(find.textContaining('PWR'), findsNothing);
    });

    testWidgets('tapping Dark theme option sets theme to Dark and triggers snackbar', (tester) async {
      final mockRepo = MockUserPreferencesRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userPreferencesRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap 'Dark'
      await tester.ensureVisible(find.text('Dark'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(await mockRepo.getThemeMode(), equals(ThemeMode.dark));
      expect(find.text('Theme set to Dark Mode'), findsOneWidget);

      // Advance time to allow the floating SnackBar to dismiss cleanly
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Tap 'Light'
      await tester.ensureVisible(find.text('Light'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();

      expect(await mockRepo.getThemeMode(), equals(ThemeMode.light));
      expect(find.text('Theme set to Light Mode'), findsOneWidget);
    });

    testWidgets('dark theme applies dark background colors to Scaffold and cards instead of white', (tester) async {
      final mockRepo = MockUserPreferencesRepository();
      await mockRepo.setThemeMode(ThemeMode.dark);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userPreferencesRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Scaffold has dark background color
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(const Color(0xFF101419)));

      // Verify none of the cards in SettingsScreen have the old pure white background
      final containers = tester.widgetList<Container>(find.byType(Container));
      for (final container in containers) {
        if (container.decoration is BoxDecoration) {
          final box = container.decoration as BoxDecoration;
          if (box.color != null && box.color != Colors.transparent) {
            // Assert that none of the main surface containers are pure white (0xFFFFFFFF) or light cream (0xFFFAF8FF)
            expect(
              box.color != const Color(0xFFFFFFFF) && box.color != const Color(0xFFFAF8FF),
              isTrue,
              reason: 'Expected dark surface color, but found light color: ${box.color}',
            );
          }
        }
      }
    });

    testWidgets('switching Language to Filipino immediately re-renders localized titles', (tester) async {
      final mockRepo = MockUserPreferencesRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userPreferencesRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially in English
      expect(find.text('Display Theme'), findsOneWidget);
      expect(find.text('Temperature Metric'), findsOneWidget);
      expect(find.text('Operating Scale'), findsNothing);

      // Scroll to Language and tap 'Filipino'
      await tester.ensureVisible(find.text('Filipino'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Filipino'));
      await tester.pumpAndSettle();

      // Verify UI text switched to Filipino
      expect(find.text('Tema ng Display'), findsOneWidget);
      expect(find.text('Yunit ng Temperatura'), findsOneWidget);
      expect(await mockRepo.getPreference('is_english_language'), equals('false'));

      // Tap back to 'English'
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(find.text('Display Theme'), findsOneWidget);
      expect(find.text('Temperature Metric'), findsOneWidget);
      expect(await mockRepo.getPreference('is_english_language'), equals('true'));
    });

    testWidgets('switching Temperature Metric toggles between Celsius and Fahrenheit', (tester) async {
      final mockRepo = MockUserPreferencesRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userPreferencesRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find '°F' and tap it
      await tester.ensureVisible(find.text('°F'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('°F'));
      await tester.pumpAndSettle();

      expect(await mockRepo.getPreference('is_celsius_metric'), equals('false'));

      // Tap '°C'
      await tester.tap(find.text('°C'));
      await tester.pumpAndSettle();

      expect(await mockRepo.getPreference('is_celsius_metric'), equals('true'));
    });
  });
}
