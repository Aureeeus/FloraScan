import 'package:flutter/foundation.dart';

/// Immutable domain entity representing an actionable treatment or triage task for a diagnosed crop.
@immutable
class DiagnosticTaskModel {
  const DiagnosticTaskModel({
    required this.id,
    required this.plantId,
    required this.title,
    required this.subtitle,
    this.tier = 1,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
  });

  final String id;
  final String plantId;
  final String title;
  final String subtitle;
  final int tier;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;

  DiagnosticTaskModel copyWith({
    String? id,
    String? plantId,
    String? title,
    String? subtitle,
    int? tier,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return DiagnosticTaskModel(
      id: id ?? this.id,
      plantId: plantId ?? this.plantId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      tier: tier ?? this.tier,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plant_id': plantId,
      'title': title,
      'subtitle': subtitle,
      'tier': tier,
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DiagnosticTaskModel.fromMap(Map<String, dynamic> map) {
    return DiagnosticTaskModel(
      id: map['id'] as String? ?? '',
      plantId: map['plant_id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      tier: (map['tier'] as num?)?.toInt() ?? 1,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      completedAt: map['completed_at'] != null
          ? DateTime.tryParse(map['completed_at'] as String)
          : null,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
