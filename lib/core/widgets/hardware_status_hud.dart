import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/home/presentation/providers/telemetry_providers.dart';
import '../theme/agri_theme_extension.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Floating compact status HUD anchored to app headers.
///
/// Displays:
/// - Real-time BLE IoT Wand connectivity state.
/// - Wand battery percentage.
/// - Offline edge TFLite inference badge.
class HardwareStatusHud extends ConsumerWidget {
  const HardwareStatusHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetryAsync = ref.watch(liveTelemetryProvider);
    final agriColors = context.agriTheme;

    return telemetryAsync.maybeWhen(
      data: (telemetry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: AppColors.outlineVariant, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(15, 23, 42, 0.05),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // IoT Wand status dot
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: telemetry.isWandConnected
                      ? agriColors.healthyVigor
                      : agriColors.cautionStress,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                telemetry.isWandConnected ? 'BLE Wand' : 'Wand Offline',
                style: AppTypography.labelUi.copyWith(
                  color: AppColors.onSurface,
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${telemetry.wandBatteryPercent}%',
                style: AppTypography.telemetrySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 10,
                color: AppColors.outlineVariant,
              ),
              const SizedBox(width: 8),
              // Edge AI indicator
              Text(
                'TFLite Local (${telemetry.localInferenceLatencyMs}ms)',
                style: AppTypography.telemetrySmall.copyWith(
                  color: AppColors.secondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
