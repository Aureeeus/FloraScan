import 'dart:math' as math;
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
    this.hasReading = true,
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

  /// True when live physical telemetry has been acquired from the wand.
  final bool hasReading;

  /// Formatted moisture display (e.g. "64%" or "--" placeholder).
  String get formattedMoisture => hasReading ? '${soilMoisturePercent.toStringAsFixed(0)}%' : '--';

  /// Formats any Celsius temperature into either Celsius or Fahrenheit based on [isCelsius].
  static String formatTemp(double? celsius, {bool isCelsius = true}) {
    if (celsius == null) return '--';
    if (isCelsius) {
      return '${celsius.toStringAsFixed(1)}°C';
    }
    final fahrenheit = (celsius * 1.8) + 32.0;
    return '${fahrenheit.toStringAsFixed(1)}°F';
  }

  /// Formatted temperature display conforming to [isCelsius] user preference.
  String formatTemperature({bool isCelsius = true}) {
    if (!hasReading) return '--';
    return formatTemp(temperatureCelsius, isCelsius: isCelsius);
  }

  /// Formatted temperature display (defaults to Celsius for backward compatibility).
  String get formattedTemperature => formatTemperature(isCelsius: true);

  /// Formatted humidity display (e.g. "68%" or "--" placeholder).
  String get formattedHumidity => hasReading ? '${humidityPercent.toStringAsFixed(0)}%' : '--';

  /// Formatted light display (e.g. "850 Lux" or "--" placeholder).
  String get formattedLight {
    if (!hasReading) return '--';
    return lightLux >= 1000
        ? '${(lightLux / 1000).toStringAsFixed(1)}k Lux'
        : '${lightLux.toStringAsFixed(0)} Lux';
  }

  /// Returns a copy of [CalibratedTelemetry] with updated fields.
  CalibratedTelemetry copyWith({
    double? soilMoisturePercent,
    String? soilMoistureTag,
    bool? isMoistureWarning,
    double? temperatureCelsius,
    String? temperatureTag,
    bool? isTemperatureWarning,
    double? humidityPercent,
    String? humidityTag,
    bool? isHumidityWarning,
    double? lightLux,
    String? lightTag,
    bool? isLightWarning,
    int? batteryPercent,
    bool? isProbeInserted,
    DateTime? timestamp,
    bool? hasReading,
  }) {
    return CalibratedTelemetry(
      soilMoisturePercent: soilMoisturePercent ?? this.soilMoisturePercent,
      soilMoistureTag: soilMoistureTag ?? this.soilMoistureTag,
      isMoistureWarning: isMoistureWarning ?? this.isMoistureWarning,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      temperatureTag: temperatureTag ?? this.temperatureTag,
      isTemperatureWarning: isTemperatureWarning ?? this.isTemperatureWarning,
      humidityPercent: humidityPercent ?? this.humidityPercent,
      humidityTag: humidityTag ?? this.humidityTag,
      isHumidityWarning: isHumidityWarning ?? this.isHumidityWarning,
      lightLux: lightLux ?? this.lightLux,
      lightTag: lightTag ?? this.lightTag,
      isLightWarning: isLightWarning ?? this.isLightWarning,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      isProbeInserted: isProbeInserted ?? this.isProbeInserted,
      timestamp: timestamp ?? this.timestamp,
      hasReading: hasReading ?? this.hasReading,
    );
  }

  /// Factory creating placeholder offline / default unmeasured state.
  factory CalibratedTelemetry.initial({bool hasReading = false}) {
    return CalibratedTelemetry(
      soilMoisturePercent: 0.0,
      soilMoistureTag: '--',
      isMoistureWarning: false,
      temperatureCelsius: 0.0,
      temperatureTag: '--',
      isTemperatureWarning: false,
      humidityPercent: 0.0,
      humidityTag: '--',
      isHumidityWarning: false,
      lightLux: 0.0,
      lightTag: '--',
      isLightWarning: false,
      batteryPercent: 92,
      isProbeInserted: false,
      timestamp: DateTime.now(),
      hasReading: hasReading,
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
    bool isDirectLux = false,
  }) {
    final now = timestamp ?? DateTime.now();

    // 1. Soil Moisture Calibration & Open-Air Probe Grounding Check
    double moisturePercent;
    String moistureTag;
    bool moistureWarning;
    bool isProbeInserted;

    if (rawMoisture <= 100 && rawMoisture >= 0) {
      // Direct percentage transmitted by firmware (0% - 100%)
      moisturePercent = rawMoisture.toDouble();
      isProbeInserted = moisturePercent > 0.0;
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
    } else {
      // Raw 12-bit capacitive ADC counts (dry air ~3200, submerged water ~1200)
      isProbeInserted = rawMoisture > 400 && rawMoisture < openAirThresholdAdc;
      if (!isProbeInserted) {
        moisturePercent = 0.0;
        moistureTag = rawMoisture >= openAirThresholdAdc ? 'Probe in Air' : 'Sensor Fault';
        moistureWarning = true;
      } else {
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
    }

    // 2. Temperature Calibration & Bounds Checking (-10°C to 60°C)
    double temp = rawTemperature;
    if (temp > 150.0 && temp < 1000.0) {
      temp = temp / 10.0; // Scaled by 10 (e.g. 265 -> 26.5°C)
    } else if (temp >= 1000.0) {
      temp = temp / 100.0; // Scaled by 100 (e.g. 2650 -> 26.5°C)
    } else if (temp > 70.0 && temp <= 130.0) {
      // Likely Fahrenheit (e.g. 77°F -> 25°C)
      temp = (temp - 32.0) * 5.0 / 9.0;
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
    double lightLux = rawLight;
    if (!isDirectLux && rawLight <= 4095) {
      if (rawLight <= 15.0) {
        // Darkness baseline (covered sensor or night)
        lightLux = 0.0;
      } else {
        // Circuit: 3.3V -> LDR -> ADC -> 10kΩ pull-down -> GND (ESP32 12-bit ADC).
        // As light increases, LDR resistance drops, and ADC voltage climbs.
        // Conductance ratio R_fixed / R_ldr = ADC / (4095 - ADC).
        // Photoconductive power-law: Lux = A * (ratio)^(1/gamma)
        // Calibrated against hardware benchmarks:
        // - Darkness (ADC <= 15) -> 0 Lux
        // - Normal room light (ADC 200 - 350) -> ~220 - 465 Lux
        // - Direct bright sunlight (ADC 3000 - 3500) -> ~31,700 - 82,500 Lux
        final clampedAdc = rawLight.clamp(1.0, 4094.0);
        final ratio = clampedAdc / (4095.0 - clampedAdc);
        const double scaleFactor = 9000.0;
        const double exponent = 1.25; // 1 / gamma (GL5528 standard gamma ~ 0.8)
        lightLux = scaleFactor * math.pow(ratio, exponent);
      }
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
    } else if (lightLux > 2500.0) {
      lightTag = 'Bright';
      lightWarning = false;
    } else {
      lightTag = 'Normal';
      lightWarning = false;
    }

    // 5. Battery Level Calibration (0% to 100%)
    int battery;
    if (rawBattery >= 2500 && rawBattery <= 4500) {
      // Millivolts from Li-ion battery (3000mV empty to 4200mV full)
      battery = (((rawBattery - 3000) / 1200.0) * 100.0).clamp(0.0, 100.0).round();
    } else {
      battery = rawBattery.clamp(0, 100);
    }

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
