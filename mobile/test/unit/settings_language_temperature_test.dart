import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florascan_1/core/ble/flora_wand_calibration_service.dart';
import 'package:florascan_1/core/l10n/app_localizations.dart';
import 'package:florascan_1/features/settings/domain/repositories/user_preferences_repository.dart';
import 'package:florascan_1/features/settings/presentation/providers/settings_providers.dart';

class InMemoryUserPreferencesRepository implements UserPreferencesRepository {
  final Map<String, String> _storage = {};

  @override
  Future<ThemeMode> getThemeMode() async => ThemeMode.system;

  @override
  Future<void> setThemeMode(ThemeMode themeMode) async {}

  @override
  Future<String?> getPreference(String key) async => _storage[key];

  @override
  Future<void> setPreference(String key, String value) async {
    _storage[key] = value;
  }
}

void main() {
  group('CalibratedTelemetry Temperature Conversion Tests', () {
    test('formatTemp formats Celsius accurately and handles null', () {
      expect(CalibratedTelemetry.formatTemp(null, isCelsius: true), equals('--'));
      expect(CalibratedTelemetry.formatTemp(null, isCelsius: false), equals('--'));
      expect(CalibratedTelemetry.formatTemp(25.0, isCelsius: true), equals('25.0°C'));
      expect(CalibratedTelemetry.formatTemp(0.0, isCelsius: true), equals('0.0°C'));
      expect(CalibratedTelemetry.formatTemp(37.5, isCelsius: true), equals('37.5°C'));
      expect(CalibratedTelemetry.formatTemp(-5.2, isCelsius: true), equals('-5.2°C'));
    });

    test('formatTemp converts Celsius to Fahrenheit accurately (T_F = T_C * 1.8 + 32)', () {
      // 0°C -> 32°F
      expect(CalibratedTelemetry.formatTemp(0.0, isCelsius: false), equals('32.0°F'));
      // 25°C -> 77°F (25 * 1.8 + 32 = 45 + 32 = 77)
      expect(CalibratedTelemetry.formatTemp(25.0, isCelsius: false), equals('77.0°F'));
      // 100°C -> 212°F
      expect(CalibratedTelemetry.formatTemp(100.0, isCelsius: false), equals('212.0°F'));
      // -10°C -> 14°F (-10 * 1.8 + 32 = -18 + 32 = 14)
      expect(CalibratedTelemetry.formatTemp(-10.0, isCelsius: false), equals('14.0°F'));
      // 28.5°C -> 83.3°F (28.5 * 1.8 + 32 = 51.3 + 32 = 83.3)
      expect(CalibratedTelemetry.formatTemp(28.5, isCelsius: false), equals('83.3°F'));
    });

    test('CalibratedTelemetry instance methods formatTemperature and formattedTemperature', () {
      final telemetry = CalibratedTelemetry(
        soilMoisturePercent: 55.0,
        soilMoistureTag: 'Optimal',
        isMoistureWarning: false,
        temperatureCelsius: 25.0,
        temperatureTag: 'Optimal',
        isTemperatureWarning: false,
        humidityPercent: 65.0,
        humidityTag: 'Optimal',
        isHumidityWarning: false,
        lightLux: 3200,
        lightTag: 'Good',
        isLightWarning: false,
        batteryPercent: 88,
        isProbeInserted: true,
        timestamp: DateTime(2026, 10, 23),
      );

      // Backwards-compatible getter
      expect(telemetry.formattedTemperature, equals('25.0°C'));
      // Explicit Celsius
      expect(telemetry.formatTemperature(isCelsius: true), equals('25.0°C'));
      // Explicit Fahrenheit
      expect(telemetry.formatTemperature(isCelsius: false), equals('77.0°F'));
    });
  });

  group('AppLocalizations English and Filipino Tests', () {
    test('verifies English localizations', () {
      const l10n = AppLocalizationsEn();
      expect(l10n.navHome, equals('Home'));
      expect(l10n.navMyPlants, equals('My Plants'));
      expect(l10n.navScan, equals('Scan'));
      expect(l10n.navLearn, equals('Learn'));
      expect(l10n.navSettings, equals('Settings'));
      expect(l10n.english, equals('English'));
      expect(l10n.filipino, equals('Filipino'));
      expect(l10n.operatingScale, equals('Operating Scale'));
      expect(l10n.temperatureMetric, equals('Temperature Metric'));
    });

    test('verifies Filipino localizations', () {
      const l10n = AppLocalizationsFil();
      expect(l10n.navHome, equals('Tahanan'));
      expect(l10n.navMyPlants, equals('Aking Halaman'));
      expect(l10n.navScan, equals('Suriin'));
      expect(l10n.navLearn, equals('Matuto'));
      expect(l10n.navSettings, equals('Mga Setting'));
      expect(l10n.english, equals('English'));
      expect(l10n.filipino, equals('Filipino'));
      expect(l10n.operatingScale, equals('Sukat ng Pagtatanim'));
      expect(l10n.temperatureMetric, equals('Yunit ng Temperatura'));
    });
  });

  group('Settings Providers Reactivity Tests', () {
    test('isEnglishLanguageProvider updates state and syncs appLocalizationsProvider', () async {
      final repo = InMemoryUserPreferencesRepository();
      final container = ProviderContainer(
        overrides: [
          userPreferencesRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      // Default should be English
      expect(container.read(isEnglishLanguageProvider), isTrue);
      expect(container.read(appLocalizationsProvider).navHome, equals('Home'));

      // Switch to Filipino
      await container.read(isEnglishLanguageProvider.notifier).set(false);
      expect(container.read(isEnglishLanguageProvider), isFalse);
      expect(container.read(appLocalizationsProvider).navHome, equals('Tahanan'));
      expect(await repo.getPreference('is_english_language'), equals('false'));

      // Switch back to English
      await container.read(isEnglishLanguageProvider.notifier).set(true);
      expect(container.read(isEnglishLanguageProvider), isTrue);
      expect(container.read(appLocalizationsProvider).navHome, equals('Home'));
      expect(await repo.getPreference('is_english_language'), equals('true'));
    });

    test('isCelsiusMetricProvider updates state and persists preference', () async {
      final repo = InMemoryUserPreferencesRepository();
      final container = ProviderContainer(
        overrides: [
          userPreferencesRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      // Default should be Celsius
      expect(container.read(isCelsiusMetricProvider), isTrue);

      // Switch to Fahrenheit
      await container.read(isCelsiusMetricProvider.notifier).set(false);
      expect(container.read(isCelsiusMetricProvider), isFalse);
      expect(await repo.getPreference('is_celsius_metric'), equals('false'));

      // Switch back to Celsius
      await container.read(isCelsiusMetricProvider.notifier).set(true);
      expect(container.read(isCelsiusMetricProvider), isTrue);
      expect(await repo.getPreference('is_celsius_metric'), equals('true'));
    });
  });
}
