import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/flora_scan_header.dart';
import '../../../core/widgets/sproutly_mascot.dart';

/// Screen providing agronomic educational guides and atlas matching Google Stitch.
class LearnScreen extends ConsumerStatefulWidget {
  const LearnScreen({super.key});

  @override
  ConsumerState<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends ConsumerState<LearnScreen> {
  int _activeTabIndex = 0; // 0: Quick Lessons, 1: Problems, 2: A-Z Terms
  String _selectedProblemCrop = 'All';

  void _openStoryLessonModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.secondary)),
                    const SizedBox(width: 4),
                    Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.secondary)),
                    const SizedBox(width: 4),
                    Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.surfaceContainerHighest)),
                    const SizedBox(width: 4),
                    Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.surfaceContainerHighest)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(modalContext),
                ),
              ],
            ),
            Text(
              'LESSON 3 • STEP 2 OF 4',
              style: AppTypography.labelUi.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Compare Sharp vs Blurry',
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 90,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(Icons.check_circle, color: AppColors.secondary, size: 36),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'GOOD',
                            style: AppTypography.labelUi.copyWith(
                              color: AppColors.onSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 9,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sharp focus on leaf veins under daylight.',
                          style: AppTypography.bodySmall.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 90,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(Icons.cancel, color: AppColors.error, size: 36),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'POOR',
                            style: AppTypography.labelUi.copyWith(
                              color: AppColors.onError,
                              fontWeight: FontWeight.w700,
                              fontSize: 9,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Direct sun flare washes out diagnostic color.',
                          style: AppTypography.bodySmall.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => Navigator.pop(modalContext),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Got it! Continue Lesson'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const FloraScanHeader(subtitle: 'Learn'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Mascot Greeting & Search Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryFixed,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.secondary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'OFFLINE READY • ZERO DATA',
                                  style: AppTypography.labelUi.copyWith(
                                    color: AppColors.onSecondaryFixedVariant,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Magandang araw!',
                            style: AppTypography.headlineSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.onSurface,
                            ),
                          ),
                          Text(
                            'Quick 30-sec garden guides for outdoor sun.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SproutlyMascot(size: 52),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Search Input
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search lessons, pests, leaf spots, terms...',
                    hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.outline),
                    prefixIcon: const Icon(Icons.search, color: AppColors.onSurfaceVariant),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.mic, color: AppColors.onSurfaceVariant),
                      onPressed: () {},
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Replaying interactive garden tour...'),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.replay, size: 14, color: AppColors.secondary),
                        const SizedBox(width: 4),
                        Text(
                          'Replay Garden App Tour',
                          style: AppTypography.labelUi.copyWith(
                            color: AppColors.secondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'v2.4.0 • Local DB',
                    style: AppTypography.telemetrySmall.copyWith(
                      color: AppColors.outline,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 2. "Continue Where You Left Off" Hero Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Color(0x1F012D1D), blurRadius: 10, offset: Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryFixed,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            'IN PROGRESS • 2 OF 4 CARDS',
                            style: AppTypography.labelUi.copyWith(
                              color: AppColors.onSecondaryFixedVariant,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.timer, size: 14, color: AppColors.onPrimaryContainer),
                            const SizedBox(width: 3),
                            Text(
                              '30s left',
                              style: AppTypography.telemetrySmall.copyWith(
                                color: AppColors.onPrimaryContainer,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'How to Take a Good Leaf Photo',
                                style: AppTypography.headlineSmall.copyWith(
                                  color: AppColors.onPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Avoid glare & blurry focus in direct afternoon sunlight.',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.onPrimaryContainer,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          child: const Icon(
                            Icons.center_focus_strong,
                            color: AppColors.secondaryFixed,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(9999),
                      child: LinearProgressIndicator(
                        value: 0.5,
                        minHeight: 5,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondaryFixed),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _openStoryLessonModal,
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('Resume Step 2 (30s)'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        backgroundColor: AppColors.secondaryFixed,
                        foregroundColor: AppColors.onSecondaryFixed,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Segmented Tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _buildSegmentTab('Quick Lessons (6)', 0),
                    _buildSegmentTab('Problems (12)', 1),
                    _buildSegmentTab('A–Z Terms', 2),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // TAB CONTENT PANELS
              if (_activeTabIndex == 0) _buildLessonsTab(),
              if (_activeTabIndex == 1) _buildProblemsTab(),
              if (_activeTabIndex == 2) _buildGlossaryTab(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentTab(String title, int index) {
    final isSelected = _activeTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTabIndex = index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceContainerLowest : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))]
                : null,
          ),
          child: Center(
            child: Text(
              title,
              style: AppTypography.labelUi.copyWith(
                color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLessonsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Story Lessons',
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  'Tap to launch bite-sized 30-sec tutorials',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.secondaryFixed,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                '4 of 6 Done',
                style: AppTypography.telemetrySmall.copyWith(
                  color: AppColors.onSecondaryFixed,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Lesson 1
        _buildLessonCard(
          number: '1.',
          title: 'Charging & Pairing Wand',
          subtitle: 'Fast BLE pairing in the garden yard',
          duration: '30s',
          icon: Icons.usb,
          isCompleted: true,
          onTap: _openStoryLessonModal,
        ),
        const SizedBox(height: 8),

        // Lesson 2
        _buildLessonCard(
          number: '2.',
          title: 'Using Wand in Soil',
          subtitle: '5cm root insertion depth & probe safety',
          duration: '45s',
          icon: Icons.water_drop,
          isCompleted: true,
          onTap: _openStoryLessonModal,
        ),
        const SizedBox(height: 8),

        // Lesson 3: Spotlight
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
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
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.photo_camera, color: AppColors.secondaryFixed, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '3. Taking a Good Leaf Photo',
                                style: AppTypography.headlineSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryFixed,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Active',
                                  style: AppTypography.labelUi.copyWith(
                                    color: AppColors.onSecondaryFixedVariant,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Fill frame & prevent sun washing',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    '45s',
                    style: AppTypography.telemetrySmall.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check, size: 14, color: AppColors.secondary),
                          const SizedBox(width: 4),
                          Text(
                            'Sharp focus',
                            style: AppTypography.bodySmall.copyWith(fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.close, size: 14, color: AppColors.error),
                          const SizedBox(width: 4),
                          Text(
                            'Sun flare',
                            style: AppTypography.bodySmall.copyWith(fontSize: 10, fontWeight: FontWeight.w600),
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
        const SizedBox(height: 8),

        // Lesson 4
        _buildLessonCard(
          number: '4.',
          title: 'Reading Your Result',
          subtitle: 'Too Low, Good, & Outbreak zones',
          duration: '60s',
          icon: Icons.speed,
          isCompleted: false,
          onTap: _openStoryLessonModal,
        ),
        const SizedBox(height: 8),

        // Lesson 5
        _buildLessonCard(
          number: '5.',
          title: 'Water & Sun for 3 Crops',
          subtitle: 'Tomato, Potato & Corn optimal lux',
          duration: '60s',
          icon: Icons.wb_sunny,
          isCompleted: false,
          onTap: _openStoryLessonModal,
        ),
        const SizedBox(height: 8),

        // Lesson 6
        _buildLessonCard(
          number: '6.',
          title: 'Safe Garden Treatments',
          subtitle: 'Neem oil, baking soda & dilution',
          duration: '45s',
          icon: Icons.sanitizer,
          isCompleted: false,
          onTap: _openStoryLessonModal,
        ),
      ],
    );
  }

  Widget _buildLessonCard({
    required String number,
    required String title,
    required String subtitle,
    required String duration,
    required IconData icon,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.secondary, size: 18),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$number $title',
                          style: AppTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.onSurface,
                          ),
                        ),
                        if (isCompleted) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.check_circle, size: 14, color: AppColors.secondary),
                        ],
                      ],
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              duration,
              style: AppTypography.telemetrySmall.copyWith(
                color: AppColors.outline,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProblemsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Crop Diagnostics Atlas',
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.onSurface,
              ),
            ),
            Text(
              '12 offline conditions',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCropFilterBtn('All', 'All (12)'),
              const SizedBox(width: 6),
              _buildCropFilterBtn('Tomato', '🍅 Tomato'),
              const SizedBox(width: 6),
              _buildCropFilterBtn('Potato', '🥔 Potato'),
              const SizedBox(width: 6),
              _buildCropFilterBtn('Corn', '🌽 Corn'),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Problem 1: Tomato Early Blight
        _buildProblemAtlasCard(
          title: 'Tomato Early Blight',
          pathogen: 'Alternaria solani',
          crop: 'Tomato',
          severityTag: 'HIGH SEVERITY',
          tagBg: AppColors.tertiaryFixed,
          tagColor: AppColors.onTertiaryFixed,
          description: 'Concentric brown rings on lower leaves caused by wet soil splash during heavy watering.',
          recipeLabel: 'Neem / Soda safe',
        ),
        const SizedBox(height: 10),

        // Problem 2: Potato Late Blight
        _buildProblemAtlasCard(
          title: 'Potato Late Blight',
          pathogen: 'Phytophthora infestans',
          crop: 'Potato',
          severityTag: 'URGENT OUTBREAK',
          tagBg: AppColors.errorContainer,
          tagColor: AppColors.onErrorContainer,
          description: 'Rapidly expanding dark brown lesions with pale margins. Spreads fast during humid, cool mornings.',
          recipeLabel: 'Isolate immediately',
        ),
        const SizedBox(height: 10),

        // Problem 3: Corn Common Rust
        _buildProblemAtlasCard(
          title: 'Corn Common Rust',
          pathogen: 'Puccinia sorghi',
          crop: 'Corn',
          severityTag: 'MODERATE',
          tagBg: AppColors.surfaceContainerHighest,
          tagColor: AppColors.onSurface,
          description: 'Cinnamon-colored pustules that erupt on both surfaces of corn leaves, reducing overall plant vigor.',
          recipeLabel: 'Manageable airflow',
        ),
        const SizedBox(height: 10),

        // Problem 4: Blossom End Rot
        _buildProblemAtlasCard(
          title: 'Blossom End Rot',
          pathogen: 'Calcium & Moisture Swings',
          crop: 'Tomato',
          severityTag: 'ENVIRONMENTAL',
          tagBg: AppColors.secondaryFixed,
          tagColor: AppColors.onSecondaryFixed,
          description: 'Sunken leathery patch on tomato bottom caused by uneven watering and low root calcium uptake.',
          recipeLabel: 'Watering calibration',
        ),
      ],
    );
  }

  Widget _buildCropFilterBtn(String key, String label) {
    final isSelected = _selectedProblemCrop == key;
    return InkWell(
      onTap: () => setState(() => _selectedProblemCrop = key),
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Text(
          label,
          style: AppTypography.labelUi.copyWith(
            color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildProblemAtlasCard({
    required String title,
    required String pathogen,
    required String crop,
    required String severityTag,
    required Color tagBg,
    required Color tagColor,
    required String description,
    required String recipeLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tagBg,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          severityTag,
                          style: AppTypography.labelUi.copyWith(
                            color: tagColor,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        crop.toUpperCase(),
                        style: AppTypography.labelUi.copyWith(
                          color: AppColors.outline,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: AppTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    pathogen,
                    style: AppTypography.bodySmall.copyWith(
                      fontStyle: FontStyle.italic,
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.biotech, color: AppColors.secondary, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.eco, size: 14, color: AppColors.secondary),
                  const SizedBox(width: 4),
                  Text(
                    recipeLabel,
                    style: AppTypography.labelUi.copyWith(
                      color: AppColors.secondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Displaying treatment recipe for $title'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      'TREATMENT RECIPE',
                      style: AppTypography.labelUi.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward, size: 12, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlossaryTab() {
    final terms = [
      {'term': 'Abiotic Stress', 'meaning': 'Non-living stressors such as drought, extreme heat, or soil compaction.'},
      {'term': 'Blight (Alternaria)', 'meaning': 'Fungal infection causing circular brown spots with yellow chlorotic halos.'},
      {'term': 'Chlorosis (Paninilaw)', 'meaning': 'Yellowing of leaf tissue due to lack of chlorophyll, often from waterlogging.'},
      {'term': 'Inference Latency', 'meaning': 'Time taken by local on-device AI (e.g. 42ms) to identify pathogen spots.'},
      {'term': 'Solanaceae (Nightshades)', 'meaning': 'Plant family including tomato, red chili, eggplant, and potato.'},
      {'term': 'VWC (Volumetric Water)', 'meaning': 'Percentage of water volume in soil substrate measured by the FloraWand.'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Gardener's Glossary",
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.onSurface,
              ),
            ),
            Text(
              '18 Terms • English + Tagalog',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...terms.map(
          (t) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t['term']!,
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t['meaning']!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onSurface,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
