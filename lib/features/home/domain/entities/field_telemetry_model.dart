import 'package:flutter/foundation.dart';

/// Single field alert item for agronomy risks.
@immutable
class AgronomyAlertItem {
  const AgronomyAlertItem({
    required this.id,
    required this.title,
    required this.description,
    required this.isUrgent,
    required this.timestamp,
  });

  final String id;
  final String title;
  final String description;
  final bool isUrgent;
  final DateTime timestamp;
}

/// Immutable domain snapshot representing live sensor telemetry from IoT soil wand & greenhouse nodes.
@immutable
class FieldTelemetrySnapshot {
  const FieldTelemetrySnapshot({
    required this.soilMoisturePercent,
    required this.soilTemperatureCelsius,
    required this.soilConductivityEc,
    required this.ambientHumidityPercent,
    required this.solarRadiationPar,
    required this.isWandConnected,
    required this.wandBatteryPercent,
    required this.localInferenceLatencyMs,
    required this.activeAlerts,
    required this.lastUpdated,
  });

  final double soilMoisturePercent;
  final double soilTemperatureCelsius;
  final double soilConductivityEc;
  final double ambientHumidityPercent;
  final double solarRadiationPar;
  final bool isWandConnected;
  final int wandBatteryPercent;
  final int localInferenceLatencyMs;
  final List<AgronomyAlertItem> activeAlerts;
  final DateTime lastUpdated;
}
