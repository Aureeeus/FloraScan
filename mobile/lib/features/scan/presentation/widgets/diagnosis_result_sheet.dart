import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/sproutly_mascot.dart';
import '../../../plants/domain/entities/plant_model.dart';
import '../../../plants/presentation/providers/diagnostic_task_providers.dart';
import '../../../plants/presentation/providers/plant_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../../core/ble/flora_wand_ble_service.dart';
import '../../domain/entities/diagnostic_scan_model.dart';

/// Modal bottom sheet or full-view diagnostic report strictly mimicking Google Stitch.
class DiagnosisResultSheet extends ConsumerStatefulWidget {
  const DiagnosisResultSheet({
    required this.result,
    required this.onDismiss,
    super.key,
  });

  final DiagnosticScanResult result;
  final VoidCallback onDismiss;

  @override
  ConsumerState<DiagnosisResultSheet> createState() => _DiagnosisResultSheetState();
}

class _DiagnosisResultSheetState extends ConsumerState<DiagnosisResultSheet> {
  // Checkbox states for Tier 1 action items
  bool _step1Checked = false;
  bool _step2Checked = false;
  bool _step3Checked = false;

  // Accordion toggle states for "Why?" explanations
  bool _showWhyMoisture = false;
  bool _showWhyTemp = false;
  bool _showWhyHumidity = false;
  bool _showWhyLight = false;

  PlantModel? _selectedPlant;

  String _resolveCrop(PlantModel plant) {
    final lowerName = plant.name.toLowerCase();
    final lowerVariety = plant.variety.toLowerCase();
    final lowerFamily = plant.cropFamily.toLowerCase();
    if (lowerName.contains('tomato') || lowerVariety.contains('tomato') || lowerFamily.contains('tomato') || lowerVariety.contains('lycopersicum')) {
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

  String _resolveTargetCrop(String rawCrop) {
    final lower = rawCrop.toLowerCase();
    if (lower.contains('chili') || lower.contains('pepper')) return 'Chili';
    if (lower.contains('eggplant') || lower.contains('aubergine')) return 'Eggplant';
    return 'Tomato';
  }

  String _resolveMasterVerdictTitle(DiagnosticScanResult result, CalibratedTelemetry telemetry) {
    if (result.detectedCondition.contains('&') ||
        telemetry.isMoistureWarning ||
        telemetry.isTemperatureWarning ||
        telemetry.isHumidityWarning) {
      return 'Dual Issue: Disease & Environment Problem';
    }
    if (result.severity == DiagnosticSeverity.healthy) {
      return 'Healthy Canopy: Optimal Conditions';
    }
    return 'Foliar Pathology Detected';
  }

  String _resolveMasterVerdictDescription(
    DiagnosticScanResult result,
    CalibratedTelemetry telemetry,
    PlantModel? plant, {
    bool isCelsius = true,
  }) {
    final cropName = plant?.name ?? (result.targetCrop.isNotEmpty ? result.targetCrop : 'plant');
    final condition = result.detectedCondition;
    final tempStr = telemetry.formatTemperature(isCelsius: isCelsius);

    if (result.severity == DiagnosticSeverity.healthy) {
      return 'Your $cropName foliage is clean, turgid, and pathogen-free. Surrounding root-zone moisture (${telemetry.formattedMoisture}) and climate ($tempStr) are optimal.';
    }

    if (telemetry.soilMoisturePercent > 70) {
      return 'Your $cropName leaf has symptoms of $condition. At the same time, your soil is currently too wet (${telemetry.formattedMoisture}), which encourages fungal spores to multiply and spread quickly.';
    } else if (telemetry.soilMoisturePercent < 25 && telemetry.isProbeInserted) {
      return 'Your $cropName leaf shows symptoms of $condition under acute drought stress (${telemetry.formattedMoisture} moisture), weakening foliar defenses.';
    } else if (telemetry.isTemperatureWarning) {
      return 'Your $cropName leaf shows symptoms of $condition exacerbated by thermal stress ($tempStr, ${telemetry.temperatureTag}).';
    } else if (telemetry.isHumidityWarning) {
      return 'Your $cropName leaf has symptoms of $condition. Ambient humidity is stagnant (${telemetry.formattedHumidity}), prolonging leaf surface wetness.';
    }

    return 'Your $cropName leaf shows symptoms of $condition (${result.scientificPathogen}). Surrounding root-zone telemetry is within stable agronomic thresholds.';
  }

  void _openPlantPickerSheet(BuildContext context, List<PlantModel> plants) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return _PlantSearchPickerSheet(
          plants: plants,
          initialCropFilter: _resolveTargetCrop(widget.result.targetCrop),
          currentSelectedPlantId: _selectedPlant?.id,
          onPlantSelected: (plant) {
            setState(() {
              _selectedPlant = plant;
            });
            Navigator.of(modalCtx).pop();
          },
        );
      },
    );
  }

  Color _confidenceBgColor(double confidence) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    if (confidence >= 85.0) {
      return isDark
          ? colorScheme.secondaryContainer.withValues(alpha: 0.35)
          : AppColors.secondaryContainer;
    } else if (confidence >= 70.0) {
      return isDark
          ? colorScheme.surfaceContainerHigh
          : AppColors.surfaceContainerHigh;
    } else {
      return isDark
          ? colorScheme.errorContainer.withValues(alpha: 0.35)
          : AppColors.errorContainer;
    }
  }

  Color _confidenceTextColor(double confidence) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    if (confidence >= 85.0) {
      return isDark
          ? colorScheme.secondary
          : AppColors.secondary;
    } else if (confidence >= 70.0) {
      return isDark
          ? colorScheme.onSurface
          : AppColors.onSurface;
    } else {
      return isDark
          ? colorScheme.error
          : AppColors.onErrorContainer;
    }
  }

  bool _hasValidLocalImage(String? path) {
    if (path == null || path.isEmpty) return false;
    if (kIsWeb) return false;
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }

  bool get _isTestEnvironment {
    if (kIsWeb) return false;
    return Platform.environment.containsKey('FLUTTER_TEST');
  }

  static const Map<String, String> _pathologyReferenceMap = {
    'early blight': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ae/Alternaria_solani_early_blight_on_tomato.jpg/640px-Alternaria_solani_early_blight_on_tomato.jpg',
    'late blight': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d1/Phytophthora_infestans_tomato.jpg/640px-Phytophthora_infestans_tomato.jpg',
    'septoria': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Septoria_lycopersici_spots.jpg/640px-Septoria_lycopersici_spots.jpg',
    'yellow leaf curl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/44/Tomato_yellow_leaf_curl_virus.jpg/640px-Tomato_yellow_leaf_curl_virus.jpg',
    'leaf mold': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3b/Passalora_fulva_tomato_leaf_mold.jpg/640px-Passalora_fulva_tomato_leaf_mold.jpg',
    'anthracnose': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/07/Colletotrichum_capsici_on_pepper.jpg/640px-Colletotrichum_capsici_on_pepper.jpg',
    'bacterial spot': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Xanthomonas_campestris_pepper_leaf.jpg/640px-Xanthomonas_campestris_pepper_leaf.jpg',
    'cercospora': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f8/Cercospora_capsici_frogeye_spot.jpg/640px-Cercospora_capsici_frogeye_spot.jpg',
    'frogeye': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f8/Cercospora_capsici_frogeye_spot.jpg/640px-Cercospora_capsici_frogeye_spot.jpg',
    'curl virus': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/19/Chili_leaf_curl_virus_symptoms.jpg/640px-Chili_leaf_curl_virus_symptoms.jpg',
    'mosaic': 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/52/Tobacco_mosaic_virus_symptoms_leaf.jpg/640px-Tobacco_mosaic_virus_symptoms_leaf.jpg',
    'white mold': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/70/Sclerotinia_sclerotiorum_stem_rot.jpg/640px-Sclerotinia_sclerotiorum_stem_rot.jpg',
    'wilt': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/75/Ralstonia_solanacearum_wilt.jpg/640px-Ralstonia_solanacearum_wilt.jpg',
    'little leaf': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Phytoplasma_little_leaf.jpg/640px-Phytoplasma_little_leaf.jpg',
    'pest': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/af/Flea_beetle_damage_leaf.jpg/640px-Flea_beetle_damage_leaf.jpg',
    'chlorosis': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b3/Leaf_chlorosis_iron_deficiency.jpg/640px-Leaf_chlorosis_iron_deficiency.jpg',
    'deficiency': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b3/Leaf_chlorosis_iron_deficiency.jpg/640px-Leaf_chlorosis_iron_deficiency.jpg',
    'healthy': 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5a/Healthy_tomato_plant_leaves.jpg/640px-Healthy_tomato_plant_leaves.jpg',
  };

  String _resolvePathologyReferenceUrl(String condition) {
    final lower = condition.toLowerCase();
    for (final entry in _pathologyReferenceMap.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ae/Alternaria_solani_early_blight_on_tomato.jpg/640px-Alternaria_solani_early_blight_on_tomato.jpg';
  }

  /// Resolves the bundled offline reference image from the trained dataset.
  String _resolvePathologyReferenceAsset(String condition, String crop) {
    final lowerCond = condition.toLowerCase();
    final lowerCrop = crop.toLowerCase();

    // 1. Chili pathology classes
    if (lowerCrop.contains('chili') || lowerCrop.contains('pepper')) {
      if (lowerCond.contains('anthracnose')) return 'assets/pathology_reference/chili_anthracnose.jpg';
      if (lowerCond.contains('bacterial')) return 'assets/pathology_reference/chili_bacterial_spot.jpg';
      if (lowerCond.contains('cercospora') || lowerCond.contains('frogeye')) {
        return 'assets/pathology_reference/chili_cercospora_leaf_spot.jpg';
      }
      if (lowerCond.contains('curl')) return 'assets/pathology_reference/chili_curl_virus.jpg';
      if (lowerCond.contains('deficiency') || lowerCond.contains('nutrition') || lowerCond.contains('chlorosis')) {
        return 'assets/pathology_reference/chili_nutrition_deficiency.jpg';
      }
      if (lowerCond.contains('white spot')) return 'assets/pathology_reference/chili_white_spot.jpg';
      if (lowerCond.contains('healthy')) return 'assets/pathology_reference/chili_healthy.jpg';
    }

    // 2. Eggplant pathology classes
    if (lowerCrop.contains('eggplant') || lowerCrop.contains('aubergine')) {
      if (lowerCond.contains('pest') || lowerCond.contains('insect') || lowerCond.contains('flea')) {
        return 'assets/pathology_reference/eggplant_insect_pest.jpg';
      }
      if (lowerCond.contains('leaf spot') || lowerCond.contains('cercospora') || lowerCond.contains('spot')) {
        return 'assets/pathology_reference/eggplant_leaf_spot.jpg';
      }
      if (lowerCond.contains('mosaic')) return 'assets/pathology_reference/eggplant_mosaic_virus.jpg';
      if (lowerCond.contains('small') || lowerCond.contains('little')) {
        return 'assets/pathology_reference/eggplant_small_leaf.jpg';
      }
      if (lowerCond.contains('white mold') || lowerCond.contains('mold')) {
        return 'assets/pathology_reference/eggplant_white_mold.jpg';
      }
      if (lowerCond.contains('wilt')) return 'assets/pathology_reference/eggplant_wilt.jpg';
      if (lowerCond.contains('healthy')) return 'assets/pathology_reference/eggplant_healthy.jpg';
    }

    // 3. Tomato pathology classes
    if (lowerCond.contains('early blight')) return 'assets/pathology_reference/tomato_early_blight.jpg';
    if (lowerCond.contains('late blight')) return 'assets/pathology_reference/tomato_late_blight.jpg';
    if (lowerCond.contains('septoria')) return 'assets/pathology_reference/tomato_septoria_leaf_spot.jpg';
    if (lowerCond.contains('curl') || lowerCond.contains('tylcv')) {
      return 'assets/pathology_reference/tomato_yellow_leaf_curl.jpg';
    }
    if (lowerCond.contains('mold')) return 'assets/pathology_reference/tomato_mold_leaf.jpg';
    if (lowerCond.contains('healthy')) return 'assets/pathology_reference/tomato_healthy.jpg';

    // 4. Cross-crop fallback by pathology keyword
    if (lowerCond.contains('anthracnose')) return 'assets/pathology_reference/chili_anthracnose.jpg';
    if (lowerCond.contains('bacterial')) return 'assets/pathology_reference/chili_bacterial_spot.jpg';
    if (lowerCond.contains('cercospora') || lowerCond.contains('frogeye')) {
      return 'assets/pathology_reference/chili_cercospora_leaf_spot.jpg';
    }
    if (lowerCond.contains('mosaic')) return 'assets/pathology_reference/eggplant_mosaic_virus.jpg';
    if (lowerCond.contains('pest') || lowerCond.contains('insect')) {
      return 'assets/pathology_reference/eggplant_insect_pest.jpg';
    }
    if (lowerCond.contains('wilt')) return 'assets/pathology_reference/eggplant_wilt.jpg';
    if (lowerCond.contains('white mold')) return 'assets/pathology_reference/eggplant_white_mold.jpg';
    if (lowerCond.contains('deficiency') || lowerCond.contains('chlorosis')) {
      return 'assets/pathology_reference/chili_nutrition_deficiency.jpg';
    }
    if (lowerCond.contains('white spot')) return 'assets/pathology_reference/chili_white_spot.jpg';

    return 'assets/pathology_reference/tomato_early_blight.jpg';
  }

  Widget _buildViewfinderCorners() {
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white70, width: 1.5),
                    left: BorderSide(color: Colors.white70, width: 1.5),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white70, width: 1.5),
                    right: BorderSide(color: Colors.white70, width: 1.5),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white70, width: 1.5),
                    left: BorderSide(color: Colors.white70, width: 1.5),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white70, width: 1.5),
                    right: BorderSide(color: Colors.white70, width: 1.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapturedLeafFrame() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final imagePath = widget.result.capturedImagePath;
    final hasLocal = _hasValidLocalImage(imagePath);
    final isAsset = imagePath != null && imagePath.startsWith('assets/');

    Widget content;
    if (hasLocal) {
      content = Image.file(
        File(imagePath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => _buildCapturedLeafFallback(),
      );
    } else if (isAsset) {
      content = Image.asset(
        imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => _buildCapturedLeafFallback(),
      );
    } else {
      content = _buildCapturedLeafFallback();
    }

    return Container(
      height: 108,
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHigh
            : AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? colorScheme.outlineVariant.withValues(alpha: 0.35)
              : AppColors.outlineVariant.withValues(alpha: 0.8),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.5),
        child: Stack(
          fit: StackFit.expand,
          children: [
            content,
            _buildViewfinderCorners(),
            Positioned(
              bottom: 5,
              left: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Captured Frame',
                      style: AppTypography.labelUi.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapturedLeafFallback() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    return Container(
      color: isDark
          ? colorScheme.surfaceContainerHighest
          : const Color(0xFF1E293B),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.center_focus_strong,
              size: 34,
              color: isDark
                  ? colorScheme.secondary
                  : AppColors.secondary.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 3),
            Text(
              'Optical Scout',
              style: AppTypography.labelUi.copyWith(
                color: Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosedIllnessPicture() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final condition = widget.result.detectedCondition.split('&').first.trim();
    final assetPath = _resolvePathologyReferenceAsset(condition, widget.result.targetCrop);

    Widget content;
    if (_isTestEnvironment) {
      content = _buildPathologyFallback(condition);
    } else {
      content = Image.asset(
        assetPath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) {
          final url = _resolvePathologyReferenceUrl(condition);
          return Image.network(
            url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, _, _) => _buildPathologyFallback(condition),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildPathologyFallback(condition);
            },
          );
        },
      );
    }

    return Container(
      height: 108,
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHigh
            : AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? colorScheme.secondary.withValues(alpha: 0.35)
              : AppColors.secondary.withValues(alpha: 0.45),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.5),
        child: Stack(
          fit: StackFit.expand,
          children: [
            content,
            Positioned(
              bottom: 5,
              left: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark
                            ? colorScheme.secondary
                            : AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Pathology Reference',
                      style: AppTypography.labelUi.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPathologyFallback(String condition) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    return Container(
      color: isDark
          ? colorScheme.surfaceContainerHighest
          : const Color(0xFF0F2E22),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.biotech,
              size: 34,
              color: isDark
                  ? colorScheme.secondary
                  : AppColors.secondary,
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                condition,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelUi.copyWith(
                  color: Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final plantsAsync = ref.watch(plantListNotifierProvider);
    final wandState = ref.watch(floraWandNotifierProvider);
    final isCelsius = ref.watch(isCelsiusMetricProvider);
    final telemetry = wandState.telemetry;
    final allPlants = plantsAsync.value ?? const <PlantModel>[];

    final targetCropCategory = _resolveTargetCrop(widget.result.targetCrop);
    final PlantModel? activePlant = (_selectedPlant != null && allPlants.any((p) => p.id == _selectedPlant!.id))
        ? allPlants.firstWhere((p) => p.id == _selectedPlant!.id)
        : (allPlants.isNotEmpty
            ? allPlants.firstWhere(
                (p) => _resolveCrop(p).toLowerCase() == targetCropCategory.toLowerCase(),
                orElse: () => allPlants.first,
              )
            : null);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerLow : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: isDark
            ? Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.25),
                  width: 1,
                ),
              )
            : null,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.outlineVariant.withValues(alpha: 0.6)
                      : AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Top Status Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? colorScheme.surfaceContainer : AppColors.surfaceContainerLow,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      wandState.isConnected ? 'IoT Wand Linked' : 'IoT Wand Offline',
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelUi.copyWith(
                        color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? colorScheme.surfaceContainerHigh : AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          size: 11,
                          color: isDark ? colorScheme.primary : AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Scan Verified',
                          style: AppTypography.labelUi.copyWith(
                            color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Crop Identity Badge
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(14),
                        border: isDark
                            ? Border.all(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.25),
                              )
                            : null,
                        boxShadow: isDark
                            ? null
                            : const [
                                BoxShadow(
                                  color: Color(0x06000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 1),
                                ),
                              ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isDark ? colorScheme.surfaceContainerHigh : AppColors.surfaceContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.yard,
                                    color: isDark ? colorScheme.primary : AppColors.primary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'CROP CONFIRMED',
                                            style: AppTypography.labelUi.copyWith(
                                              color: isDark ? colorScheme.secondary : AppColors.secondary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 9,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.verified,
                                            size: 13,
                                            color: isDark ? colorScheme.secondary : AppColors.secondary,
                                          ),
                                        ],
                                      ),
                                      Text(
                                        activePlant != null
                                            ? '${activePlant.name}, ${activePlant.variety}'
                                            : (widget.result.targetCrop.isNotEmpty
                                                ? widget.result.targetCrop
                                                : 'Roma Tomato, Balcony Pot'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.headlineSmall.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.tune,
                              color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 2. Master Unified Verdict Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: isDark
                            ? Border.all(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.25),
                              )
                            : null,
                        boxShadow: isDark
                            ? null
                            : const [
                                BoxShadow(
                                  color: Color(0x0A000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? colorScheme.errorContainer.withValues(alpha: 0.35)
                                        : AppColors.errorContainer,
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.warning,
                                        size: 13,
                                        color: isDark ? colorScheme.error : AppColors.onErrorContainer,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'Dual Action Required',
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.labelUi.copyWith(
                                            color: isDark ? colorScheme.error : AppColors.onErrorContainer,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _confidenceBgColor(widget.result.confidencePercentage),
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.auto_awesome,
                                        size: 11,
                                        color: _confidenceTextColor(widget.result.confidencePercentage),
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          '${widget.result.confidencePercentage.toStringAsFixed(1)}% AI Confidence',
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.telemetrySmall.copyWith(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: _confidenceTextColor(widget.result.confidencePercentage),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _resolveMasterVerdictTitle(widget.result, telemetry),
                            style: AppTypography.headlineSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _resolveMasterVerdictDescription(widget.result, telemetry, activePlant, isCelsius: isCelsius),
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Mascot encouragement
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? colorScheme.surfaceContainer : AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                SproutlyMascot(
                                  size: 46,
                                  badgeEmoji: '🌿',
                                  badgeColor: isDark ? colorScheme.primary : AppColors.secondary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '"Don\'t worry, we caught it early!"',
                                        style: AppTypography.headlineSmall.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: isDark ? colorScheme.primary : AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Follow the 3 quick steps below to keep your balcony Roma thriving.',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 3. Side-by-Side Visual Comparison
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Optical Evidence',
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.headlineSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Reticle Analysis',
                          style: AppTypography.labelUi.copyWith(
                            color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Captured Leaf Frame
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                              border: isDark
                                  ? Border.all(
                                      color: colorScheme.outlineVariant.withValues(alpha: 0.25),
                                    )
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCapturedLeafFrame(),
                                const SizedBox(height: 7),
                                Text(
                                  'Your Captured Leaf',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.result.symptoms.isNotEmpty
                                      ? widget.result.symptoms.first
                                      : 'Visual inspection frame',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 10,
                                    color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Right: Visual Picture of Diagnosed Illness
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                              border: isDark
                                  ? Border.all(
                                      color: colorScheme.outlineVariant.withValues(alpha: 0.25),
                                    )
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDiagnosedIllnessPicture(),
                                const SizedBox(height: 7),
                                Text(
                                  widget.result.detectedCondition.split('&').first.trim(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.result.scientificPathogen,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 10,
                                    fontStyle: FontStyle.italic,
                                    color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 4. Surroundings Telemetry: 4 Wand Sensors
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "What Your Plant's Surroundings Say",
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.headlineSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                                ),
                              ),
                              Text(
                                wandState.isConnected
                                    ? 'Live ${wandState.deviceName} probe telemetry'
                                    : 'Real-time Bluetooth probe telemetry',
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (wandState.isConnected) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? colorScheme.secondaryContainer.withValues(alpha: 0.35)
                                      : AppColors.secondaryContainer,
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Text(
                                  '${telemetry.batteryPercent}% PWR',
                                  style: AppTypography.labelUi.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? colorScheme.secondary
                                        : AppColors.onSecondaryContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Icon(
                              Icons.sensors,
                              color: wandState.isConnected
                                  ? (isDark ? colorScheme.secondary : AppColors.secondary)
                                  : (isDark ? colorScheme.outline : AppColors.outline),
                              size: 20,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Sensor 1: Soil Moisture
                    _buildWandSensorCard(
                      title: 'Soil Moisture',
                      icon: Icons.water_drop,
                      value: telemetry.formattedMoisture,
                      target: 'Target: 50–70%',
                      statusTag: telemetry.soilMoistureTag,
                      isError: telemetry.isMoistureWarning,
                      summary: !telemetry.isProbeInserted
                          ? 'Probe blades in open air. Insert into soil.'
                          : telemetry.soilMoisturePercent > 70
                              ? 'Roots are staying waterlogged.'
                              : telemetry.soilMoisturePercent < 50
                                  ? 'Soil is dry; roots need hydration.'
                                  : 'Optimal root-zone moisture level.',
                      isExpanded: _showWhyMoisture,
                      onToggleWhy: () => setState(() => _showWhyMoisture = !_showWhyMoisture),
                      whyText:
                          'Why Soil Moisture Matters: Proper root zone moisture (${telemetry.formattedMoisture}) ensures ${activePlant?.name ?? targetCropCategory} roots absorb vital minerals without waterlogging that favors soil-borne blight pathogens.',
                    ),
                    const SizedBox(height: 8),

                    // Sensor 2: Air Temperature
                    _buildWandSensorCard(
                      title: 'Air Temperature',
                      icon: Icons.thermostat,
                      value: telemetry.formatTemperature(isCelsius: isCelsius),
                      target: isCelsius ? 'Target: 20–30°C' : 'Target: 68–86°F',
                      statusTag: telemetry.temperatureTag,
                      isError: telemetry.isTemperatureWarning,
                      summary: telemetry.temperatureCelsius > 32
                          ? 'Heat stress elevates foliar transpiration.'
                          : telemetry.temperatureCelsius < 18
                              ? 'Cool temperatures slow down nutrient uptake.'
                              : 'Comfortable growth temp.',
                      isExpanded: _showWhyTemp,
                      onToggleWhy: () => setState(() => _showWhyTemp = !_showWhyTemp),
                      whyText:
                          'Why Temperature Matters: ${activePlant?.name ?? targetCropCategory} plants metabolize carbohydrates efficiently between ${isCelsius ? "20°C and 30°C" : "68°F and 86°F"}. Current reading of ${telemetry.formatTemperature(isCelsius: isCelsius)} (${telemetry.temperatureTag}) directly impacts cellular repair during foliar defense.',
                    ),
                    const SizedBox(height: 8),

                    // Sensor 3: Humidity
                    _buildWandSensorCard(
                      title: 'Humidity',
                      icon: Icons.cloud,
                      value: telemetry.formattedHumidity,
                      target: 'Target: 50–75%',
                      statusTag: telemetry.humidityTag,
                      isError: telemetry.isHumidityWarning,
                      summary: telemetry.humidityPercent > 75
                          ? 'Damp air traps mold spores.'
                          : telemetry.humidityPercent < 45
                              ? 'Arid air accelerates leaf desiccation.'
                              : 'Healthy ambient relative humidity.',
                      isExpanded: _showWhyHumidity,
                      onToggleWhy: () => setState(() => _showWhyHumidity = !_showWhyHumidity),
                      whyText:
                          'Why Humidity Matters: Ambient humidity (${telemetry.formattedHumidity}) above 75% keeps water drops lingering on ${activePlant?.name ?? targetCropCategory} leaves, acting as a germination incubator for fungal pathogens.',
                    ),
                    const SizedBox(height: 8),

                    // Sensor 4: Light
                    _buildWandSensorCard(
                      title: 'Light',
                      icon: Icons.wb_sunny,
                      value: telemetry.formattedLight,
                      target: 'Target: 30k–60k Lux',
                      statusTag: telemetry.lightTag,
                      isError: telemetry.isLightWarning,
                      summary: telemetry.lightLux > 60000
                          ? 'Direct solar intensity is scorching leaves.'
                          : telemetry.lightLux < 10000
                              ? 'Insufficient light slows photosynthesis.'
                              : 'Plenty of natural sunlight.',
                      isExpanded: _showWhyLight,
                      onToggleWhy: () => setState(() => _showWhyLight = !_showWhyLight),
                      whyText:
                          'Why Light Matters: Solar illuminance (${telemetry.formattedLight}) boosts cuticle thickness on ${activePlant?.name ?? targetCropCategory} foliage, preventing spore penetrations and maintaining defensive vigor.',
                    ),

                    const SizedBox(height: 18),

                    // 5. Prioritized Action Plan
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'What to Do Now',
                                style: AppTypography.headlineSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                                ),
                              ),
                              Text(
                                'Prioritized checklist in strict order',
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.checklist,
                          color: isDark ? colorScheme.primary : AppColors.primary,
                          size: 22,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Priority Tier 1: Simple Fixes First
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(14),
                        border: isDark
                            ? Border.all(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.25),
                              )
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? colorScheme.primary : AppColors.primary,
                                ),
                                child: Center(
                                  child: Text(
                                    '1',
                                    style: AppTypography.labelUi.copyWith(
                                      color: isDark ? colorScheme.onPrimary : AppColors.onPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Simple Fixes First',
                                  style: AppTypography.headlineSmall.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? colorScheme.primary : AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildChecklistItem(
                            value: _step1Checked,
                            title: 'Stop watering for 2 days until top 2 inches of soil feel dry.',
                            subtitle: 'Check topsoil with your fingertip or wand depth probe.',
                            onChanged: (val) => setState(() => _step1Checked = val ?? false),
                          ),
                          _buildChecklistItem(
                            value: _step2Checked,
                            title: 'Snip off the 3 yellowing bottom leaves with clean scissors and throw in trash (do not compost).',
                            subtitle: 'Wipe scissors with rubbing alcohol after cutting.',
                            onChanged: (val) => setState(() => _step2Checked = val ?? false),
                          ),
                          _buildChecklistItem(
                            value: _step3Checked,
                            title: 'Move pot 1 foot away from the wall for better breeze.',
                            subtitle: 'Breaks up balcony air stagnation and lowers micro-humidity.',
                            onChanged: (val) => setState(() => _step3Checked = val ?? false),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Priority Tier 2: Eco-Friendly Options
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(14),
                        border: isDark
                            ? Border.all(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.25),
                              )
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? colorScheme.secondary : AppColors.secondary,
                                ),
                                child: Center(
                                  child: Text(
                                    '2',
                                    style: AppTypography.labelUi.copyWith(
                                      color: isDark ? colorScheme.onSecondary : AppColors.onSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'ECO-FRIENDLY OPTIONS',
                                  style: AppTypography.headlineSmall.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? colorScheme.secondary : AppColors.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? colorScheme.surfaceContainer : AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.science,
                                      color: isDark ? colorScheme.secondary : AppColors.secondary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Baking Soda Spray',
                                        style: AppTypography.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Mix 1 tbsp baking soda + 1 tsp mild liquid soap into 1 liter water. Spray tops and bottoms of remaining leaves tomorrow morning.',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 12,
                                    color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? colorScheme.surfaceContainer : AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.eco,
                                      color: isDark ? colorScheme.secondary : AppColors.secondary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Organic Neem Oil',
                                        style: AppTypography.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Apply once every 7 days as a natural shield to suppress fungal spore germination.',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 12,
                                    color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Priority Tier 3: Chemicals (Last Resort)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(14),
                        border: isDark
                            ? Border.all(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.25),
                              )
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? colorScheme.error : AppColors.error,
                                ),
                                child: Center(
                                  child: Text(
                                    '3',
                                    style: AppTypography.labelUi.copyWith(
                                      color: isDark ? colorScheme.onError : AppColors.onError,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'CHEMICALS (LAST RESORT ONLY)',
                                  style: AppTypography.headlineSmall.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? colorScheme.error : AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? colorScheme.errorContainer.withValues(alpha: 0.25)
                                  : AppColors.errorContainer.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Copper Fungicide Spray',
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: isDark ? colorScheme.error : AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Use only if spots keep spreading after 1 week of drying and organic spray.',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 12,
                                    color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 1. Target Plant Plot Selector Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? colorScheme.outlineVariant.withValues(alpha: 0.25)
                              : AppColors.surfaceContainerHigh,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.yard_outlined,
                                    size: 16,
                                    color: isDark ? colorScheme.primary : AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'TARGET PLANT PLOT',
                                    style: AppTypography.labelUi.copyWith(
                                      color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                              if (allPlants.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () => _openPlantPickerSheet(context, allPlants),
                                  icon: const Icon(Icons.search, size: 13),
                                  label: const Text('Change / Search'),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    minimumSize: const Size(0, 26),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    foregroundColor: isDark ? colorScheme.primary : AppColors.primary,
                                    textStyle: AppTypography.labelUi.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (activePlant != null) ...[
                            InkWell(
                              onTap: () => _openPlantPickerSheet(context, allPlants),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark ? colorScheme.surfaceContainer : AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? colorScheme.primaryContainer.withValues(alpha: 0.35)
                                            : AppColors.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        _resolveCrop(activePlant) == 'Chili'
                                            ? Icons.local_fire_department
                                            : (_resolveCrop(activePlant) == 'Eggplant'
                                                ? Icons.spa
                                                : Icons.eco),
                                        size: 20,
                                        color: isDark ? colorScheme.primary : AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            activePlant.name,
                                            style: AppTypography.bodyMedium.copyWith(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            activePlant.variety.isNotEmpty
                                                ? activePlant.variety
                                                : '${_resolveCrop(activePlant)} Plot',
                                            style: AppTypography.bodySmall.copyWith(
                                              fontSize: 11,
                                              color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: activePlant.healthStatus == PlantHealthStatus.healthy
                                            ? (isDark ? colorScheme.secondaryContainer.withValues(alpha: 0.35) : AppColors.secondaryContainer)
                                            : (activePlant.healthStatus == PlantHealthStatus.caution
                                                ? (isDark ? colorScheme.tertiaryContainer.withValues(alpha: 0.35) : AppColors.tertiaryContainer)
                                                : (isDark ? colorScheme.errorContainer.withValues(alpha: 0.35) : AppColors.errorContainer)),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        activePlant.healthStatus.name.toUpperCase(),
                                        style: AppTypography.labelUi.copyWith(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: activePlant.healthStatus == PlantHealthStatus.healthy
                                              ? (isDark ? colorScheme.secondary : AppColors.onSecondaryContainer)
                                              : (activePlant.healthStatus == PlantHealthStatus.caution
                                                  ? (isDark ? colorScheme.tertiary : AppColors.onTertiaryContainer)
                                                  : (isDark ? colorScheme.error : AppColors.onErrorContainer)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                              decoration: BoxDecoration(
                                color: isDark ? colorScheme.surfaceContainer : AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'No registered plants found. Add plants in My Plants first to save scan diagnostics.',
                                      style: AppTypography.bodySmall.copyWith(
                                        fontSize: 11,
                                        color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Primary Action Button: Save Diagnosis to Plant
                    ElevatedButton.icon(
                      onPressed: activePlant == null
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please register a crop plot in My Plants first.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          : () async {
                              final severity = widget.result.severity;
                              final newStatus = severity == DiagnosticSeverity.severe
                                  ? PlantHealthStatus.critical
                                  : (severity == DiagnosticSeverity.caution
                                      ? PlantHealthStatus.caution
                                      : PlantHealthStatus.healthy);

                              final updated = activePlant.copyWith(
                                healthStatus: newStatus,
                                primaryDiagnosis: '${widget.result.detectedCondition} (${widget.result.confidencePercentage.toStringAsFixed(1)}%)',
                                lastScannedAt: widget.result.scannedAt,
                              );

                              await ref.read(plantListNotifierProvider.notifier).addPlant(updated);

                              if (newStatus != PlantHealthStatus.healthy) {
                                await ref
                                    .read(plantDiagnosticTasksNotifierProvider(updated.id).notifier)
                                    .initializeTasksIfEmpty(updated);
                              }

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Updated diagnostics for "${updated.name}"! Status: ${newStatus.name.toUpperCase()}.'),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: isDark ? colorScheme.primary : AppColors.primary,
                                  ),
                                );
                                widget.onDismiss();
                              }
                            },
                      icon: const Icon(Icons.bookmark, size: 18),
                      label: Text(
                        activePlant != null
                            ? 'Save Diagnosis to ${activePlant.name}'
                            : 'Save Diagnosis to Plant',
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: isDark ? colorScheme.primary : AppColors.primary,
                        foregroundColor: isDark ? colorScheme.onPrimary : AppColors.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: activePlant == null
                                ? () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Select or register a plant first to log treatment.'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                : () async {
                                    final treatment = widget.result.organicTreatment.isNotEmpty
                                        ? widget.result.organicTreatment
                                        : 'Applied treatment protocol for ${widget.result.detectedCondition}.';
                                    final updated = activePlant.copyWith(
                                      notes: activePlant.notes.isEmpty
                                          ? 'Treatment: $treatment'
                                          : '${activePlant.notes}\n• Treatment: $treatment',
                                      lastScannedAt: DateTime.now(),
                                    );
                                    await ref.read(plantListNotifierProvider.notifier).addPlant(updated);

                                    if (updated.healthStatus != PlantHealthStatus.healthy) {
                                      await ref
                                          .read(plantDiagnosticTasksNotifierProvider(updated.id).notifier)
                                          .initializeTasksIfEmpty(updated);
                                    }
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Treatment logged to "${activePlant.name}" history!'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.edit_calendar, size: 16),
                            label: const Text(
                              'Log Treatment',
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              minimumSize: const Size.fromHeight(46),
                              backgroundColor: isDark ? colorScheme.surfaceContainerHigh : AppColors.surfaceContainerHigh,
                              foregroundColor: isDark ? colorScheme.onSurface : AppColors.onSurface,
                              side: isDark ? BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.25)) : BorderSide.none,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: widget.onDismiss,
                            icon: const Icon(Icons.document_scanner, size: 16),
                            label: const Text(
                              'Scan Again',
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              minimumSize: const Size.fromHeight(46),
                              backgroundColor: isDark ? colorScheme.surfaceContainerHigh : AppColors.surfaceContainerHigh,
                              foregroundColor: isDark ? colorScheme.onSurface : AppColors.onSurface,
                              side: isDark ? BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.25)) : BorderSide.none,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWandSensorCard({
    required String title,
    required IconData icon,
    required String value,
    required String target,
    required String statusTag,
    required bool isError,
    required String summary,
    required bool isExpanded,
    required VoidCallback onToggleWhy,
    required String whyText,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError
              ? (isDark ? colorScheme.error.withValues(alpha: 0.4) : AppColors.errorContainer)
              : (isDark ? colorScheme.outlineVariant.withValues(alpha: 0.25) : AppColors.surfaceContainerHigh),
        ),
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
                    Icon(
                      icon,
                      size: 16,
                      color: isError
                          ? (isDark ? colorScheme.error : AppColors.error)
                          : (isDark ? colorScheme.secondary : AppColors.secondary),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isError
                          ? (isDark ? colorScheme.errorContainer.withValues(alpha: 0.35) : AppColors.errorContainer)
                          : (isDark ? colorScheme.secondaryContainer.withValues(alpha: 0.35) : AppColors.secondaryContainer),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      statusTag,
                      style: AppTypography.labelUi.copyWith(
                        color: isError
                            ? (isDark ? colorScheme.error : AppColors.onErrorContainer)
                            : (isDark ? colorScheme.secondary : AppColors.onSecondaryContainer),
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: onToggleWhy,
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? colorScheme.surfaceContainerHigh : AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Why?',
                            style: AppTypography.labelUi.copyWith(
                              fontSize: 9,
                              color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                            ),
                          ),
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            size: 14,
                            color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                value,
                style: AppTypography.telemetryLarge.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  target,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            summary,
            style: AppTypography.bodySmall.copyWith(
              color: isError
                  ? (isDark ? colorScheme.error : AppColors.error)
                  : (isDark ? colorScheme.secondary : AppColors.secondary),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? colorScheme.surfaceContainer : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                whyText,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11,
                  color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChecklistItem({
    required bool value,
    required String title,
    required String subtitle,
    required ValueChanged<bool?> onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                activeColor: isDark ? colorScheme.primary : AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: value
                          ? (isDark ? colorScheme.onSurfaceVariant.withValues(alpha: 0.6) : AppColors.onSurfaceVariant.withValues(alpha: 0.6))
                          : (isDark ? colorScheme.onSurface : AppColors.onSurface),
                      decoration: value ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 11,
                      color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet dialog allowing the user to search, filter by crop category, and select which registered plant to update.
class _PlantSearchPickerSheet extends StatefulWidget {
  const _PlantSearchPickerSheet({
    required this.plants,
    required this.initialCropFilter,
    required this.currentSelectedPlantId,
    required this.onPlantSelected,
  });

  final List<PlantModel> plants;
  final String initialCropFilter;
  final String? currentSelectedPlantId;
  final ValueChanged<PlantModel> onPlantSelected;

  @override
  State<_PlantSearchPickerSheet> createState() => _PlantSearchPickerSheetState();
}

class _PlantSearchPickerSheetState extends State<_PlantSearchPickerSheet> {
  late String _selectedCropFilter;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCropFilter = widget.initialCropFilter;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _resolveCrop(PlantModel plant) {
    final lowerName = plant.name.toLowerCase();
    final lowerVariety = plant.variety.toLowerCase();
    final lowerFamily = plant.cropFamily.toLowerCase();
    if (lowerName.contains('tomato') || lowerVariety.contains('tomato') || lowerFamily.contains('tomato') || lowerVariety.contains('lycopersicum')) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final query = _searchController.text.trim().toLowerCase();
    final filtered = widget.plants.where((p) {
      final cropMatch = _selectedCropFilter == 'All' ||
          _resolveCrop(p).toLowerCase() == _selectedCropFilter.toLowerCase();
      if (!cropMatch) return false;
      if (query.isEmpty) return true;
      return p.name.toLowerCase().contains(query) ||
          p.variety.toLowerCase().contains(query) ||
          p.notes.toLowerCase().contains(query);
    }).toList();

    final tomatoCount = widget.plants.where((p) => _resolveCrop(p) == 'Tomato').length;
    final chiliCount = widget.plants.where((p) => _resolveCrop(p) == 'Chili').length;
    final eggplantCount = widget.plants.where((p) => _resolveCrop(p) == 'Eggplant').length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerLow : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: isDark
            ? Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.25),
                  width: 1,
                ),
              )
            : null,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.outlineVariant.withValues(alpha: 0.6)
                      : AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header title & close
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Scanned Plant',
                        style: AppTypography.headlineSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                        ),
                      ),
                      Text(
                        'Filter by category or search by crop name',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 20,
                      color: isDark ? colorScheme.onSurfaceVariant : null,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Search text input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                style: isDark ? TextStyle(color: colorScheme.onSurface) : null,
                decoration: InputDecoration(
                  hintText: 'Search plant by title or variety...',
                  hintStyle: AppTypography.bodySmall.copyWith(
                    color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: isDark ? colorScheme.primary : AppColors.primary,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            size: 18,
                            color: isDark ? colorScheme.onSurfaceVariant : null,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? colorScheme.surfaceContainer : AppColors.surfaceContainerLow,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: isDark
                        ? BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.25))
                        : BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: isDark
                        ? BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.25))
                        : BorderSide.none,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),

            const SizedBox(height: 10),

            // Crop Category Filter Chips (All, Tomato, Chili, Eggplant)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildCategoryChip('All', 'All (${widget.plants.length})'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Tomato', '🍅 Tomato ($tomatoCount)'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Chili', '🌶️ Chili ($chiliCount)'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Eggplant', '🍆 Eggplant ($eggplantCount)'),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: isDark
                  ? colorScheme.outlineVariant.withValues(alpha: 0.25)
                  : AppColors.surfaceContainerHigh,
            ),

            // Filtered Plant List
            Flexible(
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.yard_outlined,
                            size: 36,
                            color: (isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant).withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No matching plants found',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try changing the crop category filter or clear your search keyword.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11,
                              color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (ctx, idx) {
                        final plant = filtered[idx];
                        final isSelected = plant.id == widget.currentSelectedPlantId;
                        return InkWell(
                          onTap: () => widget.onPlantSelected(plant),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark ? colorScheme.primaryContainer.withValues(alpha: 0.3) : AppColors.primaryContainer.withValues(alpha: 0.25))
                                  : (isDark ? colorScheme.surfaceContainer : AppColors.surfaceContainerLowest),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? (isDark ? colorScheme.primary : AppColors.primary)
                                    : (isDark ? colorScheme.outlineVariant.withValues(alpha: 0.25) : AppColors.surfaceContainerHigh),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (isDark ? colorScheme.primary : AppColors.primary)
                                        : (isDark ? colorScheme.surfaceContainerHigh : AppColors.surfaceContainer),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _resolveCrop(plant) == 'Chili'
                                        ? Icons.local_fire_department
                                        : (_resolveCrop(plant) == 'Eggplant'
                                            ? Icons.spa
                                            : Icons.eco),
                                    size: 22,
                                    color: isSelected
                                        ? (isDark ? colorScheme.onPrimary : AppColors.onPrimary)
                                        : (isDark ? colorScheme.primary : AppColors.primary),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        plant.name,
                                        style: AppTypography.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        plant.variety.isNotEmpty
                                            ? plant.variety
                                            : '${_resolveCrop(plant)} Plot',
                                        style: AppTypography.bodySmall.copyWith(
                                          fontSize: 11,
                                          color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: plant.healthStatus == PlantHealthStatus.healthy
                                        ? (isDark ? colorScheme.secondaryContainer.withValues(alpha: 0.35) : AppColors.secondaryContainer)
                                        : (plant.healthStatus == PlantHealthStatus.caution
                                            ? (isDark ? colorScheme.tertiaryContainer.withValues(alpha: 0.35) : AppColors.tertiaryContainer)
                                            : (isDark ? colorScheme.errorContainer.withValues(alpha: 0.35) : AppColors.errorContainer)),
                                        borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    plant.healthStatus.name.toUpperCase(),
                                    style: AppTypography.labelUi.copyWith(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: plant.healthStatus == PlantHealthStatus.healthy
                                          ? (isDark ? colorScheme.secondary : AppColors.onSecondaryContainer)
                                          : (plant.healthStatus == PlantHealthStatus.caution
                                              ? (isDark ? colorScheme.tertiary : AppColors.onTertiaryContainer)
                                              : (isDark ? colorScheme.error : AppColors.onErrorContainer)),
                                    ),
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.check_circle,
                                    color: isDark ? colorScheme.primary : AppColors.primary,
                                    size: 20,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category, String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final isSelected = _selectedCropFilter.toLowerCase() == category.toLowerCase();
    return InkWell(
      onTap: () => setState(() => _selectedCropFilter = category),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? colorScheme.primary : AppColors.primary)
              : (isDark ? colorScheme.surfaceContainer : AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (isDark ? colorScheme.primary : AppColors.primary)
                : (isDark ? colorScheme.outlineVariant.withValues(alpha: 0.35) : AppColors.outlineVariant),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelUi.copyWith(
            color: isSelected
                ? (isDark ? colorScheme.onPrimary : AppColors.onPrimary)
                : (isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
