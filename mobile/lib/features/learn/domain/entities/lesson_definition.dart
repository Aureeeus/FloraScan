import 'package:flutter/material.dart';

/// Single step definition within an interactive micro-lesson.
@immutable
class LessonStepData {
  const LessonStepData({
    required this.stepNumber,
    required this.title,
    required this.goodTip,
    required this.poorTip,
  });

  final int stepNumber;
  final String title;
  final String goodTip;
  final String poorTip;
}

/// Metadata definition for interactive agronomy micro-lessons.
@immutable
class LessonDefinition {
  const LessonDefinition({
    required this.id,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.icon,
    required this.steps,
  });

  final String id;
  final int number;
  final String title;
  final String subtitle;
  final String duration;
  final IconData icon;
  final List<LessonStepData> steps;

  int get totalSteps => steps.length;
  String get storyTitle => steps.isNotEmpty ? steps.first.title : title;
  String get goodTip => steps.isNotEmpty ? steps.first.goodTip : '';
  String get poorTip => steps.isNotEmpty ? steps.first.poorTip : '';
}
