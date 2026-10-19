import 'package:flutter/foundation.dart';

/// SSOT Agronomic biophysical profile defining temperature, humidity, and moisture
/// permissiveness boundaries for a Solanaceae pathology or healthy baseline.
@immutable
class AgronomicBiophysicalProfile {
  const AgronomicBiophysicalProfile({
    required this.index,
    required this.id,
    required this.crop,
    required this.displayName,
    required this.scientificPathogen,
    required this.optimalTemp,
    required this.tempMin,
    required this.tempMax,
    required this.tempSigma,
    required this.minHumidity,
    required this.humidityType,
    required this.soilMoistureIdeal,
    required this.soilMoistureMin,
    required this.soilMoistureMax,
    required this.keyDistinguisher,
    required this.citation,
  });

  factory AgronomicBiophysicalProfile.fromJson(Map<String, dynamic> json) {
    return AgronomicBiophysicalProfile(
      index: json['index'] as int,
      id: json['id'] as String,
      crop: json['crop'] as String,
      displayName: json['display_name'] as String,
      scientificPathogen: json['scientific_pathogen'] as String,
      optimalTemp: (json['optimal_temp'] as num).toDouble(),
      tempMin: (json['temp_min'] as num).toDouble(),
      tempMax: (json['temp_max'] as num).toDouble(),
      tempSigma: (json['temp_sigma'] as num).toDouble(),
      minHumidity: (json['min_humidity'] as num).toDouble(),
      humidityType: json['humidity_type'] as String,
      soilMoistureIdeal: (json['soil_moisture_ideal'] as num).toDouble(),
      soilMoistureMin: (json['soil_moisture_min'] as num).toDouble(),
      soilMoistureMax: (json['soil_moisture_max'] as num).toDouble(),
      keyDistinguisher: json['key_distinguisher'] as String? ?? '',
      citation: json['citation'] as String? ?? '',
    );
  }

  final int index;
  final String id;
  final String crop;
  final String displayName;
  final String scientificPathogen;
  final double optimalTemp;
  final double tempMin;
  final double tempMax;
  final double tempSigma;
  final double minHumidity;
  final String humidityType;
  final double soilMoistureIdeal;
  final double soilMoistureMin;
  final double soilMoistureMax;
  final String keyDistinguisher;
  final String citation;
}
