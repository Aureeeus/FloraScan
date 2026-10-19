import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ble/flora_wand_ble_service.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/flora_scan_header.dart';
import '../../../core/widgets/sproutly_mascot.dart';
import '../domain/entities/diagnostic_task_model.dart';
import '../domain/entities/plant_model.dart';
import 'providers/diagnostic_task_providers.dart';
import 'providers/plant_providers.dart';

/// Screen listing all monitored crop plots matching Google Stitch specifications.
///
/// Serves as the authoritative SSOT for data manipulation:
/// - Create: via Add Plant
/// - Read: reactive stream from SQLite
/// - Update: edit dialog
/// - Delete: delete confirmation dialog
class MyPlantsScreen extends ConsumerStatefulWidget {
  const MyPlantsScreen({super.key});

  @override
  ConsumerState<MyPlantsScreen> createState() => _MyPlantsScreenState();
}

class _MyPlantsScreenState extends ConsumerState<MyPlantsScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _telemetrySectionKey = GlobalKey();
  final GlobalKey _diagnosisSectionKey = GlobalKey();

  String _selectedCropFilter = 'All';
  String _selectedAreaFilter = 'All';
  String _selectedPlantId = '';

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _matchesFilter(String crop, String area) {
    final matchesCrop = _selectedCropFilter == 'All' || crop.toLowerCase() == _selectedCropFilter.toLowerCase();
    final matchesArea = _selectedAreaFilter == 'All' || area.toLowerCase() == _selectedAreaFilter.toLowerCase();
    return matchesCrop && matchesArea;
  }

  String _resolveCrop(PlantModel plant) {
    final lowerName = plant.name.toLowerCase();
    final lowerVariety = plant.variety.toLowerCase();
    if (lowerName.contains('tomato') || lowerVariety.contains('tomato') || lowerVariety.contains('lycopersicum')) {
      return 'Tomato';
    }
    if (lowerName.contains('chili') || lowerName.contains('pepper') || lowerVariety.contains('chili') || lowerVariety.contains('capsicum')) {
      return 'Chili';
    }
    if (lowerName.contains('eggplant') || lowerVariety.contains('eggplant') || lowerVariety.contains('melongena') || lowerName.contains('aubergine')) {
      return 'Eggplant';
    }
    return 'Tomato';
  }

  String _resolveArea(PlantModel plant) {
    final lowerNotes = plant.notes.toLowerCase();
    if (lowerNotes.contains('backyard')) return 'Backyard';
    if (lowerNotes.contains('indoor')) return 'Indoor';
    return 'Balcony';
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return diff.inMinutes <= 1 ? 'Just now' : '${diff.inMinutes} mins ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} hrs ago';
    }
    if (diff.inDays == 1) {
      return 'Yesterday';
    }
    return '${diff.inDays} days ago';
  }

  void _openEditPlantDialog(PlantModel plant) {
    final nameController = TextEditingController(text: plant.name);
    final notesController = TextEditingController(text: plant.notes);
    CropGrowthStage selectedStage = plant.stage;
    PlantHealthStatus selectedHealth = plant.healthStatus;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceContainerLowest,
          title: Text(
            'Edit ${plant.name}',
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Crop Nickname / Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<CropGrowthStage>(
                  initialValue: selectedStage,
                  decoration: const InputDecoration(
                    labelText: 'Growth Stage',
                    border: OutlineInputBorder(),
                  ),
                  items: CropGrowthStage.values.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(s.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedStage = val);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PlantHealthStatus>(
                  initialValue: selectedHealth,
                  decoration: const InputDecoration(
                    labelText: 'Health Status',
                    border: OutlineInputBorder(),
                  ),
                  items: PlantHealthStatus.values.map((h) {
                    return DropdownMenuItem(
                      value: h,
                      child: Text(h.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedHealth = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Field Notes',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final updated = plant.copyWith(
                  name: nameController.text.trim().isNotEmpty
                      ? nameController.text.trim()
                      : plant.name,
                  stage: selectedStage,
                  healthStatus: selectedHealth,
                  notes: notesController.text.trim(),
                );
                ref.read(plantListNotifierProvider.notifier).addPlant(updated);
                Navigator.of(dialogCtx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Updated "${updated.name}" details!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePlant(PlantModel plant) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        title: Text(
          'Delete ${plant.name}?',
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to remove "${plant.name}" from your garden? This record will be permanently deleted from local device storage.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(plantListNotifierProvider.notifier).removePlant(plant.id);
              Navigator.of(dialogCtx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Removed "${plant.name}" from garden records.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plantsAsync = ref.watch(plantListNotifierProvider);
    final allPlants = plantsAsync.value ?? const <PlantModel>[];

    final visiblePlants = allPlants.where((p) =>
      _matchesFilter(_resolveCrop(p), _resolveArea(p))
    ).toList();

    final visibleCount = visiblePlants.length;
    final totalCount = allPlants.length;
    final tomatoCount = allPlants.where((p) => _resolveCrop(p) == 'Tomato').length;
    final chiliCount = allPlants.where((p) => _resolveCrop(p) == 'Chili').length;
    final eggplantCount = allPlants.where((p) => _resolveCrop(p) == 'Eggplant').length;

    final balconyCount = allPlants.where((p) => _resolveArea(p) == 'Balcony').length;
    final backyardCount = allPlants.where((p) => _resolveArea(p) == 'Backyard').length;
    final indoorCount = allPlants.where((p) => _resolveArea(p) == 'Indoor').length;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: const FloraScanHeader(subtitle: 'My Plants'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(plantListNotifierProvider.notifier).reload();
            if (mounted && _selectedPlantId.isNotEmpty) {
              await ref
                  .read(plantDiagnosticTasksNotifierProvider(_selectedPlantId).notifier)
                  .reload();
            }
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Garden Welcome Bar & Cheerful Mascot Delight
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F012D1D),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.secondaryFixed,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'GARDEN TELEMETRY ACTIVE',
                                    style: AppTypography.labelUi.copyWith(
                                      color: AppColors.secondaryFixed,
                                      fontSize: 9,
                                      letterSpacing: 1.1,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Urban Patch #04',
                              style: AppTypography.headlineSmall.copyWith(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              totalCount == 0
                                  ? 'No green buddies yet. Add your first plant!'
                                  : '$totalCount green ${totalCount == 1 ? "buddy" : "buddies"} growing strong!',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.onPrimaryContainer,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          SproutlyMascot(
                            size: 52,
                            badgeEmoji: '✨',
                            badgeColor: AppColors.secondary,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Sprouty cheers you on! Keep up the great gardening! 🌿'),
                                  duration: Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sprouty',
                            style: AppTypography.labelUi.copyWith(
                              color: AppColors.secondaryFixed,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Quick Add & Summary Action Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'My Plants',
                              style: AppTypography.headlineMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: AppColors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              '$visibleCount Total',
                              style: AppTypography.telemetrySmall.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton.icon(
                      onPressed: () => context.go(AppRoutes.addPlant),
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('Add Plant'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Filter Section: Crop Categories (Sticky 'All Plants' + Swipable Carousel)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    // Static / Sticky "All Plants" Chip
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 8),
                      child: _buildCropChip('All', 'All Plants ($totalCount)', Icons.yard),
                    ),
                    // Swipable Carousel for individual crop chips
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(right: 16),
                        child: Row(
                          children: [
                            _buildCropChip('Tomato', '🍅 Tomato ($tomatoCount)', null),
                            const SizedBox(width: 8),
                            _buildCropChip('Chili', '🌶️ Chili ($chiliCount)', null),
                            const SizedBox(width: 8),
                            _buildCropChip('Eggplant', '🍆 Eggplant ($eggplantCount)', null),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Location Filter Section (Sticky 'AREA' + Swipable Carousel)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    // Static / Sticky "AREA" Badge
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.place, size: 14, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            'AREA: ',
                            style: AppTypography.labelUi.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Swipable Carousel for location filter pills
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(right: 16),
                        child: Row(
                          children: [
                            _buildAreaChip('All', 'All Areas'),
                            const SizedBox(width: 6),
                            _buildAreaChip('Balcony', 'Balcony ($balconyCount)'),
                            const SizedBox(width: 6),
                            _buildAreaChip('Backyard', 'Backyard ($backyardCount)'),
                            const SizedBox(width: 6),
                            _buildAreaChip('Indoor', 'Indoor Pots ($indoorCount)'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // 4. Plant List Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    for (int i = 0; i < visiblePlants.length; i++) ...[
                      _buildPlantItemCard(
                        id: visiblePlants[i].id,
                        name: visiblePlants[i].name,
                        nickname: '"${visiblePlants[i].variety}"',
                        crop: _resolveCrop(visiblePlants[i]),
                        location: _resolveArea(visiblePlants[i]),
                        statusTag: visiblePlants[i].healthStatus == PlantHealthStatus.healthy
                            ? 'Healthy'
                            : (visiblePlants[i].healthStatus == PlantHealthStatus.caution ? 'Caution' : 'Needs Care'),
                        isError: visiblePlants[i].healthStatus != PlantHealthStatus.healthy,
                        avatarIcon: _resolveCrop(visiblePlants[i]) == 'Chili'
                            ? Icons.local_fire_department
                            : (_resolveCrop(visiblePlants[i]) == 'Eggplant' ? Icons.spa : Icons.eco),
                        avatarColor: visiblePlants[i].healthStatus == PlantHealthStatus.healthy
                            ? AppColors.secondary
                            : (visiblePlants[i].healthStatus == PlantHealthStatus.caution ? AppColors.tertiary : AppColors.error),
                        metricsBar: visiblePlants[i].primaryDiagnosis != null &&
                                visiblePlants[i].healthStatus != PlantHealthStatus.healthy
                            ? _buildAlertBanner(
                                icon: Icons.warning_amber_rounded,
                                alertText: visiblePlants[i].primaryDiagnosis!,
                              )
                            : _buildDualMetricBar(
                                metric1Icon: Icons.water_drop,
                                metric1Label: 'MOISTURE',
                                metric1Value:
                                    '${visiblePlants[i].soilMoisturePercent.toStringAsFixed(0)}% (${visiblePlants[i].soilMoisturePercent < 25 ? "Too Dry" : "Good"})',
                                metric1IsError: visiblePlants[i].soilMoisturePercent < 25,
                                metric2Icon: Icons.thermostat,
                                metric2Label: 'AIR TEMP',
                                metric2Value: '${visiblePlants[i].soilTemperatureCelsius.toStringAsFixed(1)}°C',
                              ),
                        timeAgo: _formatTimeAgo(visiblePlants[i].lastScannedAt),
                        actionLabel: visiblePlants[i].healthStatus != PlantHealthStatus.healthy
                            ? 'Diagnostics'
                            : 'View Sensor Data',
                        actionRoute: () {
                          setState(() => _selectedPlantId = visiblePlants[i].id);
                          if (visiblePlants[i].healthStatus != PlantHealthStatus.healthy) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              final targetContext = _diagnosisSectionKey.currentContext;
                              if (targetContext != null) {
                                Scrollable.ensureVisible(
                                  targetContext,
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeInOutCubic,
                                  alignment: 0.05,
                                );
                              }
                            });
                          } else {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              final targetContext = _telemetrySectionKey.currentContext;
                              if (targetContext != null) {
                                Scrollable.ensureVisible(
                                  targetContext,
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeInOutCubic,
                                  alignment: 0.05,
                                );
                              }
                            });
                          }
                        },
                        onEdit: () => _openEditPlantDialog(visiblePlants[i]),
                        onDelete: () => _confirmDeletePlant(visiblePlants[i]),
                      ),
                      if (i < visiblePlants.length - 1) const SizedBox(height: 10),
                    ],

                    if (visibleCount == 0)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.surfaceContainerHigh),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.yard_outlined, size: 28, color: AppColors.primary),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              totalCount == 0 ? 'Your Garden is Empty' : 'No plants matching filter',
                              style: AppTypography.headlineSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              totalCount == 0
                                  ? 'Tap "+ Add Plant" above to register and monitor your first crop plot.'
                                  : 'Try selecting a different crop category or area filter.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                            if (totalCount == 0) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => context.go(AppRoutes.addPlant),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add Your First Plant'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.onPrimary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              if (allPlants.isNotEmpty) ...[
                const SizedBox(height: 20),

                // 5. Detail Preview Section (Interactive Focal Plant)
                Builder(
                  builder: (context) {
                    final focalPlant = allPlants.firstWhere(
                      (p) => p.id == _selectedPlantId,
                      orElse: () => allPlants.first,
                    );
                    final wandState = ref.watch(floraWandNotifierProvider);
                    final isWandConnected = wandState.isConnected;
                    final syncHour = focalPlant.lastScannedAt.hour.toString().padLeft(2, '0');
                    final syncMinute = focalPlant.lastScannedAt.minute.toString().padLeft(2, '0');
                    final moistureLow = focalPlant.soilMoisturePercent < 30;
                    final moistureHigh = focalPlant.soilMoisturePercent > 75;
                    final tempHigh = focalPlant.soilTemperatureCelsius > 32;
                    final tempLow = focalPlant.soilTemperatureCelsius < 16;
                    final isCritical = focalPlant.healthStatus == PlantHealthStatus.critical;
                    final isCaution = focalPlant.healthStatus == PlantHealthStatus.caution;
                    final hasDeficit = focalPlant.npkSummary.toLowerCase().contains('deficit');

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (focalPlant.healthStatus != PlantHealthStatus.healthy) ...[
                          _buildDiagnosisSection(context, focalPlant),
                          const SizedBox(height: 16),
                        ],
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            key: _telemetrySectionKey,
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.analytics, color: AppColors.onPrimary, size: 20),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    'TELEMETRY ACTIVE',
                                                    style: AppTypography.labelUi.copyWith(
                                                      color: AppColors.secondary,
                                                      fontSize: 9,
                                                      letterSpacing: 0.8,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.surfaceContainerHighest,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    'BLE Live',
                                                    style: AppTypography.telemetrySmall.copyWith(
                                                      fontSize: 9,
                                                      color: AppColors.onSurfaceVariant,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              focalPlant.name + (focalPlant.variety.isNotEmpty ? ' (${focalPlant.variety})' : ''),
                                              style: AppTypography.headlineSmall.copyWith(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                                color: AppColors.onSurface,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.download, color: AppColors.onSurface),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Exporting telemetry PDF & CSV records...'),
                                        duration: Duration(seconds: 1),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'LIVE OPTICAL & PROBE TELEMETRY',
                                    style: AppTypography.labelUi.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      fontSize: 10,
                                      letterSpacing: 0.8,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isWandConnected
                                      ? 'Live BLE (${wandState.telemetry.batteryPercent}%)'
                                      : 'Sync: $syncHour:$syncMinute',
                                  style: AppTypography.telemetrySmall.copyWith(
                                    color: isWandConnected ? AppColors.secondary : AppColors.onSurfaceVariant,
                                    fontSize: 11,
                                    fontWeight: isWandConnected ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // 4 Sensors Snapshot (Live BLE if connected, DB history if offline)
                            GridView.count(
                              crossAxisCount: 2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio: 1.35,
                              children: [
                                _buildDetailSensorBox(
                                  title: 'Soil Moisture',
                                  icon: Icons.water_drop,
                                  iconColor: isWandConnected
                                      ? (wandState.telemetry.isMoistureWarning ? AppColors.error : AppColors.secondary)
                                      : (moistureLow ? AppColors.error : AppColors.secondary),
                                  tag: isWandConnected
                                      ? wandState.telemetry.soilMoistureTag.toUpperCase()
                                      : (moistureLow ? 'TOO LOW ⚠️' : moistureHigh ? 'TOO HIGH ⚠️' : 'GOOD'),
                                  tagColor: isWandConnected
                                      ? (wandState.telemetry.isMoistureWarning ? AppColors.onErrorContainer : AppColors.onSecondaryFixedVariant)
                                      : (moistureLow ? AppColors.onErrorContainer : AppColors.onSecondaryFixedVariant),
                                  tagBg: isWandConnected
                                      ? (wandState.telemetry.isMoistureWarning ? AppColors.errorContainer : AppColors.secondaryFixed)
                                      : (moistureLow ? AppColors.errorContainer : AppColors.secondaryFixed),
                                  value: isWandConnected
                                      ? wandState.telemetry.formattedMoisture
                                      : '${focalPlant.soilMoisturePercent.toStringAsFixed(0)}%',
                                  subvalue: isWandConnected ? 'Live Sensor' : '/ 60% opt',
                                  progress: isWandConnected
                                      ? (wandState.telemetry.soilMoisturePercent / 100.0).clamp(0.0, 1.0)
                                      : (focalPlant.soilMoisturePercent / 100.0).clamp(0.0, 1.0),
                                  progressColor: isWandConnected
                                      ? (wandState.telemetry.isMoistureWarning ? AppColors.error : AppColors.secondary)
                                      : (moistureLow ? AppColors.error : AppColors.secondary),
                                ),
                                _buildDetailSensorBox(
                                  title: 'Air Temp',
                                  icon: Icons.thermostat,
                                  iconColor: isWandConnected
                                      ? (wandState.telemetry.isTemperatureWarning ? AppColors.error : AppColors.secondary)
                                      : AppColors.secondary,
                                  tag: isWandConnected
                                      ? wandState.telemetry.temperatureTag.toUpperCase()
                                      : (tempHigh ? 'HIGH' : tempLow ? 'LOW' : 'GOOD'),
                                  tagColor: isWandConnected && wandState.telemetry.isTemperatureWarning
                                      ? AppColors.onErrorContainer
                                      : AppColors.onSecondaryFixedVariant,
                                  tagBg: isWandConnected && wandState.telemetry.isTemperatureWarning
                                      ? AppColors.errorContainer
                                      : AppColors.secondaryFixed,
                                  value: isWandConnected
                                      ? wandState.telemetry.formattedTemperature
                                      : '${focalPlant.soilTemperatureCelsius.toStringAsFixed(1)}°C',
                                  subvalue: isWandConnected ? 'Live Sensor' : 'Ideal 22-28°',
                                  progress: isWandConnected
                                      ? (((wandState.telemetry.temperatureCelsius) - 10) / 30.0).clamp(0.0, 1.0)
                                      : (((focalPlant.soilTemperatureCelsius) - 10) / 30.0).clamp(0.0, 1.0),
                                  progressColor: isWandConnected && wandState.telemetry.isTemperatureWarning
                                      ? AppColors.error
                                      : AppColors.secondary,
                                ),
                                _buildDetailSensorBox(
                                  title: isWandConnected ? 'Humidity' : 'Stage',
                                  icon: isWandConnected ? Icons.cloud : Icons.spa,
                                  iconColor: isWandConnected
                                      ? (wandState.telemetry.isHumidityWarning ? AppColors.error : AppColors.secondary)
                                      : AppColors.secondary,
                                  tag: isWandConnected
                                      ? wandState.telemetry.humidityTag.toUpperCase()
                                      : (isCritical ? 'CRITICAL' : isCaution ? 'CAUTION' : 'GOOD'),
                                  tagColor: isWandConnected
                                      ? (wandState.telemetry.isHumidityWarning ? AppColors.onErrorContainer : AppColors.onSecondaryFixedVariant)
                                      : (isCritical ? AppColors.onErrorContainer : AppColors.onSecondaryFixedVariant),
                                  tagBg: isWandConnected
                                      ? (wandState.telemetry.isHumidityWarning ? AppColors.errorContainer : AppColors.secondaryFixed)
                                      : (isCritical ? AppColors.errorContainer : AppColors.secondaryFixed),
                                  value: isWandConnected
                                      ? wandState.telemetry.formattedHumidity
                                      : focalPlant.stage.name.toUpperCase(),
                                  subvalue: isWandConnected ? 'Live Sensor' : focalPlant.cropFamily,
                                  progress: isWandConnected
                                      ? (wandState.telemetry.humidityPercent / 100.0).clamp(0.0, 1.0)
                                      : ((focalPlant.stage.index + 1) / CropGrowthStage.values.length).clamp(0.0, 1.0),
                                  progressColor: isWandConnected
                                      ? (wandState.telemetry.isHumidityWarning ? AppColors.error : AppColors.secondary)
                                      : (isCritical ? AppColors.error : AppColors.secondary),
                                ),
                                _buildDetailSensorBox(
                                  title: isWandConnected ? 'Light Lux' : 'Nutrient / NPK',
                                  icon: isWandConnected ? Icons.wb_sunny : Icons.science,
                                  iconColor: isWandConnected
                                      ? (wandState.telemetry.isLightWarning ? AppColors.error : AppColors.secondary)
                                      : AppColors.secondary,
                                  tag: isWandConnected
                                      ? wandState.telemetry.lightTag.toUpperCase()
                                      : (hasDeficit ? 'DEFICIT' : 'BALANCED'),
                                  tagColor: isWandConnected
                                      ? (wandState.telemetry.isLightWarning ? AppColors.onErrorContainer : AppColors.onTertiaryFixed)
                                      : (hasDeficit ? AppColors.onErrorContainer : AppColors.onTertiaryFixed),
                                  tagBg: isWandConnected
                                      ? (wandState.telemetry.isLightWarning ? AppColors.errorContainer : AppColors.tertiaryFixed)
                                      : (hasDeficit ? AppColors.errorContainer : AppColors.tertiaryFixed),
                                  value: isWandConnected
                                      ? wandState.telemetry.formattedLight
                                      : focalPlant.npkSummary.split(' ').first,
                                  subvalue: isWandConnected ? 'Live Sensor' : focalPlant.npkSummary,
                                  progress: isWandConnected
                                      ? (wandState.telemetry.lightLux / 1200.0).clamp(0.0, 1.0)
                                      : 0.75,
                                  progressColor: isWandConnected && wandState.telemetry.isLightWarning
                                      ? AppColors.error
                                      : AppColors.tertiaryFixedDim,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
                ),
              ],
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildCropChip(String key, String label, IconData? icon) {
    final isSelected = _selectedCropFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedCropFilter = key),
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTypography.labelUi.copyWith(
                color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAreaChip(String key, String label) {
    final isSelected = _selectedAreaFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedAreaFilter = key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceContainerHigh : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isSelected ? AppColors.onSurface : AppColors.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildPlantItemCard({
    required String id,
    required String name,
    required String nickname,
    required String crop,
    required String location,
    required String statusTag,
    required bool isError,
    required IconData avatarIcon,
    required Color avatarColor,
    required Widget metricsBar,
    required String timeAgo,
    required String actionLabel,
    required VoidCallback actionRoute,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    final isSelected = _selectedPlantId == id;

    return InkWell(
      onTap: () => setState(() => _selectedPlantId = id),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : const Color(0x08000000),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(avatarIcon, color: avatarColor, size: 24),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHighest.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          location,
                          style: AppTypography.telemetrySmall.copyWith(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: AppTypography.headlineSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isError ? AppColors.errorContainer : AppColors.secondaryFixed,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isError ? AppColors.error : AppColors.secondary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  statusTag,
                                  style: AppTypography.labelUi.copyWith(
                                    color: isError ? AppColors.onErrorContainer : AppColors.onSecondaryFixedVariant,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (onEdit != null || onDelete != null) ...[
                            const SizedBox(width: 2),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 16, color: AppColors.onSurfaceVariant),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onSelected: (val) {
                                if (val == 'edit' && onEdit != null) onEdit();
                                if (val == 'delete' && onDelete != null) onDelete();
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 16, color: AppColors.primary),
                                      SizedBox(width: 8),
                                      Text('Edit Plot'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                                      SizedBox(width: 8),
                                      Text('Delete Plot'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Nickname: $nickname • $crop',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      metricsBar,
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule, size: 12, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          timeAgo,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: InkWell(
                    onTap: actionRoute,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            actionLabel,
                            style: AppTypography.bodySmall.copyWith(
                              color: isError ? AppColors.error : AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 10,
                          color: isError ? AppColors.error : AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDualMetricBar({
    required IconData metric1Icon,
    required String metric1Label,
    required String metric1Value,
    required bool metric1IsError,
    required IconData metric2Icon,
    required String metric2Label,
    required String metric2Value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  metric1Icon,
                  size: 15,
                  color: metric1IsError ? AppColors.error : AppColors.secondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        metric1Label.toUpperCase(),
                        style: AppTypography.labelUi.copyWith(
                          fontSize: 8,
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        metric1Value,
                        style: AppTypography.telemetrySmall.copyWith(
                          fontSize: 10,
                          fontWeight: metric1IsError ? FontWeight.w700 : FontWeight.w600,
                          color: metric1IsError ? AppColors.error : AppColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Row(
              children: [
                Icon(metric2Icon, size: 15, color: AppColors.secondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        metric2Label.toUpperCase(),
                        style: AppTypography.labelUi.copyWith(
                          fontSize: 8,
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        metric2Value,
                        style: AppTypography.telemetrySmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner({
    required IconData icon,
    required String alertText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.error),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              alertText,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSensorBox({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String tag,
    required Color tagColor,
    required Color tagBg,
    required String value,
    required String subvalue,
    required double progress,
    required Color progressColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, size: 13, color: iconColor),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: tagBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag,
                    style: AppTypography.labelUi.copyWith(
                      color: tagColor,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: AppTypography.telemetryLarge.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  subvalue,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 10,
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: AppColors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisSection(BuildContext context, PlantModel focalPlant) {
    final tasksAsync = ref.watch(plantDiagnosticTasksNotifierProvider(focalPlant.id));
    final tasks = tasksAsync.value ?? const <DiagnosticTaskModel>[];
    final completedCount = tasks.where((t) => t.isCompleted).length;
    final totalCount = tasks.length;
    final progress = totalCount > 0 ? (completedCount / totalCount).clamp(0.0, 1.0) : 0.0;
    final isCritical = focalPlant.healthStatus == PlantHealthStatus.critical;
    final isCaution = focalPlant.healthStatus == PlantHealthStatus.caution;
    final isHealthy = focalPlant.healthStatus == PlantHealthStatus.healthy;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        key: _diagnosisSectionKey,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCritical
                ? AppColors.error.withValues(alpha: 0.4)
                : (isCaution
                    ? AppColors.tertiary.withValues(alpha: 0.4)
                    : AppColors.secondary.withValues(alpha: 0.3)),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header with Diagnosis Badge and Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isCritical
                              ? AppColors.errorContainer
                              : (isCaution ? AppColors.tertiaryContainer : AppColors.secondaryContainer),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isHealthy ? Icons.verified : Icons.biotech,
                          color: isCritical
                              ? AppColors.error
                              : (isCaution ? AppColors.tertiary : AppColors.secondary),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    isHealthy ? 'HEALTHY • TRIAGE COMPLETE' : 'ACTIVE DIAGNOSIS & PROTOCOL',
                                    style: AppTypography.labelUi.copyWith(
                                      color: isCritical
                                          ? AppColors.error
                                          : (isCaution ? AppColors.tertiary : AppColors.secondary),
                                      fontSize: 9,
                                      letterSpacing: 0.8,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: isCritical
                                        ? AppColors.errorContainer
                                        : (isCaution ? AppColors.tertiaryContainer : AppColors.secondaryContainer),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    focalPlant.healthStatus.name.toUpperCase(),
                                    style: AppTypography.telemetrySmall.copyWith(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      color: isCritical
                                          ? AppColors.onErrorContainer
                                          : (isCaution ? AppColors.onTertiaryContainer : AppColors.onSecondaryContainer),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              focalPlant.primaryDiagnosis ?? 'Detected Foliage Stress',
                              style: AppTypography.headlineSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Re-scan with Camera Wand',
                  icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 20),
                  onPressed: () => context.go(AppRoutes.scan),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 2. Checklist Header & Progress Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'TRIAGE CHECKLIST',
                    style: AppTypography.labelUi.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 10,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$completedCount of $totalCount Done',
                  style: AppTypography.telemetrySmall.copyWith(
                    color: completedCount == totalCount && totalCount > 0
                        ? AppColors.secondary
                        : AppColors.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(9999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  completedCount == totalCount && totalCount > 0
                      ? AppColors.secondary
                      : (isCritical ? AppColors.error : AppColors.primary),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 3. To-Do Checklist Items
            if (tasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text(
                    'No pending triage tasks for this crop plot.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ),
              )
            else
              for (final task in tasks)
                _buildTaskChecklistTile(focalPlant.id, task),

            const SizedBox(height: 14),

            // 4. Action Row: Mark as Recovered & Optical Re-scan
            Row(
              children: [
                if (!isHealthy) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final updated = focalPlant.copyWith(
                          healthStatus: PlantHealthStatus.healthy,
                          notes: focalPlant.notes.isEmpty
                              ? 'Recovered: All diagnostic triage tasks completed.'
                              : '${focalPlant.notes}\n• Recovered: Diagnostic triage completed.',
                        );
                        await ref.read(plantListNotifierProvider.notifier).addPlant(updated);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('"${focalPlant.name}" marked as Healthy and Recovered! 🎉'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.secondary,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Mark Recovered'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.scan),
                    icon: const Icon(Icons.camera_alt, size: 16),
                    label: const Text('Optical Re-scan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.onSurface,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskChecklistTile(String plantId, DiagnosticTaskModel task) {
    return InkWell(
      onTap: () {
        ref
            .read(plantDiagnosticTasksNotifierProvider(plantId).notifier)
            .toggleTask(task.id, !task.isCompleted);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: task.isCompleted,
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: (bool? val) {
                  if (val != null) {
                    ref
                        .read(plantDiagnosticTasksNotifierProvider(plantId).notifier)
                        .toggleTask(task.id, val);
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: task.tier == 1
                              ? AppColors.errorContainer.withValues(alpha: 0.6)
                              : AppColors.secondaryContainer.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          task.tier == 1 ? 'Tier 1 • Urgent' : 'Tier 2 • Care',
                          style: AppTypography.labelUi.copyWith(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: task.tier == 1
                                ? AppColors.onErrorContainer
                                : AppColors.onSecondaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          task.title,
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: task.isCompleted ? AppColors.onSurfaceVariant : AppColors.onSurface,
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (task.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      task.subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 10.5,
                        color: AppColors.onSurfaceVariant,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
