import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Severity of detected pathological condition or abiotic stress.
enum DiagnosticSeverity {
  healthy,
  caution,
  severe,
}

/// Domain model representing optical diagnostic inference results on a leaf image.
///
/// Designed to support both local on-device ONNX models and cloud diagnostics.
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

  /// Serializes entity to a SQLite-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'scan_id': scanId,
      'target_crop': targetCrop,
      'detected_condition': detectedCondition,
      'scientific_pathogen': scientificPathogen,
      'confidence_percentage': confidencePercentage,
      'severity': severity.name,
      'inference_latency_ms': inferenceLatencyMs,
      'is_offline_inference': isOfflineInference ? 1 : 0,
      'symptoms_json': jsonEncode(symptoms),
      'organic_treatment': organicTreatment,
      'chemical_treatment': chemicalTreatment,
      'preventative_action': preventativeAction,
      'scanned_at': scannedAt.toIso8601String(),
      'captured_image_path': capturedImagePath,
    };
  }

  /// Deserializes entity from a SQLite row map defensively.
  factory DiagnosticScanResult.fromMap(Map<String, dynamic> map) {
    List<String> parsedSymptoms = const [];
    final rawSymptoms = map['symptoms_json'] ?? map['symptoms'];
    if (rawSymptoms is String && rawSymptoms.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawSymptoms);
        if (decoded is List) {
          parsedSymptoms = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        parsedSymptoms = [rawSymptoms];
      }
    } else if (rawSymptoms is List) {
      parsedSymptoms = rawSymptoms.map((e) => e.toString()).toList();
    }

    return DiagnosticScanResult(
      scanId: map['scan_id'] as String? ?? map['scanId'] as String? ?? '',
      targetCrop: map['target_crop'] as String? ?? map['targetCrop'] as String? ?? '',
      detectedCondition: map['detected_condition'] as String? ?? map['detectedCondition'] as String? ?? '',
      scientificPathogen: map['scientific_pathogen'] as String? ?? map['scientificPathogen'] as String? ?? '',
      confidencePercentage: (map['confidence_percentage'] as num?)?.toDouble() ??
          (map['confidencePercentage'] as num?)?.toDouble() ??
          0.0,
      severity: DiagnosticSeverity.values.firstWhere(
        (e) => e.name == map['severity'],
        orElse: () => DiagnosticSeverity.healthy,
      ),
      inferenceLatencyMs: (map['inference_latency_ms'] as num?)?.toInt() ??
          (map['inferenceLatencyMs'] as num?)?.toInt() ??
          0,
      isOfflineInference: map['is_offline_inference'] == 1 ||
          map['is_offline_inference'] == true ||
          map['isOfflineInference'] == true,
      symptoms: parsedSymptoms,
      organicTreatment: map['organic_treatment'] as String? ?? map['organicTreatment'] as String? ?? '',
      chemicalTreatment: map['chemical_treatment'] as String? ?? map['chemicalTreatment'] as String? ?? '',
      preventativeAction: map['preventative_action'] as String? ?? map['preventativeAction'] as String? ?? '',
      scannedAt: DateTime.tryParse(map['scanned_at'] as String? ?? '') ?? DateTime.now(),
      capturedImagePath: map['captured_image_path'] as String? ?? map['capturedImagePath'] as String?,
    );
  }
}
