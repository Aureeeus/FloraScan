import 'dart:math' as math;
import 'package:flutter/foundation.dart';

import '../entities/agronomic_biophysical_profile.dart';
import '../entities/telemetry_reading.dart';

/// Diagnostic outcome containing fused probabilities, differential diagnoses, and environmental telemetry notes.
@immutable
class BayesianFusedDiagnostic {
  const BayesianFusedDiagnostic({
    required this.fusedLogits,
    required this.fusedProbabilities,
    required this.topClassIndex,
    required this.topClassId,
    required this.topDisplayName,
    required this.topConfidencePct,
    required this.isDifferentialDiagnosis,
    required this.differentialClassId,
    required this.differentialDisplayName,
    required this.differentialConfidencePct,
    required this.isTemporalDiscrepancy,
    required this.temporalAdvisoryMessage,
    required this.isTelemetryApplied,
    required this.isCropMaskApplied,
    required this.calibratedTemperatureT,
    required this.environmentalLambda,
  });

  final List<double> fusedLogits;
  final List<double> fusedProbabilities;
  final int topClassIndex;
  final String topClassId;
  final String topDisplayName;
  final double topConfidencePct;

  // Differential diagnosis when margin < 20% or in ambiguity zone (45%-75%)
  final bool isDifferentialDiagnosis;
  final String? differentialClassId;
  final String? differentialDisplayName;
  final double? differentialConfidencePct;

  // Edge case 1: Historical lesion advisory
  final bool isTemporalDiscrepancy;
  final String? temporalAdvisoryMessage;

  final bool isTelemetryApplied;
  final bool isCropMaskApplied;
  final double calibratedTemperatureT;
  final double environmentalLambda;
}

/// Pure stateless domain service executing continuous Bayesian environmental log-odds fusion.
///
/// Adheres strictly to Software Engineering principles:
/// - Single Responsibility (Pure mathematical transformations)
/// - Zero external side-effects
/// - Guard clauses & early exits
/// - Continuous biophysical functions (no brittle hardcoded if/else rules)
class BayesianEnvironmentalService {
  const BayesianEnvironmentalService();

  /// Continuous Gaussian thermal viability bell curve with smooth zero-clamp.
  double computeTemperatureViability({
    required double currentTemp,
    required double optimalTemp,
    required double tempMin,
    required double tempMax,
    required double tempSigma,
  }) {
    if (currentTemp < tempMin - 2.0 || currentTemp > tempMax + 2.0) {
      return 0.01; // Lethal / dormant boundary
    }

    final exponent = -math.pow(currentTemp - optimalTemp, 2) / (2.0 * math.pow(tempSigma, 2));
    final gaussianScore = math.exp(exponent);

    if (currentTemp < tempMin) {
      final taper = math.max(0.01, (currentTemp - (tempMin - 2.0)) / 2.0);
      return gaussianScore * taper;
    } else if (currentTemp > tempMax) {
      final taper = math.max(0.01, ((tempMax + 2.0) - currentTemp) / 2.0);
      return gaussianScore * taper;
    }

    return gaussianScore.clamp(0.01, 1.0);
  }

  /// Continuous Sigmoidal moisture responsiveness.
  double computeHumidityViability({
    required double currentHumidity,
    required double minHumidity,
    required String humidityType,
  }) {
    if (humidityType == 'independent') {
      return 0.70; // Abiotic chlorosis
    }

    if (humidityType == 'high_favorable') {
      final x = currentHumidity - minHumidity;
      return 1.0 / (1.0 + math.exp(-0.15 * x));
    } else if (humidityType == 'arid_favorable') {
      final x = currentHumidity - 50.0;
      return 1.0 / (1.0 + math.exp(0.10 * x));
    } else {
      // Moderate distribution around 60%
      return math.exp(-math.pow(currentHumidity - 60.0, 2) / (2.0 * math.pow(20.0, 2)));
    }
  }

  /// Evaluates root-zone moisture permissiveness. Returns neutral (0.50) if probe not in soil.
  double computeSoilViability({
    required double calibratedMoisture,
    required double soilIdeal,
    required double soilMin,
    required double soilMax,
    required bool isProbeInserted,
  }) {
    if (!isProbeInserted) {
      return 0.50; // Neutral prior when soil sensor is ungrounded
    }

    if (calibratedMoisture < soilMin - 15.0 || calibratedMoisture > soilMax + 15.0) {
      return 0.15;
    }

    final spread = math.max(10.0, (soilMax - soilMin) / 2.0);
    final exponent = -math.pow(calibratedMoisture - soilIdeal, 2) / (2.0 * math.pow(spread, 2));
    return math.exp(exponent).clamp(0.05, 1.0);
  }

  /// Calculates continuous log-odds adjustments delta_z in [-2.0, +2.0].
  List<double> computeEnvironmentalLogOdds({
    required TelemetryReading telemetry,
    required List<AgronomicBiophysicalProfile> profiles,
  }) {
    // Graceful degradation (Stale or invalid reading -> zero distortion)
    if (!telemetry.isValid) {
      return List<double>.filled(profiles.length, 0.0);
    }

    final viabilities = List<double>.filled(profiles.length, 0.0);

    for (var i = 0; i < profiles.length; i++) {
      final p = profiles[i];

      final vTemp = computeTemperatureViability(
        currentTemp: telemetry.temperatureCelsius,
        optimalTemp: p.optimalTemp,
        tempMin: p.tempMin,
        tempMax: p.tempMax,
        tempSigma: p.tempSigma,
      );

      final vHum = computeHumidityViability(
        currentHumidity: telemetry.relativeHumidityPct,
        minHumidity: p.minHumidity,
        humidityType: p.humidityType,
      );

      final vSoil = computeSoilViability(
        calibratedMoisture: telemetry.calibratedMoisturePct,
        soilIdeal: p.soilMoistureIdeal,
        soilMin: p.soilMoistureMin,
        soilMax: p.soilMoistureMax,
        isProbeInserted: telemetry.isProbeInserted,
      );

      // Combined Permissiveness Index: 45% Thermal, 40% Atmospheric, 15% Root-zone
      final combined = (vTemp * 0.45) + (vHum * 0.40) + (vSoil * 0.15);
      viabilities[i] = combined.clamp(0.02, 0.98);
    }

    // Convert probabilities into log-odds
    const eps = 1e-4;
    final logOdds = <double>[];
    var sumLogOdds = 0.0;

    for (final v in viabilities) {
      final lo = math.log((v + eps) / (1.0 - v + eps));
      logOdds.add(lo);
      sumLogOdds += lo;
    }

    // Mean-center to prevent arbitrary global logit inflation
    final meanLogOdds = sumLogOdds / logOdds.length;
    final clampedDeltaZ = logOdds.map((lo) {
      return (lo - meanLogOdds).clamp(-2.0, 2.0);
    }).toList(growable: false);

    return clampedDeltaZ;
  }

  /// Executes crop-masked, temperature-scaled, Bayesian environmental fusion.
  BayesianFusedDiagnostic fuseWithOpticalLogits({
    required List<double> rawLogits,
    required TelemetryReading telemetry,
    required List<AgronomicBiophysicalProfile> profiles,
    double temperature = 0.5235,
    double lambdaEnv = 0.20,
    String? cropFilter,
  }) {
    if (rawLogits.length != profiles.length) {
      throw ArgumentError(
        'Mismatch between rawLogits length (${rawLogits.length}) and profiles count (${profiles.length}).',
      );
    }

    final logits = List<double>.from(rawLogits);

    // 1. Crop-Conditioned Masking (Eliminates 100% cross-crop confusion)
    var cropApplied = false;
    if (cropFilter != null && cropFilter.trim().isNotEmpty) {
      final normFilter = cropFilter.trim().toLowerCase();
      for (var i = 0; i < profiles.length; i++) {
        if (profiles[i].crop.toLowerCase() != normFilter) {
          logits[i] = -1e9;
        } else {
          cropApplied = true;
        }
      }
    }

    // 2. Temperature Scaling Calibration
    final effectiveT = math.max(temperature, 1e-4);
    final calibratedOpticalLogits = logits.map((z) => z / effectiveT).toList();

    // Baseline optical probabilities before fusion
    final optMax = calibratedOpticalLogits.reduce(math.max);
    final optExp = calibratedOpticalLogits.map((z) => math.exp(z - optMax)).toList();
    final optSumExp = optExp.reduce((a, b) => a + b);
    final opticalProbs = optExp.map((e) => e / optSumExp).toList();

    var top1OpticalIdx = 0;
    var top1OpticalConf = opticalProbs[0];
    for (var i = 1; i < opticalProbs.length; i++) {
      if (opticalProbs[i] > top1OpticalConf) {
        top1OpticalConf = opticalProbs[i];
        top1OpticalIdx = i;
      }
    }

    // 3. Dynamic Environmental Prior delta_z
    final deltaZ = computeEnvironmentalLogOdds(
      telemetry: telemetry,
      profiles: profiles,
    );

    // 4. Edge Case 1: Temporal Weather Latency Protection
    // If optical conviction is high (>= 70%) but current telemetry is dry/unfavorable,
    // attenuate the negative penalty by 60% so historical lesions are preserved.
    var temporalDiscrepancy = false;
    String? temporalMessage;
    final effectiveDeltaZ = List<double>.from(deltaZ);

    if (telemetry.isValid && top1OpticalConf >= 0.70) {
      if (effectiveDeltaZ[top1OpticalIdx] < -0.5) {
        temporalDiscrepancy = true;
        effectiveDeltaZ[top1OpticalIdx] *= 0.40;
        final profile = profiles[top1OpticalIdx];
        temporalMessage =
            'Historical foliar lesion detected: Strong visual markers for '
            '${profile.displayName} observed, but current micro-climate '
            '(${telemetry.temperatureCelsius}°C, ${telemetry.relativeHumidityPct}% RH) '
            'is temporarily unfavorable for active sporulation.';
      }
    }

    // 5. Logit Fusion: z_fused = (z_opt / T) + (lambda * delta_z)
    final fusedLogits = <double>[];
    for (var i = 0; i < calibratedOpticalLogits.length; i++) {
      fusedLogits.add(calibratedOpticalLogits[i] + (lambdaEnv * effectiveDeltaZ[i]));
    }

    // 6. Numerically stable Softmax calculation
    final maxFused = fusedLogits.reduce(math.max);
    final expFused = fusedLogits.map((z) => math.exp(z - maxFused)).toList();
    final sumExpFused = expFused.reduce((a, b) => a + b);
    final fusedProbs = expFused.map((e) => e / sumExpFused).toList();

    // 7. Extract primary and secondary (differential) diagnoses
    final indexedProbs = List.generate(fusedProbs.length, (i) => MapEntry(i, fusedProbs[i]))
      ..sort((a, b) => b.value.compareTo(a.value));

    final top1 = indexedProbs[0];
    final top2 = indexedProbs.length > 1 ? indexedProbs[1] : null;

    final top1Idx = top1.key;
    final top1Prob = top1.value;
    final top1Profile = profiles[top1Idx];

    var isDifferential = false;
    String? diffClassId;
    String? diffDisplayName;
    double? diffConfidencePct;

    if (top2 != null) {
      final margin = top1Prob - top2.value;
      // Ambiguity zone: Margin < 20% or confidence between 45% and 75%
      if (margin < 0.20 || (top1Prob >= 0.45 && top1Prob < 0.75)) {
        isDifferential = true;
        final top2Profile = profiles[top2.key];
        diffClassId = top2Profile.id;
        diffDisplayName = top2Profile.displayName;
        diffConfidencePct = double.parse((top2.value * 100.0).toStringAsFixed(1));
      }
    }

    return BayesianFusedDiagnostic(
      fusedLogits: fusedLogits,
      fusedProbabilities: fusedProbs,
      topClassIndex: top1Idx,
      topClassId: top1Profile.id,
      topDisplayName: top1Profile.displayName,
      topConfidencePct: double.parse((top1Prob * 100.0).toStringAsFixed(1)),
      isDifferentialDiagnosis: isDifferential,
      differentialClassId: diffClassId,
      differentialDisplayName: diffDisplayName,
      differentialConfidencePct: diffConfidencePct,
      isTemporalDiscrepancy: temporalDiscrepancy,
      temporalAdvisoryMessage: temporalMessage,
      isTelemetryApplied: telemetry.isValid,
      isCropMaskApplied: cropApplied,
      calibratedTemperatureT: effectiveT,
      environmentalLambda: lambdaEnv,
    );
  }
}
