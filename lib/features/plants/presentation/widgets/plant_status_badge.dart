import 'package:flutter/material.dart';
import '../../../../core/theme/agri_theme_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/plant_model.dart';

/// Semantic status badge with high-contrast indicator for outdoor sunlight legibility.
class PlantStatusBadge extends StatelessWidget {
  const PlantStatusBadge({
    required this.status,
    super.key,
  });

  final PlantHealthStatus status;

  @override
  Widget build(BuildContext context) {
    final agriColors = context.agriTheme;

    final (label, color, backgroundColor) = switch (status) {
      PlantHealthStatus.healthy => (
          'Healthy Vigor',
          agriColors.healthyVigor,
          agriColors.healthyVigor.withValues(alpha: 0.12),
        ),
      PlantHealthStatus.caution => (
          'Caution (Stress)',
          agriColors.cautionStress,
          agriColors.cautionStress.withValues(alpha: 0.12),
        ),
      PlantHealthStatus.critical => (
          'Critical (Outbreak)',
          agriColors.severeOutbreak,
          agriColors.severeOutbreak.withValues(alpha: 0.12),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.labelUi.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
