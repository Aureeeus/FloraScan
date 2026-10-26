import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/ble/flora_wand_ble_service.dart';
import '../../../core/routing/navigation_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/entities/diagnostic_scan_model.dart';
import '../domain/entities/telemetry_reading.dart';
import 'providers/diagnostic_providers.dart';
import 'widgets/diagnosis_result_sheet.dart';
import 'widgets/scan_viewfinder_reticle.dart';

/// Screen presenting the live optical viewfinder and leaf disease detection engine.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({
    super.key,
    this.cameraController,
  });

  /// Optional injected camera controller (for testability and mock feeds).
  final CameraController? cameraController;

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> with WidgetsBindingObserver {
  String _selectedCrop = 'Tomato';
  bool _isFlashOn = false;
  CameraController? _cameraController;
  bool _isCameraInitializing = false;
  bool _isCameraDisposing = false;
  String? _cameraError;
  final ImagePicker _picker = ImagePicker();

  final List<String> _crops = const ['Tomato', 'Red Chili', 'Eggplant'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.cameraController != null) {
      _cameraController = widget.cameraController;
    } else {
      // Initialize live camera if Scan screen is currently active
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (ref.read(activeNavBranchProvider) == 2) {
          _initializeLiveCamera();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.cameraController == null) {
      _disposeCurrentCamera();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.cameraController != null) return;

    final isScanActive = ref.read(activeNavBranchProvider) == 2;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      // Release camera hardware immediately when app is paused or external intent is opened
      _disposeCurrentCamera();
    } else if (state == AppLifecycleState.resumed) {
      // Re-initialize live camera if user is currently on the Scan screen
      if (isScanActive && mounted) {
        _initializeLiveCamera();
      }
    }
  }

  /// Cleanly disposes the current camera controller and releases hardware locks.
  Future<void> _disposeCurrentCamera() async {
    if (widget.cameraController != null) return;
    final controller = _cameraController;
    _cameraController = null;
    _isFlashOn = false;

    if (controller != null) {
      _isCameraDisposing = true;
      try {
        await controller.dispose();
      } catch (e) {
        debugPrint('FloraScan live camera disposal error: $e');
      } finally {
        _isCameraDisposing = false;
      }
      if (mounted) {
        setState(() {});
      }
    }
  }

  /// Initializes the optical sensor with camera hardware enumeration and safety checks.
  Future<void> _initializeLiveCamera() async {
    if (widget.cameraController != null) return;
    if (_isCameraInitializing) return;

    // Await any ongoing disposal to avoid native Camera2/AVFoundation lock collisions
    while (_isCameraDisposing) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
    }

    if (_cameraController != null) {
      await _disposeCurrentCamera();
    }

    if (!mounted) return;
    if (ref.read(activeNavBranchProvider) != 2) return;

    setState(() {
      _isCameraInitializing = true;
      _cameraError = null;
    });

    try {
      final cameras = await availableCameras();

      if (!mounted) return;
      if (ref.read(activeNavBranchProvider) != 2) {
        setState(() => _isCameraInitializing = false);
        return;
      }

      if (cameras.isEmpty) {
        setState(() {
          _isCameraInitializing = false;
          _cameraError = 'No optical sensor detected on device.';
        });
        return;
      }

      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      // Check if user navigated away while camera was initializing
      if (ref.read(activeNavBranchProvider) != 2) {
        await controller.dispose();
        setState(() => _isCameraInitializing = false);
        return;
      }

      setState(() {
        _cameraController = controller;
        _isCameraInitializing = false;
        _cameraError = null;
      });
    } catch (e) {
      debugPrint('FloraScan live camera initialization: $e');
      if (mounted) {
        setState(() {
          _isCameraInitializing = false;
          _cameraError = 'Failed to connect to optical sensor.';
        });
      }
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _cameraController;
    final nextFlashState = !_isFlashOn;

    if (controller != null && controller.value.isInitialized) {
      try {
        await controller.setFlashMode(nextFlashState ? FlashMode.torch : FlashMode.off);
        if (mounted) {
          setState(() {
            _isFlashOn = nextFlashState;
          });
        }
        return;
      } catch (e) {
        debugPrint('Flash toggle error: $e');
      }
    }

    setState(() {
      _isFlashOn = nextFlashState;
    });
  }

  Future<void> _captureOpticalScout() async {
    final controller = _cameraController;
    if (controller != null && controller.value.isInitialized) {
      try {
        final image = await controller.takePicture();
        final wandState = ref.read(floraWandNotifierProvider);
        final telemetry = wandState.isConnected
            ? TelemetryReading.fromCalibrated(wandState.telemetry)
            : null;

        final result = await ref
            .read(activeDiagnosticScanNotifierProvider.notifier)
            .executeScan(
              imagePath: image.path,
              cropType: _selectedCrop,
              telemetry: telemetry,
            );

        if (result != null && mounted) {
          _displayDiagnosisSheet(result);
        }
        return;
      } catch (e) {
        debugPrint('Live camera capture exception: $e');
      }
    }

    // Graceful fallback to image picker camera (release live camera lock first)
    await _disposeCurrentCamera();
    await _pickAndScan(ImageSource.camera);
  }


  Future<void> _pickAndScan(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (picked == null) {
        return;
      }

      final wandState = ref.read(floraWandNotifierProvider);
      final telemetry = wandState.isConnected
          ? TelemetryReading.fromCalibrated(wandState.telemetry)
          : null;

      final result = await ref
          .read(activeDiagnosticScanNotifierProvider.notifier)
          .executeScan(
            imagePath: picked.path,
            cropType: _selectedCrop,
            telemetry: telemetry,
          );

      if (result != null && mounted) {
        _displayDiagnosisSheet(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not access ${source == ImageSource.camera ? 'camera' : 'gallery'}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget? _buildCameraPreview() {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      if (_isCameraInitializing) {
        return Container(
          color: const Color(0xFF0F172A),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sensors, color: AppColors.leafBright, size: 28),
                SizedBox(height: 8),
                Text(
                  'INITIALIZING OPTICAL SENSOR...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (_cameraError != null) {
        return Container(
          color: const Color(0xFF0F172A),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam_off_outlined, color: AppColors.solarAmber, size: 36),
                const SizedBox(height: 10),
                Text(
                  _cameraError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _initializeLiveCamera,
                  icon: const Icon(Icons.refresh, size: 14, color: AppColors.leafBright),
                  label: const Text(
                    'RECONNECT SENSOR',
                    style: TextStyle(
                      color: AppColors.leafBright,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.leafBright, width: 1.2),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return null;
    }

    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: controller.value.previewSize?.height ?? 400,
        height: controller.value.previewSize?.width ?? 400,
        child: CameraPreview(controller),
      ),
    );
  }

  void _displayDiagnosisSheet(DiagnosticScanResult result) {
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
    // Re-initialize camera when navigating to Scan screen; dispose when navigating away
    ref.listen<int>(activeNavBranchProvider, (previous, next) {
      if (next == 2 && previous != 2) {
        _initializeLiveCamera();
      } else if (previous == 2 && next != 2) {
        _disposeCurrentCamera();
      }
    });

    final scanState = ref.watch(activeDiagnosticScanNotifierProvider);
    final isAnalyzing = scanState.isLoading;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

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
                  Center(
                    child: Text(
                      'OPTICAL SCOUT',
                      style: AppTypography.labelUi.copyWith(
                        color: Colors.white70,
                        letterSpacing: 1.2,
                      ),
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
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedCrop = crop;
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF22C55E) // Bright vibrant green when selected
                                    : const Color(0xFF1E293B), // High-visibility slate when unselected
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF22C55E)
                                      : Colors.white54,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                crop,
                                style: AppTypography.bodySmall.copyWith(
                                  color: isSelected ? Colors.black : Colors.white,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Viewfinder Frame with Live Camera Feed & AR Overlay
                  Expanded(
                    child: Center(
                      child: ScanViewfinderReticle(
                        cameraPreview: _buildCameraPreview(),
                      ),
                    ),
                  ),
                  // Instructions text and Quick Test button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Real-Time Pre-Capture Optical Quality Badges
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _QualityPill(
                              icon: Icons.filter_center_focus,
                              label: 'Center Focus',
                            ),
                            SizedBox(width: 8),
                            _QualityPill(
                              icon: Icons.crop,
                              label: 'Fill 70% Area',
                            ),
                            SizedBox(width: 8),
                            _QualityPill(
                              icon: Icons.wb_sunny_outlined,
                              label: 'No Hard Glare',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Position a single leaf within the silhouette under diffuse daylight.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Bottom controls bar (Thumb zone)
                  Container(
                    padding: const EdgeInsets.fromLTRB(32, 16, 32, 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Flashlight toggle (Camera Torch)
                        IconButton(
                          tooltip: _isFlashOn ? 'Turn Flashlight Off' : 'Turn Flashlight On',
                          icon: Icon(
                            _isFlashOn ? Icons.flash_on : Icons.flash_off,
                            color: _isFlashOn ? AppColors.solarAmber : Colors.white70,
                          ),
                          onPressed: _toggleFlash,
                        ),
                        // Shutter trigger button (Live Camera Capture)
                        GestureDetector(
                          onTap: isAnalyzing ? null : _captureOpticalScout,
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
                        // Device Image / Gallery Picker button
                        IconButton(
                          tooltip: 'Choose from Gallery',
                          icon: const Icon(Icons.photo_library_outlined, color: Colors.white70),
                          onPressed: isAnalyzing ? null : () => _pickAndScan(ImageSource.gallery),
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
                        color: isDark ? colorScheme.surfaceContainerHigh : AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: isDark
                            ? Border.all(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.25),
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: isDark ? colorScheme.secondary : AppColors.secondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Analyzing Leaf Pathology...',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Evaluating foliar symptoms & biometrics',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
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

class _QualityPill extends StatelessWidget {
  const _QualityPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.leafBright),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelUi.copyWith(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

