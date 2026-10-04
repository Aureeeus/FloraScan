import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/agri_theme_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../plants/domain/entities/plant_model.dart';
import '../../../plants/presentation/providers/plant_providers.dart';

/// Card showing the distribution of plant health statuses across plots.
class CropHealthSummaryCard extends ConsumerWidget {
  const CropHealthSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantsAsync = ref.watch(plantListNotifierProvider);
    final agriColors = context.agriTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CROP HEALTH STATUS',
                style: AppTypography.labelUi.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
              InkWell(
                onTap: () => context.go(AppRoutes.plants),
                child: Text(
                  'View All Plants →',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          plantsAsync.when(
            data: (plants) {
              final healthyCount = plants
                  .where((p) => p.healthStatus == PlantHealthStatus.healthy)
                  .length;
              final cautionCount = plants
                  .where((p) => p.healthStatus == PlantHealthStatus.caution)
                  .length;
              final criticalCount = plants
                  .where((p) => p.healthStatus == PlantHealthStatus.critical)
                  .length;

              return Row(
                children: [
                  _StatusCounter(
                    label: 'Healthy',
                    count: healthyCount,
                    color: agriColors.healthyVigor,
                  ),
                  const SizedBox(width: 12),
                  _StatusCounter(
                    label: 'Caution',
                    count: cautionCount,
                    color: agriColors.cautionStress,
                  ),
                  const SizedBox(width: 12),
                  _StatusCounter(
                    label: 'Critical',
                    count: criticalCount,
                    color: agriColors.severeOutbreak,
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (err, _) => Text(
              'Unable to load crop status',
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCounter extends StatelessWidget {
  const _StatusCounter({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              count.toString(),
              style: AppTypography.telemetryLarge.copyWith(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
