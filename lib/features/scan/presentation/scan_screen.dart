import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/hardware_status_hud.dart';
import 'providers/diagnostic_providers.dart';
import 'widgets/diagnosis_result_sheet.dart';
import 'widgets/scan_viewfinder_reticle.dart';

/// Screen presenting the live optical viewfinder and leaf disease detection engine.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  String _selectedCrop = 'Tomato';
  bool _isFlashOn = false;

  final List<String> _crops = const ['Tomato', 'Red Chili', 'Eggplant'];

  Future<void> _triggerScan() async {
    final result = await ref
        .read(activeDiagnosticScanNotifierProvider.notifier)
        .executeScan(
          imagePath: 'assets/sample_leaf_scout.jpg',
          cropType: _selectedCrop,
        );

    if (result != null && mounted) {
      _displayDiagnosisSheet(result);
    }
  }

  void _displayDiagnosisSheet(dynamic result) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => DiagnosisResultSheet(
        result: result,
        onDismiss: () {
          Navigator.pop(bottomSheetContext);
          ref.read(activeDiagnosticScanNotifierProvider.notifier).resetScan();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(activeDiagnosticScanNotifierProvider);
    final isAnalyzing = scanState.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep dark camera canvas
      body: SafeArea(
        child: Stack(
          children: [
            // Viewfinder Camera simulation canvas
            Positioned.fill(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Header Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'OPTICAL SCOUT',
                          style: AppTypography.labelUi.copyWith(
                            color: Colors.white70,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const HardwareStatusHud(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Crop Selector Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: _crops.map((crop) {
                        final isSelected = _selectedCrop == crop;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(crop),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedCrop = crop;
                                });
                              }
                            },
                            selectedColor: AppColors.leafBright,
                            backgroundColor: Colors.white12,
                            labelStyle: AppTypography.bodySmall.copyWith(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const Spacer(),
                  // Viewfinder Frame
                  const ScanViewfinderReticle(),
                  const Spacer(),
                  // Instructions text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Align single leaf within frame under daylight. Hold steady for edge inference.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Bottom controls bar (Thumb zone)
                  Container(
                    padding: const EdgeInsets.fromLTRB(32, 16, 32, 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Flashlight toggle
                        IconButton(
                          icon: Icon(
                            _isFlashOn ? Icons.flash_on : Icons.flash_off,
                            color: _isFlashOn ? AppColors.solarAmber : Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              _isFlashOn = !_isFlashOn;
                            });
                          },
                        ),
                        // Shutter trigger button
                        GestureDetector(
                          onTap: isAnalyzing ? null : _triggerScan,
                          child: Container(
                            width: 76,
                            height: 76,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3.5),
                            ),
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.leafBright,
                              ),
                              child: isAnalyzing
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt,
                                      color: Colors.black,
                                      size: 32,
                                    ),
                            ),
                          ),
                        ),
                        // Simulate gallery pick
                        IconButton(
                          icon: const Icon(Icons.photo_library_outlined, color: Colors.white70),
                          onPressed: isAnalyzing ? null : _triggerScan,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Loading Overlay when scanning
            if (isAnalyzing)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: AppColors.secondary),
                          const SizedBox(height: 16),
                          Text(
                            'Executing On-Device Inference...',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'TFLite Solanaceae Model v1.4',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
