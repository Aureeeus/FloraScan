import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ble/flora_wand_ble_service.dart';
import '../../../../core/database/app_database.dart';
import '../../../home/presentation/providers/telemetry_providers.dart';
import '../../../plants/presentation/providers/plant_providers.dart';
import '../../data/repositories/local_learn_repository.dart';
import '../../domain/entities/agronomy_article_model.dart';
import '../../domain/entities/atlas_condition_model.dart';
import '../../domain/entities/glossary_term_model.dart';
import '../../domain/entities/lesson_definition.dart';
import '../../domain/entities/lesson_progress.dart';
import '../../domain/repositories/learn_repository.dart';
import '../../domain/services/learn_context_greeting_service.dart';

/// Dependency injection provider for [LearnRepository].
///
/// Injects local knowledge-base repository backed by packaged agronomic registries and SQLite.
final learnRepositoryProvider = Provider<LearnRepository>((ref) {
  final appDb = ref.watch(appDatabaseProvider);
  return LocalLearnRepository(appDatabase: appDb);
});

/// Reactive provider fetching all agronomy guides.
final agronomyArticlesProvider = FutureProvider<List<AgronomyArticle>>((ref) {
  final repository = ref.watch(learnRepositoryProvider);
  return repository.fetchAllArticles();
});

/// Reactive provider delivering all interactive micro-lessons.
final lessonsProvider = FutureProvider<List<LessonDefinition>>((ref) {
  final repository = ref.watch(learnRepositoryProvider);
  return repository.fetchLessons();
});

/// Reactive provider delivering all diagnostic atlas conditions.
final atlasConditionsProvider = FutureProvider<List<AtlasCondition>>((ref) {
  final repository = ref.watch(learnRepositoryProvider);
  return repository.fetchAtlasConditions();
});

/// Reactive provider delivering all agricultural dictionary glossary terms.
final glossaryTermsProvider = FutureProvider<List<GlossaryTerm>>((ref) {
  final repository = ref.watch(learnRepositoryProvider);
  return repository.fetchGlossaryTerms();
});

/// Reactive notifier managing user learning progress across interactive lessons.
class LessonProgressNotifier extends AsyncNotifier<Map<String, LessonProgress>> {
  @override
  Future<Map<String, LessonProgress>> build() async {
    final repository = ref.watch(learnRepositoryProvider);
    return repository.fetchAllProgress();
  }

  /// Marks a lesson as fully completed and saves to local SQLite database.
  Future<void> completeLesson(String lessonId) async {
    final current = state.value ?? {};
    final existing = current[lessonId] ?? LessonProgress(lessonId: lessonId, isCompleted: false, lastStep: 0);
    final updated = existing.copyWith(
      isCompleted: true,
      lastStep: existing.totalSteps,
      completedAt: DateTime.now(),
    );

    final updatedMap = Map<String, LessonProgress>.from(current)..[lessonId] = updated;
    state = AsyncValue.data(updatedMap);

    final repository = ref.read(learnRepositoryProvider);
    await repository.saveProgress(updated);
  }

  /// Updates step progress for a lesson and saves to local SQLite database.
  Future<void> updateStep(String lessonId, int step, {bool? isCompleted}) async {
    final current = state.value ?? {};
    final existing = current[lessonId] ?? LessonProgress(lessonId: lessonId, isCompleted: false, lastStep: 0);
    final completed = isCompleted ?? (step >= existing.totalSteps);
    final updated = existing.copyWith(
      lastStep: step,
      isCompleted: completed,
      completedAt: completed ? DateTime.now() : null,
    );

    final updatedMap = Map<String, LessonProgress>.from(current)..[lessonId] = updated;
    state = AsyncValue.data(updatedMap);

    final repository = ref.read(learnRepositoryProvider);
    await repository.saveProgress(updated);
  }

  /// Resets all lesson progress back to the beginning state and persists to SQLite.
  Future<void> resetProgress() async {
    final repository = ref.read(learnRepositoryProvider);
    await repository.resetAllProgress();
    final fresh = await repository.fetchAllProgress();
    state = AsyncValue.data(fresh);
  }
}

/// Provider exposing reactive learning progress across all lessons.
final lessonProgressNotifierProvider =
    AsyncNotifierProvider<LessonProgressNotifier, Map<String, LessonProgress>>(
  LessonProgressNotifier.new,
);

/// Provider delivering the context-aware agronomic greeting.
///
/// Reactively evaluates current solar time, FloraWand BLE live telemetry,
/// registered plant health alerts, and curriculum milestones.
final learnContextGreetingProvider = Provider<LearnContextGreeting>((ref) {
  final telemetryAsync = ref.watch(liveTelemetryProvider);
  final plantsAsync = ref.watch(plantListNotifierProvider);
  final progressAsync = ref.watch(lessonProgressNotifierProvider);
  final wandState = ref.watch(floraWandNotifierProvider);

  return resolveLearnContextGreeting(
    currentTime: DateTime.now(),
    telemetry: telemetryAsync.value,
    plants: plantsAsync.value,
    progressMap: progressAsync.value,
    isWandConnected: wandState.isConnected,
  );
});
