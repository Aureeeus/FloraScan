import '../entities/field_telemetry_model.dart';

/// Contract for querying IoT wand and greenhouse telemetry streams.
abstract interface class TelemetryRepository {
  /// Fetches the latest sensor metrics snapshot.
  Future<FieldTelemetrySnapshot> fetchLatestTelemetry();

  /// Provides a stream of real-time telemetry updates.
  Stream<FieldTelemetrySnapshot> watchTelemetryStream();
}
