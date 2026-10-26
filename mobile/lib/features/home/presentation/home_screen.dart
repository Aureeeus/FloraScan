import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ble/flora_wand_ble_service.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/flora_scan_header.dart';
import '../../../core/widgets/sproutly_mascot.dart';
import '../../plants/domain/entities/plant_model.dart';
import '../../plants/presentation/providers/plant_providers.dart';
import '../../scan/domain/entities/diagnostic_scan_model.dart';
import '../../scan/presentation/providers/diagnostic_providers.dart';
import '../../settings/presentation/providers/settings_providers.dart';
import '../domain/entities/field_telemetry_model.dart';
import 'providers/telemetry_providers.dart';

/// Main home dashboard screen strictly dedicated to viewing real-time agronomic data.
///
/// Adheres to Clean Architecture and SRP:
/// - Strictly read-only presentation (data mutation resides exclusively in "My Plants").
/// - Reactively consumes [liveTelemetryProvider], [plantListNotifierProvider], [recentScansProvider],
///   and [floraWandNotifierProvider].
/// - Offers interactive pot switching for live probe readings and clear, high-contrast triage summaries.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _selectedPlotId;

  PlantModel? _resolveActivePlant(List<PlantModel> plants) {
    if (plants.isEmpty) return null;
    if (_selectedPlotId != null) {
      final match = plants.where((p) => p.id == _selectedPlotId).firstOrNull;
      if (match != null) return match;
    }
    return plants.first;
  }

  @override
  Widget build(BuildContext context) {
    final wandState = ref.watch(floraWandNotifierProvider);
    final telemetryAsync = ref.watch(liveTelemetryProvider);
    final plantsAsync = ref.watch(plantListNotifierProvider);
    final scansAsync = ref.watch(recentScansProvider);

    final telemetry = telemetryAsync.value;
    final plants = plantsAsync.value ?? const <PlantModel>[];
    final scans = scansAsync.value ?? const <DiagnosticScanResult>[];

    final attentionPlants = plants
        .where((p) =>
            p.healthStatus == PlantHealthStatus.caution ||
            p.healthStatus == PlantHealthStatus.critical)
        .toList();

    final activePlant = _resolveActivePlant(plants);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: const FloraScanHeader(subtitle: 'Home'),
      body: SafeArea(
        child: RefreshIndicator(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.primary
              : AppColors.primary,
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.surfaceContainerHigh
              : AppColors.surfaceContainerLowest,
          onRefresh: () async {
            await ref.read(plantListNotifierProvider.notifier).reload();
            if (context.mounted) {
              ref.invalidate(baseTelemetrySnapshotProvider);
              ref.invalidate(liveTelemetryProvider);
              ref.invalidate(recentScansProvider);
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Warm Greeting Card with Sproutly Mascot & Garden Pulse
                _buildGreetingCard(context, plants, attentionPlants),

                const SizedBox(height: 16),

                // 2. Sensor Wand Status & Live Root-Zone Telemetry with Pot Selector
                _buildTelemetryCard(context, wandState, telemetry, plants, activePlant),

                const SizedBox(height: 18),

                // 3. Plants That Need Attention (Focal Alert Stream)
                _buildAttentionSection(context, attentionPlants, hasNoPlants: plants.isEmpty),

                const SizedBox(height: 18),

                // 4. Latest Diagnosis Summary Card (Recent Scan History)
                _buildLatestDiagnosisCard(context, scans),

                const SizedBox(height: 18),

                // 5. Rotating Care Tip Featuring Sproutly
                _buildCareTipCard(context),

                const SizedBox(height: 18),

                // 6. Navigation CTA to Optical Scout
                _buildInspectBanner(context),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingCard(
    BuildContext context,
    List<PlantModel> plants,
    List<PlantModel> attentionPlants,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final String gardenPulseText;
    final Color pulseColor;
    if (plants.isEmpty) {
      gardenPulseText = 'Ready for your first plant';
      pulseColor = colorScheme.onSurfaceVariant;
    } else if (attentionPlants.isEmpty) {
      gardenPulseText = 'All ${plants.length} ${plants.length == 1 ? "crop is" : "crops are"} healthy';
      pulseColor = isDark ? colorScheme.secondary : AppColors.secondary;
    } else {
      gardenPulseText = '${attentionPlants.length} ${attentionPlants.length == 1 ? "crop needs" : "crops need"} attention';
      pulseColor = isDark ? const Color(0xFFFFB4AB) : AppColors.error;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? colorScheme.outlineVariant.withValues(alpha: 0.25) : Colors.transparent,
          width: 1,
        ),
        boxShadow: isDark
            ? const []
            : const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          SproutlyMascot(
            size: 64,
            badgeEmoji: attentionPlants.isNotEmpty ? '🩺' : '🌱',
            badgeColor: attentionPlants.isNotEmpty
                ? (isDark ? colorScheme.tertiaryContainer : AppColors.tertiaryContainer)
                : (isDark ? colorScheme.primaryContainer : AppColors.primaryContainer),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    attentionPlants.isNotEmpty
                        ? 'Sproutly says: Let\'s give some TLC to ${attentionPlants.first.name}! 🌿'
                        : 'Sproutly says: Hello! Your garden is thriving beautifully! 🌿',
                  ),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good morning!',
                  style: AppTypography.headlineSmall.copyWith(
                    color: isDark ? colorScheme.primary : AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Let's check your plants.",
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: pulseColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        gardenPulseText,
                        style: AppTypography.bodySmall.copyWith(
                          color: pulseColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryCard(
    BuildContext context,
    FloraWandState wandState,
    FieldTelemetrySnapshot? telemetry,
    List<PlantModel> plants,
    PlantModel? activePlant,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final isConnected = wandState.isConnected;

    final activePotLabel = activePlant != null
        ? 'Active Plot: ${activePlant.name}'
        : 'No registered plots';

    final hasData = isConnected && wandState.telemetry.hasReading;

    // Soil Moisture
    final String moistureCondition;
    if (!hasData) {
      moistureCondition = 'Offline';
    } else if (wandState.telemetry.soilMoistureTag == 'Good') {
      moistureCondition = 'Optimal';
    } else {
      moistureCondition = wandState.telemetry.soilMoistureTag;
    }
    final moistureVal = hasData
        ? '${wandState.telemetry.soilMoisturePercent.toStringAsFixed(0)}% moisture'
        : '--';
    final moistureProgress = hasData
        ? (wandState.telemetry.soilMoisturePercent / 100.0).clamp(0.0, 1.0)
        : 0.0;

    final isCelsius = ref.watch(isCelsiusMetricProvider);
    // Air Temperature
    final String tempCondition;
    if (!hasData) {
      tempCondition = 'Offline';
    } else if (wandState.telemetry.temperatureTag == 'Good') {
      tempCondition = 'Comfortable';
    } else {
      tempCondition = wandState.telemetry.temperatureTag;
    }
    final tempVal = wandState.telemetry.formatTemperature(isCelsius: isCelsius);
    final tempProgress = hasData
        ? (((wandState.telemetry.temperatureCelsius - 10) / 30.0)).clamp(0.0, 1.0)
        : 0.0;

    // Humidity
    final String humidityCondition;
    if (!hasData) {
      humidityCondition = 'Offline';
    } else if (wandState.telemetry.humidityTag == 'Good') {
      humidityCondition = 'Ideal Air';
    } else {
      humidityCondition = wandState.telemetry.humidityTag;
    }
    final humidityVal = hasData
        ? '${wandState.telemetry.humidityPercent.toStringAsFixed(0)}% RH'
        : '--';
    final humidityProgress = hasData
        ? (wandState.telemetry.humidityPercent / 100.0).clamp(0.0, 1.0)
        : 0.0;

    // Light
    final String lightCondition;
    if (!hasData) {
      lightCondition = 'Offline';
    } else if (wandState.telemetry.lightTag == 'Bright') {
      lightCondition = 'Bright Sun';
    } else if (wandState.telemetry.lightTag == 'Normal') {
      lightCondition = 'Moderate';
    } else {
      lightCondition = wandState.telemetry.lightTag;
    }
    final parVal = hasData
        ? (wandState.telemetry.lightLux >= 1000
            ? '${(wandState.telemetry.lightLux / 1000).toStringAsFixed(1)}k Lux'
            : '${wandState.telemetry.lightLux.toStringAsFixed(0)} Lux')
        : '--';
    final parProgress = hasData
        ? (wandState.telemetry.lightLux / 50000.0).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? colorScheme.outlineVariant.withValues(alpha: 0.25) : Colors.transparent,
          width: 1,
        ),
        boxShadow: isDark
            ? const []
            : const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Wand status and active pot name
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? colorScheme.secondaryContainer : AppColors.secondaryContainer,
                ),
                child: Icon(
                  Icons.sensors,
                  color: isDark ? colorScheme.onSecondaryContainer : AppColors.onSecondaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wandState.statusLabel,
                      style: AppTypography.headlineSmall.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      activePotLabel,
                      style: AppTypography.telemetrySmall.copyWith(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Interactive Plot Switcher Pills (If user has multiple plants)
          if (plants.length > 1) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: plants.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final plant = plants[index];
                  final isSelected = plant.id == activePlant?.id;
                  final hasWarning = plant.healthStatus != PlantHealthStatus.healthy;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedPlotId = plant.id;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? colorScheme.primary : AppColors.primary)
                            : (isDark ? colorScheme.surfaceContainerHigh : AppColors.surfaceContainerLow),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? colorScheme.primary : AppColors.primary)
                              : (isDark
                                  ? colorScheme.outlineVariant.withValues(alpha: 0.4)
                                  : AppColors.outlineVariant.withValues(alpha: 0.5)),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            plant.cropFamily.toLowerCase().contains('chili')
                                ? Icons.local_fire_department
                                : Icons.eco,
                            size: 13,
                            color: isSelected
                                ? (isDark ? colorScheme.onPrimary : AppColors.onPrimary)
                                : (isDark ? colorScheme.secondary : AppColors.secondary),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            plant.name,
                            style: AppTypography.labelUi.copyWith(
                              color: isSelected
                                  ? (isDark ? colorScheme.onPrimary : AppColors.onPrimary)
                                  : colorScheme.onSurface,
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          if (hasWarning) ...[
                            const SizedBox(width: 4),
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? const Color(0xFFFFB4AB) : AppColors.error,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 14),

          // 4 Telemetry Metrics Grid (2x2)
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.38,
            children: [
              _TelemetryMiniCard(
                icon: Icons.water_drop,
                iconColor: isDark ? colorScheme.secondary : AppColors.secondary,
                label: 'Soil Moist.',
                conditionText: moistureCondition,
                measurementText: moistureVal,
                isWarning: hasData && wandState.telemetry.isMoistureWarning,
                progressPercent: moistureProgress,
                progressColor: isDark ? colorScheme.secondary : AppColors.secondary,
              ),
              _TelemetryMiniCard(
                icon: Icons.thermostat,
                iconColor: isDark ? colorScheme.tertiary : AppColors.tertiaryContainer,
                label: 'Air Temp',
                conditionText: tempCondition,
                measurementText: tempVal,
                isWarning: hasData && wandState.telemetry.isTemperatureWarning,
                progressPercent: tempProgress,
                progressColor: isDark ? colorScheme.secondary : AppColors.secondaryFixedDim,
              ),
              _TelemetryMiniCard(
                icon: Icons.cloud,
                iconColor: isDark ? colorScheme.secondary : AppColors.secondary,
                label: 'Humidity',
                conditionText: humidityCondition,
                measurementText: humidityVal,
                isWarning: hasData && wandState.telemetry.isHumidityWarning,
                progressPercent: humidityProgress,
                progressColor: isDark ? colorScheme.secondary : AppColors.secondary,
              ),
              _TelemetryMiniCard(
                icon: Icons.wb_sunny,
                iconColor: isDark ? colorScheme.tertiary : AppColors.tertiaryFixedDim,
                label: 'Light Lux',
                conditionText: lightCondition,
                measurementText: parVal,
                isWarning: hasData && wandState.telemetry.isLightWarning,
                progressPercent: parProgress,
                progressColor: isDark ? colorScheme.tertiary : AppColors.tertiaryFixedDim,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Wand Connection & Telemetry Action CTA
          if (!isConnected)
            FilledButton.icon(
              onPressed: wandState.isScanning
                  ? null
                  : () async {
                      await ref.read(floraWandNotifierProvider.notifier).startScan();
                    },
              icon: wandState.isScanning
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark ? colorScheme.onPrimary : AppColors.onPrimary,
                      ),
                    )
                  : const Icon(Icons.bluetooth_searching, size: 18),
              label: Text(
                wandState.isScanning ? 'Searching for FloraWand...' : 'Connect FloraWand',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                backgroundColor: isDark ? colorScheme.secondary : AppColors.secondaryFixed,
                foregroundColor: isDark ? const Color(0xFF002114) : AppColors.onSecondaryFixed,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: AppTypography.labelUi.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: () async {
                if (plants.length > 1) {
                  final currentIndex = plants.indexWhere((p) => p.id == activePlant?.id);
                  final nextIndex = (currentIndex + 1) % plants.length;
                  setState(() {
                    _selectedPlotId = plants[nextIndex].id;
                  });
                }
                await ref.read(floraWandNotifierProvider.notifier).triggerSample();
                if (context.mounted) {
                  final potName = activePlant?.name ?? 'selected plot';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Probe active. Viewing live root-zone telemetry for $potName.'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.sync, size: 18),
              label: const Text('Read Another Pot'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                backgroundColor: isDark ? colorScheme.surfaceContainerHigh : AppColors.surfaceContainerHigh,
                foregroundColor: colorScheme.onSurface,
                side: BorderSide(
                  color: isDark ? colorScheme.outlineVariant.withValues(alpha: 0.3) : Colors.transparent,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttentionSection(
    BuildContext context,
    List<PlantModel> attentionPlants, {
    required bool hasNoPlants,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Plants That Need Attention',
                style: AppTypography.headlineSmall.copyWith(
                  color: isDark ? colorScheme.primary : AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${attentionPlants.length} Tracked',
              style: AppTypography.telemetrySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (hasNoPlants)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? colorScheme.outlineVariant.withValues(alpha: 0.25) : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.yard_outlined, color: isDark ? colorScheme.secondary : AppColors.secondary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No Plants Added Yet',
                        style: AppTypography.headlineSmall.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your garden is waiting. Head over to My Plants to register your first plant!',
                        style: AppTypography.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else if (attentionPlants.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? colorScheme.outlineVariant.withValues(alpha: 0.25) : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: isDark ? colorScheme.secondary : AppColors.secondary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Monitored Crops Healthy!',
                        style: AppTypography.headlineSmall.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'All registered plots are operating within nominal agronomic thresholds.',
                        style: AppTypography.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          for (int i = 0; i < attentionPlants.length; i++) ...[
            _buildPlantAttentionCard(context, attentionPlants[i]),
            if (i < attentionPlants.length - 1) const SizedBox(height: 10),
          ],
      ],
    );
  }

  Widget _buildPlantAttentionCard(BuildContext context, PlantModel plant) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final isCritical = plant.healthStatus == PlantHealthStatus.critical;
    const tagLabel = 'Needs Care';
    final diagnosis = plant.primaryDiagnosis ??
        (plant.notes.isNotEmpty ? plant.notes : 'Canopy inspection recommended');

    final pillBg = isCritical
        ? (isDark ? colorScheme.errorContainer : AppColors.errorContainer)
        : (isDark ? colorScheme.tertiaryContainer : AppColors.tertiaryFixed);
    final pillFg = isCritical
        ? (isDark ? colorScheme.onErrorContainer : AppColors.onErrorContainer)
        : (isDark ? colorScheme.onTertiaryContainer : AppColors.onTertiaryFixed);
    final dotColor = isCritical
        ? (isDark ? const Color(0xFFFFB4AB) : AppColors.error)
        : (isDark ? colorScheme.tertiary : AppColors.tertiary);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? colorScheme.outlineVariant.withValues(alpha: 0.25) : Colors.transparent,
        ),
        boxShadow: isDark
            ? const []
            : const [
                BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
              ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.name,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        letterSpacing: -0.2,
                      ),
                      softWrap: true,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${plant.variety} • Soil ${plant.soilMoisturePercent.toStringAsFixed(0)}%',
                      style: AppTypography.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      softWrap: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: isDark ? pillFg.withValues(alpha: 0.3) : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tagLabel,
                      style: AppTypography.labelUi.copyWith(
                        color: pillFg,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surfaceContainer : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? colorScheme.outlineVariant.withValues(alpha: 0.15) : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: isCritical
                      ? (isDark ? const Color(0xFFFFB4AB) : AppColors.error)
                      : (isDark ? colorScheme.tertiary : AppColors.tertiary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    diagnosis,
                    style: AppTypography.bodySmall.copyWith(
                      color: colorScheme.onSurface,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () => context.go(AppRoutes.scan),
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('Check Now'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              backgroundColor: isDark ? colorScheme.primary : AppColors.primaryContainer,
              foregroundColor: isDark ? colorScheme.onPrimary : AppColors.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestDiagnosisCard(
    BuildContext context,
    List<DiagnosticScanResult> scans,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (scans.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? colorScheme.outlineVariant.withValues(alpha: 0.25) : Colors.transparent,
          ),
          boxShadow: isDark
              ? const []
              : const [
                  BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 2)),
                ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.biotech, color: isDark ? colorScheme.secondary : AppColors.secondary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Latest Diagnosis',
                    style: AppTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Icon(Icons.qr_code_scanner, size: 36, color: isDark ? colorScheme.secondary : AppColors.secondary),
            const SizedBox(height: 8),
            Text(
              'No Diagnostic Scans Yet',
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Capture or upload a leaf photo to get real-time offline AI diagnosis.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.go(AppRoutes.scan),
              icon: const Icon(Icons.camera_alt, size: 16),
              label: const Text('Start First Scan'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                backgroundColor: isDark ? colorScheme.surfaceContainerHigh : AppColors.surfaceContainerHigh,
                foregroundColor: isDark ? colorScheme.primary : AppColors.primary,
                side: BorderSide(
                  color: isDark ? colorScheme.outlineVariant.withValues(alpha: 0.3) : Colors.transparent,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    }

    final latest = scans.first;
    final condition = latest.detectedCondition;
    final crop = latest.targetCrop;
    final pathogen = latest.scientificPathogen;
    final confidence = '${latest.confidencePercentage.toStringAsFixed(0)}%';
    final symptoms = latest.symptoms.isNotEmpty
        ? latest.symptoms.first
        : 'Fungal leaf spots detected, but your soil moisture and humidity are optimal.';
    final action = latest.organicTreatment.isNotEmpty
        ? latest.organicTreatment
        : 'Snip affected bottom leaves & spray baking soda solution.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? colorScheme.outlineVariant.withValues(alpha: 0.25) : Colors.transparent,
        ),
        boxShadow: isDark
            ? const []
            : const [
                BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 2)),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.biotech,
                      color: isDark ? const Color(0xFFFFB4AB) : AppColors.error,
                      size: 22,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Latest Diagnosis',
                        style: AppTypography.headlineSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? colorScheme.errorContainer : AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: isDark ? colorScheme.onErrorContainer.withValues(alpha: 0.3) : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        'DISEASE',
                        style: AppTypography.labelUi.copyWith(
                          color: isDark ? colorScheme.onErrorContainer : AppColors.onErrorContainer,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? colorScheme.surfaceContainerHigh : AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: isDark ? colorScheme.outlineVariant.withValues(alpha: 0.3) : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        '$confidence Conf.',
                        style: AppTypography.telemetrySmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surfaceContainer : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? colorScheme.outlineVariant.withValues(alpha: 0.15) : Colors.transparent,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crop: $crop ($pathogen)',
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  condition,
                  style: AppTypography.telemetrySmall.copyWith(
                    color: isDark ? const Color(0xFFFFB4AB) : AppColors.error,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  symptoms,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.tertiaryContainer : AppColors.tertiaryFixed,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? colorScheme.tertiary.withValues(alpha: 0.3) : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.content_cut,
                  color: isDark ? colorScheme.tertiary : AppColors.tertiary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'IMMEDIATE ACTION',
                        style: AppTypography.labelUi.copyWith(
                          fontSize: 9,
                          letterSpacing: 0.8,
                          color: (isDark ? colorScheme.onTertiaryContainer : AppColors.onTertiaryFixed)
                              .withValues(alpha: 0.8),
                        ),
                      ),
                      Text(
                        action,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? colorScheme.onTertiaryContainer : AppColors.onTertiaryFixed,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => context.go(AppRoutes.scan),
            icon: const Icon(Icons.medical_services, size: 16),
            label: const Text('View Full Advice & Recipe'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              backgroundColor: isDark ? colorScheme.surfaceContainerHigh : AppColors.surfaceContainerHigh,
              foregroundColor: isDark ? colorScheme.primary : AppColors.primary,
              side: BorderSide(
                color: isDark ? colorScheme.outlineVariant.withValues(alpha: 0.3) : Colors.transparent,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareTipCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? colorScheme.outlineVariant.withValues(alpha: 0.25) : Colors.transparent,
        ),
        boxShadow: isDark
            ? const []
            : const [
                BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
              ],
      ),
      child: Row(
        children: [
          SproutlyMascot(
            size: 48,
            badgeEmoji: '💡',
            badgeColor: isDark ? colorScheme.tertiaryContainer : AppColors.tertiaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QUICK GARDENING TIP',
                  style: AppTypography.labelUi.copyWith(
                    color: isDark ? colorScheme.secondary : AppColors.secondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Water in the early morning at the soil base, not over the leaves, to prevent fungal mold!',
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.onSurface,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectBanner(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () => context.go(AppRoutes.scan),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.primaryContainer : AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? colorScheme.primary.withValues(alpha: 0.3) : Colors.transparent,
            width: 1,
          ),
          boxShadow: isDark
              ? const []
              : const [
                  BoxShadow(color: Color(0x22012D1D), blurRadius: 10, offset: Offset(0, 3)),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? colorScheme.primary.withValues(alpha: 0.2) : AppColors.secondaryFixed,
              ),
              child: Icon(
                Icons.center_focus_strong,
                color: isDark ? colorScheme.primary : AppColors.onSecondaryFixedVariant,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ready to Inspect?',
                    style: AppTypography.headlineSmall.copyWith(
                      color: isDark ? colorScheme.onSurface : AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'Tap to test a leaf with your camera & wand.',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? colorScheme.onPrimaryContainer : AppColors.onPrimaryContainer,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isDark ? colorScheme.primary : AppColors.onPrimaryContainer,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _TelemetryMiniCard extends StatelessWidget {
  const _TelemetryMiniCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.conditionText,
    required this.measurementText,
    required this.progressPercent,
    required this.progressColor,
    this.isWarning = false,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String conditionText;
  final String measurementText;
  final double progressPercent;
  final Color progressColor;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainer : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? colorScheme.outlineVariant.withValues(alpha: 0.2) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Header: Icon + Sensor Label (Clean, zero pill clutter)
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // 2. Middle Block: Hero Condition Text + Tabular Quantitative Measurement
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                conditionText,
                style: AppTypography.headlineSmall.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isWarning
                      ? (isDark ? const Color(0xFFFFB4AB) : AppColors.error)
                      : colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                measurementText,
                style: AppTypography.telemetrySmall.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),

          // 3. Bottom: Concentric 4px Progress Indicator
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(
              value: progressPercent,
              minHeight: 4,
              backgroundColor: isDark
                  ? colorScheme.surfaceContainerHighest
                  : AppColors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }
}
