import 'package:flutter/foundation.dart';

/// Categories of agronomy educational content.
enum AgronomyCategory {
  pathology,
  soilNutrition,
  prevention,
  irrigation,
}

/// Immutable domain entity representing an agronomy educational article.
@immutable
class AgronomyArticle {
  const AgronomyArticle({
    required this.id,
    required this.title,
    required this.targetCrop,
    required this.category,
    required this.readTimeMinutes,
    required this.summary,
    required this.content,
  });

  final String id;
  final String title;
  final String targetCrop;
  final AgronomyCategory category;
  final int readTimeMinutes;
  final String summary;
  final String content;
}
