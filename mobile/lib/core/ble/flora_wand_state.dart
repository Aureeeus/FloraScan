import 'package:flutter/foundation.dart';
import 'flora_wand_calibration_service.dart';

/// Connection state machine for the FloraWand BLE peripheral.
enum FloraWandConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

/// Discovered Bluetooth Low Energy peripheral device metadata.
@immutable
class FloraWandDiscoveredDevice {
  const FloraWandDiscoveredDevice({
    required this.id,
    required this.name,
    required this.rssi,
  });

  final String id;
  final String name;
  final int rssi;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FloraWandDiscoveredDevice && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Immutable state container holding FloraWand BLE connection and calibrated telemetry.
@immutable
class FloraWandState {
  const FloraWandState({
    required this.connectionState,
    required this.telemetry,
    this.connectedDevice,
    this.discoveredDevices = const <FloraWandDiscoveredDevice>[],
    this.errorMessage,
    this.lastSampledAt,
    this.isSampling = false,
  });

  final FloraWandConnectionState connectionState;
  final FloraWandDiscoveredDevice? connectedDevice;
  final List<FloraWandDiscoveredDevice> discoveredDevices;
  final CalibratedTelemetry telemetry;
  final String? errorMessage;
  final DateTime? lastSampledAt;
  final bool isSampling;

  bool get isConnected => connectionState == FloraWandConnectionState.connected;
  bool get isScanning => connectionState == FloraWandConnectionState.scanning;
  bool get isConnecting => connectionState == FloraWandConnectionState.connecting;

  /// User-friendly label for current wand hardware status.
  String get statusLabel {
    switch (connectionState) {
      case FloraWandConnectionState.connected:
        return 'FloraWand Connected';
      case FloraWandConnectionState.connecting:
        return 'FloraWand Connecting...';
      case FloraWandConnectionState.scanning:
        return 'FloraWand Searching...';
      case FloraWandConnectionState.disconnected:
        return 'FloraWand Offline';
      case FloraWandConnectionState.error:
        return errorMessage ?? 'Connection Error';
    }
  }

  /// Device hardware model name for display (defaulting to FloraWand Model S1).
  String get deviceName => connectedDevice?.name.isNotEmpty == true
      ? connectedDevice!.name
      : 'FloraWand Model S1';

  /// Hardware ID or MAC address representation.
  String get hardwareId => connectedDevice != null
      ? '#FW-${connectedDevice!.id.replaceAll(':', '').takeLast(4)}'
      : '#FW-8840';

  FloraWandState copyWith({
    FloraWandConnectionState? connectionState,
    FloraWandDiscoveredDevice? connectedDevice,
    bool clearConnectedDevice = false,
    List<FloraWandDiscoveredDevice>? discoveredDevices,
    CalibratedTelemetry? telemetry,
    String? errorMessage,
    bool clearError = false,
    DateTime? lastSampledAt,
    bool? isSampling,
  }) {
    return FloraWandState(
      connectionState: connectionState ?? this.connectionState,
      connectedDevice: clearConnectedDevice ? null : (connectedDevice ?? this.connectedDevice),
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      telemetry: telemetry ?? this.telemetry,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastSampledAt: lastSampledAt ?? this.lastSampledAt,
      isSampling: isSampling ?? this.isSampling,
    );
  }

  factory FloraWandState.initial() {
    return FloraWandState(
      connectionState: FloraWandConnectionState.connected,
      telemetry: CalibratedTelemetry.initial(),
      connectedDevice: const FloraWandDiscoveredDevice(
        id: 'C4:4F:33:1B:88:40',
        name: 'FloraWand Model S1',
        rssi: -58,
      ),
      lastSampledAt: DateTime.now(),
    );
  }
}

extension _StringSlice on String {
  String takeLast(int n) {
    if (length <= n) return this;
    return substring(length - n);
  }
}
