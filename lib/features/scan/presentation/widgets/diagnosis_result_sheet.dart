import 'package:flutter/material.dart';
import '../../../../core/theme/agri_theme_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/diagnostic_scan_model.dart';

/// Modal bottom sheet displaying detailed AI inference pathology results.
class DiagnosisResultSheet extends StatelessWidget {
  const DiagnosisResultSheet({
    required this.result,
    required this.onDismiss,
    super.key,
  });

  final DiagnosticScanResult result;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final agriColors = context.agriTheme;

    final (severityLabel, severityColor) = switch (result.severity) {
      DiagnosticSeverity.healthy => ('Healthy Canopy Vigor', agriColors.healthyVigor),
      DiagnosticSeverity.caution => ('Abiotic Stress / Early Stage', agriColors.cautionStress),
      DiagnosticSeverity.severe => ('Confirmed Pathogenic Outbreak', agriColors.severeOutbreak),
    };

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Header: Crop & Severity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${result.targetCrop.toUpperCase()} DIAGNOSTIC REPORT',
                  style: AppTypography.labelUi.copyWith(
                    color: AppColors.secondary,
                    letterSpacing: 1.1,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: severityColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    severityLabel,
                    style: AppTypography.labelUi.copyWith(
                      color: severityColor,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Disease Title & Scientific Name
            Text(
              result.detectedCondition,
              style: AppTypography.headlineLarge.copyWith(
                color: AppColors.onSurface,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              result.scientificPathogen,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 14),
            // AI Confidence & Inference Latency Metrics
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outlineVariant, width: 0.8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _DiagnosticStat(
                    label: 'AI Confidence',
                    value: '${result.confidencePercentage.toStringAsFixed(1)}%',
                    color: severityColor,
                  ),
                  Container(width: 1, height: 24, color: AppColors.outlineVariant),
                  _DiagnosticStat(
                    label: 'Inference Engine',
                    value: 'TFLite Local',
                    color: AppColors.secondary,
                  ),
                  Container(width: 1, height: 24, color: AppColors.outlineVariant),
                  _DiagnosticStat(
                    label: 'Latency',
                    value: '${result.inferenceLatencyMs}ms',
                    color: AppColors.onSurface,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Symptoms checklist
            Text(
              'OBSERVED PATHOLOGICAL SYMPTOMS',
              style: AppTypography.labelUi.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            ...result.symptoms.map(
              (symptom) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_box_outlined, size: 16, color: severityColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        symptom,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Organic Intervention
            _TreatmentCard(
              title: 'Biological / Organic Intervention',
              content: result.organicTreatment,
              icon: Icons.eco_outlined,
              color: agriColors.healthyVigor,
            ),
            const SizedBox(height: 10),
            // Chemical Intervention
            _TreatmentCard(
              title: 'Chemical / Synthetic Option',
              content: result.chemicalTreatment,
              icon: Icons.science_outlined,
              color: agriColors.richOchreSoil,
            ),
            const SizedBox(height: 10),
            // Preventative action
            _TreatmentCard(
              title: 'Preventative Cultural Practices',
              content: result.preventativeAction,
              icon: Icons.shield_outlined,
              color: agriColors.foliageMid,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onDismiss,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.onPrimary,
              ),
              child: const Text('Dismiss & Return to Viewfinder'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticStat extends StatelessWidget {
  const _DiagnosticStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.labelUi.copyWith(
            color: AppColors.onSurfaceVariant,
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.telemetrySmall.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TreatmentCard extends StatelessWidget {
  const _TreatmentCard({
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
  });

  final String title;
  final String content;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
