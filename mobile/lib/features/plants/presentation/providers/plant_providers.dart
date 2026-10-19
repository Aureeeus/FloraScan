import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../data/repositories/sqlite_plant_repository.dart';
import '../../domain/entities/plant_model.dart';
import '../../domain/repositories/plant_repository.dart';

/// Dependency Injection provider for [PlantRepository].
///
/// Injects SQLite-backed repository for offline persistence across mobile and tablet devices.
final plantRepositoryProvider = Provider<PlantRepository>((ref) {
  final appDb = ref.watch(appDatabaseProvider);
  return SqlitePlantRepository(appDb);
});

/// Async notifier managing the collection of registered crops.
class PlantListNotifier extends AsyncNotifier<List<PlantModel>> {
  @override
  FutureOr<List<PlantModel>> build() {
    final repository = ref.watch(plantRepositoryProvider);
    if (repository is SqlitePlantRepository) {
      final initial = repository.currentPlants;
      Future.microtask(() async {
        final plants = await repository.fetchAllPlants();
        if (ref.mounted) {
          state = AsyncData(plants);
        }
      });
      return initial;
    }
    return repository.fetchAllPlants();
  }

  /// Adds a new plant and refreshes local state.
  Future<void> addPlant(PlantModel newPlant) async {
    final repository = ref.read(plantRepositoryProvider);
    await repository.savePlant(newPlant);
    final updated = await repository.fetchAllPlants();
    if (ref.mounted) {
      state = AsyncData(updated);
    }
  }

  /// Deletes a plant by ID and updates state.
  Future<void> removePlant(String plantId) async {
    final repository = ref.read(plantRepositoryProvider);
    await repository.deletePlant(plantId);
    final updated = await repository.fetchAllPlants();
    if (ref.mounted) {
      state = AsyncData(updated);
    }
  }

  /// Reloads crops from the underlying repository.
  Future<void> reload() async {
    final repository = ref.read(plantRepositoryProvider);
    final updated = await repository.fetchAllPlants();
    if (ref.mounted) {
      state = AsyncData(updated);
    }
  }
}

/// Provider exposing reactive list of crops.
final plantListNotifierProvider =
    AsyncNotifierProvider<PlantListNotifier, List<PlantModel>>(
  PlantListNotifier.new,
);
