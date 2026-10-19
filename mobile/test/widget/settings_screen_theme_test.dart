import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florascan_1/core/theme/app_theme.dart';
import 'package:florascan_1/features/settings/domain/repositories/user_preferences_repository.dart';
import 'package:florascan_1/features/settings/presentation/providers/settings_providers.dart';
import 'package:florascan_1/features/settings/presentation/settings_screen.dart';

class MockUserPreferencesRepository implements UserPreferencesRepository {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Future<ThemeMode> getThemeMode() async => _themeMode;

  @override
  Future<void> setThemeMode(ThemeMode themeMode) async {
    _themeMode = themeMode;
  }

  @override
  Future<String?> getPreference(String key) async => null;

  @override
  Future<void> setPreference(String key, String value) async {}
}

void main() {
  group('SettingsScreen Theme & UI Elements Widget Tests', () {
    testWidgets('renders Display Theme options and intuitive icon before Operating Scale', (tester) async {
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

      // Verify Operating Scale icon and label
      expect(find.text('Operating Scale'), findsOneWidget);
      expect(find.byIcon(Icons.agriculture_rounded), findsOneWidget);

      // Verify Display Theme options
      expect(find.text('Display Theme'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
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
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(await mockRepo.getThemeMode(), equals(ThemeMode.dark));
      expect(find.text('Theme set to Dark Mode'), findsOneWidget);

      // Advance time to allow the floating SnackBar to dismiss cleanly
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Tap 'Light'
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
  });
}
