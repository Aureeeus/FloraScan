import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/sproutly_mascot.dart';
import '../../domain/entities/diagnostic_scan_model.dart';

/// Modal bottom sheet or full-view diagnostic report strictly mimicking Google Stitch.
class DiagnosisResultSheet extends StatefulWidget {
  const DiagnosisResultSheet({
    required this.result,
    required this.onDismiss,
    super.key,
  });

  final DiagnosticScanResult result;
  final VoidCallback onDismiss;

  @override
  State<DiagnosisResultSheet> createState() => _DiagnosisResultSheetState();
}

class _DiagnosisResultSheetState extends State<DiagnosisResultSheet> {
  // Checkbox states for Tier 1 action items
  bool _step1Checked = false;
  bool _step2Checked = false;
  bool _step3Checked = false;

  // Accordion toggle states for "Why?" explanations
  bool _showWhyMoisture = false;
  bool _showWhyTemp = false;
  bool _showWhyHumidity = false;
  bool _showWhyLight = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Top Telemetry & Edge AI Sync Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surfaceContainerLow,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'IoT Wand Linked • 42ms Edge AI',
                        style: AppTypography.labelUi.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 13,
                          color: AppColors.onSecondaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'STEP 5 OF 5',
                          style: AppTypography.labelUi.copyWith(
                            color: AppColors.onSecondaryContainer,
                            fontWeight: FontWeight.w700,
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
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
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
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.yard,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'CROP CONFIRMED',
                                        style: AppTypography.labelUi.copyWith(
                                          color: AppColors.secondary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 9,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.verified,
                                        size: 13,
                                        color: AppColors.secondary,
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Roma Tomato, Balcony Pot',
                                    style: AppTypography.headlineSmall.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.tune, color: AppColors.onSurfaceVariant),
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
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
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
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.errorContainer,
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.warning,
                                      size: 13,
                                      color: AppColors.onErrorContainer,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Dual Action Required',
                                      style: AppTypography.labelUi.copyWith(
                                        color: AppColors.onErrorContainer,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Text(
                                  'High Confidence',
                                  style: AppTypography.telemetrySmall.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'BOTH: DISEASE & ENVIRONMENT PROBLEM',
                            style: AppTypography.headlineSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppColors.onSurface,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Your tomato leaf has early fungal leaf spots (Early Blight). At the same time, your soil is currently too wet, which encourages the fungus to spread quickly.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Mascot encouragement
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const SproutlyMascot(
                                  size: 46,
                                  badgeEmoji: '🌿',
                                  badgeColor: AppColors.secondary,
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
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Follow the 3 quick steps below to keep your balcony Roma thriving.',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.onSurfaceVariant,
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
                        Text(
                          'Optical Evidence',
                          style: AppTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          'RETICLE ANALYSIS',
                          style: AppTypography.labelUi.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        // Left: Captured Leaf
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: Icon(
                                          Icons.center_focus_strong,
                                          size: 44,
                                          color: AppColors.error.withValues(alpha: 0.7),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 4,
                                        left: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.inverseSurface.withValues(alpha: 0.85),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Live Scan',
                                            style: AppTypography.labelUi.copyWith(
                                              color: AppColors.inverseOnSurface,
                                              fontSize: 8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Your Captured Leaf',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                Text(
                                  'Distinct bullseye rings',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 10,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Right: Reference Catalog
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Stack(
                                    children: [
                                      const Center(
                                        child: Icon(
                                          Icons.biotech,
                                          size: 44,
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 4,
                                        left: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.inverseSurface.withValues(alpha: 0.85),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'FloraScan Base',
                                            style: AppTypography.labelUi.copyWith(
                                              color: AppColors.inverseOnSurface,
                                              fontSize: 8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Early Blight',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                Text(
                                  'Alternaria solani',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 10,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.onSurfaceVariant,
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "What Your Plant's Surroundings Say",
                              style: AppTypography.headlineSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.onSurface,
                              ),
                            ),
                            Text(
                              'Real-time Bluetooth probe telemetry',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 11,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const Icon(Icons.sensors, color: AppColors.secondary, size: 20),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Sensor 1: Soil Moisture (Too High)
                    _buildWandSensorCard(
                      title: 'Soil Moisture',
                      icon: Icons.water_drop,
                      value: '78%',
                      target: 'Target: 50–70%',
                      statusTag: 'Too High',
                      isError: true,
                      summary: 'Roots are staying waterlogged.',
                      isExpanded: _showWhyMoisture,
                      onToggleWhy: () => setState(() => _showWhyMoisture = !_showWhyMoisture),
                      whyText:
                          'Why Soil Moisture Matters: Saturated soil limits root oxygen and triggers spore multiplication of soil-borne blight pathogens that splash onto lower foliage.',
                    ),
                    const SizedBox(height: 8),

                    // Sensor 2: Air Temperature (Good)
                    _buildWandSensorCard(
                      title: 'Air Temperature',
                      icon: Icons.thermostat,
                      value: '28°C',
                      target: 'Target: 22–30°C',
                      statusTag: 'Good',
                      isError: false,
                      summary: 'Comfortable growth temp.',
                      isExpanded: _showWhyTemp,
                      onToggleWhy: () => setState(() => _showWhyTemp = !_showWhyTemp),
                      whyText:
                          'Why Temperature Matters: Roma tomatoes metabolize sugars efficiently between 22°C and 30°C. 28°C supports cellular repair while plants fight off leaf infections.',
                    ),
                    const SizedBox(height: 8),

                    // Sensor 3: Humidity (Too High)
                    _buildWandSensorCard(
                      title: 'Humidity',
                      icon: Icons.cloud,
                      value: '86%',
                      target: 'Target: 50–75%',
                      statusTag: 'Too High',
                      isError: true,
                      summary: 'Damp air traps mold spores.',
                      isExpanded: _showWhyHumidity,
                      onToggleWhy: () => setState(() => _showWhyHumidity = !_showWhyHumidity),
                      whyText:
                          'Why Humidity Matters: Stagnant balcony humidity above 75% keeps water drops lingering on leaves, which acts as a germination incubator for fungal spores.',
                    ),
                    const SizedBox(height: 8),

                    // Sensor 4: Light (Good)
                    _buildWandSensorCard(
                      title: 'Light',
                      icon: Icons.wb_sunny,
                      value: '42,000 Lux',
                      target: 'Target: 30k–60k Lux',
                      statusTag: 'Good',
                      isError: false,
                      summary: 'Plenty of natural sunlight.',
                      isExpanded: _showWhyLight,
                      onToggleWhy: () => setState(() => _showWhyLight = !_showWhyLight),
                      whyText:
                          'Why Light Matters: Strong natural sunlight boosts tomato leaf cuticle thickness and speeds surface evaporation, strengthening plant natural defense.',
                    ),

                    const SizedBox(height: 18),

                    // 5. Prioritized Action Plan
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'What to Do Now',
                              style: AppTypography.headlineSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.onSurface,
                              ),
                            ),
                            Text(
                              'Prioritized checklist in strict order',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 11,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const Icon(Icons.checklist, color: AppColors.primary, size: 22),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Priority Tier 1: Simple Fixes First
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                ),
                                child: Center(
                                  child: Text(
                                    '1',
                                    style: AppTypography.labelUi.copyWith(
                                      color: AppColors.onPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'SIMPLE FIXES FIRST',
                                style: AppTypography.headlineSmall.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
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
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.secondary,
                                ),
                                child: Center(
                                  child: Text(
                                    '2',
                                    style: AppTypography.labelUi.copyWith(
                                      color: AppColors.onSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'ECO-FRIENDLY OPTIONS',
                                style: AppTypography.headlineSmall.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.science, color: AppColors.secondary, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Baking Soda Spray',
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Mix 1 tbsp baking soda + 1 tsp mild liquid soap into 1 liter water. Spray tops and bottoms of remaining leaves tomorrow morning.',
                                  style: AppTypography.bodySmall.copyWith(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.eco, color: AppColors.secondary, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Organic Neem Oil',
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Apply once every 7 days as a natural shield to suppress fungal spore germination.',
                                  style: AppTypography.bodySmall.copyWith(fontSize: 12),
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
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.error,
                                ),
                                child: Center(
                                  child: Text(
                                    '3',
                                    style: AppTypography.labelUi.copyWith(
                                      color: AppColors.onError,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'CHEMICALS (LAST RESORT ONLY)',
                                style: AppTypography.headlineSmall.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.errorContainer.withValues(alpha: 0.35),
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
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Use only if spots keep spreading after 1 week of drying and organic spray.',
                                  style: AppTypography.bodySmall.copyWith(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Action buttons
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Diagnosis and treatment log saved to Roma Tomato!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        widget.onDismiss();
                      },
                      icon: const Icon(Icons.bookmark, size: 18),
                      label: const Text('Save to Roma Tomato'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                  content: Text('Treatment logged to plant history.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit_calendar, size: 16),
                            label: const Text('Log Treatment'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(46),
                              backgroundColor: AppColors.surfaceContainerHigh,
                              foregroundColor: AppColors.onSurface,
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: widget.onDismiss,
                            icon: const Icon(Icons.document_scanner, size: 16),
                            label: const Text('Scan Again'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(46),
                              backgroundColor: AppColors.surfaceContainerHigh,
                              foregroundColor: AppColors.onSurface,
                              side: BorderSide.none,
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: isError ? AppColors.error : AppColors.secondary),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isError ? AppColors.errorContainer : AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      statusTag,
                      style: AppTypography.labelUi.copyWith(
                        color: isError ? AppColors.onErrorContainer : AppColors.onSecondaryContainer,
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
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Why?',
                            style: AppTypography.labelUi.copyWith(
                              fontSize: 9,
                              color: AppColors.onSurface,
                            ),
                          ),
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            size: 14,
                            color: AppColors.onSurface,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    value,
                    style: AppTypography.telemetryLarge.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    target,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Text(
                summary,
                style: AppTypography.bodySmall.copyWith(
                  color: isError ? AppColors.error : AppColors.secondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          if (isExpanded) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                whyText,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11,
                  color: AppColors.onSurface,
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
                activeColor: AppColors.primary,
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
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
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
