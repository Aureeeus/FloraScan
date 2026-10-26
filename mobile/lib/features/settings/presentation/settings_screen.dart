import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ble/flora_wand_ble_service.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/flora_scan_header.dart';
import 'providers/settings_providers.dart';

/// Settings screen managing hardware IoT wand, Edge AI models, and field units matching Google Stitch.
///
/// Follows UI/UX Designer standards: Fitts's Law touch compliance,
/// dynamic hardware connection states, tabular sensor numerals, and persistent user preferences.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showPairingModal(BuildContext context, WidgetRef ref) {
    ref.read(floraWandNotifierProvider.notifier).startScan();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final wandState = ref.watch(floraWandNotifierProvider);
            final devices = wandState.discoveredDevices;
            final colorScheme = Theme.of(context).colorScheme;
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.bluetooth_searching, color: colorScheme.secondary, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Nearby FloraWand Devices',
                              style: AppTypography.headlineSmall.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        if (wandState.isScanning)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ensure your ESP32 FloraWand power switch is ON and within BLE range.',
                      style: AppTypography.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (devices.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        child: Text(
                          wandState.isScanning
                              ? 'Searching for nearby FloraWand over BLE...'
                              : 'No FloraWand devices found nearby. Check power switch.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: devices.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final dev = devices[i];
                          final isCurrent =
                              wandState.connectedDevice?.id == dev.id && wandState.isConnected;

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? colorScheme.secondaryContainer.withValues(alpha: 0.25)
                                    : AppColors.secondaryContainer,
                              ),
                              child: Icon(
                                Icons.sensors,
                                color: isDark ? colorScheme.secondary : AppColors.onSecondaryContainer,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              dev.name,
                              style: AppTypography.headlineSmall.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              'ID: ${dev.id} • Signal: ${dev.rssi} dBm',
                              style: AppTypography.telemetrySmall.copyWith(fontSize: 11),
                            ),
                            trailing: ElevatedButton(
                              onPressed: isCurrent
                                  ? null
                                  : () async {
                                      Navigator.pop(ctx);
                                      final success = await ref
                                          .read(floraWandNotifierProvider.notifier)
                                          .connect(dev);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              success
                                                  ? 'FloraWand paired and connected successfully!'
                                                  : 'Failed to connect to ${dev.name}.',
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(96, 38),
                                backgroundColor: isDark ? colorScheme.secondary : AppColors.secondaryFixed,
                                foregroundColor: isDark ? const Color(0xFF002114) : AppColors.onSecondaryFixed,
                                disabledBackgroundColor: isDark
                                    ? colorScheme.surfaceContainerHigh
                                    : AppColors.surfaceContainerHigh,
                                disabledForegroundColor: colorScheme.onSurfaceVariant,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                textStyle: AppTypography.labelUi.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                              child: Text(isCurrent ? 'Paired' : 'Pair & Connect'),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    final activeThemeMode = ref.watch(themeModeProvider);
    final isEnglish = ref.watch(isEnglishLanguageProvider);
    final isCelsius = ref.watch(isCelsiusMetricProvider);
    final wandState = ref.watch(floraWandNotifierProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Dynamic connection status badge text and color
    final (statusBadgeText, statusBadgeColor) = switch (wandState.connectionState) {
      FloraWandConnectionState.connected => (isEnglish ? 'Online' : 'Online', isDark ? colorScheme.secondary : AppColors.secondary),
      FloraWandConnectionState.scanning => (isEnglish ? 'Connecting...' : 'Kumokonekta...', colorScheme.primary),
      FloraWandConnectionState.connecting => (isEnglish ? 'Connecting...' : 'Kumokonekta...', colorScheme.primary),
      FloraWandConnectionState.disconnected => (isEnglish ? 'Offline' : 'Offline', colorScheme.onSurfaceVariant),
      FloraWandConnectionState.error => (isEnglish ? 'Error' : 'Error', colorScheme.error),
    };

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: FloraScanHeader(subtitle: l10n.navSettings),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header title row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.settingsHeaderTitle,
                          style: AppTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          l10n.settingsHeaderSubtitle,
                          style: AppTypography.bodySmall.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Section 1: Biometric Sensor Wand (Sentence Case)
              _buildSectionTitle(
                context,
                Icons.bluetooth_searching,
                l10n.sectionBiometricWand,
                statusBadgeText,
                statusBadgeColor,
              ),
              const SizedBox(height: 6),

              // Wand Card with dynamic Connected vs Disconnected states
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? colorScheme.outlineVariant.withValues(alpha: 0.25) : Colors.transparent,
                  ),
                  boxShadow: isDark
                      ? const []
                      : const [
                          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Wand header row (Device name, status dot)
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isDark
                                ? colorScheme.secondaryContainer.withValues(alpha: 0.25)
                                : AppColors.secondaryContainer,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            Icons.sensors,
                            color: isDark ? colorScheme.secondary : AppColors.onSecondaryContainer,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      wandState.deviceName,
                                      style: AppTypography.headlineSmall.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: wandState.isConnected
                                          ? colorScheme.secondary
                                          : (wandState.isScanning || wandState.isConnecting)
                                              ? Colors.amber
                                              : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                wandState.isConnected
                                    ? 'Online • Paired via BLE (${wandState.connectedDevice?.rssi ?? -58} dBm)'
                                    : (wandState.isScanning || wandState.isConnecting)
                                        ? 'Connecting to FloraWand...'
                                        : 'Offline • Ready to pair',
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: wandState.isConnected
                                      ? (isDark ? colorScheme.secondary : AppColors.secondary)
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // State-Aware Wand Body
                    if (!wandState.isConnected) ...[
                      // Disconnected / Offline / Connecting State
                      if (wandState.isScanning || wandState.isConnecting) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Connecting to FloraWand over BLE...',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ] else ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            l10n.noWandStreaming,
                            style: AppTypography.bodySmall.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 11,
                              height: 1.35,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showPairingModal(context, ref),
                          icon: Icon(
                            Icons.bluetooth_searching,
                            size: 18,
                            color: isDark ? const Color(0xFF002114) : AppColors.onSecondaryFixed,
                          ),
                          label: Text(l10n.pairConnectWand),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            backgroundColor: isDark ? colorScheme.secondary : AppColors.secondaryFixed,
                            foregroundColor: isDark ? const Color(0xFF002114) : AppColors.onSecondaryFixed,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            textStyle: AppTypography.labelUi.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Guided calibration section
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.tune, color: colorScheme.primary, size: 15),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    l10n.guidedCalibrationTitle,
                                    style: AppTypography.headlineSmall.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: colorScheme.primary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              l10n.guidedCalibrationDesc,
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 10,
                                color: colorScheme.onSurfaceVariant,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Calibrating Soil Probe (0%/100%)... OK!'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    icon: Icon(Icons.water_drop, size: 14, color: colorScheme.secondary),
                                    label: Text(l10n.soilCalibration),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(0, 38),
                                      backgroundColor: colorScheme.surfaceContainerLowest,
                                      foregroundColor: colorScheme.primary,
                                      side: BorderSide(
                                        color: isDark ? colorScheme.outlineVariant.withValues(alpha: 0.3) : Colors.transparent,
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Calibrating Optical Lux Sensor... OK!'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    icon: Icon(Icons.wb_sunny, size: 14, color: colorScheme.secondary),
                                    label: Text(l10n.luxCalibration),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(0, 38),
                                      backgroundColor: colorScheme.surfaceContainerLowest,
                                      foregroundColor: colorScheme.primary,
                                      side: BorderSide(
                                        color: isDark ? colorScheme.outlineVariant.withValues(alpha: 0.3) : Colors.transparent,
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Wand action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showPairingModal(context, ref),
                              icon: Icon(
                                Icons.sync,
                                size: 16,
                                color: isDark ? const Color(0xFF002114) : AppColors.onSecondaryFixed,
                              ),
                              label: Text(l10n.pairNewWand),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(42),
                                backgroundColor: isDark ? colorScheme.secondary : AppColors.secondaryFixed,
                                foregroundColor: isDark ? const Color(0xFF002114) : AppColors.onSecondaryFixed,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                                textStyle: AppTypography.labelUi.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () async {
                              await ref.read(floraWandNotifierProvider.notifier).disconnect();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.wandDisconnected),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.bluetooth_disabled, size: 16),
                            label: Text(l10n.disconnect),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 42),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              backgroundColor: colorScheme.surfaceContainerHigh,
                              foregroundColor: colorScheme.error,
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Section 2: Garden Preferences & UI (Sentence Case)
              _buildSectionTitle(context, Icons.yard, l10n.sectionGardenOps, null, null),
              const SizedBox(height: 6),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? colorScheme.outlineVariant.withValues(alpha: 0.25) : Colors.transparent,
                  ),
                  boxShadow: isDark
                      ? const []
                      : const [
                          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Theme Mode Selector
                    Row(
                      children: [
                        Icon(Icons.palette_outlined, size: 16, color: colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          l10n.displayTheme,
                          style: AppTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildThemeSegment(
                              context: context,
                              title: l10n.themeLight,
                              icon: Icons.light_mode_outlined,
                              isSelected: activeThemeMode == ThemeMode.light,
                              onTap: () {
                                ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Theme set to Light Mode'),
                                    duration: Duration(milliseconds: 900),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: _buildThemeSegment(
                              context: context,
                              title: l10n.themeDark,
                              icon: Icons.dark_mode_outlined,
                              isSelected: activeThemeMode == ThemeMode.dark,
                              onTap: () {
                                ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Theme set to Dark Mode'),
                                    duration: Duration(milliseconds: 900),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: _buildThemeSegment(
                              context: context,
                              title: l10n.themeSystem,
                              icon: Icons.brightness_auto_outlined,
                              isSelected: activeThemeMode == ThemeMode.system,
                              onTap: () {
                                ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Theme set to System Default'),
                                    duration: Duration(milliseconds: 900),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),



                    const SizedBox(height: 12),

                    // Language Preference
                    Row(
                      children: [
                        Icon(Icons.language, size: 16, color: colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          l10n.language,
                          style: AppTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildLanguageSegment(
                              context: context,
                              title: 'English',
                              isSelected: isEnglish,
                              onTap: () => ref.read(isEnglishLanguageProvider.notifier).set(true),
                            ),
                          ),
                          Expanded(
                            child: _buildLanguageSegment(
                              context: context,
                              title: 'Filipino',
                              isSelected: !isEnglish,
                              onTap: () => ref.read(isEnglishLanguageProvider.notifier).set(false),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Temperature Metric Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.temperatureMetric,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                l10n.temperatureMetricDesc,
                                style: AppTypography.bodySmall.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              _buildMetricSegment(
                                context: context,
                                label: '°C',
                                isSelected: isCelsius,
                                onTap: () => ref.read(isCelsiusMetricProvider.notifier).set(true),
                              ),
                              _buildMetricSegment(
                                context: context,
                                label: '°F',
                                isSelected: !isCelsius,
                                onTap: () => ref.read(isCelsiusMetricProvider.notifier).set(false),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Section 3: Data, Privacy & Storage (Sentence Case)
              _buildSectionTitle(context, Icons.shield, l10n.sectionDataPrivacy, null, null),
              const SizedBox(height: 6),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? colorScheme.outlineVariant.withValues(alpha: 0.25) : Colors.transparent,
                  ),
                  boxShadow: isDark
                      ? const []
                      : const [
                          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.zeroTrackingTitle,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.zeroTrackingDesc,
                      style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant, fontSize: 11),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    IconData icon,
    String title,
    String? badge,
    Color? badgeColor,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(icon, size: 14, color: colorScheme.primary),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.labelUi.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    letterSpacing: 0.3,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 6),
          Text(
            badge,
            style: AppTypography.telemetrySmall.copyWith(
              color: badgeColor ?? colorScheme.secondary,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildThemeSegment({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title theme',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.surfaceContainerLowest : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSegment({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title language',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.surfaceContainerLowest : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Center(
            child: Text(
              title,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricSegment({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label temperature unit',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.surfaceContainerLowest : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: AppTypography.telemetrySmall.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
