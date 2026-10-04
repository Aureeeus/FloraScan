import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/mock_learn_repository.dart';
import '../../domain/entities/agronomy_article_model.dart';
import '../../domain/repositories/learn_repository.dart';

/// Dependency injection provider for [LearnRepository].
final learnRepositoryProvider = Provider<LearnRepository>((ref) {
  return MockLearnRepository();
});

/// Reactive provider fetching all agronomy guides.
final agronomyArticlesProvider = FutureProvider<List<AgronomyArticle>>((ref) {
  final repository = ref.watch(learnRepositoryProvider);
  return repository.fetchAllArticles();
});
