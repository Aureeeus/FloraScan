import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:florascan_1/core/theme/app_theme.dart';
import 'package:florascan_1/features/learn/presentation/learn_screen.dart';
import 'package:florascan_1/features/plants/presentation/add_plant_screen.dart';
import 'package:florascan_1/features/plants/presentation/my_plants_screen.dart';
import 'package:florascan_1/features/scan/domain/entities/diagnostic_scan_model.dart';
import 'package:florascan_1/features/scan/presentation/widgets/diagnosis_result_sheet.dart';
import 'package:florascan_1/features/settings/presentation/settings_screen.dart';

void main() {
  group('Google Stitch UI Screens Fidelity Tests', () {
    testWidgets('MyPlantsScreen renders garden banner, Sprouty mascot, and plant cards', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MyPlantsScreen(),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert (AAA Pattern)
      expect(find.text('Urban Patch #04'), findsOneWidget);
      expect(find.text('Sprouty'), findsOneWidget);
      expect(find.text('Sweet Plum Tomato'), findsOneWidget);
      expect(find.text('Russet Potato Bucket'), findsOneWidget);
      expect(find.text('Golden Bantam Corn'), findsOneWidget);
      expect(find.text('Roma Tomato'), findsOneWidget);
      expect(find.text('LIVE OPTICAL & PROBE TELEMETRY'), findsOneWidget);
    });

    testWidgets('MyPlantsScreen renders without RenderFlex overflow on narrow viewport (360x640)', (tester) async {
      // Arrange - Narrow mobile viewport constraint (360px width)
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MyPlantsScreen(),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert (AAA Pattern)
      expect(tester.takeException(), isNull);
      expect(find.text('Sweet Plum Tomato'), findsOneWidget);
      expect(find.text('Golden Bantam Corn'), findsOneWidget);
      expect(find.text('Roma Tomato'), findsOneWidget);
    });

    testWidgets('MyPlantsScreen renders without RenderFlex overflow on ultra-compact viewport (320x568)', (tester) async {
      // Arrange - Compact mobile viewport constraint (320px width)
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MyPlantsScreen(),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert (AAA Pattern)
      expect(find.text('Sweet Plum Tomato'), findsOneWidget);
      expect(find.text('Golden Bantam Corn'), findsOneWidget);
      expect(find.text('Roma Tomato'), findsOneWidget);
    });

    testWidgets('LearnScreen renders lesson hero, tabs, and story cards', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LearnScreen(),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert (AAA Pattern)
      expect(find.text('How to Take a Good Leaf Photo'), findsOneWidget);
      expect(find.text('Quick Lessons (6)'), findsOneWidget);
      expect(find.text('Problems (12)'), findsOneWidget);
      expect(find.text('A–Z Terms'), findsOneWidget);
      expect(find.text('1. Charging & Pairing Wand'), findsOneWidget);
    });

    testWidgets('SettingsScreen renders hardware wand, calibration, and edge AI', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const SettingsScreen(),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert (AAA Pattern)
      expect(find.text('App & Hardware Settings'), findsOneWidget);
      expect(find.text('FloraWand Model S1'), findsOneWidget);
      expect(find.text('Guided Probe Calibration'), findsOneWidget);
      expect(find.text('Tomato (Solanum lycopersicum)'), findsOneWidget);
      expect(find.text('Daily Soil Inspection'), findsOneWidget);
    });

    testWidgets('SettingsScreen renders without RenderFlex overflow on standard mobile (390x844)', (tester) async {
      // Arrange - iPhone 12/13/14 standard mobile viewport (390px width)
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const SettingsScreen(),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert (AAA Pattern)
      expect(tester.takeException(), isNull);
      expect(find.text('FloraWand Model S1'), findsOneWidget);
      expect(find.text('92% PWR'), findsOneWidget);
    });

    testWidgets('SettingsScreen renders without RenderFlex overflow on narrow viewport (360x640)', (tester) async {
      // Arrange - Narrow mobile viewport constraint (360px width)
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const SettingsScreen(),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert (AAA Pattern)
      expect(tester.takeException(), isNull);
      expect(find.text('FloraWand Model S1'), findsOneWidget);
      expect(find.text('92% PWR'), findsOneWidget);
    });

    testWidgets('SettingsScreen renders without RenderFlex overflow on ultra-compact viewport (320x568)', (tester) async {
      // Arrange - Ultra-compact mobile viewport constraint (320px width)
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const SettingsScreen(),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert (AAA Pattern)
      expect(tester.takeException(), isNull);
      expect(find.text('FloraWand Model S1'), findsOneWidget);
      expect(find.text('92% PWR'), findsOneWidget);
    });

    testWidgets('AddPlantScreen renders step tracker and crop profiles', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AddPlantScreen(),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert (AAA Pattern)
      expect(find.text('Add New Plant'), findsOneWidget);
      expect(find.text('Step 1 of 4'), findsOneWidget);
      expect(find.text('FloraScan Agri-Guide'), findsOneWidget);
      expect(find.text('Tomato'), findsOneWidget);
      expect(find.text('Red Chili'), findsOneWidget);
      expect(find.text('Eggplant'), findsOneWidget);
    });

    testWidgets('DiagnosisResultSheet renders Step 5 Verdict, dual problem badge, and action checklist', (tester) async {
      // Arrange
      final dummyResult = DiagnosticScanResult(
        scanId: 'scan_001',
        targetCrop: 'Sweet Plum Tomato',
        detectedCondition: 'Early Blight & Moderate Water Stress',
        scientificPathogen: 'Alternaria solani',
        confidencePercentage: 94.2,
        severity: DiagnosticSeverity.caution,
        inferenceLatencyMs: 42,
        isOfflineInference: true,
        symptoms: const ['Concentric ring lesions', 'Lower leaf yellowing', 'Curling margins'],
        organicTreatment: 'Apply organic copper fungicide spray in early morning.',
        chemicalTreatment: 'Chlorothalonil 720 SC (0.15% v/v) or Mancozeb 75 WG.',
        preventativeAction: 'Prune bottom 6 inches of foliage to avoid soil splash.',
        scannedAt: DateTime(2026, 10, 4, 10, 30),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: DiagnosisResultSheet(
                result: dummyResult,
                onDismiss: () {},
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert (AAA Pattern)
      expect(find.text('STEP 5 OF 5'), findsOneWidget);
      expect(find.text('Dual Action Required'), findsOneWidget);
      expect(find.text('BOTH: DISEASE & ENVIRONMENT PROBLEM'), findsOneWidget);
      expect(find.text('SIMPLE FIXES FIRST'), findsOneWidget);
    });
  });
}
