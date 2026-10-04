import 'package:flutter/material.dart';
import '../../../../core/theme/agri_theme_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Screen managing hardware IoT wand pairing, Edge AI configurations, and field units.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _offlineInferenceEnabled = true;
  double _confidenceThreshold = 75.0;
  bool _isCelsius = true;
  bool _autoSyncCloudWhenOnline = true;

  @override
  Widget build(BuildContext context) {
    final agriColors = context.agriTheme;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Device & App Settings',
          style: AppTypography.headlineMedium.copyWith(color: AppColors.primary),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // BLE IoT Wand Section
            _SectionHeader(title: 'FIELD HARDWARE (BLE IOT WAND)'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: agriColors.healthyVigor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.bluetooth_connected, color: agriColors.healthyVigor),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FloraScan Probe Wand #782',
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Connected • RSSI: -58 dBm • Battery: 91%',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Wand probe recalibrated successfully.')),
                          );
                        },
                        child: const Text('Calibrate'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Edge AI Configuration
            _SectionHeader(title: 'ON-DEVICE EDGE AI (TFLITE)'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Edge Offline Inference',
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Run disease diagnostics directly on-device without internet',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    value: _offlineInferenceEnabled,
                    activeTrackColor: AppColors.secondary,
                    onChanged: (val) {
                      setState(() {
                        _offlineInferenceEnabled = val;
                      });
                    },
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active Model Engine',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                      Text(
                        'Solanaceae-v1.4 (TFLite Int8)',
                        style: AppTypography.telemetrySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'MINIMUM CONFIDENCE THRESHOLD: ${_confidenceThreshold.toStringAsFixed(0)}%',
                    style: AppTypography.labelUi.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                  Slider(
                    value: _confidenceThreshold,
                    min: 60.0,
                    max: 95.0,
                    divisions: 7,
                    label: '${_confidenceThreshold.toStringAsFixed(0)}%',
                    activeColor: AppColors.secondary,
                    onChanged: (val) {
                      setState(() {
                        _confidenceThreshold = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Agronomy Units & Cloud Sync
            _SectionHeader(title: 'PREFERENCES & TELEMETRY UNITS'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Temperature Unit'),
                    subtitle: Text(_isCelsius ? 'Celsius (°C)' : 'Fahrenheit (°F)'),
                    trailing: Switch(
                      value: _isCelsius,
                      activeThumbColor: AppColors.secondary,
                      onChanged: (val) {
                        setState(() {
                          _isCelsius = val;
                        });
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    title: const Text('Auto-Sync Field Records'),
                    subtitle: const Text('Upload diagnostics when Wi-Fi / LTE resumes'),
                    value: _autoSyncCloudWhenOnline,
                    activeTrackColor: AppColors.secondary,
                    onChanged: (val) {
                      setState(() {
                        _autoSyncCloudWhenOnline = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // About / Architecture metadata
            _SectionHeader(title: 'SYSTEM & ARCHITECTURE'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SystemInfoRow(label: 'Application', value: 'FloraScan Mobile'),
                  _SystemInfoRow(label: 'Version', value: 'v0.1.0 (Alpha Build)'),
                  _SystemInfoRow(label: 'Design System', value: 'Stitch AgriTech Light'),
                  _SystemInfoRow(label: 'Architecture', value: 'Clean Arch + Riverpod'),
                  _SystemInfoRow(label: 'Platform Targets', value: 'iOS & Android Exclusive'),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppTypography.labelUi.copyWith(
          color: AppColors.onSurfaceVariant,
          fontSize: 10,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _SystemInfoRow extends StatelessWidget {
  const _SystemInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
          ),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
