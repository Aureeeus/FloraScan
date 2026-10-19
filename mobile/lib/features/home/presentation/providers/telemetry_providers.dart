import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ble/flora_wand_ble_service.dart';
import '../../../../core/database/app_database.dart';
import '../../data/repositories/local_telemetry_repository.dart';
import '../../domain/entities/field_telemetry_model.dart';
import '../../domain/repositories/telemetry_repository.dart';

/// Dependency injection provider for [TelemetryRepository].
///
/// Injects local database-backed telemetry repository.
final telemetryRepositoryProvider = Provider<TelemetryRepository>((ref) {
  final appDb = ref.watch(appDatabaseProvider);
  return LocalTelemetryRepository(appDb);
});

/// Infrequently fetched base SQLite database snapshot (on-demand/startup).
final baseTelemetrySnapshotProvider = FutureProvider<FieldTelemetrySnapshot>((ref) async {
  final repository = ref.watch(telemetryRepositoryProvider);
  return repository.fetchLatestTelemetry();
});

/// Reactive provider delivering live field telemetry snapshot merged with FloraWand BLE.
/// Evaluates synchronously in memory without blocking UI thread or querying SQLite on every BLE packet tick.
final liveTelemetryProvider = Provider<AsyncValue<FieldTelemetrySnapshot>>((ref) {
  final baseAsync = ref.watch(baseTelemetrySnapshotProvider);
  final wandState = ref.watch(floraWandNotifierProvider);

  return baseAsync.whenData((base) {
    final isConnected = wandState.isConnected;
    return FieldTelemetrySnapshot(
      soilMoisturePercent: isConnected ? wandState.telemetry.soilMoisturePercent : base.soilMoisturePercent,
      soilTemperatureCelsius: isConnected ? wandState.telemetry.temperatureCelsius : base.soilTemperatureCelsius,
      soilConductivityEc: base.soilConductivityEc,
      ambientHumidityPercent: isConnected ? wandState.telemetry.humidityPercent : base.ambientHumidityPercent,
      solarRadiationPar: isConnected ? wandState.telemetry.lightLux : base.solarRadiationPar,
      isWandConnected: isConnected,
      wandBatteryPercent: isConnected ? wandState.telemetry.batteryPercent : base.wandBatteryPercent,
      localInferenceLatencyMs: base.localInferenceLatencyMs,
      activeAlerts: [
        if (isConnected && wandState.telemetry.isMoistureWarning)
          AgronomyAlertItem(
            id: 'wand_moist_alert',
            title: 'Soil Moisture: ${wandState.telemetry.soilMoistureTag}',
            description: wandState.telemetry.soilMoisturePercent < 25.0
                ? 'Soil moisture is critically low. Root zone needs watering.'
                : 'Soil is waterlogged. Reduce irrigation to prevent root rot.',
            isUrgent: wandState.telemetry.soilMoisturePercent < 15.0,
            timestamp: wandState.telemetry.timestamp,
          )
        else
          ...base.activeAlerts,
      ],
      lastUpdated: (isConnected && wandState.lastSampledAt != null) ? wandState.lastSampledAt! : base.lastUpdated,
    );
  });
});
