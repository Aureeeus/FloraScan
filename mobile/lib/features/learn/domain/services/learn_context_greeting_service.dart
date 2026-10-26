import 'package:flutter/material.dart';

import '../../../home/domain/entities/field_telemetry_model.dart';
import '../../../plants/domain/entities/plant_model.dart';
import '../entities/lesson_progress.dart';

/// Data model representing a dynamic context-aware agronomy greeting.
@immutable
class LearnContextGreeting {
  const LearnContextGreeting({
    required this.greeting,
    required this.subtitle,
    this.badge,
    this.icon,
  });

  final String greeting;
  final String subtitle;
  final String? badge;
  final IconData? icon;
}

/// Resolves a context-aware agronomic greeting based on time of day, plant health,
/// live telemetry, and learning curriculum milestones.
LearnContextGreeting resolveLearnContextGreeting({
  DateTime? currentTime,
  FieldTelemetrySnapshot? telemetry,
  List<PlantModel>? plants,
  Map<String, LessonProgress>? progressMap,
  bool isWandConnected = false,
}) {
  final now = currentTime ?? DateTime.now();
  final hour = now.hour;

  // 1. Check for urgent plant health warnings first (Priority 1)
  final criticalPlants = plants?.where((p) => p.healthStatus == PlantHealthStatus.critical).toList() ?? [];
  if (criticalPlants.isNotEmpty) {
    final first = criticalPlants.first;
    return LearnContextGreeting(
      greeting: _timeSalutation(hour),
      subtitle: 'Critical attention required on ${first.name} (${first.primaryDiagnosis}). Check treatment protocols below.',
      badge: 'URGENT SCOUT',
      icon: Icons.warning_amber_rounded,
    );
  }

  // 2. Check for active live moisture warnings from connected FloraWand (Priority 2)
  if (isWandConnected && telemetry != null) {
    if (telemetry.soilMoisturePercent < 20.0) {
      return LearnContextGreeting(
        greeting: _timeSalutation(hour),
        subtitle: 'Wand telemetry: Soil moisture is low (${telemetry.soilMoisturePercent.toStringAsFixed(1)}%). Water root zone before heat rises.',
        badge: 'LOW MOISTURE',
        icon: Icons.water_drop_outlined,
      );
    } else if (telemetry.soilMoisturePercent > 40.0) {
      return LearnContextGreeting(
        greeting: _timeSalutation(hour),
        subtitle: 'Wand telemetry: Soil is waterlogged (${telemetry.soilMoisturePercent.toStringAsFixed(1)}%). Empty saucer to prevent hypoxia.',
        badge: 'WATERLOGGED',
        icon: Icons.water_damage_outlined,
      );
    }
  }

  // 3. Check for learning curriculum milestones (Priority 3)
  if (progressMap != null && progressMap.isNotEmpty) {
    final allCompleted = progressMap.values.every((p) => p.isCompleted);
    if (allCompleted) {
      return LearnContextGreeting(
        greeting: _timeSalutation(hour),
        subtitle: 'Curriculum complete! All 6 core agronomic guides mastered. Review treatment recipes below.',
        badge: 'CERTIFIED GROWER',
        icon: Icons.verified_outlined,
      );
    }
  }

  // 4. Default to Agronomic Time-of-Day Window (Natural baseline - clean, zero badge clutter)
  if (hour >= 5 && hour < 11) {
    return const LearnContextGreeting(
      greeting: 'Good morning!',
      subtitle: 'Early hours are optimal for morning bicarb sprays and checking root-zone moisture.',
      icon: Icons.wb_sunny_outlined,
    );
  } else if (hour >= 11 && hour < 16) {
    return const LearnContextGreeting(
      greeting: 'Good afternoon!',
      subtitle: 'Peak sun intensity: avoid foliar chemical sprays during midday heat to prevent leaf scorch.',
      icon: Icons.wb_sunny,
    );
  } else if (hour >= 16 && hour < 20) {
    return const LearnContextGreeting(
      greeting: 'Good evening!',
      subtitle: 'Dusk is the ideal window for organic neem oil treatments to protect pollinators and prevent scorch.',
      icon: Icons.nights_stay_outlined,
    );
  } else {
    return const LearnContextGreeting(
      greeting: 'Good evening!',
      subtitle: 'Foliage rests overnight. Avoid late overhead irrigation to keep canopy humidity low.',
      icon: Icons.bedtime_outlined,
    );
  }
}

String _timeSalutation(int hour) {
  if (hour < 12) return 'Good morning!';
  if (hour < 17) return 'Good afternoon!';
  return 'Good evening!';
}
