import 'dart:async';
import '../../domain/entities/field_telemetry_model.dart';
import '../../domain/repositories/telemetry_repository.dart';

/// In-memory mock implementation of [TelemetryRepository].
class MockTelemetryRepository implements TelemetryRepository {
  FieldTelemetrySnapshot _createSnapshot() {
    return FieldTelemetrySnapshot(
      soilMoisturePercent: 28.6,
      soilTemperatureCelsius: 22.4,
      soilConductivityEc: 1.65,
      ambientHumidityPercent: 62.0,
      solarRadiationPar: 840.0,
      isWandConnected: true,
      wandBatteryPercent: 91,
      localInferenceLatencyMs: 42,
      lastUpdated: DateTime.now(),
      activeAlerts: [
        AgronomyAlertItem(
          id: 'alert_01',
          title: 'Early Blight Detected in Plot #2',
          description:
              'Eggplant canopy exhibits 18% target necrosis. Immediate copper spray recommended.',
          isUrgent: true,
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
        AgronomyAlertItem(
          id: 'alert_02',
          title: 'Subsurface Moisture Depletion in Plot #4',
          description:
              'Chili block B soil moisture has dropped to 21% (below 25% target).',
          isUrgent: false,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ],
    );
  }

  @override
  Future<FieldTelemetrySnapshot> fetchLatestTelemetry() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return _createSnapshot();
  }

  @override
  Stream<FieldTelemetrySnapshot> watchTelemetryStream() {
    return Stream.periodic(
      const Duration(seconds: 15),
      (_) => _createSnapshot(),
    );
  }
}
