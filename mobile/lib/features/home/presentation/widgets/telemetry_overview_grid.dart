import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/agri_theme_extension.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../domain/entities/field_telemetry_model.dart';
import 'telemetry_card.dart';

/// 2x2 grid displaying live telemetry metrics for field operations.
class TelemetryOverviewGrid extends ConsumerWidget {
  const TelemetryOverviewGrid({
    required this.snapshot,
    super.key,
  });

  final FieldTelemetrySnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agriColors = context.agriTheme;
    final isCelsius = ref.watch(isCelsiusMetricProvider);

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.35,
      children: [
        TelemetryCard(
          title: 'Soil Moisture',
          value: snapshot.soilMoisturePercent.toStringAsFixed(1),
          unit: '% VWC',
          statusLabel: snapshot.soilMoisturePercent < 25 ? 'Low' : 'Optimal',
          accentColor: agriColors.moistureCyan,
          icon: Icons.water_drop_outlined,
        ),
        TelemetryCard(
          title: 'Soil Temp',
          value: isCelsius
              ? snapshot.soilTemperatureCelsius.toStringAsFixed(1)
              : ((snapshot.soilTemperatureCelsius * 1.8) + 32.0).toStringAsFixed(1),
          unit: isCelsius ? '°C' : '°F',
          statusLabel: 'Normal',
          accentColor: agriColors.richOchreSoil,
          icon: Icons.thermostat_outlined,
        ),
        TelemetryCard(
          title: 'Subsurface EC',
          value: snapshot.soilConductivityEc.toStringAsFixed(2),
          unit: 'dS/m',
          statusLabel: 'Balanced',
          accentColor: agriColors.ambientTeal,
          icon: Icons.bolt_outlined,
        ),
        TelemetryCard(
          title: 'Solar PAR',
          value: snapshot.solarRadiationPar.toStringAsFixed(0),
          unit: 'µmol',
          statusLabel: 'Peak Sun',
          accentColor: agriColors.solarAmber,
          icon: Icons.wb_sunny_outlined,
        ),
      ],
    );
  }
}
