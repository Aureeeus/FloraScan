import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:florascan_1/features/home/domain/entities/field_telemetry_model.dart';
import 'package:florascan_1/features/learn/domain/entities/lesson_progress.dart';
import 'package:florascan_1/features/learn/domain/services/learn_context_greeting_service.dart';
import 'package:florascan_1/features/plants/domain/entities/plant_model.dart';

void main() {
  group('LearnContextGreetingService Unit Tests', () {
    test('returns critical plant health warning when a plant is in critical condition', () {
      final plant = PlantModel(
        id: 'plant_1',
        name: 'Monstera Deliciosa',
        cropFamily: 'Araceae',
        variety: 'Monstera deliciosa',
        stage: CropGrowthStage.vegetative,
        healthStatus: PlantHealthStatus.critical,
        soilMoisturePercent: 22.0,
        soilTemperatureCelsius: 21.0,
        npkSummary: 'N:120 P:40 K:100',
        lastScannedAt: DateTime.now(),
        primaryDiagnosis: 'Late Blight',
      );

      final greeting = resolveLearnContextGreeting(
        currentTime: DateTime(2026, 10, 23, 8, 30),
        plants: [plant],
      );

      expect(greeting.greeting, 'Good morning!');
      expect(greeting.badge, 'URGENT SCOUT');
      expect(greeting.subtitle, contains('Critical attention required on Monstera Deliciosa (Late Blight)'));
      expect(greeting.icon, Icons.warning_amber_rounded);
    });

    test('returns low moisture alert when FloraWand is connected and moisture < 20%', () {
      final telemetry = FieldTelemetrySnapshot(
        soilMoisturePercent: 14.5,
        soilTemperatureCelsius: 24.0,
        soilConductivityEc: 1.2,
        ambientHumidityPercent: 65.0,
        solarRadiationPar: 450.0,
        isWandConnected: true,
        wandBatteryPercent: 90,
        localInferenceLatencyMs: 12,
        activeAlerts: const [],
        lastUpdated: DateTime.now(),
      );

      final greeting = resolveLearnContextGreeting(
        currentTime: DateTime(2026, 10, 23, 13, 0),
        isWandConnected: true,
        telemetry: telemetry,
      );

      expect(greeting.greeting, 'Good afternoon!');
      expect(greeting.badge, 'LOW MOISTURE');
      expect(greeting.subtitle, contains('14.5%'));
      expect(greeting.subtitle, contains('Water root zone'));
      expect(greeting.icon, Icons.water_drop_outlined);
    });

    test('returns waterlogged alert when FloraWand is connected and moisture > 40%', () {
      final telemetry = FieldTelemetrySnapshot(
        soilMoisturePercent: 44.8,
        soilTemperatureCelsius: 22.0,
        soilConductivityEc: 1.5,
        ambientHumidityPercent: 70.0,
        solarRadiationPar: 350.0,
        isWandConnected: true,
        wandBatteryPercent: 88,
        localInferenceLatencyMs: 12,
        activeAlerts: const [],
        lastUpdated: DateTime.now(),
      );

      final greeting = resolveLearnContextGreeting(
        currentTime: DateTime(2026, 10, 23, 17, 30),
        isWandConnected: true,
        telemetry: telemetry,
      );

      expect(greeting.greeting, 'Good evening!');
      expect(greeting.badge, 'WATERLOGGED');
      expect(greeting.subtitle, contains('44.8%'));
      expect(greeting.subtitle, contains('Empty saucer to prevent hypoxia'));
      expect(greeting.icon, Icons.water_damage_outlined);
    });

    test('returns curriculum complete badge when all lessons are finished', () {
      final Map<String, LessonProgress> progressMap = {
        'lesson_1': const LessonProgress(lessonId: 'lesson_1', isCompleted: true, lastStep: 4),
        'lesson_2': const LessonProgress(lessonId: 'lesson_2', isCompleted: true, lastStep: 4),
      };

      final greeting = resolveLearnContextGreeting(
        currentTime: DateTime(2026, 10, 23, 10, 0),
        progressMap: progressMap,
      );

      expect(greeting.greeting, 'Good morning!');
      expect(greeting.badge, 'CERTIFIED GROWER');
      expect(greeting.subtitle, contains('Curriculum complete! All 6 core agronomic guides mastered.'));
      expect(greeting.icon, Icons.verified_outlined);
    });

    test('returns natural Morning greeting without badge clutter between 5:00 and 10:59', () {
      final greeting = resolveLearnContextGreeting(
        currentTime: DateTime(2026, 10, 23, 7, 15),
      );

      expect(greeting.greeting, 'Good morning!');
      expect(greeting.badge, isNull);
      expect(greeting.subtitle, contains('Early hours are optimal for morning bicarb sprays'));
      expect(greeting.icon, Icons.wb_sunny_outlined);
    });

    test('returns natural Afternoon greeting without badge clutter between 11:00 and 15:59', () {
      final greeting = resolveLearnContextGreeting(
        currentTime: DateTime(2026, 10, 23, 13, 45),
      );

      expect(greeting.greeting, 'Good afternoon!');
      expect(greeting.badge, isNull);
      expect(greeting.subtitle, contains('Peak sun intensity: avoid foliar chemical sprays'));
      expect(greeting.icon, Icons.wb_sunny);
    });

    test('returns natural Dusk greeting without badge clutter between 16:00 and 19:59', () {
      final greeting = resolveLearnContextGreeting(
        currentTime: DateTime(2026, 10, 23, 18, 20),
      );

      expect(greeting.greeting, 'Good evening!');
      expect(greeting.badge, isNull);
      expect(greeting.subtitle, contains('Dusk is the ideal window for organic neem oil treatments'));
      expect(greeting.icon, Icons.nights_stay_outlined);
    });

    test('returns natural Night greeting without "Night Cycle" pill clutter after 20:00 or before 05:00', () {
      final greetingLate = resolveLearnContextGreeting(
        currentTime: DateTime(2026, 10, 23, 22, 0),
      );
      expect(greetingLate.greeting, 'Good evening!');
      expect(greetingLate.badge, isNull);
      expect(greetingLate.subtitle, contains('Foliage rests overnight'));
      expect(greetingLate.icon, Icons.bedtime_outlined);

      final greetingDawn = resolveLearnContextGreeting(
        currentTime: DateTime(2026, 10, 23, 3, 30),
      );
      expect(greetingDawn.greeting, 'Good evening!');
      expect(greetingDawn.badge, isNull);
    });
  });
}
