import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/entities/plant_model.dart';
import 'providers/plant_providers.dart';
import 'widgets/plant_card.dart';

/// Screen listing all monitored crop plots with search and filter capabilities.
class MyPlantsScreen extends ConsumerStatefulWidget {
  const MyPlantsScreen({super.key});

  @override
  ConsumerState<MyPlantsScreen> createState() => _MyPlantsScreenState();
}

class _MyPlantsScreenState extends ConsumerState<MyPlantsScreen> {
  PlantHealthStatus? _selectedStatusFilter;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final plantsAsync = ref.watch(plantListNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Monitored Crops',
          style: AppTypography.headlineMedium.copyWith(color: AppColors.primary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryContainer),
            tooltip: 'Add Crop Plot',
            onPressed: () => context.go(AppRoutes.addPlant),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search and filter area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search plot, variety, or pathogen...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: AppColors.surfaceContainerLowest,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.outlineVariant),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                  });
                },
              ),
            ),
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _buildFilterChip('All Plots', null),
                  const SizedBox(width: 8),
                  _buildFilterChip('Healthy', PlantHealthStatus.healthy),
                  const SizedBox(width: 8),
                  _buildFilterChip('Caution', PlantHealthStatus.caution),
                  const SizedBox(width: 8),
                  _buildFilterChip('Critical', PlantHealthStatus.critical),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Plant list
            Expanded(
              child: plantsAsync.when(
                data: (plants) {
                  final filtered = plants.where((p) {
                    final matchesStatus = _selectedStatusFilter == null ||
                        p.healthStatus == _selectedStatusFilter;
                    final matchesQuery = _searchQuery.isEmpty ||
                        p.name.toLowerCase().contains(_searchQuery) ||
                        p.variety.toLowerCase().contains(_searchQuery) ||
                        (p.primaryDiagnosis?.toLowerCase().contains(_searchQuery) ?? false);
                    return matchesStatus && matchesQuery;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.eco_outlined, size: 48, color: AppColors.outline),
                          const SizedBox(height: 12),
                          Text(
                            'No crops matching current filters',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final plant = filtered[index];
                      return PlantCard(
                        plant: plant,
                        onDelete: () {
                          ref
                              .read(plantListNotifierProvider.notifier)
                              .removePlant(plant.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Removed ${plant.name}'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(
                    'Failed to load crops: $error',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(AppRoutes.addPlant),
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Add Plot'),
      ),
    );
  }

  Widget _buildFilterChip(String label, PlantHealthStatus? status) {
    final isSelected = _selectedStatusFilter == status;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedStatusFilter = status;
        });
      },
      selectedColor: AppColors.secondaryContainer,
      labelStyle: AppTypography.bodySmall.copyWith(
        color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(9999),
        side: BorderSide(
          color: isSelected ? AppColors.secondary : AppColors.outlineVariant,
        ),
      ),
    );
  }
}
