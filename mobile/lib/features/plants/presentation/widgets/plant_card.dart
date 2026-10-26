import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/ble/flora_wand_calibration_service.dart';
import '../../../../core/theme/agri_theme_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../domain/entities/plant_model.dart';
import 'plant_status_badge.dart';

/// Interactive card component representing a monitored crop plot.
class PlantCard extends ConsumerWidget {
  const PlantCard({
    required this.plant,
    required this.onDelete,
    super.key,
  });

  final PlantModel plant;
  final VoidCallback onDelete;

  String _formatGrowthStage(CropGrowthStage stage) {
    return switch (stage) {
      CropGrowthStage.vegetative => 'Vegetative',
      CropGrowthStage.flowering => 'Flowering',
      CropGrowthStage.fruiting => 'Fruiting',
      CropGrowthStage.harvesting => 'Harvesting',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agriColors = context.agriTheme;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final isCelsius = ref.watch(isCelsiusMetricProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? colorScheme.outlineVariant.withValues(alpha: 0.25)
              : AppColors.outlineVariant,
          width: 1,
        ),
        boxShadow: isDark
            ? const []
            : const [
                BoxShadow(
                  color: Color.fromRGBO(15, 23, 42, 0.04),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.name,
                      style: AppTypography.headlineSmall.copyWith(
                        color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plant.variety,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                onPressed: () {
                  _showActionsBottomSheet(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              PlantStatusBadge(status: plant.healthStatus),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.surfaceContainerHigh : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  _formatGrowthStage(plant.stage),
                  style: AppTypography.labelUi.copyWith(
                    color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Telemetry readings row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surfaceContainer : AppColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark
                    ? colorScheme.outlineVariant.withValues(alpha: 0.25)
                    : AppColors.outlineVariant,
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MiniTelemetryMetric(
                  label: 'Moisture',
                  value: '${plant.soilMoisturePercent.toStringAsFixed(1)}%',
                  accentColor: agriColors.moistureCyan,
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: isDark
                      ? colorScheme.outlineVariant.withValues(alpha: 0.3)
                      : AppColors.outlineVariant,
                ),
                _MiniTelemetryMetric(
                  label: 'Root Temp',
                  value: CalibratedTelemetry.formatTemp(plant.soilTemperatureCelsius, isCelsius: isCelsius),
                  accentColor: agriColors.richOchreSoil,
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: isDark
                      ? colorScheme.outlineVariant.withValues(alpha: 0.3)
                      : AppColors.outlineVariant,
                ),
                _MiniTelemetryMetric(
                  label: 'Nutrients',
                  value: 'NPK OK',
                  accentColor: agriColors.foliageMid,
                ),
              ],
            ),
          ),
          if (plant.primaryDiagnosis != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.biotech_outlined,
                  size: 15,
                  color: plant.healthStatus == PlantHealthStatus.healthy
                      ? agriColors.healthyVigor
                      : agriColors.cautionStress,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    plant.primaryDiagnosis!,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showActionsBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? colorScheme.surfaceContainerHigh : null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: isDark ? colorScheme.error : AppColors.error,
                ),
                title: Text(
                  'Remove Plot from Scouting',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? colorScheme.error : AppColors.error,
                  ),
                ),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  onDelete();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniTelemetryMetric extends StatelessWidget {
  const _MiniTelemetryMetric({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.labelUi.copyWith(
            color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.telemetrySmall.copyWith(
            color: isDark ? colorScheme.onSurface : AppColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
