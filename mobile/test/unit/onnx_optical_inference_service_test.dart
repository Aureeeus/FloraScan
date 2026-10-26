import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:florascan_1/core/database/app_database.dart';
import 'package:florascan_1/features/scan/data/repositories/sqlite_diagnostic_repository.dart';
import 'package:florascan_1/features/scan/data/services/onnx_optical_inference_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('OnnxOpticalInferenceService & Dynamic Diagnosis Verification', () {
    late OnnxOpticalInferenceService opticalService;

    setUp(() {
      opticalService = OnnxOpticalInferenceService();
    });

    tearDown(() async {
      await opticalService.dispose();
    });

    test('OnnxOpticalInferenceService infers 20 dynamic logits on real tomato leaf', () async {
      // Arrange
      const imagePath = 'assets/pathology_reference/tomato_early_blight.jpg';
      expect(File(imagePath).existsSync(), isTrue);

      // Act
      final logits = await opticalService.inferLogits(imagePath);

      // Assert
      expect(logits.length, equals(20));
      // Top class should be index 7 (tomato_early_blight)
      var maxIdx = 0;
      var maxVal = logits[0];
      for (var i = 1; i < logits.length; i++) {
        if (logits[i] > maxVal) {
          maxVal = logits[i];
          maxIdx = i;
        }
      }
      expect(maxIdx, equals(7)); // tomato_early_blight
      expect(maxVal, greaterThan(1.5));
    });

    test('OnnxOpticalInferenceService infers dynamic logits distinct across different images', () async {
      // Arrange
      const tomatoImage = 'assets/pathology_reference/tomato_early_blight.jpg';
      const chiliImage = 'assets/pathology_reference/chili_anthracnose.jpg';

      expect(File(tomatoImage).existsSync(), isTrue);
      expect(File(chiliImage).existsSync(), isTrue);

      // Act
      final tomatoLogits = await opticalService.inferLogits(tomatoImage);
      final chiliLogits = await opticalService.inferLogits(chiliImage);

      // Assert: Verify inference produces dynamic, distinct logits per image
      expect(tomatoLogits, isNot(equals(chiliLogits)));

      // Chili top class should be index 13 (chili_anthracnose)
      var chiliMaxIdx = 0;
      var chiliMaxVal = chiliLogits[0];
      for (var i = 1; i < chiliLogits.length; i++) {
        if (chiliLogits[i] > chiliMaxVal) {
          chiliMaxVal = chiliLogits[i];
          chiliMaxIdx = i;
        }
      }
      expect(chiliMaxIdx, equals(13)); // chili_anthracnose
    });

    test('SqliteDiagnosticRepository executes dynamic diagnosis per scan on authentic images', () async {
      // Arrange
      final appDb = await AppDatabase.inMemory();
      final repository = SqliteDiagnosticRepository(
        appDb,
        opticalService: opticalService,
      );

      // Act: Scan tomato image
      final tomatoResult = await repository.analyzeLeaf(
        imagePath: 'assets/pathology_reference/tomato_early_blight.jpg',
        cropType: 'Tomato',
      );

      // Act: Scan chili image
      final chiliResult = await repository.analyzeLeaf(
        imagePath: 'assets/pathology_reference/chili_anthracnose.jpg',
        cropType: 'Red Chili',
      );

      // Assert: Dynamic diagnosis verified
      expect(tomatoResult.detectedCondition, equals('Early Blight'));
      expect(tomatoResult.scientificPathogen, equals('Alternaria solani'));
      expect(chiliResult.detectedCondition, equals('Anthracnose Fruit & Foliage Spot'));
      expect(chiliResult.scientificPathogen, equals('Colletotrichum capsici'));

      expect(tomatoResult.confidencePercentage, greaterThan(80.0));
      expect(chiliResult.confidencePercentage, greaterThan(80.0));
      expect(tomatoResult.scanId, isNot(equals(chiliResult.scanId)));

      final recent = await repository.fetchRecentScans();
      expect(recent.length, equals(2));

      await appDb.close();
    });
  });
}
