import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'providers/telemetry_providers.dart';
import 'widgets/crop_health_summary_card.dart';
import 'widgets/field_alerts_section.dart';
import 'widgets/home_header.dart';
import 'widgets/telemetry_overview_grid.dart';

/// Main home dashboard screen displaying live telemetry, crop health, and alerts.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetryAsync = ref.watch(liveTelemetryProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.secondary,
          onRefresh: () async {
            ref.invalidate(liveTelemetryProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HomeHeader(),
                const SizedBox(height: 20),
                telemetryAsync.when(
                  data: (telemetry) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TelemetryOverviewGrid(snapshot: telemetry),
                      const SizedBox(height: 20),
                      const CropHealthSummaryCard(),
                      const SizedBox(height: 20),
                      FieldAlertsSection(alerts: telemetry.activeAlerts),
                    ],
                  ),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'Failed to connect to field telemetry: $error',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Quick Action Bar
                ElevatedButton.icon(
                  onPressed: () => context.go(AppRoutes.scan),
                  icon: const Icon(Icons.center_focus_strong),
                  label: const Text('Start Diagnostic Optical Scan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: AppColors.onPrimary,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
