import '../../domain/entities/plant_model.dart';
import '../../domain/repositories/plant_repository.dart';

/// In-memory mock implementation of [PlantRepository] for prototyping.
class MockPlantRepository implements PlantRepository {
  MockPlantRepository() {
    _plants = [
      PlantModel(
        id: 'crop_01',
        name: 'San Marzano Tomato #1',
        cropFamily: 'Solanaceae',
        variety: 'Solanum lycopersicum (Indeterminate)',
        stage: CropGrowthStage.flowering,
        healthStatus: PlantHealthStatus.healthy,
        soilMoisturePercent: 32.4,
        soilTemperatureCelsius: 21.8,
        npkSummary: 'N:180 P:60 K:220 ppm (Optimal)',
        lastScannedAt: DateTime.now().subtract(const Duration(hours: 2)),
        primaryDiagnosis: 'Optimal Vigor - Clean Canopy',
        notes: 'Drip fertigation zone 2 active. No fungal sporulation observed.',
      ),
      PlantModel(
        id: 'crop_02',
        name: 'Red Habanero Chili #4',
        cropFamily: 'Solanaceae',
        variety: 'Capsicum chinense',
        stage: CropGrowthStage.fruiting,
        healthStatus: PlantHealthStatus.caution,
        soilMoisturePercent: 21.0,
        soilTemperatureCelsius: 24.5,
        npkSummary: 'N:110 P:45 K:160 ppm (Nitrogen deficit)',
        lastScannedAt: DateTime.now().subtract(const Duration(hours: 5)),
        primaryDiagnosis: 'Early Magnesium Chlorosis',
        notes: 'Interveinal yellowing detected on lower leaves. Foliar feeding scheduled.',
      ),
      PlantModel(
        id: 'crop_03',
        name: 'Black Beauty Eggplant #2',
        cropFamily: 'Solanaceae',
        variety: 'Solanum melongena',
        stage: CropGrowthStage.vegetative,
        healthStatus: PlantHealthStatus.critical,
        soilMoisturePercent: 18.2,
        soilTemperatureCelsius: 23.1,
        npkSummary: 'N:140 P:55 K:190 ppm',
        lastScannedAt: DateTime.now().subtract(const Duration(minutes: 45)),
        primaryDiagnosis: 'Early Blight (Alternaria solani)',
        notes: 'Target spot concentric lesions on 3 basal leaves. Urgent fungicide intervention required.',
      ),
      PlantModel(
        id: 'crop_04',
        name: 'Cayenne Long Slim #3',
        cropFamily: 'Solanaceae',
        variety: 'Capsicum annuum',
        stage: CropGrowthStage.fruiting,
        healthStatus: PlantHealthStatus.healthy,
        soilMoisturePercent: 29.8,
        soilTemperatureCelsius: 22.0,
        npkSummary: 'N:175 P:58 K:210 ppm',
        lastScannedAt: DateTime.now().subtract(const Duration(hours: 18)),
        primaryDiagnosis: 'Healthy - Ready for first harvest cycle',
        notes: 'High fruit load. Support staking intact.',
      ),
    ];
  }

  late List<PlantModel> _plants;

  @override
  Future<List<PlantModel>> fetchAllPlants() async {
    // Simulate brief asynchronous dispatch
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return List<PlantModel>.unmodifiable(_plants);
  }

  @override
  Future<PlantModel?> fetchPlantById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    try {
      return _plants.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> savePlant(PlantModel plant) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final existingIndex = _plants.indexWhere((p) => p.id == plant.id);
    if (existingIndex >= 0) {
      _plants[existingIndex] = plant;
    } else {
      _plants.insert(0, plant);
    }
  }

  @override
  Future<void> deletePlant(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _plants.removeWhere((p) => p.id == id);
  }
}
