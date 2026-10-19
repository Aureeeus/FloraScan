import 'package:flutter_test/flutter_test.dart';
import 'package:florascan_1/core/database/app_database.dart';
import 'package:florascan_1/features/learn/data/repositories/local_learn_repository.dart';
import 'package:florascan_1/features/learn/domain/entities/lesson_progress.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  group('LessonProgress Entity Tests', () {
    test('LessonProgress serializes toMap and deserializes fromMap correctly', () {
      final now = DateTime(2026, 10, 19, 10, 0);
      final progress = LessonProgress(
        lessonId: 'lesson_1',
        isCompleted: true,
        lastStep: 4,
        totalSteps: 4,
        completedAt: now,
      );

      final map = progress.toMap();
      expect(map['lesson_id'], 'lesson_1');
      expect(map['is_completed'], 1);
      expect(map['last_step'], 4);
      expect(map['total_steps'], 4);
      expect(map['completed_at'], now.toIso8601String());

      final restored = LessonProgress.fromMap(map);
      expect(restored.lessonId, progress.lessonId);
      expect(restored.isCompleted, true);
      expect(restored.lastStep, 4);
      expect(restored.totalSteps, 4);
      expect(restored.completedAt, now);
    });

    test('LessonProgress copyWith produces expected immutable copy', () {
      const original = LessonProgress(
        lessonId: 'lesson_3',
        isCompleted: false,
        lastStep: 2,
        totalSteps: 4,
      );

      final updated = original.copyWith(
        isCompleted: true,
        lastStep: 4,
        completedAt: DateTime(2026, 10, 19),
      );

      expect(updated.lessonId, 'lesson_3');
      expect(updated.isCompleted, true);
      expect(updated.lastStep, 4);
      expect(updated.totalSteps, 4);
      expect(updated.completedAt, DateTime(2026, 10, 19));
      expect(original.isCompleted, false);
      expect(original.lastStep, 2);
    });
  });

  group('LocalLearnRepository SQLite Persistence Tests', () {
    late AppDatabase appDb;
    late LocalLearnRepository repository;

    setUp(() async {
      appDb = await AppDatabase.inMemory(factory: databaseFactoryFfi);
      repository = LocalLearnRepository(appDatabase: appDb);
    });

    tearDown(() async {
      await appDb.close();
    });

    test('fetchAllProgress loads initial seeded progress records from SQLite', () async {
      final progressMap = await repository.fetchAllProgress();

      expect(progressMap.length, 6);
      for (int i = 1; i <= 6; i++) {
        expect(progressMap['lesson_$i']?.isCompleted, false);
        expect(progressMap['lesson_$i']?.lastStep, 0);
        expect(progressMap['lesson_$i']?.totalSteps, 4);
      }
    });

    test('saveProgress persists updated lesson step and completion into SQLite', () async {
      // 1. Initially Lesson 1 is at step 0
      final initial = await repository.fetchAllProgress();
      expect(initial['lesson_1']?.isCompleted, false);
      expect(initial['lesson_1']?.lastStep, 0);

      // 2. Advance Lesson 1 to step 1
      final step1 = initial['lesson_1']!.copyWith(lastStep: 1);
      await repository.saveProgress(step1);

      final afterStep1 = await repository.fetchAllProgress();
      expect(afterStep1['lesson_1']?.lastStep, 1);
      expect(afterStep1['lesson_1']?.isCompleted, false);

      // 3. Complete Lesson 1
      final completed = afterStep1['lesson_1']!.copyWith(
        lastStep: 4,
        isCompleted: true,
        completedAt: DateTime.now(),
      );
      await repository.saveProgress(completed);

      // 4. Verify directly in a new repository instance pointing to the same database
      final freshRepo = LocalLearnRepository(appDatabase: appDb);
      final freshProgress = await freshRepo.fetchAllProgress();
      expect(freshProgress['lesson_1']?.lastStep, 4);
      expect(freshProgress['lesson_1']?.isCompleted, true);
      expect(freshProgress['lesson_1']?.completedAt, isNotNull);
    });

    test('resetAllProgress clears all progress and resets all lessons to step 0', () async {
      // Complete lesson 1 and 2
      final initial = await repository.fetchAllProgress();
      await repository.saveProgress(initial['lesson_1']!.copyWith(isCompleted: true, lastStep: 4));
      await repository.saveProgress(initial['lesson_2']!.copyWith(isCompleted: true, lastStep: 4));

      final updated = await repository.fetchAllProgress();
      expect(updated['lesson_1']?.isCompleted, true);
      expect(updated['lesson_2']?.isCompleted, true);

      // Reset all progress
      await repository.resetAllProgress();

      final reset = await repository.fetchAllProgress();
      expect(reset.length, 6);
      for (int i = 1; i <= 6; i++) {
        expect(reset['lesson_$i']?.isCompleted, false);
        expect(reset['lesson_$i']?.lastStep, 0);
      }
    });

    test('LocalLearnRepository works seamlessly with in-memory fallback if no db provided', () async {
      final memoryRepo = LocalLearnRepository();
      final initial = await memoryRepo.fetchAllProgress();
      expect(initial.length, 6);
      expect(initial['lesson_1']?.isCompleted, false);
      expect(initial['lesson_1']?.lastStep, 0);

      final updated = initial['lesson_4']!.copyWith(isCompleted: true, lastStep: 4);
      await memoryRepo.saveProgress(updated);

      final rechecked = await memoryRepo.fetchAllProgress();
      expect(rechecked['lesson_4']?.isCompleted, true);
      expect(rechecked['lesson_4']?.lastStep, 4);
    });
  });
}
