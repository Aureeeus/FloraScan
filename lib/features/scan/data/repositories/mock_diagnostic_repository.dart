import '../../domain/entities/diagnostic_scan_model.dart';
import '../../domain/repositories/diagnostic_repository.dart';

/// In-memory mock implementation of [DiagnosticRepository].
///
/// Returns scientifically accurate Solanaceae pathology diagnostics.
class MockDiagnosticRepository implements DiagnosticRepository {
  final List<DiagnosticScanResult> _history = [
    DiagnosticScanResult(
      scanId: 'diag_101',
      targetCrop: 'Tomato',
      detectedCondition: 'Early Blight',
      scientificPathogen: 'Alternaria solani',
      confidencePercentage: 94.6,
      severity: DiagnosticSeverity.severe,
      inferenceLatencyMs: 38,
      isOfflineInference: true,
      symptoms: [
        'Dark brown circular lesions with concentric target rings',
        'Chlorotic yellow halo surrounding older foliage lesions',
        'Basal canopy defoliation onset',
      ],
      organicTreatment:
          'Apply copper octanoate spray; remove and destroy lower infected leaves; apply biological Bacillus subtilis.',
      chemicalTreatment:
          'Rotate preventative chlorothalonil or azoxystrobin fungicides per label intervals.',
      preventativeAction:
          'Utilize drip irrigation to avoid leaf wetness; space plants for maximum airflow; mulch soil to halt spore splash.',
      scannedAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    DiagnosticScanResult(
      scanId: 'diag_102',
      targetCrop: 'Red Chili',
      detectedCondition: 'Anthracnose Fruit & Foliage Spot',
      scientificPathogen: 'Colletotrichum capsici',
      confidencePercentage: 88.2,
      severity: DiagnosticSeverity.caution,
      inferenceLatencyMs: 44,
      isOfflineInference: true,
      symptoms: [
        'Sunken water-soaked lesions with concentric rings of acervuli',
        'Necrotic leaf spotting under warm, humid conditions',
      ],
      organicTreatment:
          'Neem oil foliar application; sulfur dust in early morning hours.',
      chemicalTreatment:
          'Mancozeb or pyraclostrobin application during fruit development.',
      preventativeAction:
          'Use certified disease-free seeds; practice 3-year crop rotation without Solanaceae succession.',
      scannedAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    DiagnosticScanResult(
      scanId: 'diag_103',
      targetCrop: 'Eggplant',
      detectedCondition: 'Healthy Canopy Vigor',
      scientificPathogen: 'None (Optimal Physiology)',
      confidencePercentage: 98.1,
      severity: DiagnosticSeverity.healthy,
      inferenceLatencyMs: 32,
      isOfflineInference: true,
      symptoms: [
        'Uniform deep-green pigmentation',
        'No fungal sporulation, necrosis, or chlorosis detected',
      ],
      organicTreatment: 'Maintain standard foliar seaweed extract feeding.',
      chemicalTreatment: 'None required.',
      preventativeAction: 'Continue weekly scouting and moisture telemetry monitoring.',
      scannedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  Future<DiagnosticScanResult> analyzeLeaf({
    required String imagePath,
    required String cropType,
  }) async {
    // Simulate Edge AI latency
    await Future<void>.delayed(const Duration(milliseconds: 650));

    final result = DiagnosticScanResult(
      scanId: 'diag_${DateTime.now().millisecondsSinceEpoch}',
      targetCrop: cropType,
      detectedCondition: 'Early Blight',
      scientificPathogen: 'Alternaria solani',
      confidencePercentage: 93.8,
      severity: DiagnosticSeverity.severe,
      inferenceLatencyMs: 41,
      isOfflineInference: true,
      capturedImagePath: imagePath,
      symptoms: [
        'Target-board concentric rings identified on lower leaf surface',
        'Yellow perimeter chlorosis indicating fungal mycelium penetration',
      ],
      organicTreatment:
          'Spray bio-fungicide (Bacillus amyloliquefaciens); prune affected leaves with sanitized shears.',
      chemicalTreatment:
          'Difenoconazole systemic application for active lesion arrest.',
      preventativeAction:
          'Ensure dry canopy before dusk; avoid overhead sprinkler irrigation.',
      scannedAt: DateTime.now(),
    );

    _history.insert(0, result);
    return result;
  }

  @override
  Future<List<DiagnosticScanResult>> fetchRecentScans() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return List<DiagnosticScanResult>.unmodifiable(_history);
  }
}
