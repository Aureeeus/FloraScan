import 'package:flutter/foundation.dart';

/// Overall crop physiological condition.
enum PlantHealthStatus {
  healthy,
  caution,
  critical,
}

/// Growth stage in the agronomic lifecycle.
enum CropGrowthStage {
  vegetative,
  flowering,
  fruiting,
  harvesting,
}

/// Immutable domain entity representing a monitored crop or plant plot.
@immutable
class PlantModel {
  const PlantModel({
    required this.id,
    required this.name,
    required this.cropFamily,
    required this.variety,
    required this.stage,
    required this.healthStatus,
    required this.soilMoisturePercent,
    required this.soilTemperatureCelsius,
    required this.npkSummary,
    required this.lastScannedAt,
    this.primaryDiagnosis,
    this.notes = '',
  });

  final String id;
  final String name;
  final String cropFamily;
  final String variety;
  final CropGrowthStage stage;
  final PlantHealthStatus healthStatus;
  final double soilMoisturePercent;
  final double soilTemperatureCelsius;
  final String npkSummary;
  final DateTime lastScannedAt;
  final String? primaryDiagnosis;
  final String notes;

  PlantModel copyWith({
    String? id,
    String? name,
    String? cropFamily,
    String? variety,
    CropGrowthStage? stage,
    PlantHealthStatus? healthStatus,
    double? soilMoisturePercent,
    double? soilTemperatureCelsius,
    String? npkSummary,
    DateTime? lastScannedAt,
    String? primaryDiagnosis,
    String? notes,
  }) {
    return PlantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      cropFamily: cropFamily ?? this.cropFamily,
      variety: variety ?? this.variety,
      stage: stage ?? this.stage,
      healthStatus: healthStatus ?? this.healthStatus,
      soilMoisturePercent: soilMoisturePercent ?? this.soilMoisturePercent,
      soilTemperatureCelsius: soilTemperatureCelsius ?? this.soilTemperatureCelsius,
      npkSummary: npkSummary ?? this.npkSummary,
      lastScannedAt: lastScannedAt ?? this.lastScannedAt,
      primaryDiagnosis: primaryDiagnosis ?? this.primaryDiagnosis,
      notes: notes ?? this.notes,
    );
  }
}
