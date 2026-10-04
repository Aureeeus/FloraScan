import '../entities/agronomy_article_model.dart';

/// Contract for agronomy educational guides and disease references.
abstract interface class LearnRepository {
  /// Fetches all reference articles.
  Future<List<AgronomyArticle>> fetchAllArticles();

  /// Fetches articles filtered by category or crop type.
  Future<List<AgronomyArticle>> fetchArticlesByCrop(String crop);
}
