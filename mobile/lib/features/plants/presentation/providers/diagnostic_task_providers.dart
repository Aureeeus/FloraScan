import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../data/repositories/sqlite_diagnostic_task_repository.dart';
import '../../domain/entities/diagnostic_task_model.dart';
import '../../domain/entities/plant_model.dart';
import '../../domain/repositories/diagnostic_task_repository.dart';
import 'plant_providers.dart';

/// Dependency injection provider for [DiagnosticTaskRepository].
final diagnosticTaskRepositoryProvider = Provider<DiagnosticTaskRepository>((ref) {
  final appDb = ref.watch(appDatabaseProvider);
  return SqliteDiagnosticTaskRepository(appDb);
});

/// Agronomic generator creating realistic, prioritized triage tasks based on diagnosis pathology.
class DiagnosticTaskGenerator {
  static List<DiagnosticTaskModel> generateTasksForPlant(PlantModel plant) {
    final lowerCondition = (plant.primaryDiagnosis ?? '').toLowerCase();
    final now = DateTime.now();

    if (lowerCondition.contains('blight') ||
        lowerCondition.contains('spot') ||
        lowerCondition.contains('fungal') ||
        lowerCondition.contains('anthracnose') ||
        lowerCondition.contains('rot')) {
      return [
        DiagnosticTaskModel(
          id: 'task_${plant.id}_1',
          plantId: plant.id,
          title: 'Stop overhead watering; keep topsoil dry for 24-48 hrs.',
          subtitle: 'Fungal spores thrive on stagnant water droplets.',
          tier: 1,
          createdAt: now,
        ),
        DiagnosticTaskModel(
          id: 'task_${plant.id}_2',
          plantId: plant.id,
          title: 'Sterilize pruners and remove infected lower leaves into trash.',
          subtitle: 'Do not compost infected tissue to avoid spore reinfection.',
          tier: 1,
          createdAt: now,
        ),
        DiagnosticTaskModel(
          id: 'task_${plant.id}_3',
          plantId: plant.id,
          title: 'Increase air circulation and provide 1-2 feet space around pot.',
          subtitle: 'Breaks up humid boundary layer around canopy.',
          tier: 1,
          createdAt: now,
        ),
        DiagnosticTaskModel(
          id: 'task_${plant.id}_4',
          plantId: plant.id,
          title: 'Apply organic copper fungicide spray in early morning.',
          subtitle: 'Coat both top and underside of remaining healthy leaves.',
          tier: 2,
          createdAt: now,
        ),
      ];
    } else if (lowerCondition.contains('chlorosis') ||
        lowerCondition.contains('yellow') ||
        lowerCondition.contains('nutrient') ||
        lowerCondition.contains('deficit')) {
      return [
        DiagnosticTaskModel(
          id: 'task_${plant.id}_1',
          plantId: plant.id,
          title: 'Check pot drainage holes to ensure no waterlogging is choking roots.',
          subtitle: 'Anaerobic roots cannot absorb iron or magnesium.',
          tier: 1,
          createdAt: now,
        ),
        DiagnosticTaskModel(
          id: 'task_${plant.id}_2',
          plantId: plant.id,
          title: 'Flush soil with 500ml fresh pH-balanced water.',
          subtitle: 'Clears accumulated mineral salts and unblocks root uptake.',
          tier: 1,
          createdAt: now,
        ),
        DiagnosticTaskModel(
          id: 'task_${plant.id}_3',
          plantId: plant.id,
          title: 'Apply foliar Cal-Mag or liquid seaweed extract amendment.',
          subtitle: 'Foliar feeding bypasses root lock and greens leaves in 48h.',
          tier: 2,
          createdAt: now,
        ),
      ];
    } else if (lowerCondition.contains('water') ||
        lowerCondition.contains('dry') ||
        lowerCondition.contains('drought')) {
      return [
        DiagnosticTaskModel(
          id: 'task_${plant.id}_1',
          plantId: plant.id,
          title: 'Deep soak soil slowly until runoff appears in saucer.',
          subtitle: 'Dry peat/coco can develop hydrophobic dry pockets.',
          tier: 1,
          createdAt: now,
        ),
        DiagnosticTaskModel(
          id: 'task_${plant.id}_2',
          plantId: plant.id,
          title: 'Empty saucer after 20 minutes to prevent root rot.',
          subtitle: 'Standing saucer water causes root suffocation.',
          tier: 1,
          createdAt: now,
        ),
        DiagnosticTaskModel(
          id: 'task_${plant.id}_3',
          plantId: plant.id,
          title: 'Mulch topsoil with 1 inch dry organic matter.',
          subtitle: 'Drastically cuts evaporation under intense sun.',
          tier: 2,
          createdAt: now,
        ),
      ];
    }

    return [
      DiagnosticTaskModel(
        id: 'task_${plant.id}_1',
        plantId: plant.id,
        title: 'Inspect underside of foliage for pests or active lesions.',
        subtitle: 'Use optical scout camera with flash if needed.',
        tier: 1,
        createdAt: now,
      ),
      DiagnosticTaskModel(
        id: 'task_${plant.id}_2',
        plantId: plant.id,
        title: 'Prune dead or dying foliage to preserve plant energy.',
        subtitle: 'Directs carbohydrates to healthy shoots and fruits.',
        tier: 1,
        createdAt: now,
      ),
      DiagnosticTaskModel(
        id: 'task_${plant.id}_3',
        plantId: plant.id,
        title: 'Monitor soil moisture reading daily with FloraWand probe.',
        subtitle: 'Maintain steady 40-60% optimal root zone saturation.',
        tier: 2,
        createdAt: now,
      ),
    ];
  }
}

/// Reactive notifier managing diagnostic checklist tasks for a specific plant plot.
class PlantDiagnosticTasksNotifier extends AsyncNotifier<List<DiagnosticTaskModel>> {
  PlantDiagnosticTasksNotifier(this.plantId);

  final String plantId;

  @override
  Future<List<DiagnosticTaskModel>> build() async {
    final repo = ref.watch(diagnosticTaskRepositoryProvider);
    final plantList = ref.watch(plantListNotifierProvider).value ?? const <PlantModel>[];
    final plant = plantList.cast<PlantModel?>().firstWhere(
          (p) => p?.id == plantId,
          orElse: () => null,
        );

    if (repo is SqliteDiagnosticTaskRepository) {
      final cached = repo.getCachedTasks(plantId);
      if (cached.isNotEmpty) return cached;
    }

    final tasks = await repo.fetchTasksForPlant(plantId);
    if (tasks.isNotEmpty) {
      return tasks;
    }

    if (plant != null && plant.healthStatus != PlantHealthStatus.healthy) {
      final generated = DiagnosticTaskGenerator.generateTasksForPlant(plant);
      await repo.saveTasks(generated);
      return generated;
    }

    return const <DiagnosticTaskModel>[];
  }

  /// Ensures tasks exist in SQLite for this diagnosed plant, generating them if first triage.
  Future<void> initializeTasksIfEmpty(PlantModel plant) async {
    final repo = ref.read(diagnosticTaskRepositoryProvider);
    final existing = await repo.fetchTasksForPlant(plant.id);
    if (existing.isEmpty) {
      final generated = DiagnosticTaskGenerator.generateTasksForPlant(plant);
      await repo.saveTasks(generated);
      if (ref.mounted) {
        state = AsyncData(generated);
      }
    } else {
      if (ref.mounted) {
        state = AsyncData(existing);
      }
    }
  }

  /// Toggles task completion and saves state in SQLite.
  Future<void> toggleTask(String taskId, bool isCompleted) async {
    final repo = ref.read(diagnosticTaskRepositoryProvider);
    await repo.toggleTaskCompletion(taskId, isCompleted);
    final updated = await repo.fetchTasksForPlant(plantId);
    if (ref.mounted) {
      state = AsyncData(updated);
    }
  }

  /// Refreshes tasks from SQLite.
  Future<void> reload() async {
    final repo = ref.read(diagnosticTaskRepositoryProvider);
    final updated = await repo.fetchTasksForPlant(plantId);
    if (ref.mounted) {
      state = AsyncData(updated);
    }
  }
}

/// Provider exposing reactive list of diagnostic tasks scoped to a specific plant ID.
final plantDiagnosticTasksNotifierProvider =
    AsyncNotifierProvider.family<PlantDiagnosticTasksNotifier, List<DiagnosticTaskModel>, String>(
  (arg) => PlantDiagnosticTasksNotifier(arg),
);
