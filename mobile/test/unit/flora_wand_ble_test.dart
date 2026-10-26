import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:florascan_1/core/ble/flora_wand_ble_service.dart';
import 'package:florascan_1/core/database/app_database.dart';
import 'package:florascan_1/features/scan/domain/entities/telemetry_reading.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('FloraWandCalibrationService Agronomy Math & Status Tests', () {
    const calibrationService = FloraWandCalibrationService();

    test('Calibrates 1200 ADC to 100% moisture and detects waterlogged status', () {
      // Arrange & Act (AAA Pattern)
      final result = calibrationService.calibrate(
        rawMoisture: 1200,
        rawTemperature: 25.0,
        rawHumidity: 60.0,
        rawLight: 1000.0,
        rawBattery: 95,
      );

      // Assert
      expect(result.soilMoisturePercent, equals(100.0));
      expect(result.soilMoistureTag, equals('Waterlogged'));
      expect(result.isMoistureWarning, isTrue);
      expect(result.isProbeInserted, isTrue);
      expect(result.formattedMoisture, equals('100%'));
    });

    test('Calibrates 2200 ADC to 50% moisture with Good status', () {
      // Arrange & Act
      final result = calibrationService.calibrate(
        rawMoisture: 2200,
        rawTemperature: 24.0,
        rawHumidity: 65.0,
        rawLight: 850.0,
        rawBattery: 90,
      );

      // Assert
      expect(result.soilMoisturePercent, equals(50.0));
      expect(result.soilMoistureTag, equals('Good'));
      expect(result.isMoistureWarning, isFalse);
      expect(result.isProbeInserted, isTrue);
    });

    test('Calibrates 3200 ADC to 0% moisture with Too Dry status', () {
      // Arrange & Act
      final result = calibrationService.calibrate(
        rawMoisture: 3200,
        rawTemperature: 24.0,
        rawHumidity: 50.0,
        rawLight: 850.0,
        rawBattery: 85,
      );

      // Assert
      expect(result.soilMoisturePercent, equals(0.0));
      expect(result.soilMoistureTag, equals('Too Dry'));
      expect(result.isMoistureWarning, isTrue);
      expect(result.isProbeInserted, isTrue);
    });

    test('Detects capacitive probe ungrounded in open air when ADC > 3400', () {
      // Arrange & Act
      final result = calibrationService.calibrate(
        rawMoisture: 3850,
        rawTemperature: 26.0,
        rawHumidity: 60.0,
        rawLight: 500.0,
        rawBattery: 80,
      );

      // Assert
      expect(result.isProbeInserted, isFalse);
      expect(result.soilMoistureTag, equals('Probe in Air'));
      expect(result.soilMoisturePercent, equals(0.0));
      expect(result.isMoistureWarning, isTrue);
    });

    test('Evaluates thermal boundaries: Good, Too Hot, Too Cold', () {
      // Normal temperature
      final normal = calibrationService.calibrate(
        rawMoisture: 2200,
        rawTemperature: 26.5,
        rawHumidity: 60.0,
        rawLight: 500.0,
        rawBattery: 80,
      );
      expect(normal.temperatureTag, equals('Good'));
      expect(normal.isTemperatureWarning, isFalse);
      expect(normal.formattedTemperature, equals('26.5°C'));

      // Too Hot (> 32°C)
      final hot = calibrationService.calibrate(
        rawMoisture: 2200,
        rawTemperature: 36.2,
        rawHumidity: 60.0,
        rawLight: 500.0,
        rawBattery: 80,
      );
      expect(hot.temperatureTag, equals('Too Hot'));
      expect(hot.isTemperatureWarning, isTrue);

      // Too Cold (< 15°C)
      final cold = calibrationService.calibrate(
        rawMoisture: 2200,
        rawTemperature: 14.1,
        rawHumidity: 60.0,
        rawLight: 500.0,
        rawBattery: 80,
      );
      expect(cold.temperatureTag, equals('Chilly'));
      expect(cold.isTemperatureWarning, isTrue);
    });

    test('Evaluates relative humidity boundaries: Good, High Mold Risk, Dry Air', () {
      final highHum = calibrationService.calibrate(
        rawMoisture: 2200,
        rawTemperature: 25.0,
        rawHumidity: 88.0,
        rawLight: 500.0,
        rawBattery: 80,
      );
      expect(highHum.humidityTag, equals('High Mold Risk'));
      expect(highHum.isHumidityWarning, isTrue);

      final aridHum = calibrationService.calibrate(
        rawMoisture: 2200,
        rawTemperature: 25.0,
        rawHumidity: 25.0,
        rawLight: 500.0,
        rawBattery: 80,
      );
      expect(aridHum.humidityTag, equals('Dry Air'));
      expect(aridHum.isHumidityWarning, isTrue);
    });

    test('Evaluates illuminance formatting and tags', () {
      final directLux = calibrationService.calibrate(
        rawMoisture: 2200,
        rawTemperature: 25.0,
        rawHumidity: 60.0,
        rawLight: 42000.0,
        rawBattery: 80,
        isDirectLux: true,
      );
      expect(directLux.formattedLight, equals('42.0k Lux'));
      expect(directLux.lightTag, equals('Bright'));
      expect(directLux.isLightWarning, isFalse);

      final dark = calibrationService.calibrate(
        rawMoisture: 2200,
        rawTemperature: 25.0,
        rawHumidity: 60.0,
        rawLight: 0.0,
        rawBattery: 80,
      );
      expect(dark.lightLux, equals(0.0));
      expect(dark.formattedLight, equals('0 Lux'));
      expect(dark.lightTag, equals('Low Light'));
      expect(dark.isLightWarning, isTrue);

      final normalRoom = calibrationService.calibrate(
        rawMoisture: 2200,
        rawTemperature: 25.0,
        rawHumidity: 60.0,
        rawLight: 280.0,
        rawBattery: 80,
      );
      expect(normalRoom.lightLux, closeTo(344.0, 5.0));
      expect(normalRoom.formattedLight, equals('344 Lux'));
      expect(normalRoom.lightTag, equals('Normal'));
      expect(normalRoom.isLightWarning, isFalse);

      final directSun = calibrationService.calibrate(
        rawMoisture: 2200,
        rawTemperature: 25.0,
        rawHumidity: 60.0,
        rawLight: 3200.0,
        rawBattery: 80,
      );
      expect(directSun.lightLux, closeTo(44249.0, 500.0));
      expect(directSun.formattedLight, equals('44.2k Lux'));
      expect(directSun.lightTag, equals('Bright'));
      expect(directSun.isLightWarning, isFalse);
    });
  });

  group('FloraWand State Machine & Labels Tests', () {
    test('State machine produces intent-revealing status labels', () {
      final initial = FloraWandState(
        connectionState: FloraWandConnectionState.connected,
        telemetry: CalibratedTelemetry(
          soilMoisturePercent: 60,
          soilMoistureTag: 'Good',
          isMoistureWarning: false,
          temperatureCelsius: 24,
          temperatureTag: 'Good',
          isTemperatureWarning: false,
          humidityPercent: 65,
          humidityTag: 'Good',
          isHumidityWarning: false,
          lightLux: 1200,
          lightTag: 'Good',
          isLightWarning: false,
          batteryPercent: 92,
          isProbeInserted: true,
          timestamp: DateTime(2026, 10, 19, 12, 0),
        ),
      );

      expect(initial.isConnected, isTrue);
      expect(initial.statusLabel, equals('FloraWand Online'));
      expect(initial.deviceName, equals('FloraWand Model S1'));
      expect(initial.hardwareId, equals('#FW-8840'));

      final scanning = initial.copyWith(connectionState: FloraWandConnectionState.scanning);
      expect(scanning.statusLabel, equals('FloraWand Searching...'));

      final disconnected = initial.copyWith(connectionState: FloraWandConnectionState.disconnected);
      expect(disconnected.statusLabel, equals('FloraWand Offline'));
    });
  });

  group('FloraWand Packet Decoding & Riverpod Tests', () {
    late AppDatabase appDb;
    late ProviderContainer container;

    setUp(() async {
      appDb = await AppDatabase.inMemory();
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(appDb),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await appDb.close();
    });

    test('Decodes Option B Binary Struct (9 bytes Little-Endian)', () async {
      // Arrange:
      // Byte 0-1: uint16 rawMoisture = 2000 (0x07D0) -> (3200 - 2000)/2000 * 100 = 60.0%
      // Byte 2-3: int16  rawTemp = 285 (0x011D) -> 28.5°C
      // Byte 4-5: uint16 rawHumidity = 720 (0x02D0) -> 72.0%
      // Byte 6-7: uint16 rawLight = 4200 (0x1068) -> 4200 Lux
      // Byte 8:   uint8  battery = 88
      final byteData = ByteData(9);
      byteData.setUint16(0, 2000, Endian.little);
      byteData.setInt16(2, 285, Endian.little);
      byteData.setUint16(4, 720, Endian.little);
      byteData.setUint16(6, 4200, Endian.little);
      byteData.setUint8(8, 88);

      final rawBytes = byteData.buffer.asUint8List();

      // Act
      final notifier = container.read(floraWandNotifierProvider.notifier);
      notifier.processRawPayload(rawBytes);

      // Assert
      final state = container.read(floraWandNotifierProvider);
      expect(state.telemetry.soilMoisturePercent, equals(60.0));
      expect(state.telemetry.temperatureCelsius, equals(28.5));
      expect(state.telemetry.humidityPercent, equals(72.0));
      expect(state.telemetry.lightLux, equals(4200.0));
      expect(state.telemetry.batteryPercent, equals(88));
      expect(state.telemetry.isProbeInserted, isTrue);
    });

    test('Decodes Base64 encoded telemetry string fallback', () async {
      // Arrange
      final byteData = ByteData(9);
      byteData.setUint16(0, 1600, Endian.little); // 80% moisture
      byteData.setInt16(2, 240, Endian.little);   // 24.0°C
      byteData.setUint16(4, 650, Endian.little);  // 65.0%
      byteData.setUint16(6, 1500, Endian.little); // 1500 Lux
      byteData.setUint8(8, 94);                  // 94% battery

      final base64Str = base64Encode(byteData.buffer.asUint8List());
      final asciiBytes = utf8.encode(base64Str);

      // Act
      final notifier = container.read(floraWandNotifierProvider.notifier);
      notifier.processRawPayload(asciiBytes);

      // Assert
      final state = container.read(floraWandNotifierProvider);
      expect(state.telemetry.soilMoisturePercent, equals(80.0));
      expect(state.telemetry.temperatureCelsius, equals(24.0));
      expect(state.telemetry.humidityPercent, equals(65.0));
      expect(state.telemetry.batteryPercent, equals(94));
    });

    test('Decodes ASCII serial string fallback ("moisture=2200, temp=27.5, humidity=68.0, light=900, batt=91")', () async {
      // Arrange
      const asciiPacket = 'Data: moisture=2200, temp=27.5, humidity=68.0, light=900, batt=91';
      final asciiBytes = utf8.encode(asciiPacket);

      // Act
      final notifier = container.read(floraWandNotifierProvider.notifier);
      notifier.processRawPayload(asciiBytes);

      // Assert
      final state = container.read(floraWandNotifierProvider);
      expect(state.telemetry.soilMoisturePercent, equals(50.0));
      expect(state.telemetry.temperatureCelsius, equals(27.5));
      expect(state.telemetry.humidityPercent, equals(68.0));
      expect(state.telemetry.lightLux, closeTo(1846.0, 5.0));
      expect(state.telemetry.batteryPercent, equals(91));
    });

    test('Decodes JSON telemetry packet ({"moisture": 2200, "temp": 26.5, "humidity": 68.0, "light": 850, "battery": 92})', () async {
      // Arrange
      const jsonPacket = '{"moisture": 2200, "temp": 26.5, "humidity": 68.0, "light": 850, "battery": 92}';
      final jsonBytes = utf8.encode(jsonPacket);

      // Act
      final notifier = container.read(floraWandNotifierProvider.notifier);
      notifier.processRawPayload(jsonBytes);

      // Assert
      final state = container.read(floraWandNotifierProvider);
      expect(state.telemetry.soilMoisturePercent, equals(50.0));
      expect(state.telemetry.temperatureCelsius, equals(26.5));
      expect(state.telemetry.humidityPercent, equals(68.0));
      expect(state.telemetry.batteryPercent, equals(92));
      expect(state.telemetry.isProbeInserted, isTrue);
    });

    test('Decodes colon-delimited Key-Value telemetry string ("moisture: 2200, temp: 25.0, hum: 60.0, light: 850, batt: 90")', () async {
      // Arrange
      const kvPacket = 'moisture: 2200, temp: 25.0, hum: 60.0, light: 850, batt: 90';
      final kvBytes = utf8.encode(kvPacket);

      // Act
      final notifier = container.read(floraWandNotifierProvider.notifier);
      notifier.processRawPayload(kvBytes);

      // Assert
      final state = container.read(floraWandNotifierProvider);
      expect(state.telemetry.soilMoisturePercent, equals(50.0));
      expect(state.telemetry.temperatureCelsius, equals(25.0));
      expect(state.telemetry.humidityPercent, equals(60.0));
      expect(state.telemetry.batteryPercent, equals(90));
    });

    test('Decodes CSV telemetry string ("2200, 24.5, 62.0, 850, 93")', () async {
      // Arrange
      const csvPacket = '2200, 24.5, 62.0, 850, 93';
      final csvBytes = utf8.encode(csvPacket);

      // Act
      final notifier = container.read(floraWandNotifierProvider.notifier);
      notifier.processRawPayload(csvBytes);

      // Assert
      final state = container.read(floraWandNotifierProvider);
      expect(state.telemetry.soilMoisturePercent, equals(50.0));
      expect(state.telemetry.temperatureCelsius, equals(24.5));
      expect(state.telemetry.humidityPercent, equals(62.0));
      expect(state.telemetry.batteryPercent, equals(93));
    });

    test('Decodes IEEE-754 32-bit Float Little-Endian Binary Struct', () async {
      // Arrange (16 bytes: float32 moisture, temp, humidity, light)
      final byteData = ByteData(20);
      byteData.setFloat32(0, 2200.0, Endian.little);
      byteData.setFloat32(4, 25.5, Endian.little);
      byteData.setFloat32(8, 65.0, Endian.little);
      byteData.setFloat32(12, 1200.0, Endian.little);
      byteData.setFloat32(16, 95.0, Endian.little);

      final rawBytes = byteData.buffer.asUint8List();

      // Act
      final notifier = container.read(floraWandNotifierProvider.notifier);
      notifier.processRawPayload(rawBytes);

      // Assert
      final state = container.read(floraWandNotifierProvider);
      expect(state.telemetry.soilMoisturePercent, equals(50.0));
      expect(state.telemetry.temperatureCelsius, equals(25.5));
      expect(state.telemetry.humidityPercent, equals(65.0));
      expect(state.telemetry.batteryPercent, equals(95));
    });

    test('Converts CalibratedTelemetry to TelemetryReading seamlessly for Bayesian fusion', () {
      // Arrange
      final state = container.read(floraWandNotifierProvider);
      final calibrated = state.telemetry;

      // Act
      final reading = TelemetryReading.fromCalibrated(calibrated);

      // Assert
      expect(reading.isValid, isTrue);
      expect(reading.isStale, isFalse);
      expect(reading.isProbeInserted, equals(calibrated.isProbeInserted));
      expect(reading.calibratedMoisturePct, equals(calibrated.soilMoisturePercent));
      expect(reading.temperatureCelsius, equals(calibrated.temperatureCelsius));
      expect(reading.relativeHumidityPct, equals(calibrated.humidityPercent));
    });

    test('CalibratedTelemetry.copyWith preserves unchanged fields and overrides specified ones', () {
      // Arrange
      final original = CalibratedTelemetry(
        soilMoisturePercent: 45.0,
        temperatureCelsius: 24.0,
        humidityPercent: 62.0,
        lightLux: 750.0,
        batteryPercent: 88,
        soilMoistureTag: 'Good',
        temperatureTag: 'Good',
        humidityTag: 'Good',
        lightTag: 'Good',
        isMoistureWarning: false,
        isTemperatureWarning: false,
        isHumidityWarning: false,
        isLightWarning: false,
        isProbeInserted: true,
        timestamp: DateTime(2026, 1, 1),
      );

      // Act
      final updated = original.copyWith(batteryPercent: 99);

      // Assert
      expect(updated.batteryPercent, equals(99));
      expect(updated.soilMoisturePercent, equals(45.0));
      expect(updated.temperatureCelsius, equals(24.0));
      expect(updated.humidityPercent, equals(62.0));
      expect(updated.lightLux, equals(750.0));
      expect(updated.soilMoistureTag, equals('Good'));
      expect(updated.isProbeInserted, isTrue);
    });

    test('Partial JSON telemetry packet updates specified values while preserving existing telemetry', () {
      // Arrange: Seed initial telemetry
      const initialPacket = '{"moisture": 1800, "temp": 28.0, "humidity": 70.0, "light": 950, "battery": 90}';
      final notifier = container.read(floraWandNotifierProvider.notifier);
      notifier.processRawPayload(utf8.encode(initialPacket));

      var state = container.read(floraWandNotifierProvider);
      final initialLight = state.telemetry.lightLux;
      expect(state.telemetry.temperatureCelsius, equals(28.0));
      expect(state.telemetry.humidityPercent, equals(70.0));

      // Act: Receive partial packet with only temp and humidity
      const partialPacket = '{"temp": 29.5, "humidity": 72.0}';
      notifier.processRawPayload(utf8.encode(partialPacket));

      // Assert: moisture and light are preserved, temp and humidity updated
      state = container.read(floraWandNotifierProvider);
      expect(state.telemetry.temperatureCelsius, equals(29.5));
      expect(state.telemetry.humidityPercent, equals(72.0));
      expect(state.telemetry.lightLux, equals(initialLight));
    });
  });
}

