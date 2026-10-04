import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/mock_telemetry_repository.dart';
import '../../domain/entities/field_telemetry_model.dart';
import '../../domain/repositories/telemetry_repository.dart';

/// Dependency injection provider for [TelemetryRepository].
final telemetryRepositoryProvider = Provider<TelemetryRepository>((ref) {
  return MockTelemetryRepository();
});

/// Reactive provider delivering live field telemetry snapshot.
final liveTelemetryProvider = FutureProvider<FieldTelemetrySnapshot>((ref) async {
  final repository = ref.watch(telemetryRepositoryProvider);
  return repository.fetchLatestTelemetry();
});
