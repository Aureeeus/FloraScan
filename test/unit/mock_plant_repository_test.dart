import 'package:flutter_test/flutter_test.dart';
import 'package:florascan_1/features/plants/data/repositories/mock_plant_repository.dart';
import 'package:florascan_1/features/plants/domain/entities/plant_model.dart';

void main() {
  group('MockPlantRepository Unit Tests', () {
    late MockPlantRepository repository;

    setUp(() {
      repository = MockPlantRepository();
    });

    test('fetchAllPlants returns initial mock crop catalog', () async {
      // Arrange & Act
      final plants = await repository.fetchAllPlants();

      // Assert
      expect(plants, isNotEmpty);
      expect(plants.length, greaterThanOrEqualTo(3));
      expect(plants.first.cropFamily, equals('Solanaceae'));
    });

    test('savePlant prepends new crop and persists in memory', () async {
      // Arrange
      final newPlant = PlantModel(
        id: 'test_crop_99',
        name: 'Test Tomato Plot',
        cropFamily: 'Solanaceae',
        variety: 'Roma',
        stage: CropGrowthStage.vegetative,
        healthStatus: PlantHealthStatus.healthy,
        soilMoisturePercent: 30.0,
        soilTemperatureCelsius: 22.0,
        npkSummary: 'Balanced',
        lastScannedAt: DateTime.now(),
      );

      // Act
      await repository.savePlant(newPlant);
      final retrieved = await repository.fetchPlantById('test_crop_99');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('Test Tomato Plot'));
    });

    test('deletePlant removes target crop plot', () async {
      // Arrange
      const targetId = 'crop_01';

      // Act
      await repository.deletePlant(targetId);
      final retrieved = await repository.fetchPlantById(targetId);

      // Assert
      expect(retrieved, isNull);
    });
  });
}
