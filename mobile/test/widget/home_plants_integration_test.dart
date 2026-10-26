import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:florascan_1/core/database/app_database.dart';
import 'package:florascan_1/core/theme/app_theme.dart';
import 'package:florascan_1/features/home/presentation/home_screen.dart';
import 'package:florascan_1/features/plants/data/repositories/sqlite_diagnostic_task_repository.dart';
import 'package:florascan_1/features/plants/data/repositories/sqlite_plant_repository.dart';
import 'package:florascan_1/features/plants/domain/entities/plant_model.dart';
import 'package:florascan_1/features/plants/presentation/my_plants_screen.dart';
import 'package:florascan_1/features/plants/presentation/providers/diagnostic_task_providers.dart';
import 'package:florascan_1/features/plants/presentation/providers/plant_providers.dart';
import 'package:florascan_1/features/scan/domain/entities/diagnostic_scan_model.dart';
import 'package:florascan_1/features/scan/presentation/widgets/diagnosis_result_sheet.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Home Screen & My Plants Screen Architecture & CRUD Integration Tests', () {
    late AppDatabase testDb;
    late SqlitePlantRepository testRepo;
    late SqliteDiagnosticTaskRepository testTaskRepo;

    setUp(() async {
      testDb = await AppDatabase.inMemory();
      testRepo = SqlitePlantRepository(testDb);
      testTaskRepo = SqliteDiagnosticTaskRepository(testDb);
    });

    tearDown(() {
      testDb.close().ignore();
    });

    testWidgets('Home tab is strictly read-only for viewing telemetry and plant alerts', (tester) async {
      // Arrange: Render HomeScreen within ProviderScope
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(testDb),
            plantRepositoryProvider.overrideWithValue(testRepo),
            diagnosticTaskRepositoryProvider.overrideWithValue(testTaskRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Allow background SQLite FFI isolate tasks to complete cleanly
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      // Assert (AAA Pattern adhering to /Software Engineer):
      // Home screen is for viewing data only.
      expect(find.text('FloraScan'), findsOneWidget);
      expect(find.text('Plants That Need Attention'), findsOneWidget);
      expect(find.text('Latest Diagnosis'), findsOneWidget);

      // Verify that Home tab has ZERO add/create/edit/delete interactive controls
      expect(find.widgetWithText(ElevatedButton, 'Add Plant'), findsNothing);
      expect(find.widgetWithIcon(IconButton, Icons.delete), findsNothing);
      expect(find.widgetWithIcon(IconButton, Icons.edit), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
    });

    testWidgets('My Plants screen handles all CRUD operations and updates state dynamically', (tester) async {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(testDb),
          plantRepositoryProvider.overrideWithValue(testRepo),
          diagnosticTaskRepositoryProvider.overrideWithValue(testTaskRepo),
        ],
      );
      addTearDown(container.dispose);

      // Arrange: Render MyPlantsScreen
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MyPlantsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: Empty garden state on clean boot
      expect(find.text('Your Garden is Empty'), findsOneWidget);
      expect(find.text('Add Plant'), findsOneWidget);

      // Act: Add a new custom crop plot via plantListNotifierProvider
      final customPlot = PlantModel(
        id: 'plot_custom_999',
        name: 'Heirloom Bell Pepper',
        cropFamily: 'Solanaceae',
        variety: 'Capsicum annuum',
        stage: CropGrowthStage.flowering,
        healthStatus: PlantHealthStatus.caution,
        soilMoisturePercent: 35.0,
        soilTemperatureCelsius: 22.5,
        npkSummary: 'N:150 P:50 K:180 ppm',
        lastScannedAt: DateTime.now(),
        primaryDiagnosis: 'Healthy foliage',
        notes: 'Balcony 1 container pot.',
      );

      await tester.runAsync(() async {
        await container.read(plantListNotifierProvider.notifier).addPlant(customPlot);
      });
      await tester.pumpAndSettle();

      // Assert: New custom crop is rendered in MyPlantsScreen and empty state is gone
      expect(find.text('Heirloom Bell Pepper'), findsOneWidget);
      expect(find.text('Your Garden is Empty'), findsNothing);

      // Act: Delete the plant
      await tester.runAsync(() async {
        await container.read(plantListNotifierProvider.notifier).removePlant('plot_custom_999');
      });
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      // Assert: Deleted crop is gone and garden returns to empty state
      expect(find.text('Heirloom Bell Pepper'), findsNothing);
      expect(find.text('Your Garden is Empty'), findsOneWidget);
    });

    testWidgets('Modifications in My Plants screen dynamically reflect on Home screen alerts', (tester) async {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(testDb),
          plantRepositoryProvider.overrideWithValue(testRepo),
          diagnosticTaskRepositoryProvider.overrideWithValue(testTaskRepo),
        ],
      );
      addTearDown(container.dispose);

      // Arrange: Render HomeScreen
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: Initially empty garden shows no plants added
      expect(find.text('No Plants Added Yet'), findsOneWidget);

      // Act: Add an attention-needing plant
      final criticalEggplant = PlantModel(
        id: 'crop_03',
        name: 'Black Beauty Eggplant',
        cropFamily: 'Solanaceae',
        variety: 'Solanum melongena',
        stage: CropGrowthStage.vegetative,
        healthStatus: PlantHealthStatus.critical,
        soilMoisturePercent: 18.2,
        soilTemperatureCelsius: 23.1,
        npkSummary: 'N:140 P:55 K:190 ppm',
        lastScannedAt: DateTime.now(),
        primaryDiagnosis: 'Early Blight',
        notes: 'Indoor Patio Pot',
      );

      await tester.runAsync(() async {
        await container.read(plantListNotifierProvider.notifier).addPlant(criticalEggplant);
      });
      await tester.pumpAndSettle();

      // Assert: "Black Beauty Eggplant" is now under "Plants That Need Attention"
      expect(find.text('Black Beauty Eggplant'), findsOneWidget);

      // Act: Update Black Beauty Eggplant to healthy via My Plants notifier
      await tester.runAsync(() async {
        final healedEggplant = criticalEggplant.copyWith(
          healthStatus: PlantHealthStatus.healthy,
          primaryDiagnosis: 'Fully Recovered - Vigor restored',
        );
        await container.read(plantListNotifierProvider.notifier).addPlant(healedEggplant);
      });
      await tester.pumpAndSettle();

      // Assert: Black Beauty Eggplant is no longer under "Plants That Need Attention"
      expect(find.text('All Monitored Crops Healthy!'), findsOneWidget);
    });

    testWidgets('My Plants "View Sensor Data" action glides view to telemetry section and selects plant', (tester) async {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(testDb),
          plantRepositoryProvider.overrideWithValue(testRepo),
          diagnosticTaskRepositoryProvider.overrideWithValue(testTaskRepo),
        ],
      );
      addTearDown(container.dispose);

      final healthyTomato = PlantModel(
        id: 'crop_01',
        name: 'Sweet Plum Tomato',
        cropFamily: 'Solanaceae',
        variety: 'Solanum lycopersicum',
        stage: CropGrowthStage.flowering,
        healthStatus: PlantHealthStatus.healthy,
        soilMoisturePercent: 32.4,
        soilTemperatureCelsius: 21.8,
        npkSummary: 'Balanced',
        lastScannedAt: DateTime.now(),
        primaryDiagnosis: 'Optimal Vigor',
      );

      final healthyChili = PlantModel(
        id: 'crop_02',
        name: 'Red Habanero Chili',
        cropFamily: 'Solanaceae',
        variety: 'Capsicum chinense',
        stage: CropGrowthStage.fruiting,
        healthStatus: PlantHealthStatus.healthy,
        soilMoisturePercent: 28.0,
        soilTemperatureCelsius: 23.5,
        npkSummary: 'Balanced',
        lastScannedAt: DateTime.now(),
        primaryDiagnosis: 'Healthy foliage',
      );

      await tester.runAsync(() async {
        await container.read(plantListNotifierProvider.notifier).addPlant(healthyTomato);
        await container.read(plantListNotifierProvider.notifier).addPlant(healthyChili);
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MyPlantsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sweet Plum Tomato'), findsWidgets);
      expect(find.text('Red Habanero Chili'), findsWidgets);
      expect(find.text('Plant Details'), findsNWidgets(2));

      // Act: Tap "Plant Details" for Red Habanero Chili
      await tester.ensureVisible(find.text('Plant Details').last);
      await tester.tap(find.text('Plant Details').last);
      await tester.pump();
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();

      // Assert: Crop profile section displays Red Habanero Chili
      expect(find.text('Active Crop Profile'), findsOneWidget);
      expect(find.text('Red Habanero Chili (Capsicum chinense)'), findsOneWidget);
    });

    testWidgets('Scan-to-plant diagnosis workflow: User selects plant via search & category filter and updates SQLite diagnostics', (tester) async {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(testDb),
          plantRepositoryProvider.overrideWithValue(testRepo),
          diagnosticTaskRepositoryProvider.overrideWithValue(testTaskRepo),
        ],
      );
      addTearDown(container.dispose);

      final tomato = PlantModel(
        id: 'plant_tomato_1',
        name: 'Sweet Plum Tomato',
        cropFamily: 'Solanaceae',
        variety: 'Solanum lycopersicum',
        stage: CropGrowthStage.flowering,
        healthStatus: PlantHealthStatus.healthy,
        soilMoisturePercent: 32.4,
        soilTemperatureCelsius: 21.8,
        npkSummary: 'Balanced',
        lastScannedAt: DateTime(2026, 10, 10, 8, 0),
        primaryDiagnosis: 'Optimal Vigor',
      );

      final chili = PlantModel(
        id: 'plant_chili_1',
        name: 'Red Habanero Chili',
        cropFamily: 'Solanaceae',
        variety: 'Capsicum chinense',
        stage: CropGrowthStage.fruiting,
        healthStatus: PlantHealthStatus.healthy,
        soilMoisturePercent: 28.0,
        soilTemperatureCelsius: 23.5,
        npkSummary: 'Balanced',
        lastScannedAt: DateTime(2026, 10, 10, 8, 0),
        primaryDiagnosis: 'Optimal Vigor',
      );

      await tester.runAsync(() async {
        await container.read(plantListNotifierProvider.notifier).addPlant(tomato);
        await container.read(plantListNotifierProvider.notifier).addPlant(chili);
      });

      final scanResult = DiagnosticScanResult(
        scanId: 'scan_chili_999',
        targetCrop: 'Red Chili',
        detectedCondition: 'Chili Anthracnose Lesions',
        scientificPathogen: 'Colletotrichum capsici',
        confidencePercentage: 96.8,
        severity: DiagnosticSeverity.severe,
        inferenceLatencyMs: 38,
        isOfflineInference: true,
        symptoms: const ['Sunken necrotic lesions', 'Concentric acervuli'],
        organicTreatment: 'Spray copper octanoate fungicide every 7 days.',
        chemicalTreatment: 'Azoxystrobin 250 SC.',
        preventativeAction: 'Ensure 3 feet air spacing between chili pots.',
        scannedAt: DateTime(2026, 10, 19, 9, 30),
      );

      // Arrange: Display DiagnosisResultSheet
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: DiagnosisResultSheet(
                  result: scanResult,
                  onDismiss: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: Result sheet renders and target crop auto-matched to Chili
      await tester.ensureVisible(find.text('TARGET PLANT PLOT'));
      expect(find.text('TARGET PLANT PLOT'), findsOneWidget);
      expect(find.text('Red Habanero Chili'), findsOneWidget);

      // Act: Open Change / Search modal to test search and category filter
      await tester.ensureVisible(find.text('Change / Search'));
      await tester.tap(find.text('Change / Search'));
      await tester.pumpAndSettle();

      // Assert: Modal sheet opened
      expect(find.text('Select Scanned Plant'), findsOneWidget);
      expect(find.text('Filter by category or search by crop name'), findsOneWidget);

      // Act: Tap Tomato filter chip in picker
      await tester.tap(find.text('🍅 Tomato (1)'));
      await tester.pumpAndSettle();

      // Assert: In picker bottom sheet, Tomato is shown and Chili is filtered out
      final pickerFinder = find.byType(BottomSheet);
      expect(find.descendant(of: pickerFinder, matching: find.text('Sweet Plum Tomato')), findsOneWidget);
      expect(find.descendant(of: pickerFinder, matching: find.text('Red Habanero Chili')), findsNothing);

      // Act: Tap Chili filter chip again
      await tester.tap(find.text('🌶️ Chili (1)'));
      await tester.pumpAndSettle();

      // Assert: Only Chili is shown in picker bottom sheet
      expect(find.descendant(of: pickerFinder, matching: find.text('Red Habanero Chili')), findsOneWidget);

      // Act: Test search input
      await tester.enterText(find.byType(TextField).last, 'Habanero');
      await tester.pumpAndSettle();
      expect(find.descendant(of: pickerFinder, matching: find.text('Red Habanero Chili')), findsOneWidget);

      // Act: Select Red Habanero Chili
      await tester.tap(find.descendant(of: pickerFinder, matching: find.text('Red Habanero Chili')).last);
      await tester.pumpAndSettle();

      // Assert: Modal dismissed, back on result sheet
      expect(find.text('Select Scanned Plant'), findsNothing);
      expect(find.text('Save Diagnosis to Red Habanero Chili'), findsOneWidget);

      // Act: Save Diagnosis
      await tester.ensureVisible(find.text('Save Diagnosis to Red Habanero Chili'));
      await tester.runAsync(() async {
        await tester.tap(find.text('Save Diagnosis to Red Habanero Chili'));
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();

      // Assert: Plant record in SQLite and Riverpod has been updated
      final updatedPlants = container.read(plantListNotifierProvider).value!;
      final updatedChili = updatedPlants.firstWhere((p) => p.id == 'plant_chili_1');

      expect(updatedChili.healthStatus, PlantHealthStatus.critical);
      expect(updatedChili.primaryDiagnosis, contains('Chili Anthracnose Lesions'));
      expect(updatedChili.primaryDiagnosis, contains('96.8%'));
      expect(updatedChili.lastScannedAt, scanResult.scannedAt);
    });

    testWidgets('Diagnostics action navigates to diagnosis section with SQLite-persisted to-do checklist and interactive toggles', (tester) async {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(testDb),
          plantRepositoryProvider.overrideWithValue(testRepo),
          diagnosticTaskRepositoryProvider.overrideWithValue(testTaskRepo),
        ],
      );
      // final container setup without addTearDown

      final sickPlant = PlantModel(
        id: 'plot_sick_1',
        name: 'Infected Tomato',
        cropFamily: 'Solanaceae',
        variety: 'Solanum lycopersicum',
        stage: CropGrowthStage.fruiting,
        healthStatus: PlantHealthStatus.critical,
        soilMoisturePercent: 20.0,
        soilTemperatureCelsius: 24.0,
        npkSummary: 'Nitrogen deficit',
        lastScannedAt: DateTime.now(),
        primaryDiagnosis: 'Early Blight (Alternaria solani)',
        notes: 'Lesions on lower foliage.',
      );

      await tester.runAsync(() async {
        await container.read(plantListNotifierProvider.notifier).addPlant(sickPlant);
        await container.read(plantDiagnosticTasksNotifierProvider(sickPlant.id).notifier).initializeTasksIfEmpty(sickPlant);
        await Future.delayed(const Duration(milliseconds: 100));
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MyPlantsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: Diagnostics action button is visible on the sick plant card
      expect(find.text('Diagnostics'), findsOneWidget);

      // Act: Tap Diagnostics
      await tester.ensureVisible(find.text('Diagnostics'));
      await tester.tap(find.text('Diagnostics'));
      await tester.pump();
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();

      // Assert: Diagnosis section and persisted triage checklist rendered
      expect(find.text('ACTIVE DIAGNOSIS & PROTOCOL'), findsOneWidget);
      expect(find.text('CRITICAL'), findsWidgets);
      expect(find.text('Early Blight (Alternaria solani)'), findsWidgets);
      expect(find.text('TRIAGE CHECKLIST'), findsOneWidget);
      expect(find.byType(Checkbox), findsWidgets);

      // Act: Check the first triage task checkbox
      final firstCheckbox = find.byType(Checkbox).first;
      await tester.ensureVisible(firstCheckbox);
      await tester.runAsync(() async {
        await tester.tap(firstCheckbox);
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();

      // Assert: Task is completed and saved in SQLite
      await tester.runAsync(() async {
        final tasksInDb = await testTaskRepo.fetchTasksForPlant(sickPlant.id);
        expect(tasksInDb.first.isCompleted, isTrue);
      });
    });

    testWidgets('Swipe down on Home and My Plants triggers RefreshIndicator to reload screen', (tester) async {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(testDb),
          plantRepositoryProvider.overrideWithValue(testRepo),
          diagnosticTaskRepositoryProvider.overrideWithValue(testTaskRepo),
        ],
      );
      addTearDown(container.dispose);

      // Verify MyPlantsScreen pull-to-refresh
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MyPlantsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
      final RefreshIndicatorState plantsRefresh = tester.state(find.byType(RefreshIndicator));
      plantsRefresh.show();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      // Verify HomeScreen pull-to-refresh
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
      final RefreshIndicatorState homeRefresh = tester.state(find.byType(RefreshIndicator));
      homeRefresh.show();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
