import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/flora_scan_header.dart';
import '../../../core/widgets/sproutly_mascot.dart';
import '../domain/entities/lesson_progress.dart';
import 'providers/learn_providers.dart';

/// Metadata definition for interactive agronomy micro-lessons.
class _LessonDefinition {
  const _LessonDefinition({
    required this.id,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.icon,
    required this.storyTitle,
    required this.goodTip,
    required this.poorTip,
  });

  final String id;
  final int number;
  final String title;
  final String subtitle;
  final String duration;
  final IconData icon;
  final String storyTitle;
  final String goodTip;
  final String poorTip;
  final int totalSteps = 4;
}

const _kAllLessons = [
  _LessonDefinition(
    id: 'lesson_1',
    number: 1,
    title: 'Charging & Pairing Wand',
    subtitle: 'Fast BLE auto-pair in garden yard',
    duration: '30s',
    icon: Icons.bluetooth_connected,
    storyTitle: 'Fast BLE Auto-Pairing',
    goodTip: 'Hold probe 2s near phone. Connects instantly.',
    poorTip: 'Don\'t open phone Bluetooth menu. App auto-pairs.',
  ),
  _LessonDefinition(
    id: 'lesson_2',
    number: 2,
    title: 'Using Wand in Soil',
    subtitle: '5cm depth, 25-35% VWC & saucer triage',
    duration: '45s',
    icon: Icons.water_drop,
    storyTitle: 'The 5 cm Soil Rule & Triage',
    goodTip: 'Insert prongs 5cm deep midway between stem & pot rim.',
    poorTip: 'Don\'t touch bare surface soil or hit pot edge.',
  ),
  _LessonDefinition(
    id: 'lesson_3',
    number: 3,
    title: 'How to Take a Good Leaf Photo',
    subtitle: 'Avoid glare & blurry focus in direct afternoon sunlight.',
    duration: '45s',
    icon: Icons.photo_camera,
    storyTitle: 'Compare Sharp vs Blurry',
    goodTip: 'Sharp focus on leaf veins under daylight.',
    poorTip: 'Direct sun flare washes out diagnostic color.',
  ),
  _LessonDefinition(
    id: 'lesson_4',
    number: 4,
    title: 'Reading Your Result',
    subtitle: 'Sensor tiebreaker: hypoxia vs blight',
    duration: '60s',
    icon: Icons.speed,
    storyTitle: 'Sensor Tiebreakers & Hypoxia',
    goodTip: 'Check moisture >40% before assuming leaf disease.',
    poorTip: 'Don\'t spray fungicide on overwatered roots.',
  ),
  _LessonDefinition(
    id: 'lesson_5',
    number: 5,
    title: 'Water & Sun for 3 Crops',
    subtitle: 'Tomato, Chili & Eggplant VWC & lux',
    duration: '60s',
    icon: Icons.wb_sunny,
    storyTitle: 'Crop Light & Moisture Profiles',
    goodTip: 'Keep tomatoes 25-35% VWC; Chili loves warmth.',
    poorTip: 'Don\'t keep nightshade root zones waterlogged.',
  ),
  _LessonDefinition(
    id: 'lesson_6',
    number: 6,
    title: 'Safe Garden Treatments',
    subtitle: 'Neem at dusk, bicarb at morning & mulch',
    duration: '45s',
    icon: Icons.sanitizer,
    storyTitle: 'Safe Home Remedies & Pruning',
    goodTip: 'Apply neem oil at dusk; baking soda in early morning.',
    poorTip: 'Never spray oils at peak midday direct sunlight.',
  ),
];

/// Screen providing agronomic educational guides and atlas matching Google Stitch.
class LearnScreen extends ConsumerStatefulWidget {
  const LearnScreen({super.key});

  @override
  ConsumerState<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends ConsumerState<LearnScreen> {
  int _activeTabIndex = 0; // 0: Quick Lessons, 1: Problems, 2: A-Z Terms
  String _selectedProblemCrop = 'All';

  void _openStoryLessonModal({
    String lessonId = 'lesson_1',
    int currentStep = 1,
    int totalSteps = 4,
    String lessonTitle = 'Fast BLE Auto-Pairing',
    int lessonNumber = 1,
    String goodTip = 'Hold probe 2s near phone. Connects instantly.',
    String poorTip = 'Don\'t open phone Bluetooth menu. App auto-pairs.',
  }) {
    final displayStep = (currentStep == 0) ? 1 : currentStep;

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
                  children: List.generate(totalSteps, (index) {
                    final isDoneOrCurrent = index < displayStep;
                    return Container(
                      margin: const EdgeInsets.only(right: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDoneOrCurrent ? AppColors.secondary : AppColors.surfaceContainerHighest,
                      ),
                    );
                  }),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(modalContext),
                ),
              ],
            ),
            Text(
              'LESSON $lessonNumber • STEP $displayStep OF $totalSteps',
              style: AppTypography.labelUi.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              lessonTitle,
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
                          goodTip,
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
                          poorTip,
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
              onPressed: () {
                final nextStep = (displayStep + 1).clamp(1, totalSteps);
                final isDone = displayStep >= totalSteps;
                ref.read(lessonProgressNotifierProvider.notifier).updateStep(
                  lessonId,
                  nextStep,
                  isCompleted: isDone,
                );
                Navigator.pop(modalContext);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(displayStep >= totalSteps ? 'Complete Lesson' : 'Got it! Continue Lesson'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progressAsync = ref.watch(lessonProgressNotifierProvider);
    final progressMap = progressAsync.value ?? const {
      'lesson_1': LessonProgress(lessonId: 'lesson_1', isCompleted: false, lastStep: 0, totalSteps: 4),
      'lesson_2': LessonProgress(lessonId: 'lesson_2', isCompleted: false, lastStep: 0, totalSteps: 4),
      'lesson_3': LessonProgress(lessonId: 'lesson_3', isCompleted: false, lastStep: 0, totalSteps: 4),
      'lesson_4': LessonProgress(lessonId: 'lesson_4', isCompleted: false, lastStep: 0, totalSteps: 4),
      'lesson_5': LessonProgress(lessonId: 'lesson_5', isCompleted: false, lastStep: 0, totalSteps: 4),
      'lesson_6': LessonProgress(lessonId: 'lesson_6', isCompleted: false, lastStep: 0, totalSteps: 4),
    };
    final activeLesson = _kAllLessons.firstWhere(
      (l) => !(progressMap[l.id]?.isCompleted ?? false),
      orElse: () => _kAllLessons.first,
    );
    final activeProgress = progressMap[activeLesson.id] ??
        LessonProgress(lessonId: activeLesson.id, isCompleted: false, lastStep: 0, totalSteps: activeLesson.totalSteps);
    final allDone = _kAllLessons.every((l) => progressMap[l.id]?.isCompleted ?? false);
    final activeStep = activeProgress.lastStep == 0 ? 1 : activeProgress.lastStep;
    final activeTotal = activeProgress.totalSteps;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                          Text(
                            'Good morning!',
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

              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
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
                      mainAxisSize: MainAxisSize.min,
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
                  InkWell(
                    onTap: () async {
                      await ref.read(lessonProgressNotifierProvider.notifier).resetProgress();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Learning progress reset to beginning.'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.refresh, size: 14, color: AppColors.outline),
                        const SizedBox(width: 4),
                        Text(
                          'Reset Progress',
                          style: AppTypography.labelUi.copyWith(
                            color: AppColors.outline,
                            fontSize: 10,
                          ),
                        ),
                      ],
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
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryFixed,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              allDone
                                  ? 'ALL LESSONS COMPLETE • 6 OF 6'
                                  : (activeProgress.lastStep == 0
                                      ? 'START HERE • STEP 1 OF $activeTotal CARDS'
                                      : 'IN PROGRESS • $activeStep OF $activeTotal CARDS'),
                              style: AppTypography.labelUi.copyWith(
                                color: AppColors.onSecondaryFixedVariant,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer, size: 14, color: AppColors.onPrimaryContainer),
                            const SizedBox(width: 3),
                            Text(
                              '${activeLesson.duration} left',
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
                                activeLesson.title,
                                style: AppTypography.headlineSmall.copyWith(
                                  color: AppColors.onPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                activeLesson.subtitle,
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
                          child: Icon(
                            activeLesson.icon,
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
                        value: allDone
                            ? 1.0
                            : (activeProgress.lastStep / activeTotal).clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondaryFixed),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _openStoryLessonModal(
                        lessonId: activeLesson.id,
                        currentStep: activeStep,
                        totalSteps: activeTotal,
                        lessonTitle: activeLesson.storyTitle,
                        lessonNumber: activeLesson.number,
                        goodTip: activeLesson.goodTip,
                        poorTip: activeLesson.poorTip,
                      ),
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: Text(
                        allDone
                            ? 'Review Curriculum (30s)'
                            : (activeProgress.lastStep == 0
                                ? 'Start Step 1 (${activeLesson.duration})'
                                : 'Resume Step $activeStep (${activeLesson.duration})'),
                      ),
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
              if (_activeTabIndex == 0) _buildLessonsTab(progressMap),
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

  Widget _buildLessonsTab(Map<String, LessonProgress> progressMap) {
    final completedCount = progressMap.values.where((p) => p.isCompleted).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.secondaryFixed,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                '$completedCount of 6 Done',
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

        ..._kAllLessons.map((lesson) {
          final p = progressMap[lesson.id];
          final isCompleted = p?.isCompleted ?? false;
          final step = (p == null || p.lastStep == 0) ? 1 : p.lastStep;
          final total = p?.totalSteps ?? lesson.totalSteps;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _buildLessonCard(
              number: '${lesson.number}.',
              title: lesson.title,
              subtitle: lesson.subtitle,
              duration: lesson.duration,
              icon: lesson.icon,
              isCompleted: isCompleted,
              onTap: () => _openStoryLessonModal(
                lessonId: lesson.id,
                lessonNumber: lesson.number,
                currentStep: step,
                totalSteps: total,
                lessonTitle: lesson.storyTitle,
                goodTip: lesson.goodTip,
                poorTip: lesson.poorTip,
              ),
            ),
          );
        }),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '$number $title',
                          style: AppTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
          children: [
            Expanded(
              child: Text(
                'Crop Diagnostics Atlas',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
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
              _buildCropFilterBtn('Chili', '🌶️ Chili'),
              const SizedBox(width: 6),
              _buildCropFilterBtn('Eggplant', '🍆 Eggplant'),
            ],
          ),
        ),

        const SizedBox(height: 12),

        if (_selectedProblemCrop == 'All' || _selectedProblemCrop == 'Tomato') ...[
          // Problem 1: Tomato Early Blight
          _buildProblemAtlasCard(
            title: 'Tomato Early Blight',
            pathogen: 'Alternaria solani',
            crop: 'Tomato',
            severityTag: 'HIGH SEVERITY',
            tagBg: AppColors.tertiaryFixed,
            tagColor: AppColors.onTertiaryFixed,
            description: 'Concentric dark rings on lower leaves from soil splash. Prune lowest 15cm foliage and apply mulch.',
            recipeLabel: 'Neem (dusk) / 15cm prune',
          ),
          const SizedBox(height: 10),
        ],

        if (_selectedProblemCrop == 'All' || _selectedProblemCrop == 'Chili') ...[
          // Problem 2: Chili Anthracnose
          _buildProblemAtlasCard(
            title: 'Chili Anthracnose',
            pathogen: 'Colletotrichum capsici',
            crop: 'Chili',
            severityTag: 'HIGH SEVERITY',
            tagBg: AppColors.tertiaryFixed,
            tagColor: AppColors.onTertiaryFixed,
            description: 'Circular sunken lesions with spore rings aggravated by wet foliage. Apply bicarb in early morning.',
            recipeLabel: 'Bicarb (morning) / Airflow',
          ),
          const SizedBox(height: 10),
        ],

        if (_selectedProblemCrop == 'All' || _selectedProblemCrop == 'Eggplant') ...[
          // Problem 3: Eggplant Phomopsis Blight
          _buildProblemAtlasCard(
            title: 'Eggplant Phomopsis Blight',
            pathogen: 'Phomopsis vexans',
            crop: 'Eggplant',
            severityTag: 'URGENT OUTBREAK',
            tagBg: AppColors.errorContainer,
            tagColor: AppColors.onErrorContainer,
            description: 'Discolored brownish leaf spots with pycnidia dots. Space containers for airflow and mulch 3cm.',
            recipeLabel: 'Isolate container & 3cm mulch',
          ),
          const SizedBox(height: 10),
        ],

        if (_selectedProblemCrop == 'All' || _selectedProblemCrop == 'Tomato') ...[
          // Problem 4: Blossom End Rot
          _buildProblemAtlasCard(
            title: 'Blossom End Rot',
            pathogen: 'Calcium & Moisture Swings',
            crop: 'Tomato',
            severityTag: 'ENVIRONMENTAL',
            tagBg: AppColors.secondaryFixed,
            tagColor: AppColors.onSecondaryFixed,
            description: 'Sunken leathery patch on tomato bottom caused by uneven watering and root hypoxia. Not fungal.',
            recipeLabel: 'Stabilize 25-35% VWC',
          ),
        ],
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
            children: [
              Expanded(
                child: Column(
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      pathogen,
                      style: AppTypography.bodySmall.copyWith(
                        fontStyle: FontStyle.italic,
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.biotech, color: AppColors.secondary, size: 22),
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
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.eco, size: 14, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        recipeLabel,
                        style: AppTypography.labelUi.copyWith(
                          color: AppColors.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
                  mainAxisSize: MainAxisSize.min,
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
      {'term': 'Abiotic Stress', 'meaning': 'Non-living stressors such as drought, heatwaves, or soil waterlogging vs living pathogens.'},
      {'term': 'Blight (Alternaria)', 'meaning': 'Fungal infection causing circular brown rings with yellow chlorotic halos on lower foliage.'},
      {'term': 'Chlorosis', 'meaning': 'Yellowing of leaf tissue from root hypoxia, nutrient starvation, or fungal infection.'},
      {'term': 'Inference Latency', 'meaning': 'Time taken by local on-device ONNX AI (42ms) to identify diseases without an internet connection.'},
      {'term': 'Overwatering Triage', 'meaning': 'Empty drip saucer immediately; if soil remains soggy, amend potting mix with 20–30% perlite.'},
      {'term': 'Solanaceae (Nightshades)', 'meaning': 'Plant family including sweet plum tomato, red habanero chili, and black beauty eggplant.'},
      {'term': 'Spray Timing', 'meaning': 'Apply neem oil at dusk to protect pollinators and prevent sun scorch; apply bicarb in early morning.'},
      {'term': 'VWC (Volumetric Water)', 'meaning': 'Percentage of root-zone water volume measured 5cm deep by the FloraWand (25–35% is ideal).'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "Gardener's Glossary",
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '18 Terms • English',
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
