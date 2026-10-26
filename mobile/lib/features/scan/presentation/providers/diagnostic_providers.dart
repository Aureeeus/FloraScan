import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../data/repositories/sqlite_diagnostic_repository.dart';
import '../../data/services/onnx_optical_inference_service.dart';
import '../../domain/entities/diagnostic_scan_model.dart';
import '../../domain/entities/telemetry_reading.dart';
import '../../domain/repositories/diagnostic_repository.dart';
import '../../domain/services/optical_inference_service.dart';

/// Dependency injection provider for [OpticalInferenceService].
final opticalInferenceServiceProvider = Provider<OpticalInferenceService>((ref) {
  final service = OnnxOpticalInferenceService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// Dependency injection provider for [DiagnosticRepository].
///
/// Injects SQLite-backed repository for optical pathology inference and offline scan logging.
final diagnosticRepositoryProvider = Provider<DiagnosticRepository>((ref) {
  final appDb = ref.watch(appDatabaseProvider);
  final opticalService = ref.watch(opticalInferenceServiceProvider);
  return SqliteDiagnosticRepository(
    appDb,
    opticalService: opticalService,
  );
});

/// Reactive provider fetching recent diagnostic scans.
final recentScansProvider = FutureProvider<List<DiagnosticScanResult>>((ref) {
  final repository = ref.watch(diagnosticRepositoryProvider);
  return repository.fetchRecentScans();
});

/// Notifier managing active image scan execution and state transitions.
class ActiveDiagnosticScanNotifier extends AsyncNotifier<DiagnosticScanResult?> {
  @override
  Future<DiagnosticScanResult?> build() async {
    return null;
  }

  /// Initiates leaf analysis for a given crop type and image path.
  Future<DiagnosticScanResult?> executeScan({
    required String imagePath,
    required String cropType,
    TelemetryReading? telemetry,
  }) async {
    state = const AsyncValue.loading();
    DiagnosticScanResult? result;

    state = await AsyncValue.guard(() async {
      final repository = ref.read(diagnosticRepositoryProvider);
      result = await repository.analyzeLeaf(
        imagePath: imagePath,
        cropType: cropType,
        telemetry: telemetry,
      );
      // Invalidate scan history so UI lists update automatically
      ref.invalidate(recentScansProvider);
      return result;
    });

    return result;
  }

  /// Clears current scan result to return to live viewfinder mode.
  void resetScan() {
    state = const AsyncValue.data(null);
  }
}

/// Provider exposing the current active leaf diagnostic scan state.
final activeDiagnosticScanNotifierProvider =
    AsyncNotifierProvider<ActiveDiagnosticScanNotifier, DiagnosticScanResult?>(
  ActiveDiagnosticScanNotifier.new,
);
