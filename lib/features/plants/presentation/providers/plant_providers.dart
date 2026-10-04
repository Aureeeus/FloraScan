import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/mock_plant_repository.dart';
import '../../domain/entities/plant_model.dart';
import '../../domain/repositories/plant_repository.dart';

/// Dependency Injection provider for [PlantRepository].
///
/// Can be cleanly overridden in tests or swapped with local database / API repository.
final plantRepositoryProvider = Provider<PlantRepository>((ref) {
  return MockPlantRepository();
});

/// Async notifier managing the collection of registered crops.
class PlantListNotifier extends AsyncNotifier<List<PlantModel>> {
  @override
  Future<List<PlantModel>> build() async {
    final repository = ref.watch(plantRepositoryProvider);
    return repository.fetchAllPlants();
  }

  /// Adds a new plant and refreshes local state.
  Future<void> addPlant(PlantModel newPlant) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(plantRepositoryProvider);
      await repository.savePlant(newPlant);
      return repository.fetchAllPlants();
    });
  }

  /// Deletes a plant by ID and updates state.
  Future<void> removePlant(String plantId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(plantRepositoryProvider);
      await repository.deletePlant(plantId);
      return repository.fetchAllPlants();
    });
  }

  /// Reloads crops from the underlying repository.
  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(plantRepositoryProvider);
      return repository.fetchAllPlants();
    });
  }
}

/// Provider exposing reactive list of crops.
final plantListNotifierProvider =
    AsyncNotifierProvider<PlantListNotifier, List<PlantModel>>(
  PlantListNotifier.new,
);
