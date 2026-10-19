import 'package:flutter/foundation.dart';

/// Immutable domain entity representing a user's progress through an educational lesson.
@immutable
class LessonProgress {
  const LessonProgress({
    required this.lessonId,
    required this.isCompleted,
    required this.lastStep,
    this.totalSteps = 4,
    this.completedAt,
  });

  final String lessonId;
  final bool isCompleted;
  final int lastStep;
  final int totalSteps;
  final DateTime? completedAt;

  LessonProgress copyWith({
    String? lessonId,
    bool? isCompleted,
    int? lastStep,
    int? totalSteps,
    DateTime? completedAt,
  }) {
    return LessonProgress(
      lessonId: lessonId ?? this.lessonId,
      isCompleted: isCompleted ?? this.isCompleted,
      lastStep: lastStep ?? this.lastStep,
      totalSteps: totalSteps ?? this.totalSteps,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lesson_id': lessonId,
      'is_completed': isCompleted ? 1 : 0,
      'last_step': lastStep,
      'total_steps': totalSteps,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory LessonProgress.fromMap(Map<String, dynamic> map) {
    return LessonProgress(
      lessonId: map['lesson_id'] as String,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      lastStep: map['last_step'] as int? ?? 0,
      totalSteps: map['total_steps'] as int? ?? 4,
      completedAt: map['completed_at'] != null ? DateTime.tryParse(map['completed_at'] as String) : null,
    );
  }
}
