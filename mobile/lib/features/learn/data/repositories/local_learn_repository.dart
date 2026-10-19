import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/agronomy_article_model.dart';
import '../../domain/entities/lesson_progress.dart';
import '../../domain/repositories/learn_repository.dart';

/// Production implementation of [LearnRepository] backed by local pathology knowledge base assets and SQLite persistence.
class LocalLearnRepository implements LearnRepository {
  LocalLearnRepository({this.appDatabase});

  final AppDatabase? appDatabase;
  List<AgronomyArticle>? _cachedArticles;

  final Map<String, LessonProgress> _progressMemory = {
    'lesson_1': const LessonProgress(lessonId: 'lesson_1', isCompleted: false, lastStep: 0, totalSteps: 4),
    'lesson_2': const LessonProgress(lessonId: 'lesson_2', isCompleted: false, lastStep: 0, totalSteps: 4),
    'lesson_3': const LessonProgress(lessonId: 'lesson_3', isCompleted: false, lastStep: 0, totalSteps: 4),
    'lesson_4': const LessonProgress(lessonId: 'lesson_4', isCompleted: false, lastStep: 0, totalSteps: 4),
    'lesson_5': const LessonProgress(lessonId: 'lesson_5', isCompleted: false, lastStep: 0, totalSteps: 4),
    'lesson_6': const LessonProgress(lessonId: 'lesson_6', isCompleted: false, lastStep: 0, totalSteps: 4),
  };

  Future<List<AgronomyArticle>> _loadArticles() async {
    if (_cachedArticles != null) {
      return _cachedArticles!;
    }

    try {
      final jsonStr = await rootBundle.loadString('assets/models/pathology_registry.json');
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final classes = data['classes'] as List<dynamic>? ?? [];

      final articles = <AgronomyArticle>[];
      for (final item in classes) {
        if (item is Map<String, dynamic>) {
          final id = item['id'] as String? ?? '';
          final crop = item['crop'] as String? ?? 'General';
          final name = item['displayName'] as String? ?? 'Plant Pathology Guide';
          final pathogen = item['scientificPathogen'] as String? ?? '';
          final symptoms = (item['symptoms'] as List<dynamic>?)?.join('; ') ?? '';
          final organic = item['organicTreatment'] as String? ?? '';
          final chemical = item['chemicalTreatment'] as String? ?? '';
          final prevent = item['preventativeAction'] as String? ?? '';

          articles.add(
            AgronomyArticle(
              id: id,
              title: '$crop: $name ($pathogen)',
              targetCrop: crop,
              category: AgronomyCategory.pathology,
              readTimeMinutes: 4,
              summary: symptoms.isNotEmpty ? symptoms : 'Comprehensive scouting and management protocol.',
              content: 'Pathogen: $pathogen.\n\nKey Symptoms: $symptoms\n\nOrganic Action: $organic\n\nChemical Protocol: $chemical\n\nPrevention: $prevent',
            ),
          );
        }
      }
      _cachedArticles = articles;
    } catch (_) {
      _cachedArticles = const [
        AgronomyArticle(
          id: 'art_01',
          title: 'Managing Early Blight (Alternaria solani) in Solanaceae',
          targetCrop: 'Tomato & Eggplant',
          category: AgronomyCategory.pathology,
          readTimeMinutes: 4,
          summary: 'Mitigate lower canopy humidity and employ bio-fungicides effectively.',
          content: 'Early blight develops rapidly when foliage remains damp for extended periods.',
        ),
      ];
    }

    return _cachedArticles!;
  }

  @override
  Future<List<AgronomyArticle>> fetchAllArticles() async {
    return _loadArticles();
  }

  @override
  Future<List<AgronomyArticle>> fetchArticlesByCrop(String crop) async {
    final all = await _loadArticles();
    return all.where((a) => a.targetCrop.toLowerCase().contains(crop.toLowerCase())).toList();
  }

  @override
  Future<Map<String, LessonProgress>> fetchAllProgress() async {
    final appDb = appDatabase;
    if (appDb != null) {
      try {
        final db = await appDb.database;
        final rows = await db.query('lesson_progress');
        if (rows.isNotEmpty) {
          final result = <String, LessonProgress>{};
          for (final row in rows) {
            final progress = LessonProgress.fromMap(row);
            result[progress.lessonId] = progress;
            _progressMemory[progress.lessonId] = progress;
          }
          return result;
        } else {
          // If table exists but is empty, seed with initial defaults
          for (final entry in _progressMemory.entries) {
            await db.insert(
              'lesson_progress',
              entry.value.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      } catch (_) {
        // Fallback to in-memory state on error or if table uninitialized
      }
    }
    return Map<String, LessonProgress>.from(_progressMemory);
  }

  @override
  Future<void> saveProgress(LessonProgress progress) async {
    _progressMemory[progress.lessonId] = progress;
    final appDb = appDatabase;
    if (appDb != null) {
      try {
        final db = await appDb.database;
        await db.insert(
          'lesson_progress',
          progress.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (_) {
        // Retain in-memory fallback
      }
    }
  }

  @override
  Future<void> resetAllProgress() async {
    for (final key in _progressMemory.keys) {
      _progressMemory[key] = LessonProgress(lessonId: key, isCompleted: false, lastStep: 0, totalSteps: 4);
    }
    final appDb = appDatabase;
    if (appDb != null) {
      try {
        final db = await appDb.database;
        await db.delete('lesson_progress');
        for (final p in _progressMemory.values) {
          await db.insert('lesson_progress', p.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        }
      } catch (_) {
        // Retain in-memory fallback
      }
    }
  }
}
