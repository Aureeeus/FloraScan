import '../entities/agronomy_article_model.dart';
import '../entities/lesson_progress.dart';

/// Contract for agronomy educational guides, disease references, and user learning progress.
abstract interface class LearnRepository {
  /// Fetches all reference articles.
  Future<List<AgronomyArticle>> fetchAllArticles();

  /// Fetches articles filtered by category or crop type.
  Future<List<AgronomyArticle>> fetchArticlesByCrop(String crop);

  /// Fetches user progress across all interactive lessons.
  Future<Map<String, LessonProgress>> fetchAllProgress();

  /// Persists updated learning progress for a specific lesson.
  Future<void> saveProgress(LessonProgress progress);

  /// Resets all learning progress back to the beginning state.
  Future<void> resetAllProgress();
}
