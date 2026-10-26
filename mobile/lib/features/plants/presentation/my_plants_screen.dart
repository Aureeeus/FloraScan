import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ble/flora_wand_calibration_service.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/flora_scan_header.dart';
import '../../../core/widgets/sproutly_mascot.dart';
import '../../settings/presentation/providers/settings_providers.dart';
import '../domain/entities/diagnostic_task_model.dart';
import '../domain/entities/plant_model.dart';
import 'plant_formatting_utils.dart';
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

  String _selectedCropFilter = 'All';
  String _selectedAreaFilter = 'All';
  String _selectedPlantId = '';
  bool _isProfileExpanded = false;

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

  String _formatTimeAgo(DateTime dt) => PlantFormattingUtils.formatTimeAgo(dt);

  String _buildPlantItemMetadata(PlantModel plant) =>
      PlantFormattingUtils.buildPlantItemMetadata(
        plant: plant,
        area: _resolveArea(plant),
        crop: _resolveCrop(plant),
      );

  String _buildFocalPlantTitle(PlantModel plant) =>
      PlantFormattingUtils.buildFocalPlantTitle(plant);

  String _formatReadingTimestamp(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final isYesterday = dt.year == now.year && dt.month == now.month && dt.day == now.day - 1;

    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final timeStr = '$hour12:$minute $period';

    if (isToday) {
      return 'Today, $timeStr';
    } else if (isYesterday) {
      return 'Yesterday, $timeStr';
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final monthStr = months[dt.month - 1];
      return '$monthStr ${dt.day}, $timeStr';
    }
  }

  void _showRenamePlotDialog(BuildContext context, String currentName) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final nameController = TextEditingController(text: currentName == 'Home Garden' ? '' : currentName);
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? colorScheme.surfaceContainerHigh : AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Rename Garden Plot',
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            fontSize: 18,
          ),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: 'Garden Name',
            hintText: 'Home Garden',
            hintStyle: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.labelUi.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isDark ? colorScheme.primary : AppColors.primary,
              foregroundColor: isDark ? colorScheme.onPrimary : AppColors.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final trimmed = nameController.text.trim();
              final updatedName = trimmed.isEmpty ? 'Home Garden' : trimmed;
              await ref.read(gardenPlotNameProvider.notifier).setName(updatedName);
              if (dialogCtx.mounted) {
                Navigator.of(dialogCtx).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthPill(PlantHealthStatus status) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final (label, color, bg) = switch (status) {
      PlantHealthStatus.healthy => (
          'Healthy',
          isDark ? colorScheme.secondary : AppColors.secondary,
          isDark ? colorScheme.secondaryContainer : AppColors.secondaryContainer,
        ),
      PlantHealthStatus.caution => (
          'Caution',
          isDark ? colorScheme.tertiary : AppColors.tertiary,
          isDark ? colorScheme.tertiaryContainer : AppColors.tertiaryContainer,
        ),
      PlantHealthStatus.critical => (
          'Needs Care',
          isDark ? const Color(0xFFFFB4AB) : AppColors.error,
          isDark ? colorScheme.errorContainer : AppColors.errorContainer,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? bg.withValues(alpha: 0.45) : bg.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.6 : 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.labelUi.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? (status == PlantHealthStatus.critical
                      ? colorScheme.onErrorContainer
                      : (status == PlantHealthStatus.caution
                          ? colorScheme.onTertiaryContainer
                          : colorScheme.secondary))
                  : color,
            ),
          ),
        ],
      ),
    );
  }

  void _openEditPlantDialog(PlantModel plant) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final nameController = TextEditingController(text: plant.name);
    final notesController = TextEditingController(text: plant.notes);
    CropGrowthStage selectedStage = plant.stage;
    PlantHealthStatus selectedHealth = plant.healthStatus;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? colorScheme.surfaceContainerHigh : AppColors.surfaceContainerLowest,
          title: Text(
            'Edit ${plant.name}',
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Crop Nickname / Title',
                    labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<CropGrowthStage>(
                  initialValue: selectedStage,
                  dropdownColor: isDark ? colorScheme.surfaceContainerHigh : AppColors.surfaceContainerLowest,
                  style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Growth Stage',
                    labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    border: const OutlineInputBorder(),
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
                  dropdownColor: isDark ? colorScheme.surfaceContainerHigh : AppColors.surfaceContainerLowest,
                  style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Health Status',
                    labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    border: const OutlineInputBorder(),
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
                  style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Field Notes',
                    labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                'Cancel',
                style: AppTypography.labelUi.copyWith(color: colorScheme.onSurfaceVariant),
              ),
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
                backgroundColor: isDark ? colorScheme.primary : AppColors.primary,
                foregroundColor: isDark ? colorScheme.onPrimary : AppColors.onPrimary,
              ),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePlant(PlantModel plant) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? colorScheme.surfaceContainerHigh : AppColors.surfaceContainerLowest,
        title: Text(
          'Delete ${plant.name}?',
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to remove "${plant.name}" from your garden? This record will be permanently deleted from local device storage.',
          style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.labelUi.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_selectedPlantId == plant.id) {
                setState(() => _selectedPlantId = '');
              }
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
              backgroundColor: isDark ? const Color(0xFFFFB4AB) : AppColors.error,
              foregroundColor: isDark ? const Color(0xFF690005) : AppColors.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final isCelsius = ref.watch(isCelsiusMetricProvider);

    final gardenPlotName = ref.watch(gardenPlotNameProvider);
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
      backgroundColor: colorScheme.surface,
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.surfaceContainerLow : AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? colorScheme.outlineVariant.withValues(alpha: 0.25)
                          : Colors.transparent,
                    ),
                    boxShadow: isDark
                        ? const []
                        : const [
                            BoxShadow(
                              color: Color(0x14012D1D),
                              blurRadius: 12,
                              offset: Offset(0, 4),
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
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark ? colorScheme.primary : AppColors.secondaryFixed,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Active Garden Plot',
                                    style: AppTypography.labelUi.copyWith(
                                      color: isDark ? colorScheme.primary : AppColors.secondaryFixed,
                                      fontSize: 10,
                                      letterSpacing: 0.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () => _showRenamePlotDialog(context, gardenPlotName),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        gardenPlotName,
                                        style: AppTypography.headlineSmall.copyWith(
                                          color: isDark ? colorScheme.onSurface : AppColors.onPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.edit_outlined,
                                      size: 14,
                                      color: isDark
                                          ? colorScheme.primary.withValues(alpha: 0.9)
                                          : AppColors.secondaryFixed.withValues(alpha: 0.9),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              totalCount == 0
                                  ? 'No green buddies yet. Add your first plant!'
                                  : '$totalCount green ${totalCount == 1 ? "buddy" : "buddies"} growing strong!',
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? colorScheme.onSurfaceVariant : AppColors.onPrimaryContainer,
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
                            badgeColor: isDark ? colorScheme.primary : AppColors.secondary,
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
                              color: isDark ? colorScheme.primary : AppColors.secondaryFixed,
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

              // 2. Quick Add & Action Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'My Plants',
                        style: AppTypography.headlineMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => context.go(AppRoutes.addPlant),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Plant'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? colorScheme.primary : AppColors.primary,
                        foregroundColor: isDark ? colorScheme.onPrimary : AppColors.onPrimary,
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                          Icon(
                            Icons.place,
                            size: 14,
                            color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'AREA: ',
                            style: AppTypography.labelUi.copyWith(
                              color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
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
                        metadata: _buildPlantItemMetadata(visiblePlants[i]),
                        healthStatus: visiblePlants[i].healthStatus,
                        metricsBar: visiblePlants[i].primaryDiagnosis != null &&
                                visiblePlants[i].healthStatus != PlantHealthStatus.healthy
                            ? _buildAlertBanner(
                                icon: Icons.warning_amber_rounded,
                                alertText: visiblePlants[i].primaryDiagnosis!,
                              )
                            : _buildDualMetricBar(
                                metric1Icon: Icons.water_drop,
                                metric1Label: 'Moisture',
                                metric1Value:
                                    '${visiblePlants[i].soilMoisturePercent.toStringAsFixed(0)}% (${visiblePlants[i].soilMoisturePercent < 25 ? "Too Dry" : "Good"})',
                                metric1IsError: visiblePlants[i].soilMoisturePercent < 25,
                                metric2Icon: Icons.thermostat,
                                metric2Label: 'Air Temp',
                                metric2Value: CalibratedTelemetry.formatTemp(visiblePlants[i].soilTemperatureCelsius, isCelsius: isCelsius),
                              ),
                        timeAgo: _formatTimeAgo(visiblePlants[i].lastScannedAt),
                        actionLabel: visiblePlants[i].healthStatus != PlantHealthStatus.healthy
                            ? 'Diagnostics'
                            : 'Plant Details',
                        actionRoute: () {
                          setState(() {
                            if (_selectedPlantId == visiblePlants[i].id) {
                              _isProfileExpanded = !_isProfileExpanded;
                            } else {
                              _selectedPlantId = visiblePlants[i].id;
                              _isProfileExpanded = true;
                            }
                          });
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
                        },
                        onTap: () {
                          setState(() {
                            if (_selectedPlantId == visiblePlants[i].id) {
                              _isProfileExpanded = !_isProfileExpanded;
                            } else {
                              _selectedPlantId = visiblePlants[i].id;
                              _isProfileExpanded = true;
                            }
                          });
                        },
                        onEdit: () => _openEditPlantDialog(visiblePlants[i]),
                        onDelete: () => _confirmDeletePlant(visiblePlants[i]),
                      ),
                      if (visiblePlants[i].id == _selectedPlantId) ...[
                        const SizedBox(height: 8),
                        _buildCropProfileDropdown(context, visiblePlants[i], isCelsius),
                      ],
                      if (i < visiblePlants.length - 1) const SizedBox(height: 10),
                    ],

                    if (visibleCount == 0)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                        decoration: BoxDecoration(
                          color: isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? colorScheme.outlineVariant.withValues(alpha: 0.25)
                                : AppColors.surfaceContainerHigh,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: (isDark ? colorScheme.primary : AppColors.primaryContainer).withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.yard_outlined,
                                size: 28,
                                color: isDark ? colorScheme.primary : AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              totalCount == 0 ? 'Your Garden is Empty' : 'No plants matching filter',
                              style: AppTypography.headlineSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              totalCount == 0
                                   ? 'Tap "+ Add Plant" above to register and monitor your first crop plot.'
                                   : 'Try selecting a different crop category or area filter.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
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
                                  backgroundColor: isDark ? colorScheme.primary : AppColors.primary,
                                  foregroundColor: isDark ? colorScheme.onPrimary : AppColors.onPrimary,
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
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildCropProfileDropdown(
    BuildContext context,
    PlantModel focalPlant,
    bool isCelsius,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final isCritical = focalPlant.healthStatus == PlantHealthStatus.critical;
    final isCaution = focalPlant.healthStatus == PlantHealthStatus.caution;
    final isHealthy = focalPlant.healthStatus == PlantHealthStatus.healthy;
    final hasHealthStress = isCritical || isCaution;

    // Diagnostic tasks (SSOT from SQLite via Riverpod)
    final tasksAsync = ref.watch(plantDiagnosticTasksNotifierProvider(focalPlant.id));
    final tasks = tasksAsync.value ?? const <DiagnosticTaskModel>[];
    final completedCount = tasks.where((t) => t.isCompleted).length;
    final totalCount = tasks.length;
    final taskProgress = totalCount > 0 ? (completedCount / totalCount).clamp(0.0, 1.0) : 0.0;

    return Container(
      key: _telemetrySectionKey,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasHealthStress
              ? (isCritical
                  ? (isDark ? colorScheme.error.withValues(alpha: 0.5) : AppColors.error.withValues(alpha: 0.4))
                  : (isDark ? colorScheme.tertiary.withValues(alpha: 0.5) : AppColors.tertiary.withValues(alpha: 0.4)))
              : (isDark
                  ? colorScheme.primary.withValues(alpha: 0.35)
                  : AppColors.primary.withValues(alpha: 0.3)),
          width: hasHealthStress ? 1.5 : 1.5,
        ),
        boxShadow: isDark
            ? const []
            : [
                BoxShadow(
                  color: hasHealthStress
                      ? (isCritical ? AppColors.error.withValues(alpha: 0.08) : AppColors.tertiary.withValues(alpha: 0.08))
                      : AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Interactive Dropdown Header Bar
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => setState(() => _isProfileExpanded = !_isProfileExpanded),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: hasHealthStress
                              ? (isCritical
                                  ? (isDark ? colorScheme.errorContainer.withValues(alpha: 0.35) : AppColors.errorContainer)
                                  : (isDark ? colorScheme.tertiaryContainer.withValues(alpha: 0.35) : AppColors.tertiaryContainer))
                              : (isDark ? colorScheme.primary : AppColors.primaryContainer).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          hasHealthStress ? Icons.biotech : Icons.spa_outlined,
                          size: 18,
                          color: hasHealthStress
                              ? (isCritical
                                  ? (isDark ? colorScheme.error : AppColors.error)
                                  : (isDark ? colorScheme.tertiary : AppColors.tertiary))
                              : (isDark ? colorScheme.primary : AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Active Crop Profile',
                              style: AppTypography.labelUi.copyWith(
                                color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                                fontSize: 10,
                                letterSpacing: 0.6,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _buildFocalPlantTitle(focalPlant),
                              style: AppTypography.headlineSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildHealthPill(focalPlant.healthStatus),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _isProfileExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 22,
                          color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Collapsible Dropdown Content Body (Merged Diagnosis + Tasks + Profile)
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: isDark
                        ? colorScheme.outlineVariant.withValues(alpha: 0.2)
                        : AppColors.outlineVariant.withValues(alpha: 0.35),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // If unhealthy: Integrated Diagnostic Protocol & Tasks (NO duplicate card)
                        if (hasHealthStress) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    size: 14,
                                    color: isCritical
                                        ? (isDark ? colorScheme.error : AppColors.error)
                                        : (isDark ? colorScheme.tertiary : AppColors.tertiary),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    isHealthy ? 'HEALTHY • TRIAGE COMPLETE' : 'ACTIVE DIAGNOSIS & PROTOCOL',
                                    style: AppTypography.labelUi.copyWith(
                                      color: isCritical
                                          ? (isDark ? colorScheme.error : AppColors.error)
                                          : (isCaution
                                              ? (isDark ? colorScheme.tertiary : AppColors.tertiary)
                                              : (isDark ? colorScheme.secondary : AppColors.secondary)),
                                      fontSize: 10,
                                      letterSpacing: 0.8,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isCritical
                                      ? (isDark ? colorScheme.errorContainer.withValues(alpha: 0.35) : AppColors.errorContainer)
                                      : (isDark ? colorScheme.tertiaryContainer.withValues(alpha: 0.35) : AppColors.tertiaryContainer),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  focalPlant.healthStatus.name.toUpperCase(),
                                  style: AppTypography.telemetrySmall.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: isCritical
                                        ? (isDark ? colorScheme.error : AppColors.onErrorContainer)
                                        : (isDark ? colorScheme.tertiary : AppColors.onTertiaryContainer),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            focalPlant.primaryDiagnosis ?? 'Detected Foliage Stress',
                            style: AppTypography.headlineSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TRIAGE CHECKLIST',
                                style: AppTypography.labelUi.copyWith(
                                  color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                                  fontSize: 10,
                                  letterSpacing: 0.8,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (totalCount > 0)
                                Text(
                                  '$completedCount of $totalCount Done',
                                  style: AppTypography.telemetrySmall.copyWith(
                                    fontSize: 10,
                                    color: completedCount == totalCount && totalCount > 0
                                        ? (isDark ? colorScheme.secondary : AppColors.secondary)
                                        : (isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant),
                                  ),
                                ),
                            ],
                          ),
                          if (totalCount > 0) ...[
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: taskProgress,
                                minHeight: 4,
                                backgroundColor: isDark
                                    ? colorScheme.surfaceContainerHighest
                                    : AppColors.surfaceContainerHigh,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  taskProgress == 1.0
                                      ? (isDark ? colorScheme.secondary : AppColors.secondary)
                                      : (isCritical
                                          ? (isDark ? colorScheme.error : AppColors.error)
                                          : (isDark ? colorScheme.tertiary : AppColors.tertiary)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Interactive Care Task Checklist Tiles
                            for (final task in tasks) ...[
                              _buildTaskChecklistTile(focalPlant.id, task),
                              const SizedBox(height: 6),
                            ],
                          ],
                          const SizedBox(height: 10),
                        ],

                        // Notes (if grower added notes)
                        if (focalPlant.notes.isNotEmpty) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.note_outlined,
                                size: 14,
                                color: isDark ? colorScheme.outline : AppColors.outline,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  focalPlant.notes,
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],

                        // Reading timestamp
                        Text(
                          'Last updated: ${_formatReadingTimestamp(focalPlant.lastScannedAt)}',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 11,
                            color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Actions: Rule of One (1 Primary CTA, secondary actions demoted)
                        Row(
                          children: [
                            if (hasHealthStress) ...[
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
                                          backgroundColor: isDark ? colorScheme.secondary : AppColors.secondary,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.check_circle, size: 16),
                                  label: const Text('Recovered'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark ? colorScheme.secondary : AppColors.secondaryFixed,
                                    foregroundColor: isDark ? const Color(0xFF002114) : AppColors.onSecondaryFixed,
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: FilledButton.icon(
                                icon: const Icon(Icons.camera_alt_outlined, size: 16),
                                label: const Text('Diagnose Leaf'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: isDark ? colorScheme.primary : AppColors.primary,
                                  foregroundColor: isDark ? colorScheme.onPrimary : AppColors.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                                onPressed: () => context.go(AppRoutes.scan),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: const Text('Edit'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark ? colorScheme.onSurface : AppColors.onSurface,
                                side: BorderSide(
                                  color: isDark
                                      ? colorScheme.outlineVariant.withValues(alpha: 0.5)
                                      : AppColors.outlineVariant,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                              onPressed: () => _openEditPlantDialog(focalPlant),
                            ),
                            const SizedBox(width: 4),
                            Tooltip(
                              message: 'Delete plot',
                              child: IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: isDark ? colorScheme.error : AppColors.error,
                                ),
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                                onPressed: () => _confirmDeletePlant(focalPlant),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              crossFadeState: _isProfileExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
            ),
          ],
        ),
      );
    }

  Widget _buildCropChip(String key, String label, IconData? icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedCropFilter == key;

    return InkWell(
      onTap: () => setState(() => _selectedCropFilter = key),
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? colorScheme.primary : AppColors.primary)
              : (isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: isSelected
                ? (isDark ? colorScheme.primary : AppColors.primary)
                : (isDark
                    ? colorScheme.outlineVariant.withValues(alpha: 0.3)
                    : AppColors.outlineVariant.withValues(alpha: 0.3)),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? (isDark ? colorScheme.onPrimary : AppColors.onPrimary)
                    : (isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: AppTypography.labelUi.copyWith(
                color: isSelected
                    ? (isDark ? colorScheme.onPrimary : AppColors.onPrimary)
                    : (isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedAreaFilter == key;

    return InkWell(
      onTap: () => setState(() => _selectedAreaFilter = key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? colorScheme.surfaceContainerHighest : AppColors.surfaceContainerHigh)
              : (isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (isDark ? colorScheme.primary : AppColors.primary)
                : (isDark
                    ? colorScheme.outlineVariant.withValues(alpha: 0.25)
                    : AppColors.outlineVariant.withValues(alpha: 0.25)),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isSelected
                ? (isDark ? colorScheme.onSurface : AppColors.onSurface)
                : (isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant),
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
    required String metadata,
    required PlantHealthStatus healthStatus,
    required Widget metricsBar,
    required String timeAgo,
    required String actionLabel,
    required VoidCallback actionRoute,
    VoidCallback? onTap,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedPlantId == id;
    final isError = healthStatus != PlantHealthStatus.healthy;

    return InkWell(
      onTap: onTap ??
          () {
            setState(() {
              if (_selectedPlantId == id) {
                _isProfileExpanded = !_isProfileExpanded;
              } else {
                _selectedPlantId = id;
                _isProfileExpanded = true;
              }
            });
          },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (isDark ? colorScheme.primary : AppColors.primary)
                : (isDark ? colorScheme.outlineVariant.withValues(alpha: 0.25) : Colors.transparent),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isDark
              ? const []
              : [
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
                                fontSize: 15,
                                color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                                letterSpacing: -0.2,
                              ),
                              softWrap: true,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _buildHealthPill(healthStatus),
                          if (onEdit != null || onDelete != null) ...[
                            const SizedBox(width: 2),
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert,
                                size: 16,
                                color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                              ),
                              color: isDark ? colorScheme.surfaceContainerHigh : null,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onSelected: (val) {
                                if (val == 'edit' && onEdit != null) onEdit();
                                if (val == 'delete' && onDelete != null) onDelete();
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit,
                                        size: 16,
                                        color: isDark ? colorScheme.primary : AppColors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Edit Plot',
                                        style: TextStyle(
                                          color: isDark ? colorScheme.onSurface : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        size: 16,
                                        color: isDark ? colorScheme.error : AppColors.error,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Delete Plot',
                                        style: TextStyle(
                                          color: isDark ? colorScheme.error : AppColors.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 12,
                            color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              metadata,
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              softWrap: true,
                            ),
                          ),
                        ],
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
                      Icon(
                        Icons.schedule,
                        size: 12,
                        color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          timeAgo,
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
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
                              color: isError
                                  ? (isDark ? colorScheme.error : AppColors.error)
                                  : (isDark ? colorScheme.primary : AppColors.primary),
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
                          color: isError
                              ? (isDark ? colorScheme.error : AppColors.error)
                              : (isDark ? colorScheme.primary : AppColors.primary),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainer : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? colorScheme.outlineVariant.withValues(alpha: 0.25)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  metric1Icon,
                  size: 15,
                  color: metric1IsError
                      ? (isDark ? colorScheme.error : AppColors.error)
                      : (isDark ? colorScheme.secondary : AppColors.secondary),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        metric1Label,
                        style: AppTypography.labelUi.copyWith(
                          fontSize: 9,
                          color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        metric1Value,
                        style: AppTypography.telemetrySmall.copyWith(
                          fontSize: 11,
                          fontWeight: metric1IsError ? FontWeight.w700 : FontWeight.w600,
                          color: metric1IsError
                              ? (isDark ? colorScheme.error : AppColors.error)
                              : (isDark ? colorScheme.onSurface : AppColors.onSurface),
                          fontFeatures: const [FontFeature.tabularFigures()],
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
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Icon(
                  metric2Icon,
                  size: 15,
                  color: isDark ? colorScheme.secondary : AppColors.secondary,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        metric2Label,
                        style: AppTypography.labelUi.copyWith(
                          fontSize: 9,
                          color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        metric2Value,
                        style: AppTypography.telemetrySmall.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                          fontFeatures: const [FontFeature.tabularFigures()],
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.errorContainer.withValues(alpha: 0.3)
            : AppColors.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? colorScheme.error.withValues(alpha: 0.35)
              : Colors.transparent,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              icon,
              size: 15,
              color: isDark ? colorScheme.error : AppColors.error,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              alertText,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? colorScheme.error : AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskChecklistTile(String plantId, DiagnosticTaskModel task) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

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
                activeColor: isDark ? colorScheme.primary : AppColors.primary,
                checkColor: isDark ? colorScheme.onPrimary : AppColors.onPrimary,
                side: isDark ? BorderSide(color: colorScheme.outlineVariant) : null,
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
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: task.tier == 1
                              ? (isDark
                                  ? colorScheme.errorContainer.withValues(alpha: 0.35)
                                  : AppColors.errorContainer.withValues(alpha: 0.6))
                              : (isDark
                                  ? colorScheme.secondaryContainer.withValues(alpha: 0.35)
                                  : AppColors.secondaryContainer.withValues(alpha: 0.6)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          task.tier == 1 ? 'Tier 1 • Urgent' : 'Tier 2 • Care',
                          style: AppTypography.labelUi.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: task.tier == 1
                                ? (isDark ? colorScheme.error : AppColors.onErrorContainer)
                                : (isDark ? colorScheme.secondary : AppColors.onSecondaryContainer),
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
                            color: task.isCompleted
                                ? (isDark ? colorScheme.onSurfaceVariant.withValues(alpha: 0.6) : AppColors.onSurfaceVariant)
                                : (isDark ? colorScheme.onSurface : AppColors.onSurface),
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
                        fontSize: 11,
                        color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
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
