import 'package:flutter_test/flutter_test.dart';
import 'package:florascan_1/core/database/app_database.dart';
import 'package:florascan_1/features/scan/data/repositories/sqlite_diagnostic_repository.dart';
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
      expect(scanResult.detectedCondition, isNotEmpty);
      expect(scanResult.confidencePercentage, greaterThan(80.0));
      expect(scanResult.symptoms, isNotEmpty);

      // Verify persisted in SQLite
      final recent = await repository.fetchRecentScans();
      expect(recent.length, equals(1));
      expect(recent.first.scanId, equals(scanResult.scanId));
    });
  });
}
