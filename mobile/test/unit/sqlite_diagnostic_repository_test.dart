import 'package:flutter_test/flutter_test.dart';
import 'package:florascan_1/core/database/app_database.dart';
import 'package:florascan_1/features/scan/data/repositories/sqlite_diagnostic_repository.dart';
import 'package:florascan_1/features/scan/domain/entities/telemetry_reading.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('SqliteDiagnosticRepository Unit Tests', () {
    late AppDatabase appDatabase;
    late SqliteDiagnosticRepository repository;

    setUp(() async {
      appDatabase = await AppDatabase.inMemory();
      repository = SqliteDiagnosticRepository(appDatabase);
    });

    tearDown(() async {
      await appDatabase.close();
    });

    test('fetchRecentScans returns empty list initially from clean SQLite', () async {
      // Arrange & Act (AAA Pattern)
      final scans = await repository.fetchRecentScans();

      // Assert
      expect(scans, isEmpty);
    });

    test('analyzeLeaf infers pathology condition and persists result to SQLite', () async {
      // Arrange
      const testImage = 'sample_leaf.jpg';
      const crop = 'Tomato';

      // Act
      final scanResult = await repository.analyzeLeaf(
        imagePath: testImage,
        cropType: crop,
      );

      // Assert
      expect(scanResult.scanId, isNotEmpty);
      expect(scanResult.targetCrop, equals('Tomato'));
      expect(scanResult.detectedCondition, equals('Early Blight'));
      expect(scanResult.confidencePercentage, greaterThan(80.0));
      expect(scanResult.symptoms, isNotEmpty);

      // Verify persisted in SQLite
      final recent = await repository.fetchRecentScans();
      expect(recent.length, equals(1));
      expect(recent.first.scanId, equals(scanResult.scanId));
    });

    test('analyzeLeaf computes pure model assumption confidence without telemetry', () async {
      // Arrange
      const testImage = 'sample_leaf.jpg';
      const crop = 'Tomato';

      // Act: No telemetry provided (pure optical model assumption)
      final pureModelResult = await repository.analyzeLeaf(
        imagePath: testImage,
        cropType: crop,
        telemetry: null,
      );

      // Assert: Confidence is computed from temperature-scaled softmax without arbitrary hash
      expect(pureModelResult.confidencePercentage, closeTo(94.1, 0.5));
      expect(pureModelResult.detectedCondition, equals('Early Blight'));
      expect(pureModelResult.scientificPathogen, equals('Alternaria solani'));
    });

    test('analyzeLeaf fuses live sensor telemetry to corroborate pathology dynamically', () async {
      // Arrange: Warm and humid telemetry favorable for fungal sporulation (Early Blight)
      final favorableTelemetry = TelemetryReading.parse(
        'Data: moisture=2200, temp=26.5°C, humidity=82.0%, light=450',
      );

      // Act
      final pureModelResult = await repository.analyzeLeaf(
        imagePath: 'sample_leaf.jpg',
        cropType: 'Tomato',
        telemetry: null,
      );

      final sensorFusedResult = await repository.analyzeLeaf(
        imagePath: 'sample_leaf.jpg',
        cropType: 'Tomato',
        telemetry: favorableTelemetry,
      );

      // Assert: Favorable environmental micro-climate boosts Bayesian posterior confidence
      expect(sensorFusedResult.confidencePercentage, greaterThan(pureModelResult.confidencePercentage));
      expect(sensorFusedResult.detectedCondition, contains('High Humidity Stress'));
    });

    test('analyzeLeaf correctly isolates crop matrix for Eggplant and Red Chili', () async {
      // Arrange & Act
      final eggplantResult = await repository.analyzeLeaf(
        imagePath: 'eggplant_pest.jpg',
        cropType: 'Eggplant',
      );

      final chiliResult = await repository.analyzeLeaf(
        imagePath: 'chili_anthracnose.jpg',
        cropType: 'Red Chili',
      );

      // Assert
      expect(eggplantResult.targetCrop, equals('Eggplant'));
      expect(eggplantResult.detectedCondition, equals('Insect Pest Infestation'));
      expect(eggplantResult.confidencePercentage, greaterThan(80.0));

      expect(chiliResult.targetCrop, equals('Red Chili'));
      expect(chiliResult.detectedCondition, equals('Anthracnose Fruit & Foliage Spot'));
      expect(chiliResult.confidencePercentage, greaterThan(80.0));
    });
  });
}
