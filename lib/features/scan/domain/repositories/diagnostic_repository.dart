import '../entities/diagnostic_scan_model.dart';

/// Contract defining AI leaf disease diagnostics and scan history queries.
///
/// Enables seamless substitution between [MockDiagnosticRepository] and
/// real on-device TFLite model engines.
abstract interface class DiagnosticRepository {
  /// Executes inference on a given leaf image.
  Future<DiagnosticScanResult> analyzeLeaf({
    required String imagePath,
    required String cropType,
  });

  /// Retrieves the history of recent field diagnostic scans.
  Future<List<DiagnosticScanResult>> fetchRecentScans();
}
