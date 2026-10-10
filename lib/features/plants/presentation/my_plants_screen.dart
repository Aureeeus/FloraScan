import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/flora_scan_header.dart';
import '../../../core/widgets/sproutly_mascot.dart';

/// Screen listing all monitored crop plots matching Google Stitch specifications.
class MyPlantsScreen extends ConsumerStatefulWidget {
  const MyPlantsScreen({super.key});

  @override
  ConsumerState<MyPlantsScreen> createState() => _MyPlantsScreenState();
}

class _MyPlantsScreenState extends ConsumerState<MyPlantsScreen> {
  String _selectedCropFilter = 'All';
  String _selectedAreaFilter = 'All';
  String _selectedPlantId = 'tommy';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const FloraScanHeader(subtitle: 'My Plants'),
      body: SafeArea(
        child: SingleChildScrollView(
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
                              '3 happy green buddies, 1 needs a drink!',
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
                              '4 Total',
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

              // 3. Filter Section: Crop Categories
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _buildCropChip('All', 'All Plants (4)', Icons.yard),
                    const SizedBox(width: 8),
                    _buildCropChip('Tomato', '🍅 Tomato (2)', null),
                    const SizedBox(width: 8),
                    _buildCropChip('Potato', '🥔 Potato (1)', null),
                    const SizedBox(width: 8),
                    _buildCropChip('Corn', '🌽 Corn (1)', null),
                  ],
                ),
              ),

              // Location Filter Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.place, size: 14, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          'AREA: ',
                          style: AppTypography.labelUi.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    _buildAreaChip('All', 'All Areas'),
                    const SizedBox(width: 6),
                    _buildAreaChip('Balcony', 'Balcony (2)'),
                    const SizedBox(width: 6),
                    _buildAreaChip('Backyard', 'Backyard (1)'),
                    const SizedBox(width: 6),
                    _buildAreaChip('Indoor', 'Indoor Pots (0)'),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // 4. Plant List Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Card 1: Tommy
                    _buildPlantItemCard(
                      id: 'tommy',
                      name: 'Sweet Plum Tomato',
                      nickname: '"Tommy"',
                      crop: 'Tomato',
                      location: 'Balcony 1',
                      statusTag: 'Needs Care',
                      isError: true,
                      avatarIcon: Icons.eco,
                      avatarColor: AppColors.primary,
                      metricsBar: _buildDualMetricBar(
                        metric1Icon: Icons.water_drop,
                        metric1Label: 'MOISTURE',
                        metric1Value: '28% (Too Dry)',
                        metric1IsError: true,
                        metric2Icon: Icons.wb_sunny,
                        metric2Label: 'SUNLIGHT',
                        metric2Value: '45k Lux',
                      ),
                      timeAgo: '2 hrs ago',
                      actionLabel: 'View Sensor Data',
                      actionRoute: () => setState(() => _selectedPlantId = 'tommy'),
                    ),

                    const SizedBox(height: 10),

                    // Card 2: Spud
                    _buildPlantItemCard(
                      id: 'spud',
                      name: 'Russet Potato Bucket',
                      nickname: '"Spud"',
                      crop: 'Potato',
                      location: 'Backyard',
                      statusTag: 'Healthy',
                      isError: false,
                      avatarIcon: Icons.spa,
                      avatarColor: AppColors.secondary,
                      metricsBar: _buildDualMetricBar(
                        metric1Icon: Icons.water_drop,
                        metric1Label: 'MOISTURE',
                        metric1Value: '62% (Good)',
                        metric1IsError: false,
                        metric2Icon: Icons.thermostat,
                        metric2Label: 'AIR TEMP',
                        metric2Value: '25°C',
                      ),
                      timeAgo: 'Yesterday',
                      actionLabel: 'Check history',
                      actionRoute: () => setState(() => _selectedPlantId = 'spud'),
                    ),

                    const SizedBox(height: 10),

                    // Card 3: Maisie
                    _buildPlantItemCard(
                      id: 'maisie',
                      name: 'Golden Bantam Corn',
                      nickname: '"Maisie"',
                      crop: 'Corn',
                      location: 'Patio Pot',
                      statusTag: 'Healthy',
                      isError: false,
                      avatarIcon: Icons.grass,
                      avatarColor: AppColors.secondary,
                      metricsBar: _buildSummaryBanner(
                        leftText: 'Patio Container • Micro-irrigated',
                        rightBadgeText: 'All 4 Sensors OK',
                        rightColor: AppColors.secondary,
                      ),
                      timeAgo: '3 days ago',
                      actionLabel: 'Details',
                      actionRoute: () => setState(() => _selectedPlantId = 'maisie'),
                    ),

                    const SizedBox(height: 10),

                    // Card 4: Roma
                    _buildPlantItemCard(
                      id: 'roma',
                      name: 'Roma Tomato',
                      nickname: '"Roma"',
                      crop: 'Tomato',
                      location: 'Balcony 2',
                      statusTag: 'Issue',
                      isError: true,
                      avatarIcon: Icons.coronavirus,
                      avatarColor: AppColors.error,
                      metricsBar: _buildAlertBanner(
                        icon: Icons.coronavirus,
                        alertText: 'Late Blight spots on lower leaves',
                      ),
                      timeAgo: '4 hrs ago',
                      actionLabel: 'Diagnostics',
                      actionRoute: () => context.go(AppRoutes.scan),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 5. Detail Preview Section (Interactive Focal Plant: Tommy)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
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
                                        _selectedPlantId == 'spud'
                                            ? 'Russet Potato (Spud)'
                                            : _selectedPlantId == 'maisie'
                                                ? 'Golden Bantam Corn (Maisie)'
                                                : 'Sweet Plum Tomato (Tommy)',
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
                            'Sync: 11:42 AM',
                            style: AppTypography.telemetrySmall.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // 4 Sensors Snapshot
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
                            iconColor: AppColors.error,
                            tag: 'TOO LOW ⚠️',
                            tagColor: AppColors.onErrorContainer,
                            tagBg: AppColors.errorContainer,
                            value: '28%',
                            subvalue: '/ 60% opt',
                            progress: 0.28,
                            progressColor: AppColors.error,
                          ),
                          _buildDetailSensorBox(
                            title: 'Air Temp',
                            icon: Icons.thermostat,
                            iconColor: AppColors.secondary,
                            tag: 'GOOD',
                            tagColor: AppColors.onSecondaryFixedVariant,
                            tagBg: AppColors.secondaryFixed,
                            value: '28°C',
                            subvalue: 'Ideal 24-29°',
                            progress: 0.72,
                            progressColor: AppColors.secondary,
                          ),
                          _buildDetailSensorBox(
                            title: 'Humidity',
                            icon: Icons.cloud,
                            iconColor: AppColors.secondary,
                            tag: 'GOOD',
                            tagColor: AppColors.onSecondaryFixedVariant,
                            tagBg: AppColors.secondaryFixed,
                            value: '55%',
                            subvalue: 'Target 50-65%',
                            progress: 0.55,
                            progressColor: AppColors.secondary,
                          ),
                          _buildDetailSensorBox(
                            title: 'Light Lux',
                            icon: Icons.wb_sunny,
                            iconColor: AppColors.secondary,
                            tag: 'BRIGHT',
                            tagColor: AppColors.onTertiaryFixed,
                            tagBg: AppColors.tertiaryFixed,
                            value: '45k',
                            subvalue: '35k-50k target',
                            progress: 0.82,
                            progressColor: AppColors.tertiaryFixedDim,
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
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(avatarIcon, color: avatarColor, size: 30),
                    ),
                    Positioned(
                      bottom: 2,
                      left: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHighest.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          location,
                          style: AppTypography.telemetrySmall.copyWith(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
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
                              color: isError && id == 'roma' ? AppColors.error : AppColors.primary,
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
                          color: isError && id == 'roma' ? AppColors.error : AppColors.primary,
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

  Widget _buildSummaryBanner({
    required String leftText,
    required String rightBadgeText,
    required Color rightColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              leftText,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            rightBadgeText,
            style: AppTypography.telemetrySmall.copyWith(
              color: rightColor,
              fontWeight: FontWeight.w700,
              fontSize: 10,
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
              Text(
                value,
                style: AppTypography.telemetryLarge.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
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
}
