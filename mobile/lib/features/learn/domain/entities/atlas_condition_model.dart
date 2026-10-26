import 'package:flutter/material.dart';

/// Domain entity representing an agronomy disease atlas condition.
@immutable
class AtlasCondition {
  const AtlasCondition({
    required this.title,
    required this.pathogen,
    required this.crop,
    required this.severityTag,
    required this.tagBg,
    required this.tagColor,
    required this.description,
    required this.recipeLabel,
    required this.symptoms,
    required this.organicTreatment,
    required this.chemicalTreatment,
    required this.preventativeAction,
  });

  final String title;
  final String pathogen;
  final String crop;
  final String severityTag;
  final Color tagBg;
  final Color tagColor;
  final String description;
  final String recipeLabel;
  final List<String> symptoms;
  final String organicTreatment;
  final String chemicalTreatment;
  final String preventativeAction;
}
