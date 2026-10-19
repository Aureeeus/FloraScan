import 'package:flutter/foundation.dart';
import '../../../../core/ble/flora_wand_calibration_service.dart';

/// Immutable domain model representing live physical sensor telemetry from the IoT wand.
@immutable
class TelemetryReading {
  const TelemetryReading({
    required this.rawMoistureAdc,
    required this.temperatureCelsius,
    required this.relativeHumidityPct,
    required this.ambientLightRaw,
    required this.isValid,
    required this.isProbeInserted,
    required this.isStale,
    required this.calibratedMoisturePct,
    required this.timestamp,
    this.ttlSeconds = 300,
  });

  /// Factory creating domain telemetry from [CalibratedTelemetry].
  factory TelemetryReading.fromCalibrated(
    CalibratedTelemetry telemetry, {
    int ttlSeconds = 300,
  }) {
    return TelemetryReading(
      rawMoistureAdc: (3200 - (telemetry.soilMoisturePercent / 100.0 * 2000)).round().clamp(1200, 3200),
      temperatureCelsius: telemetry.temperatureCelsius,
      relativeHumidityPct: telemetry.humidityPercent,
      ambientLightRaw: telemetry.lightLux.round(),
      isValid: true,
      isProbeInserted: telemetry.isProbeInserted,
      isStale: false,
      calibratedMoisturePct: telemetry.soilMoisturePercent,
      timestamp: telemetry.timestamp,
      ttlSeconds: ttlSeconds,
    );
  }

  /// Factory creating an empty / disconnected reading (pure optical fallback).
  factory TelemetryReading.disconnected() {
    return TelemetryReading(
      rawMoistureAdc: 4095,
      temperatureCelsius: 0.0,
      relativeHumidityPct: 0.0,
      ambientLightRaw: 0,
      isValid: false,
      isProbeInserted: false,
      isStale: true,
      calibratedMoisturePct: 0.0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  /// Parses raw ESP32 serial or BLE string defensively.
  /// Example: "Data: moisture=3039, temp=29.7°C, humidity=75.7%, light=80"
  factory TelemetryReading.parse(
    String rawData, {
    DateTime? timestamp,
    DateTime? currentTime,
    int ttlSeconds = 300,
  }) {
    final now = currentTime ?? DateTime.now();
    final readingTime = timestamp ?? now;

    // Check Edge Case: Stale Telemetry (TTL Invalidation)
    final ageSeconds = now.difference(readingTime).inSeconds.abs();
    final isStale = ageSeconds > ttlSeconds;

    // Defensive regex extraction handling optional units, spaces, and formatting
    final moistureMatch = RegExp(r'moisture\s*=\s*([0-9]+)', caseSensitive: false).firstMatch(rawData);
    final tempMatch = RegExp(r'temp(?:erature)?\s*=\s*([0-9.]+)', caseSensitive: false).firstMatch(rawData);
    final humMatch = RegExp(r'humid(?:ity)?\s*=\s*([0-9.]+)', caseSensitive: false).firstMatch(rawData);
    final lightMatch = RegExp(r'light\s*=\s*([0-9]+)', caseSensitive: false).firstMatch(rawData);

    final rawMoisture = moistureMatch != null ? int.tryParse(moistureMatch.group(1)!) ?? 4095 : 4095;
    final temp = tempMatch != null ? double.tryParse(tempMatch.group(1)!) ?? -999.0 : -999.0;
    final hum = humMatch != null ? double.tryParse(humMatch.group(1)!) ?? -999.0 : -999.0;
    final light = lightMatch != null ? int.tryParse(lightMatch.group(1)!) ?? -1 : -1;

    // Physical sanity validation
    final isTempValid = temp >= -10.0 && temp <= 60.0;
    final isHumValid = hum >= 0.0 && hum <= 100.0;
    final isLightValid = light >= 0 && light <= 4095;

    // Probe insertion check: 12-bit ADC in soil typically 1200 (water) to 3200 (dry air)
    // Values > 3400 indicate open-air / probe ungrounded
    final isProbeInserted = rawMoisture > 400 && rawMoisture < 3400;

    double calibratedMoisture = 0.0;
    if (isProbeInserted) {
      final unrounded = (3200.0 - rawMoisture) / (3200.0 - 1200.0) * 100.0;
      calibratedMoisture = unrounded.clamp(0.0, 100.0);
    }

    final isOverallValid = isTempValid && isHumValid && isLightValid && !isStale;

    return TelemetryReading(
      rawMoistureAdc: rawMoisture,
      temperatureCelsius: temp,
      relativeHumidityPct: hum,
      ambientLightRaw: light,
      isValid: isOverallValid,
      isProbeInserted: isProbeInserted,
      isStale: isStale,
      calibratedMoisturePct: double.parse(calibratedMoisture.toStringAsFixed(2)),
      timestamp: readingTime,
      ttlSeconds: ttlSeconds,
    );
  }

  final int rawMoistureAdc;
  final double temperatureCelsius;
  final double relativeHumidityPct;
  final int ambientLightRaw;
  final bool isValid;
  final bool isProbeInserted;
  final bool isStale;
  final double calibratedMoisturePct;
  final DateTime timestamp;
  final int ttlSeconds;
}
