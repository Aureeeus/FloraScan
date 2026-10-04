import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/entities/plant_model.dart';
import 'providers/plant_providers.dart';

/// Form screen for registering a new crop plot into field observation.
class AddPlantScreen extends ConsumerStatefulWidget {
  const AddPlantScreen({super.key});

  @override
  ConsumerState<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends ConsumerState<AddPlantScreen> {
  final _formKey = GlobalKey<FormState>();

  String _selectedCropType = 'Tomato';
  final _nameController = TextEditingController();
  final _varietyController = TextEditingController();
  final _notesController = TextEditingController();
  CropGrowthStage _selectedStage = CropGrowthStage.vegetative;
  double _baselineMoisture = 28.0;

  final List<String> _cropTypes = const ['Tomato', 'Red Chili', 'Eggplant'];

  @override
  void dispose() {
    _nameController.dispose();
    _varietyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitForm() {
    // Guard clause: validate form
    if (!_formKey.currentState!.validate()) return;

    final newPlant = PlantModel(
      id: 'plot_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      cropFamily: 'Solanaceae',
      variety: _varietyController.text.trim().isEmpty
          ? '$_selectedCropType Standard'
          : _varietyController.text.trim(),
      stage: _selectedStage,
      healthStatus: PlantHealthStatus.healthy,
      soilMoisturePercent: _baselineMoisture,
      soilTemperatureCelsius: 22.0,
      npkSummary: 'N:160 P:55 K:190 ppm (Baseline)',
      lastScannedAt: DateTime.now(),
      primaryDiagnosis: 'Initial Baseline Registered - Healthy',
      notes: _notesController.text.trim(),
    );

    ref.read(plantListNotifierProvider.notifier).addPlant(newPlant);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Registered plot "${newPlant.name}" successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Register Crop Plot',
          style: AppTypography.headlineMedium.copyWith(color: AppColors.primary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CROP CLASSIFICATION',
                  style: AppTypography.labelUi.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: _cropTypes.map((crop) {
                    final isSelected = _selectedCropType == crop;
                    return ChoiceChip(
                      label: Text(crop),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCropType = crop;
                          });
                        }
                      },
                      selectedColor: AppColors.secondaryContainer,
                      labelStyle: AppTypography.bodyMedium.copyWith(
                        color: isSelected ? AppColors.primary : AppColors.onSurface,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected ? AppColors.secondary : AppColors.outlineVariant,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Plot / Row Identifier *',
                    hintText: 'e.g., Roma Tomato Block A',
                    filled: true,
                    fillColor: AppColors.surfaceContainerLowest,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please provide a plot identifier';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _varietyController,
                  decoration: const InputDecoration(
                    labelText: 'Cultivar / Variety',
                    hintText: 'e.g., San Marzano or Carolina Reaper',
                    filled: true,
                    fillColor: AppColors.surfaceContainerLowest,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<CropGrowthStage>(
                  initialValue: _selectedStage,
                  decoration: const InputDecoration(
                    labelText: 'Growth Stage',
                    filled: true,
                    fillColor: AppColors.surfaceContainerLowest,
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: CropGrowthStage.vegetative,
                      child: Text('Vegetative (Canopy Expansion)'),
                    ),
                    DropdownMenuItem(
                      value: CropGrowthStage.flowering,
                      child: Text('Flowering (Pollination)'),
                    ),
                    DropdownMenuItem(
                      value: CropGrowthStage.fruiting,
                      child: Text('Fruiting (Fruit Development)'),
                    ),
                    DropdownMenuItem(
                      value: CropGrowthStage.harvesting,
                      child: Text('Harvesting (Mature Picking)'),
                    ),
                  ],
                  onChanged: (newStage) {
                    if (newStage != null) {
                      setState(() {
                        _selectedStage = newStage;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'TARGET BASELINE MOISTURE: ${_baselineMoisture.toStringAsFixed(0)}% VWC',
                  style: AppTypography.labelUi.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                Slider(
                  value: _baselineMoisture,
                  min: 15.0,
                  max: 45.0,
                  divisions: 30,
                  label: '${_baselineMoisture.toStringAsFixed(0)}%',
                  activeColor: AppColors.secondary,
                  onChanged: (val) {
                    setState(() {
                      _baselineMoisture = val;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Field Notes & Observations',
                    hintText: 'Fertigation line notes, mulch layer, shading details...',
                    filled: true,
                    fillColor: AppColors.surfaceContainerLowest,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: AppColors.onPrimary,
                  ),
                  child: const Text('Save & Register Plot'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
