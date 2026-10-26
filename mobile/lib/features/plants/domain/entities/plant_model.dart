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
  harvesting;

  String get displayName => switch (this) {
    CropGrowthStage.vegetative => 'Vegetative',
    CropGrowthStage.flowering => 'Flowering',
    CropGrowthStage.fruiting => 'Fruiting',
    CropGrowthStage.harvesting => 'Harvesting',
  };
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

  /// Serializes entity to a SQLite-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'crop_family': cropFamily,
      'variety': variety,
      'stage': stage.name,
      'health_status': healthStatus.name,
      'soil_moisture_percent': soilMoisturePercent,
      'soil_temperature_celsius': soilTemperatureCelsius,
      'npk_summary': npkSummary,
      'last_scanned_at': lastScannedAt.toIso8601String(),
      'primary_diagnosis': primaryDiagnosis,
      'notes': notes,
    };
  }

  /// Deserializes entity from a SQLite row map defensively.
  factory PlantModel.fromMap(Map<String, dynamic> map) {
    return PlantModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unnamed Crop',
      cropFamily: map['crop_family'] as String? ?? map['cropFamily'] as String? ?? 'Solanaceae',
      variety: map['variety'] as String? ?? '',
      stage: CropGrowthStage.values.firstWhere(
        (e) => e.name == map['stage'],
        orElse: () => CropGrowthStage.vegetative,
      ),
      healthStatus: PlantHealthStatus.values.firstWhere(
        (e) => e.name == map['health_status'] || e.name == map['healthStatus'],
        orElse: () => PlantHealthStatus.healthy,
      ),
      soilMoisturePercent: (map['soil_moisture_percent'] as num?)?.toDouble() ??
          (map['soilMoisturePercent'] as num?)?.toDouble() ??
          0.0,
      soilTemperatureCelsius: (map['soil_temperature_celsius'] as num?)?.toDouble() ??
          (map['soilTemperatureCelsius'] as num?)?.toDouble() ??
          0.0,
      npkSummary: map['npk_summary'] as String? ?? map['npkSummary'] as String? ?? 'Balanced',
      lastScannedAt: DateTime.tryParse(map['last_scanned_at'] as String? ?? '') ?? DateTime.now(),
      primaryDiagnosis: map['primary_diagnosis'] as String? ?? map['primaryDiagnosis'] as String?,
      notes: map['notes'] as String? ?? '',
    );
  }
}
