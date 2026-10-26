import 'package:flutter_test/flutter_test.dart';
import 'package:florascan_1/features/plants/domain/entities/plant_model.dart';
import 'package:florascan_1/features/plants/presentation/plant_formatting_utils.dart';

void main() {
  group('PlantFormattingUtils.formatTimeAgo Unit Tests', () {
    final now = DateTime(2026, 10, 23, 12, 0, 0);

    test('returns "Just now" for current or future or <1 min timestamps', () {
      expect(
        PlantFormattingUtils.formatTimeAgo(now, referenceTime: now),
        'Just now',
      );
      expect(
        PlantFormattingUtils.formatTimeAgo(
          now.subtract(const Duration(seconds: 30)),
          referenceTime: now,
        ),
        'Just now',
      );
      expect(
        PlantFormattingUtils.formatTimeAgo(
          now.add(const Duration(minutes: 5)),
          referenceTime: now,
        ),
        'Just now',
      );
    });

    test('correctly discriminates singular vs plural minutes', () {
      expect(
        PlantFormattingUtils.formatTimeAgo(
          now.subtract(const Duration(minutes: 1)),
          referenceTime: now,
        ),
        '1 min ago',
      );
      expect(
        PlantFormattingUtils.formatTimeAgo(
          now.subtract(const Duration(minutes: 2)),
          referenceTime: now,
        ),
        '2 mins ago',
      );
      expect(
        PlantFormattingUtils.formatTimeAgo(
          now.subtract(const Duration(minutes: 59)),
          referenceTime: now,
        ),
        '59 mins ago',
      );
    });

    test('correctly discriminates singular vs plural hours without "1 hrs ago"', () {
      expect(
        PlantFormattingUtils.formatTimeAgo(
          now.subtract(const Duration(hours: 1)),
          referenceTime: now,
        ),
        '1 hr ago',
      );
      expect(
        PlantFormattingUtils.formatTimeAgo(
          now.subtract(const Duration(hours: 2)),
          referenceTime: now,
        ),
        '2 hrs ago',
      );
      expect(
        PlantFormattingUtils.formatTimeAgo(
          now.subtract(const Duration(hours: 23)),
          referenceTime: now,
        ),
        '23 hrs ago',
      );
    });

    test('formats 1 day ago as "Yesterday" and >1 days as "X days ago"', () {
      expect(
        PlantFormattingUtils.formatTimeAgo(
          now.subtract(const Duration(days: 1)),
          referenceTime: now,
        ),
        'Yesterday',
      );
      expect(
        PlantFormattingUtils.formatTimeAgo(
          now.subtract(const Duration(days: 3)),
          referenceTime: now,
        ),
        '3 days ago',
      );
    });

    test('formats weeks and months accurately', () {
      expect(
        PlantFormattingUtils.formatTimeAgo(
          now.subtract(const Duration(days: 7)),
          referenceTime: now,
        ),
        '1 wk ago',
      );
      expect(
        PlantFormattingUtils.formatTimeAgo(
          now.subtract(const Duration(days: 14)),
          referenceTime: now,
        ),
        '2 wks ago',
      );
      expect(
        PlantFormattingUtils.formatTimeAgo(
          now.subtract(const Duration(days: 35)),
          referenceTime: now,
        ),
        '1 mo ago',
      );
      expect(
        PlantFormattingUtils.formatTimeAgo(
          now.subtract(const Duration(days: 70)),
          referenceTime: now,
        ),
        '2 mos ago',
      );
    });
  });

  group('PlantFormattingUtils Subtitle & Redundancy Unit Tests', () {
    test('eliminates redundant crop and variety when already present in name', () {
      final plant = PlantModel(
        id: 'plant_1',
        name: 'Red Chili Standard',
        cropFamily: 'Solanaceae',
        variety: 'Red Chili Standard',
        stage: CropGrowthStage.flowering,
        healthStatus: PlantHealthStatus.healthy,
        soilMoisturePercent: 45.0,
        soilTemperatureCelsius: 24.5,
        npkSummary: 'Balanced',
        lastScannedAt: DateTime.now(),
      );

      final metadata = PlantFormattingUtils.buildPlantItemMetadata(
        plant: plant,
        area: 'Balcony',
        crop: 'Chili',
      );

      // Should be "Balcony • Flowering", NOT "Balcony • 'Red Chili Standard' • Chili • Flowering"
      expect(metadata, 'Balcony • Flowering');
      expect(metadata.contains('Chili • Chili'), isFalse);
    });

    test('preserves distinct crop and distinct variety for generic plot names', () {
      final plant = PlantModel(
        id: 'plant_2',
        name: 'North Bed Plot 1',
        cropFamily: 'Solanaceae',
        variety: 'Bird\'s Eye',
        stage: CropGrowthStage.vegetative,
        healthStatus: PlantHealthStatus.healthy,
        soilMoisturePercent: 50.0,
        soilTemperatureCelsius: 25.0,
        npkSummary: 'Balanced',
        lastScannedAt: DateTime.now(),
      );

      final metadata = PlantFormattingUtils.buildPlantItemMetadata(
        plant: plant,
        area: 'Backyard',
        crop: 'Chili',
      );

      expect(metadata, 'Backyard • Chili • Bird\'s Eye • Vegetative');
    });

    test('buildFocalPlantTitle avoids duplicate variety in parentheses', () {
      final plant1 = PlantModel(
        id: 'plant_1',
        name: 'Red Chili Standard',
        cropFamily: 'Solanaceae',
        variety: 'Red Chili Standard',
        stage: CropGrowthStage.flowering,
        healthStatus: PlantHealthStatus.healthy,
        soilMoisturePercent: 45.0,
        soilTemperatureCelsius: 24.5,
        npkSummary: 'Balanced',
        lastScannedAt: DateTime.now(),
      );

      expect(
        PlantFormattingUtils.buildFocalPlantTitle(plant1),
        'Red Chili Standard',
      );

      final plant2 = PlantModel(
        id: 'plant_2',
        name: 'Plot 1',
        cropFamily: 'Solanaceae',
        variety: 'Habanero',
        stage: CropGrowthStage.flowering,
        healthStatus: PlantHealthStatus.healthy,
        soilMoisturePercent: 45.0,
        soilTemperatureCelsius: 24.5,
        npkSummary: 'Balanced',
        lastScannedAt: DateTime.now(),
      );

      expect(
        PlantFormattingUtils.buildFocalPlantTitle(plant2),
        'Plot 1 (Habanero)',
      );
    });
  });
}
