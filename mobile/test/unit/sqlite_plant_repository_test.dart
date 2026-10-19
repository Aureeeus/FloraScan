import 'package:flutter_test/flutter_test.dart';
import 'package:florascan_1/core/database/app_database.dart';
import 'package:florascan_1/features/plants/data/repositories/sqlite_plant_repository.dart';
import 'package:florascan_1/features/plants/domain/entities/plant_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('SqlitePlantRepository Unit Tests', () {
    late AppDatabase appDatabase;
    late SqlitePlantRepository repository;

    setUp(() async {
      appDatabase = await AppDatabase.inMemory();
      repository = SqlitePlantRepository(appDatabase);
    });

    tearDown(() async {
      await appDatabase.close();
    });

    test('fetchAllPlants returns empty list initially from clean SQLite', () async {
      // Arrange & Act (AAA Pattern)
      final plants = await repository.fetchAllPlants();

      // Assert
      expect(plants, isEmpty);
    });

    test('savePlant writes new crop to SQLite and fetches it accurately', () async {
      // Arrange
      final newPlant = PlantModel(
        id: 'test_crop_99',
        name: 'Cherokee Purple Tomato',
        cropFamily: 'Solanaceae',
        variety: 'Heirloom',
        stage: CropGrowthStage.flowering,
        healthStatus: PlantHealthStatus.healthy,
        soilMoisturePercent: 31.5,
        soilTemperatureCelsius: 22.8,
        npkSummary: 'N:190 P:65 K:230 ppm',
        lastScannedAt: DateTime.now(),
        notes: 'Greenhouse block C.',
      );

      // Act
      await repository.savePlant(newPlant);
      final retrieved = await repository.fetchPlantById('test_crop_99');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('Cherokee Purple Tomato'));
      expect(retrieved.stage, equals(CropGrowthStage.flowering));
      expect(retrieved.soilMoisturePercent, equals(31.5));
    });

    test('deletePlant deletes record from SQLite', () async {
      // Arrange
      final plant = PlantModel(
        id: 'crop_delete_test',
        name: 'Test Crop',
        cropFamily: 'Solanaceae',
        variety: 'Test Variety',
        stage: CropGrowthStage.vegetative,
        healthStatus: PlantHealthStatus.healthy,
        soilMoisturePercent: 25.0,
        soilTemperatureCelsius: 22.0,
        npkSummary: 'N:100 P:50 K:100 ppm',
        lastScannedAt: DateTime.now(),
      );
      await repository.savePlant(plant);
      expect(await repository.fetchPlantById('crop_delete_test'), isNotNull);

      // Act
      await repository.deletePlant('crop_delete_test');
      final retrieved = await repository.fetchPlantById('crop_delete_test');

      // Assert
      expect(retrieved, isNull);
      final remaining = await repository.fetchAllPlants();
      expect(remaining, isEmpty);
    });
  });
}
