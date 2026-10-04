import '../../domain/entities/agronomy_article_model.dart';
import '../../domain/repositories/learn_repository.dart';

/// In-memory mock implementation of [LearnRepository].
class MockLearnRepository implements LearnRepository {
  final List<AgronomyArticle> _articles = [
    const AgronomyArticle(
      id: 'art_01',
      title: 'Managing Early Blight (Alternaria solani) in Solanaceae',
      targetCrop: 'Tomato & Eggplant',
      category: AgronomyCategory.pathology,
      readTimeMinutes: 4,
      summary:
          'Identify concentric target spots, mitigate lower canopy humidity, and employ bio-fungicides effectively.',
      content:
          'Early blight develops rapidly when foliage remains damp for extended periods at 24-29°C. '
          'Pruning the bottom 30cm of foliage prevents soil spore splashback. '
          'Utilize preventative copper octanoate or Bacillus amyloliquefaciens prior to canopy closure.',
    ),
    const AgronomyArticle(
      id: 'art_02',
      title: 'Differentiating Nitrogen Deficiency vs. Root Rot in Chili',
      targetCrop: 'Red Chili',
      category: AgronomyCategory.soilNutrition,
      readTimeMinutes: 3,
      summary:
          'Diagnose lower leaf chlorosis vs root necrosis using volumetric soil water readings and probe EC.',
      content:
          'Nitrogen deficiency displays uniform yellowing across older foliage starting at the leaf tips, '
          'while root rot (Phytophthora) manifests as sudden daytime wilting despite adequate soil moisture.',
    ),
    const AgronomyArticle(
      id: 'art_03',
      title: 'Optimal Drip Irrigation Regimes for Commercial Tomatoes',
      targetCrop: 'Tomato',
      category: AgronomyCategory.irrigation,
      readTimeMinutes: 5,
      summary:
          'Maintain 25-32% volumetric water content to prevent blossom end rot and fruit cracking.',
      content:
          'Inconsistent soil moisture disrupts calcium translocation to developing fruit apexes. '
          'Automated pulse irrigation timed with peak PAR solar radiation preserves optimal vapor pressure deficit.',
    ),
  ];

  @override
  Future<List<AgronomyArticle>> fetchAllArticles() async {
    await Future<void>.delayed(const Duration(milliseconds: 60));
    return List<AgronomyArticle>.unmodifiable(_articles);
  }

  @override
  Future<List<AgronomyArticle>> fetchArticlesByCrop(String crop) async {
    await Future<void>.delayed(const Duration(milliseconds: 60));
    return _articles
        .where((a) => a.targetCrop.toLowerCase().contains(crop.toLowerCase()))
        .toList(growable: false);
  }
}
