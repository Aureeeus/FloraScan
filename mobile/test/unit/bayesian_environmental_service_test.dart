import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import 'package:florascan_1/features/scan/domain/entities/agronomic_biophysical_profile.dart';
import 'package:florascan_1/features/scan/domain/entities/telemetry_reading.dart';
import 'package:florascan_1/features/scan/domain/services/bayesian_environmental_service.dart';

void main() {
  late BayesianEnvironmentalService service;
  late List<AgronomicBiophysicalProfile> profiles;

  setUpAll(() {
    service = const BayesianEnvironmentalService();

    // Load SSOT agronomic profiles from assets/models/
    final file = File('assets/models/agronomic_biophysical_profiles.json');
    expect(file.existsSync(), isTrue, reason: 'SSOT agronomic profile asset must exist');
    final jsonMap = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
    final classesList = jsonMap['classes'] as List<dynamic>;
    profiles = classesList
        .map((e) => AgronomicBiophysicalProfile.fromJson(e as Map<String, dynamic>))
        .toList();
    expect(profiles.length, equals(20));
  });

  group('TelemetryReading Parser & Validation Unit Tests', () {
    test('Defensively parses live ESP32 serial string with units and spaces', () {
      // Arrange
      const rawSerial = 'Data: moisture=3039, temp=29.7°C, humidity=75.7%, light=80';

      // Act
      final reading = TelemetryReading.parse(rawSerial);

      // Assert
      expect(reading.rawMoistureAdc, equals(3039));
      expect(reading.temperatureCelsius, equals(29.7));
      expect(reading.relativeHumidityPct, equals(75.7));
      expect(reading.ambientLightRaw, equals(80));
      expect(reading.isProbeInserted, isTrue);
      expect(reading.isValid, isTrue);
      expect(reading.isStale, isFalse);
      expect(reading.calibratedMoisturePct, closeTo(8.05, 0.05));
    });

    test('Identifies open-air / ungrounded capacitive probe (ADC > 3400)', () {
      // Arrange
      const openAirSerial = 'Data: moisture=3850, temp=28.0, humidity=65.0, light=120';

      // Act
      final reading = TelemetryReading.parse(openAirSerial);

      // Assert
      expect(reading.rawMoistureAdc, equals(3850));
      expect(reading.isProbeInserted, isFalse);
      expect(reading.calibratedMoisturePct, equals(0.0));
      // Ambient temp/hum remain valid
      expect(reading.isValid, isTrue);
    });

    test('Enforces staleness TTL threshold (> 300 seconds)', () {
      // Arrange
      const serial = 'Data: moisture=2200, temp=25.0, humidity=70.0, light=200';
      final now = DateTime.now();
      final staleTimestamp = now.subtract(const Duration(seconds: 305));

      // Act
      final reading = TelemetryReading.parse(
        serial,
        timestamp: staleTimestamp,
        currentTime: now,
        ttlSeconds: 300,
      );

      // Assert
      expect(reading.isStale, isTrue);
      expect(reading.isValid, isFalse);
    });

    test('Disconnected reading produces safe ungrounded defaults', () {
      // Arrange & Act
      final disconnected = TelemetryReading.disconnected();

      // Assert
      expect(disconnected.isValid, isFalse);
      expect(disconnected.isProbeInserted, isFalse);
      expect(disconnected.isStale, isTrue);
    });
  });

  group('Bayesian Viability Mathematics Unit Tests', () {
    test('computeTemperatureViability peaks at optimal temperature', () {
      // Arrange: Tomato Early Blight (optimal 26.0°C, min 10.0, max 35.0, sigma 4.25)
      final profile = profiles.firstWhere((p) => p.id == 'tomato_early_blight');

      // Act
      final optimalScore = service.computeTemperatureViability(
        currentTemp: 26.0,
        optimalTemp: profile.optimalTemp,
        tempMin: profile.tempMin,
        tempMax: profile.tempMax,
        tempSigma: profile.tempSigma,
      );

      final warmScore = service.computeTemperatureViability(
        currentTemp: 29.7, // User hardware temperature
        optimalTemp: profile.optimalTemp,
        tempMin: profile.tempMin,
        tempMax: profile.tempMax,
        tempSigma: profile.tempSigma,
      );

      final freezingScore = service.computeTemperatureViability(
        currentTemp: 5.0,
        optimalTemp: profile.optimalTemp,
        tempMin: profile.tempMin,
        tempMax: profile.tempMax,
        tempSigma: profile.tempSigma,
      );

      // Assert
      expect(optimalScore, closeTo(1.0, 0.01));
      expect(warmScore, greaterThan(0.65));
      expect(freezingScore, equals(0.01)); // Clamped outside active bounds
    });

    test('computeHumidityViability discriminates high_favorable vs arid_favorable', () {
      // High-favorable fungal pathogen (Late Blight) at 75.7% RH
      final highScore = service.computeHumidityViability(
        currentHumidity: 75.7,
        minHumidity: 90.0,
        humidityType: 'high_favorable',
      );

      // Arid-favorable vector pathogen (TYLCV) at 75.7% RH
      final aridScore = service.computeHumidityViability(
        currentHumidity: 75.7,
        minHumidity: 30.0,
        humidityType: 'arid_favorable',
      );

      // Assert: High RH suppresses arid vectors while supporting fungi
      expect(highScore, greaterThan(0.05));
      expect(aridScore, lessThan(0.15));
    });
  });

  group('Bayesian Log-Odds & Optical Logits Fusion Tests', () {
    test('Disconnected / Stale telemetry yields zero delta_z adjustment', () {
      // Arrange
      final disconnected = TelemetryReading.disconnected();

      // Act
      final deltaZ = service.computeEnvironmentalLogOdds(
        telemetry: disconnected,
        profiles: profiles,
      );

      // Assert: Exactly zero adjustment for all classes
      expect(deltaZ.every((val) => val == 0.0), isTrue);
    });

    test('User live telemetry (29.7°C, 75.7% RH) boosts warm humid pathogens over cool late blight', () {
      // Arrange
      const rawSerial = 'Data: moisture=3039, temp=29.7°C, humidity=75.7%, light=80';
      final telemetry = TelemetryReading.parse(rawSerial);

      // Act
      final deltaZ = service.computeEnvironmentalLogOdds(
        telemetry: telemetry,
        profiles: profiles,
      );

      final earlyBlightIdx = profiles.indexWhere((p) => p.id == 'tomato_early_blight');
      final lateBlightIdx = profiles.indexWhere((p) => p.id == 'tomato_late_blight');

      // Assert: 29.7°C strongly penalizes cool Late Blight (optimal 18°C) while favoring Early Blight (26°C)
      expect(deltaZ[earlyBlightIdx], greaterThan(deltaZ[lateBlightIdx]));
      expect(deltaZ[lateBlightIdx], lessThan(0.0));
    });

    test('Crop-conditioned masking forces non-selected crop logits to -1e9', () {
      // Arrange
      final dummyLogits = List<double>.filled(20, 2.0);
      final telemetry = TelemetryReading.disconnected();

      // Act
      final result = service.fuseWithOpticalLogits(
        rawLogits: dummyLogits,
        telemetry: telemetry,
        profiles: profiles,
        cropFilter: 'Tomato',
      );

      // Assert: All non-tomato probabilities are zero
      for (var i = 0; i < profiles.length; i++) {
        if (profiles[i].crop != 'Tomato') {
          expect(result.fusedProbabilities[i], equals(0.0));
        } else {
          expect(result.fusedProbabilities[i], greaterThan(0.0));
        }
      }
      expect(result.isCropMaskApplied, isTrue);
    });

    test('Edge Case 1: Temporal weather latency preserves high-conviction optical lesions', () {
      // Arrange: Model sees Early Blight strongly (optical conf > 70%), but telemetry is freezing cold (10°C)
      const coldSerial = 'Data: moisture=3039, temp=10.0°C, humidity=40.0%, light=80';
      final coldTelemetry = TelemetryReading.parse(coldSerial);

      final earlyBlightIdx = profiles.indexWhere((p) => p.id == 'tomato_early_blight');
      final biasedLogits = List<double>.filled(20, 0.0);
      biasedLogits[earlyBlightIdx] = 4.0; // Strong optical evidence

      // Act
      final result = service.fuseWithOpticalLogits(
        rawLogits: biasedLogits,
        telemetry: coldTelemetry,
        profiles: profiles,
        cropFilter: 'Tomato',
      );

      // Assert: Weather discrepancy detected and advisory message generated
      expect(result.isTemporalDiscrepancy, isTrue);
      expect(result.temporalAdvisoryMessage, contains('Historical foliar lesion detected'));
      // Strong optical conviction still holds top prediction
      expect(result.topClassId, equals('tomato_early_blight'));
    });

    test('Detects differential diagnosis in ambiguity zone (margin < 20%)', () {
      // Arrange: Close tie between Early Blight and Septoria Leaf Spot
      final earlyBlightIdx = profiles.indexWhere((p) => p.id == 'tomato_early_blight');
      final septoriaIdx = profiles.indexWhere((p) => p.id == 'tomato_septoria_leaf_spot');

      final tieLogits = List<double>.filled(20, 0.0);
      tieLogits[earlyBlightIdx] = 2.1;
      tieLogits[septoriaIdx] = 2.0;

      // Act
      final result = service.fuseWithOpticalLogits(
        rawLogits: tieLogits,
        telemetry: TelemetryReading.disconnected(),
        profiles: profiles,
        cropFilter: 'Tomato',
      );

      // Assert: Narrow margin triggers differential diagnosis banner
      expect(result.isDifferentialDiagnosis, isTrue);
      expect(result.differentialClassId, isNotNull);
      expect(result.differentialConfidencePct, isNotNull);
    });
  });
}
