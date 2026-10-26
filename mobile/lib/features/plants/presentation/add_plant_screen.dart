import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ble/flora_wand_ble_service.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/sproutly_mascot.dart';
import '../../settings/presentation/providers/settings_providers.dart';
import '../domain/entities/plant_model.dart';
import 'providers/plant_providers.dart';

/// Form screen for adding a new crop plot strictly matching Google Stitch specifications.
///
/// Implements a 4-step progressive disclosure wizard adhering to /UI Designer doctrine:
/// - Step 1: Crop Profile (Tomato, Chili, Eggplant calibrated targets)
/// - Step 2: Plant Identity (Nickname, Date, Growth Stage)
/// - Step 3: Growing Environment (Location, Container Type)
/// - Step 4: FloraWand IoT Link & Summary Confirmation
///
/// Fully harmonized with Dark Mode surface physics, WCAG AA/AAA contrast, and 4/8pt spatial rhythm.
class AddPlantScreen extends ConsumerStatefulWidget {
  const AddPlantScreen({super.key});

  @override
  ConsumerState<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends ConsumerState<AddPlantScreen> {
  final _formKey = GlobalKey<FormState>();

  int _currentStep = 1;
  String _selectedCrop = 'tomato';
  late final TextEditingController _nicknameController;
  late final TextEditingController _dateController;
  String _selectedGrowthStage = 'vegetative';
  String _selectedLocation = 'balcony';
  String _selectedContainer = 'earthen';
  bool _isWandPaired = true;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController();
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    _dateController = TextEditingController(text: 'Today, ${months[now.month - 1]} ${now.day}, ${now.year}');
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _handleNextStep() {
    if (_currentStep == 1) {
      if (_nicknameController.text.trim().isEmpty) {
        final cropName = switch (_selectedCrop) {
          'tomato' => 'Plum Tomato',
          'chili' => 'Red Chili',
          'eggplant' => 'Eggplant',
          _ => 'Garden Crop',
        };
        final existingPlants = ref.read(plantListNotifierProvider).value ?? const [];
        final matchingCount = existingPlants
            .where((p) => p.name.toLowerCase().contains(cropName.toLowerCase()))
            .length;
        final nextNumber = matchingCount + 1;
        _nicknameController.text = '$cropName $nextNumber';
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      if (!_formKey.currentState!.validate()) return;
      setState(() => _currentStep = 3);
    } else if (_currentStep == 3) {
      setState(() => _currentStep = 4);
    }
  }

  void _savePlant() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _currentStep = 2);
      return;
    }

    final cropName = switch (_selectedCrop) {
      'tomato' => 'Tomato',
      'chili' => 'Red Chili',
      'eggplant' => 'Eggplant',
      _ => 'Custom Plant',
    };

    final newPlant = PlantModel(
      id: 'plot_${DateTime.now().millisecondsSinceEpoch}',
      name: _nicknameController.text.trim(),
      cropFamily: 'Solanaceae',
      variety: '$cropName Standard',
      stage: switch (_selectedGrowthStage) {
        'seedling' => CropGrowthStage.vegetative,
        'flowering' => CropGrowthStage.flowering,
        'fruiting' => CropGrowthStage.fruiting,
        _ => CropGrowthStage.vegetative,
      },
      healthStatus: PlantHealthStatus.healthy,
      soilMoisturePercent: _isWandPaired ? ref.read(floraWandNotifierProvider).telemetry.soilMoisturePercent : 0.0,
      soilTemperatureCelsius: _isWandPaired ? ref.read(floraWandNotifierProvider).telemetry.temperatureCelsius : 0.0,
      npkSummary: _isWandPaired
          ? 'Initial calibration: ${ref.read(floraWandNotifierProvider).telemetry.soilMoistureTag}'
          : 'Pending probe scan',
      lastScannedAt: DateTime.now(),
      primaryDiagnosis: 'Baseline registered - Healthy',
      notes: 'Growing in $_selectedLocation using $_selectedContainer container.',
    );

    ref.read(plantListNotifierProvider.notifier).addPlant(newPlant);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Registered "${newPlant.name}" to garden logs!'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.plants);
    }
  }

  String _getStepSubtitle(int step) {
    switch (step) {
      case 1:
        return 'Select plant type';
      case 2:
        return 'Plant identity';
      case 3:
        return 'Location & container';
      case 4:
        return 'Sensor & hardware link';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final wandState = ref.watch(floraWandNotifierProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.95),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? colorScheme.outlineVariant.withValues(alpha: 0.25)
                    : const Color(0x10000000),
                width: 1,
              ),
            ),
            boxShadow: isDark
                ? const []
                : const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: colorScheme.onSurface),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppRoutes.plants);
                        }
                      },
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Plant',
                          style: AppTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'GARDEN LOG SETUP',
                          style: AppTypography.labelUi.copyWith(
                            color: isDark ? colorScheme.primary : AppColors.onSurfaceVariant,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(colorScheme, isDark),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepHeader(colorScheme, isDark),
                const SizedBox(height: 16),
                if (_currentStep == 1) _buildStep1CropProfile(colorScheme, isDark),
                if (_currentStep == 2) _buildStep2PlantIdentity(colorScheme, isDark),
                if (_currentStep == 3) _buildStep3Environment(colorScheme, isDark),
                if (_currentStep == 4) _buildStep4SensorLink(wandState, colorScheme, isDark),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepHeader(ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? colorScheme.outlineVariant.withValues(alpha: 0.25)
              : Colors.transparent,
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
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? colorScheme.primary : AppColors.primary,
                    ),
                    child: Center(
                      child: Text(
                        '$_currentStep',
                        style: AppTypography.labelUi.copyWith(
                          color: isDark ? colorScheme.onPrimary : AppColors.onPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Step $_currentStep of 4',
                    style: AppTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    ' • ${_getStepSubtitle(_currentStep)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Text(
                '${_currentStep * 25}%',
                style: AppTypography.telemetrySmall.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? colorScheme.primary : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(
              value: _currentStep / 4.0,
              minHeight: 4,
              backgroundColor: isDark
                  ? colorScheme.surfaceContainerHighest
                  : AppColors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? colorScheme.primary : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1CropProfile(ColorScheme colorScheme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Friendly Mascot Prompt
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerLow
                : AppColors.secondaryContainer,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? colorScheme.outlineVariant.withValues(alpha: 0.25)
                  : colorScheme.secondary.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              const SproutlyMascot(size: 42),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FloraScan Agri-Guide',
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isDark ? colorScheme.primary : AppColors.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tip: Select your crop type to automatically load pre-calibrated soil moisture targets and sunlight requirements for high-yield growth!',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSecondaryContainer,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'Select Plant Type / Crop Profile',
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Calibrated agronomic profiles for precision sensor thresholds',
          style: AppTypography.bodySmall.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),

        const SizedBox(height: 12),

        _buildCropPresetCard(
          colorScheme: colorScheme,
          isDark: isDark,
          key: 'tomato',
          title: 'Tomato',
          scientific: '(Solanum lycopersicum)',
          moisture: '60-70%',
          sunlight: '6-8 hrs',
          icon: Icons.eco,
          iconBg: isDark ? const Color(0x33DC2626) : const Color(0xFFFFEBEE),
          iconColor: isDark ? const Color(0xFFFF6B6B) : const Color(0xFFC62828),
        ),
        const SizedBox(height: 10),

        _buildCropPresetCard(
          colorScheme: colorScheme,
          isDark: isDark,
          key: 'chili',
          title: 'Red Chili',
          scientific: '(Capsicum frutescens)',
          moisture: '40-55%',
          sunlight: 'Full Sun',
          icon: Icons.local_fire_department,
          iconBg: isDark ? const Color(0x33F59E0B) : const Color(0xFFFFF8E1),
          iconColor: isDark ? const Color(0xFFFFB74D) : const Color(0xFFF57F17),
        ),
        const SizedBox(height: 10),

        _buildCropPresetCard(
          colorScheme: colorScheme,
          isDark: isDark,
          key: 'eggplant',
          title: 'Eggplant',
          scientific: '(Solanum melongena)',
          moisture: '65-75%',
          sunlight: 'Warm Climate',
          icon: Icons.spa,
          iconBg: isDark ? const Color(0x339333EA) : const Color(0xFFF3E5F5),
          iconColor: isDark ? const Color(0xFFCE93D8) : const Color(0xFF6A1B9A),
        ),
      ],
    );
  }

  Widget _buildStep2PlantIdentity(ColorScheme colorScheme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plant Details & Identity',
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Name your plot and assign its current developmental stage',
          style: AppTypography.bodySmall.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'Plant Nickname',
          style: AppTypography.labelUi.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _nicknameController,
          style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.label,
              size: 18,
              color: isDark ? colorScheme.secondary : AppColors.secondary,
            ),
            hintText: 'e.g., Cherry Tomato - Balcony',
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            filled: true,
            fillColor: isDark
                ? colorScheme.surfaceContainerLow
                : AppColors.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: isDark
                  ? BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.25))
                  : BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: isDark
                  ? BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.25))
                  : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? colorScheme.primary : AppColors.primary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          validator: (val) => val == null || val.trim().isEmpty ? 'Enter a nickname' : null,
        ),

        const SizedBox(height: 16),

        Text(
          'Date Planted',
          style: AppTypography.labelUi.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _dateController,
          style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.calendar_today,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            filled: true,
            fillColor: isDark
                ? colorScheme.surfaceContainerLow
                : AppColors.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: isDark
                  ? BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.25))
                  : BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: isDark
                  ? BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.25))
                  : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? colorScheme.primary : AppColors.primary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'Growth Stage',
          style: AppTypography.labelUi.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildStageChip(colorScheme, isDark, 'seedling', 'Seedling', Icons.find_replace),
            _buildStageChip(colorScheme, isDark, 'vegetative', 'Vegetative', Icons.spa),
            _buildStageChip(colorScheme, isDark, 'flowering', 'Flowering', Icons.local_florist),
            _buildStageChip(colorScheme, isDark, 'fruiting', 'Fruiting', Icons.eco),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3Environment(ColorScheme colorScheme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Growing Environment & Container',
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Environmental factors for tailored irrigation and exposure alerts',
          style: AppTypography.bodySmall.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'Growing Location',
          style: AppTypography.labelUi.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildLocationChip(colorScheme, isDark, 'balcony', 'Balcony', Icons.balcony),
            _buildLocationChip(colorScheme, isDark, 'backyard', 'Backyard Bed', Icons.yard),
            _buildLocationChip(colorScheme, isDark, 'patio', 'Patio Pots', Icons.deck),
            _buildLocationChip(colorScheme, isDark, 'indoor', 'Indoor Window', Icons.window),
          ],
        ),

        const SizedBox(height: 20),

        Text(
          'Container Type',
          style: AppTypography.labelUi.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildContainerChip(colorScheme, isDark, 'earthen', 'Earthen Pot'),
            _buildContainerChip(colorScheme, isDark, 'growbag', 'Grow Bag'),
            _buildContainerChip(colorScheme, isDark, 'raised', 'Raised Bed'),
            _buildContainerChip(colorScheme, isDark, 'direct', 'Direct Soil'),
          ],
        ),
      ],
    );
  }

  Widget _buildStep4SensorLink(
    FloraWandState wandState,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final isCelsius = ref.watch(isCelsiusMetricProvider);
    final cropName = switch (_selectedCrop) {
      'tomato' => 'Tomato',
      'chili' => 'Red Chili',
      'eggplant' => 'Eggplant',
      _ => 'Custom Plant',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sensor Link & Confirmation',
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Link FloraWand IoT probe and review your plot configuration',
          style: AppTypography.bodySmall.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),

        const SizedBox(height: 16),

        // FloraWand IoT Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: wandState.isConnected
                  ? (isDark
                      ? colorScheme.secondary.withValues(alpha: 0.4)
                      : AppColors.secondary.withValues(alpha: 0.3))
                  : (isDark
                      ? colorScheme.outlineVariant.withValues(alpha: 0.25)
                      : AppColors.outlineVariant.withValues(alpha: 0.3)),
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
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: wandState.isConnected
                                ? (isDark
                                    ? colorScheme.secondary.withValues(alpha: 0.2)
                                    : AppColors.secondary.withValues(alpha: 0.12))
                                : (isDark
                                    ? colorScheme.surfaceContainerHigh
                                    : AppColors.surfaceContainerHigh),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.sensors,
                            color: wandState.isConnected
                                ? (isDark ? colorScheme.secondary : AppColors.secondary)
                                : colorScheme.onSurfaceVariant,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                wandState.isConnected ? 'FloraWand Connected' : 'FloraWand Standby',
                                style: AppTypography.headlineSmall.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                wandState.isConnected
                                    ? 'Live probe telemetry synced'
                                    : 'Hardware probe offline or unpaired',
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant,
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
                  Switch.adaptive(
                    value: _isWandPaired,
                    activeTrackColor: isDark ? colorScheme.secondary.withValues(alpha: 0.45) : null,
                    activeThumbColor: isDark ? colorScheme.secondary : AppColors.secondary,
                    onChanged: (val) => setState(() => _isWandPaired = val),
                  ),
                ],
              ),
              if (_isWandPaired && wandState.isConnected) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.surfaceContainerLowest
                        : AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? colorScheme.outlineVariant.withValues(alpha: 0.2)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniTelemetryItem(
                        Icons.water_drop,
                        wandState.telemetry.formattedMoisture,
                        'Moisture',
                        colorScheme,
                        isDark ? colorScheme.secondary : AppColors.secondary,
                      ),
                      _buildMiniTelemetryItem(
                        Icons.thermostat,
                        wandState.telemetry.formatTemperature(isCelsius: isCelsius),
                        'Temp',
                        colorScheme,
                        isDark ? AppColors.solarAmber : AppColors.richOchreSoil,
                      ),
                      _buildMiniTelemetryItem(
                        Icons.cloud,
                        wandState.telemetry.formattedHumidity,
                        'Humidity',
                        colorScheme,
                        isDark ? AppColors.moistureCyan : AppColors.foliageMid,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Plot Summary Review Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? colorScheme.outlineVariant.withValues(alpha: 0.25)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plot Configuration Summary',
                style: AppTypography.headlineSmall.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              _buildSummaryRow(colorScheme, 'Crop', '$cropName (Solanaceae)'),
              const SizedBox(height: 6),
              _buildSummaryRow(
                colorScheme,
                'Nickname',
                _nicknameController.text.trim().isEmpty ? 'Untitled' : _nicknameController.text.trim(),
              ),
              const SizedBox(height: 6),
              _buildSummaryRow(colorScheme, 'Stage', _selectedGrowthStage.toUpperCase()),
              const SizedBox(height: 6),
              _buildSummaryRow(
                colorScheme,
                'Placement',
                '${_selectedLocation[0].toUpperCase()}${_selectedLocation.substring(1)} • ${_selectedContainer[0].toUpperCase()}${_selectedContainer.substring(1)}',
              ),
              const SizedBox(height: 6),
              _buildSummaryRow(
                colorScheme,
                'Telemetry Link',
                _isWandPaired ? 'Enabled (FloraWand)' : 'Manual / Offline',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: isDark
                ? colorScheme.outlineVariant.withValues(alpha: 0.25)
                : AppColors.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () {
                  if (_currentStep == 1) {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRoutes.plants);
                    }
                  } else {
                    setState(() => _currentStep--);
                  }
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: isDark
                      ? colorScheme.surfaceContainerHigh
                      : AppColors.surfaceContainerLow,
                  foregroundColor: colorScheme.onSurface,
                  side: isDark
                      ? BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3))
                      : BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_currentStep == 1 ? 'Cancel' : 'Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _currentStep < 4 ? _handleNextStep : _savePlant,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: isDark ? colorScheme.primary : AppColors.primary,
                  foregroundColor: isDark ? colorScheme.onPrimary : AppColors.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentStep < 4 ? 'Continue' : 'Save Plant',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      _currentStep < 4 ? Icons.arrow_forward : Icons.check_circle,
                      size: 18,
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

  Widget _buildCropPresetCard({
    required ColorScheme colorScheme,
    required bool isDark,
    required String key,
    required String title,
    required String scientific,
    required String moisture,
    required String sunlight,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
  }) {
    final isSelected = _selectedCrop == key;
    return InkWell(
      onTap: () => setState(() => _selectedCrop = key),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? colorScheme.surfaceContainerLow
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? (isDark ? colorScheme.primary : AppColors.primary)
                : (isDark
                    ? colorScheme.outlineVariant.withValues(alpha: 0.25)
                    : AppColors.outlineVariant.withValues(alpha: 0.35)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isDark ? colorScheme.primary : AppColors.primary)
                        .withValues(alpha: isDark ? 0.16 : 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: AppTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          scientific,
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? colorScheme.surfaceContainerHigh
                                : AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.water_drop,
                                size: 11,
                                color: isDark ? colorScheme.secondary : AppColors.secondary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                moisture,
                                style: AppTypography.telemetrySmall.copyWith(
                                  fontSize: 10,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? colorScheme.surfaceContainerHigh
                                : AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.wb_sunny,
                                size: 11,
                                color: isDark ? AppColors.solarAmber : AppColors.tertiaryContainer,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                sunlight,
                                style: AppTypography.telemetrySmall.copyWith(
                                  fontSize: 10,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? (isDark ? colorScheme.primary : AppColors.primary)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? (isDark ? colorScheme.primary : AppColors.primary)
                      : (isDark
                          ? colorScheme.outlineVariant.withValues(alpha: 0.5)
                          : AppColors.outlineVariant),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 14,
                      color: isDark ? colorScheme.onPrimary : AppColors.onPrimary,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageChip(
    ColorScheme colorScheme,
    bool isDark,
    String key,
    String label,
    IconData icon,
  ) {
    final isSelected = _selectedGrowthStage == key;
    return InkWell(
      onTap: () => setState(() => _selectedGrowthStage = key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? colorScheme.primary : AppColors.primary)
              : (isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (isDark ? colorScheme.primary : AppColors.primary)
                : (isDark ? colorScheme.outlineVariant.withValues(alpha: 0.25) : Colors.transparent),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? (isDark ? colorScheme.onPrimary : AppColors.onPrimary)
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? colorScheme.onPrimary : AppColors.onPrimary)
                    : colorScheme.onSurface,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationChip(
    ColorScheme colorScheme,
    bool isDark,
    String key,
    String label,
    IconData icon,
  ) {
    final isSelected = _selectedLocation == key;
    return InkWell(
      onTap: () => setState(() => _selectedLocation = key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? colorScheme.secondary : AppColors.secondary)
              : (isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (isDark ? colorScheme.secondary : AppColors.secondary)
                : (isDark ? colorScheme.outlineVariant.withValues(alpha: 0.25) : Colors.transparent),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? (isDark ? const Color(0xFF002114) : AppColors.onSecondary)
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? const Color(0xFF002114) : AppColors.onSecondary)
                    : colorScheme.onSurface,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContainerChip(
    ColorScheme colorScheme,
    bool isDark,
    String key,
    String label,
  ) {
    final isSelected = _selectedContainer == key;
    return InkWell(
      onTap: () => setState(() => _selectedContainer = key),
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? colorScheme.primary : AppColors.primary)
              : (isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: isSelected
                ? (isDark ? colorScheme.primary : AppColors.primary)
                : (isDark ? colorScheme.outlineVariant.withValues(alpha: 0.25) : Colors.transparent),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? colorScheme.onPrimary : AppColors.onPrimary)
                : colorScheme.onSurface,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildMiniTelemetryItem(
    IconData icon,
    String value,
    String label,
    ColorScheme colorScheme,
    Color iconColor,
  ) {
    return Column(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.telemetrySmall.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 11,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontSize: 10,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(ColorScheme colorScheme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
