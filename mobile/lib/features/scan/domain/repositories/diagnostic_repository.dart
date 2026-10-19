import '../entities/diagnostic_scan_model.dart';
import '../entities/telemetry_reading.dart';

/// Contract defining AI leaf disease diagnostics and scan history queries.
///
/// Enables seamless substitution between [MockDiagnosticRepository] and
/// real on-device ONNX model engines.
abstract interface class DiagnosticRepository {
  /// Executes inference on a given leaf image.
  Future<DiagnosticScanResult> analyzeLeaf({
    required String imagePath,
    required String cropType,
    TelemetryReading? telemetry,
  });

  /// Retrieves the history of recent field diagnostic scans.
  Future<List<DiagnosticScanResult>> fetchRecentScans();
}
