import 'package:flutter/foundation.dart';

/// Severity of detected pathological condition or abiotic stress.
enum DiagnosticSeverity {
  healthy,
  caution,
  severe,
}

/// Domain model representing optical diagnostic inference results on a leaf image.
///
/// Designed to support both local on-device TFLite models and cloud diagnostics.
@immutable
class DiagnosticScanResult {
  const DiagnosticScanResult({
    required this.scanId,
    required this.targetCrop,
    required this.detectedCondition,
    required this.scientificPathogen,
    required this.confidencePercentage,
    required this.severity,
    required this.inferenceLatencyMs,
    required this.isOfflineInference,
    required this.symptoms,
    required this.organicTreatment,
    required this.chemicalTreatment,
    required this.preventativeAction,
    required this.scannedAt,
    this.capturedImagePath,
  });

  final String scanId;
  final String targetCrop;
  final String detectedCondition;
  final String scientificPathogen;
  final double confidencePercentage;
  final DiagnosticSeverity severity;
  final int inferenceLatencyMs;
  final bool isOfflineInference;
  final List<String> symptoms;
  final String organicTreatment;
  final String chemicalTreatment;
  final String preventativeAction;
  final DateTime scannedAt;
  final String? capturedImagePath;

  DiagnosticScanResult copyWith({
    String? scanId,
    String? targetCrop,
    String? detectedCondition,
    String? scientificPathogen,
    double? confidencePercentage,
    DiagnosticSeverity? severity,
    int? inferenceLatencyMs,
    bool? isOfflineInference,
    List<String>? symptoms,
    String? organicTreatment,
    String? chemicalTreatment,
    String? preventativeAction,
    DateTime? scannedAt,
    String? capturedImagePath,
  }) {
    return DiagnosticScanResult(
      scanId: scanId ?? this.scanId,
      targetCrop: targetCrop ?? this.targetCrop,
      detectedCondition: detectedCondition ?? this.detectedCondition,
      scientificPathogen: scientificPathogen ?? this.scientificPathogen,
      confidencePercentage: confidencePercentage ?? this.confidencePercentage,
      severity: severity ?? this.severity,
      inferenceLatencyMs: inferenceLatencyMs ?? this.inferenceLatencyMs,
      isOfflineInference: isOfflineInference ?? this.isOfflineInference,
      symptoms: symptoms ?? this.symptoms,
      organicTreatment: organicTreatment ?? this.organicTreatment,
      chemicalTreatment: chemicalTreatment ?? this.chemicalTreatment,
      preventativeAction: preventativeAction ?? this.preventativeAction,
      scannedAt: scannedAt ?? this.scannedAt,
      capturedImagePath: capturedImagePath ?? this.capturedImagePath,
    );
  }
}
