import 'package:flutter/foundation.dart';

/// Calibrated agronomic readings and human-readable interpretations for FloraWand sensors.
@immutable
class CalibratedTelemetry {
  const CalibratedTelemetry({
    required this.soilMoisturePercent,
    required this.soilMoistureTag,
    required this.isMoistureWarning,
    required this.temperatureCelsius,
    required this.temperatureTag,
    required this.isTemperatureWarning,
    required this.humidityPercent,
    required this.humidityTag,
    required this.isHumidityWarning,
    required this.lightLux,
    required this.lightTag,
    required this.isLightWarning,
    required this.batteryPercent,
    required this.isProbeInserted,
    required this.timestamp,
  });

  /// Volumetric water content percentage (0.0% to 100.0%).
  final double soilMoisturePercent;
  final String soilMoistureTag;
  final bool isMoistureWarning;

  /// Ambient soil/air temperature in degrees Celsius.
  final double temperatureCelsius;
  final String temperatureTag;
  final bool isTemperatureWarning;

  /// Relative humidity percentage (0.0% to 100.0%).
  final double humidityPercent;
  final String humidityTag;
  final bool isHumidityWarning;

  /// Solar/ambient illuminance in Lux.
  final double lightLux;
  final String lightTag;
  final bool isLightWarning;

  /// Battery level percentage (0 to 100).
  final int batteryPercent;

  /// True when the probe's capacitive blades detect grounding in soil or water.
  final bool isProbeInserted;

  /// Timestamp of telemetry acquisition.
  final DateTime timestamp;

  /// Formatted moisture display (e.g. "64%").
  String get formattedMoisture => '${soilMoisturePercent.toStringAsFixed(0)}%';

  /// Formatted temperature display (e.g. "26.4°C").
  String get formattedTemperature => '${temperatureCelsius.toStringAsFixed(1)}°C';

  /// Formatted humidity display (e.g. "68%").
  String get formattedHumidity => '${humidityPercent.toStringAsFixed(0)}%';

  /// Formatted light display (e.g. "850 Lux" or "1.2k Lux").
  String get formattedLight => lightLux >= 1000
      ? '${(lightLux / 1000).toStringAsFixed(1)}k Lux'
      : '${lightLux.toStringAsFixed(0)} Lux';

  /// Factory creating fallback offline / default readings.
  factory CalibratedTelemetry.initial() {
    return CalibratedTelemetry(
      soilMoisturePercent: 64.0,
      soilMoistureTag: 'Good',
      isMoistureWarning: false,
      temperatureCelsius: 26.4,
      temperatureTag: 'Good',
      isTemperatureWarning: false,
      humidityPercent: 68.0,
      humidityTag: 'Good',
      isHumidityWarning: false,
      lightLux: 850.0,
      lightTag: 'Normal',
      isLightWarning: false,
      batteryPercent: 92,
      isProbeInserted: true,
      timestamp: DateTime.now(),
    );
  }
}

/// Domain calibration service that transforms raw ESP32 sensor values
/// (ADC counts, raw counts, resistance curves) into human-readable agronomy units.
///
/// Adheres to SOLID Single Responsibility Principle and fail-fast boundary validation.
class FloraWandCalibrationService {
  const FloraWandCalibrationService({
    this.airDryAdc = 3200,
    this.waterSaturatedAdc = 1200,
    this.openAirThresholdAdc = 3400,
  });

  /// Calibrated ESP32 12-bit capacitive moisture probe baseline in dry air (~3200).
  final int airDryAdc;

  /// Calibrated ESP32 12-bit capacitive moisture probe baseline in pure water (~1200).
  final int waterSaturatedAdc;

  /// ADC values above this indicate the capacitive blades are in open air (not in soil).
  final int openAirThresholdAdc;

  /// Calibrates raw telemetry inputs into a verified [CalibratedTelemetry] model.
  CalibratedTelemetry calibrate({
    required int rawMoisture,
    required double rawTemperature,
    required double rawHumidity,
    required double rawLight,
    required int rawBattery,
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();

    // 1. Soil Moisture Calibration & Open-Air Probe Grounding Check
    final isProbeInserted = rawMoisture > 400 && rawMoisture < openAirThresholdAdc;
    double moisturePercent;
    String moistureTag;
    bool moistureWarning;

    if (!isProbeInserted) {
      moisturePercent = 0.0;
      moistureTag = rawMoisture >= openAirThresholdAdc ? 'Probe in Air' : 'Sensor Fault';
      moistureWarning = true;
    } else {
      // Linear interpolation between calibrated dry air and submerged water
      final span = (airDryAdc - waterSaturatedAdc).toDouble();
      final normalized = span > 0 ? (airDryAdc - rawMoisture) / span * 100.0 : 50.0;
      moisturePercent = normalized.clamp(0.0, 100.0);

      if (moisturePercent < 25.0) {
        moistureTag = 'Too Dry';
        moistureWarning = true;
      } else if (moisturePercent > 80.0) {
        moistureTag = 'Waterlogged';
        moistureWarning = true;
      } else {
        moistureTag = 'Good';
        moistureWarning = false;
      }
    }

    // 2. Temperature Calibration & Bounds Checking (-10°C to 60°C)
    // If rawTemperature is passed as scaled integer (e.g. 264 for 26.4°C), normalize it
    double temp = rawTemperature;
    if (temp > 150.0 && temp < 1000.0) {
      temp = temp / 10.0; // Scaled by 10 (e.g. 265 -> 26.5°C)
    } else if (temp >= 1000.0) {
      temp = temp / 100.0; // Scaled by 100 (e.g. 2650 -> 26.5°C)
    }
    temp = temp.clamp(-10.0, 60.0);

    String tempTag;
    bool tempWarning;
    if (temp < 15.0) {
      tempTag = 'Chilly';
      tempWarning = true;
    } else if (temp > 35.0) {
      tempTag = 'Too Hot';
      tempWarning = true;
    } else {
      tempTag = 'Good';
      tempWarning = false;
    }

    // 3. Humidity Calibration (0% to 100%)
    double humidity = rawHumidity;
    if (humidity > 100.0 && humidity < 1000.0) {
      humidity = humidity / 10.0;
    } else if (humidity >= 1000.0) {
      humidity = humidity / 100.0;
    }
    humidity = humidity.clamp(0.0, 100.0);

    String humTag;
    bool humWarning;
    if (humidity < 30.0) {
      humTag = 'Dry Air';
      humWarning = true;
    } else if (humidity > 80.0) {
      humTag = 'High Mold Risk';
      humWarning = true;
    } else {
      humTag = 'Good';
      humWarning = false;
    }

    // 4. Light / Lux Calibration
    // If rawLight is 12-bit ADC (0 - 4095), map non-linearly to approximate Lux (0 - 50,000 Lux)
    double lightLux = rawLight;
    if (rawLight <= 4095 && rawLight > 0) {
      // Typical ESP32 LDR voltage divider mapping
      final normalizedAdc = (4095 - rawLight) / 4095.0;
      lightLux = (normalizedAdc * normalizedAdc * 50000.0).clamp(0.0, 65000.0);
    }
    lightLux = lightLux.clamp(0.0, 100000.0);

    String lightTag;
    bool lightWarning;
    if (lightLux < 200.0) {
      lightTag = 'Low Light';
      lightWarning = true;
    } else if (lightLux > 45000.0) {
      lightTag = 'Intense Sun';
      lightWarning = false;
    } else if (lightLux > 600.0) {
      lightTag = 'Bright';
      lightWarning = false;
    } else {
      lightTag = 'Normal';
      lightWarning = false;
    }

    // 5. Battery Level Calibration (0% to 100%)
    final battery = rawBattery.clamp(0, 100);

    return CalibratedTelemetry(
      soilMoisturePercent: double.parse(moisturePercent.toStringAsFixed(1)),
      soilMoistureTag: moistureTag,
      isMoistureWarning: moistureWarning,
      temperatureCelsius: double.parse(temp.toStringAsFixed(1)),
      temperatureTag: tempTag,
      isTemperatureWarning: tempWarning,
      humidityPercent: double.parse(humidity.toStringAsFixed(1)),
      humidityTag: humTag,
      isHumidityWarning: humWarning,
      lightLux: double.parse(lightLux.toStringAsFixed(0)),
      lightTag: lightTag,
      isLightWarning: lightWarning,
      batteryPercent: battery,
      isProbeInserted: isProbeInserted,
      timestamp: now,
    );
  }
}
