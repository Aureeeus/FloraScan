import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/voice_search_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/flora_scan_header.dart';
import '../../../core/widgets/sproutly_mascot.dart';
import '../domain/entities/atlas_condition_model.dart';
import '../domain/entities/glossary_term_model.dart';
import '../domain/entities/lesson_definition.dart';
import '../domain/entities/lesson_progress.dart';
import 'providers/learn_providers.dart';

/// Screen providing agronomic educational guides and atlas matching Google Stitch.
class LearnScreen extends ConsumerStatefulWidget {
  const LearnScreen({super.key});

  @override
  ConsumerState<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends ConsumerState<LearnScreen> {
  int _activeTabIndex = 0; // 0: Quick Lessons, 1: Diseases, 2: A-Z Terms
  String _selectedProblemCrop = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isVoiceListening = false;

  @override
  void dispose() {
    if (_isVoiceListening) {
      ref.read(voiceSearchServiceProvider).cancelListening();
    }
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleVoiceSearch() async {
    final voiceService = ref.read(voiceSearchServiceProvider);
    if (_isVoiceListening) {
      await voiceService.stopListening();
      if (mounted) {
        setState(() => _isVoiceListening = false);
      }
      return;
    }

    setState(() => _isVoiceListening = true);

    await voiceService.startListening(
      onResult: (words, isFinal) {
        if (!mounted) return;
        setState(() {
          _searchController.text = words;
          _searchController.selection = TextSelection.fromPosition(
            TextPosition(offset: words.length),
          );
          _searchQuery = words.trim().toLowerCase();
          if (isFinal) {
            _isVoiceListening = false;
          }
        });
      },
      onStatusChanged: () {
        if (mounted) {
          setState(() {
            _isVoiceListening = voiceService.isListening;
          });
        }
      },
      onError: (errorMessage) {
        if (!mounted) return;
        setState(() => _isVoiceListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      },
    );
  }

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  bool get _isDark => _theme.brightness == Brightness.dark;

  Color _resolveTagBg(AtlasCondition condition, ColorScheme colorScheme, bool isDark) {
    if (!isDark) return condition.tagBg;
    final tag = condition.severityTag.toUpperCase();
    if (tag.contains('URGENT') || tag.contains('CRITICAL')) {
      return colorScheme.errorContainer.withValues(alpha: 0.35);
    } else if (tag.contains('HIGH')) {
      return colorScheme.tertiaryContainer.withValues(alpha: 0.4);
    } else {
      return colorScheme.secondaryContainer.withValues(alpha: 0.35);
    }
  }

  Color _resolveTagColor(AtlasCondition condition, ColorScheme colorScheme, bool isDark) {
    if (!isDark) return condition.tagColor;
    final tag = condition.severityTag.toUpperCase();
    if (tag.contains('URGENT') || tag.contains('CRITICAL')) {
      return colorScheme.error;
    } else if (tag.contains('HIGH')) {
      return colorScheme.onTertiaryContainer;
    } else {
      return colorScheme.secondary;
    }
  }

  void _openTreatmentRecipeModal(AtlasCondition condition) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLowest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: isDark
              ? Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)))
              : null,
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.outlineVariant : AppColors.outlineVariant,
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _resolveTagBg(condition, colorScheme, isDark),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          condition.severityTag,
                          style: AppTypography.labelUi.copyWith(
                            color: _resolveTagColor(condition, colorScheme, isDark),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        condition.crop.toUpperCase(),
                        style: AppTypography.labelUi.copyWith(
                          color: isDark ? colorScheme.onSurfaceVariant : AppColors.outline,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: isDark ? colorScheme.onSurface : AppColors.onSurface),
                    onPressed: () => Navigator.pop(modalContext),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                condition.title,
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                ),
              ),
              Text(
                'Pathogen: ${condition.pathogen} • Crop: ${condition.crop}',
                style: AppTypography.bodySmall.copyWith(
                  fontStyle: FontStyle.italic,
                  color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                icon: Icons.check_circle_outline,
                title: 'Primary Symptoms',
                color: isDark ? colorScheme.secondary : AppColors.secondary,
                children: condition.symptoms
                    .map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  s,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              _buildSectionCard(
                icon: Icons.eco_outlined,
                title: 'Organic Field Protocol',
                color: isDark ? colorScheme.secondary : AppColors.secondary,
                children: [
                  Text(
                    condition.organicTreatment,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSectionCard(
                icon: Icons.biotech_outlined,
                title: 'Chemical / Synthetic Remedy',
                color: isDark ? colorScheme.tertiary : AppColors.tertiary,
                children: [
                  Text(
                    condition.chemicalTreatment,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSectionCard(
                icon: Icons.shield_outlined,
                title: 'Preventative Cultural Action',
                color: isDark ? colorScheme.primary : AppColors.primary,
                children: [
                  Text(
                    condition.preventativeAction,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(modalContext),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: isDark ? colorScheme.primary : AppColors.primaryContainer,
                  foregroundColor: isDark ? colorScheme.onPrimary : AppColors.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Close Protocol'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    final isDark = _isDark;
    final colorScheme = _colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainer : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? colorScheme.outlineVariant.withValues(alpha: 0.25)
              : AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: AppTypography.labelUi.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  void _showResetConfirmationDialog() {
    final isDark = _isDark;
    final colorScheme = _colorScheme;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? colorScheme.surfaceContainerHigh : AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reset Learning Progress?',
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? colorScheme.onSurface : AppColors.onSurface,
          ),
        ),
        content: Text(
          'This will reset your milestones across all 6 lesson guides back to Step 1. Your saved plant profiles and sensor logs will not be affected.',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: AppTypography.labelUi.copyWith(
                color: isDark ? colorScheme.onSurfaceVariant : AppColors.outline,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? colorScheme.error : AppColors.error,
              foregroundColor: isDark ? colorScheme.onError : AppColors.onError,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(lessonProgressNotifierProvider.notifier).resetProgress();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Learning progress reset to beginning.'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Reset All'),
          ),
        ],
      ),
    );
  }

  void _showGardenTourDialog() {
    final isDark = _isDark;
    final colorScheme = _colorScheme;

    showDialog<void>(
      context: context,
      builder: (tourContext) => AlertDialog(
        backgroundColor: isDark ? colorScheme.surfaceContainerHigh : AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            SproutlyMascot(
              size: 32,
              badgeColor: isDark ? colorScheme.primary : AppColors.secondary,
            ),
            const SizedBox(width: 8),
            Text(
              'FloraScan Tour',
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? colorScheme.onSurface : AppColors.onSurface,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTourStep(
              number: '1',
              title: 'BLE Wand Probe',
              desc: 'Insert probe 5cm deep to read real-time soil moisture and ambient climate.',
            ),
            const SizedBox(height: 10),
            _buildTourStep(
              number: '2',
              title: 'AI Leaf Scanner',
              desc: 'Frame leaf veins under daylight for instant on-device disease diagnosis.',
            ),
            const SizedBox(height: 10),
            _buildTourStep(
              number: '3',
              title: 'Interactive Care',
              desc: 'Follow curated 30-sec agronomic tutorials to protect your garden harvest.',
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? colorScheme.primary : AppColors.primaryContainer,
              foregroundColor: isDark ? colorScheme.onPrimary : AppColors.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(tourContext),
            child: const Text('Start Exploring'),
          ),
        ],
      ),
    );
  }

  Widget _buildTourStep({required String number, required String title, required String desc}) {
    final isDark = _isDark;
    final colorScheme = _colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isDark ? colorScheme.secondaryContainer : AppColors.secondaryFixed,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: AppTypography.labelUi.copyWith(
                color: isDark ? colorScheme.onSecondaryContainer : AppColors.onSecondaryFixed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                ),
              ),
              Text(
                desc,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openStoryLessonModal({
    required List<LessonDefinition> allLessons,
    String lessonId = 'lesson_1',
    int currentStep = 1,
    int totalSteps = 4,
    String lessonTitle = 'Fast BLE Auto-Pairing',
    int lessonNumber = 1,
    String goodTip = 'Hold probe 2s near phone. Connects instantly.',
    String poorTip = 'Don\'t open phone Bluetooth menu. App auto-pairs.',
  }) {
    final displayStep = (currentStep == 0) ? 1 : currentStep;

    final lessonDef = allLessons.firstWhere(
      (l) => l.id == lessonId,
      orElse: () => allLessons.first,
    );
    final activeStepData = (displayStep >= 1 && displayStep <= lessonDef.steps.length)
        ? lessonDef.steps[displayStep - 1]
        : null;

    final resolvedTitle = activeStepData?.title ?? lessonTitle;
    final resolvedGoodTip = activeStepData?.goodTip ?? goodTip;
    final resolvedPoorTip = activeStepData?.poorTip ?? poorTip;

    final isDark = _isDark;
    final colorScheme = _colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setModalState) {
          final isNarrow = MediaQuery.sizeOf(context).width < 340;
          return Container(
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLowest,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: isDark
                  ? Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)))
                  : null,
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
                      color: isDark ? colorScheme.outlineVariant : AppColors.outlineVariant,
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
                        final isCurrent = index == displayStep - 1;
                        final isDone = index < displayStep - 1;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 6),
                          width: isCurrent ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: (isCurrent || isDone)
                                ? (isDark ? colorScheme.secondary : AppColors.secondary)
                                : (isDark ? colorScheme.surfaceContainerHighest : AppColors.surfaceContainerHighest),
                          ),
                        );
                      }),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: isDark ? colorScheme.onSurface : AppColors.onSurface),
                      onPressed: () => Navigator.pop(modalContext),
                    ),
                  ],
                ),
                Text(
                  'LESSON $lessonNumber • STEP $displayStep OF $totalSteps',
                  style: AppTypography.labelUi.copyWith(
                    color: isDark ? colorScheme.secondary : AppColors.secondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  resolvedTitle,
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                if (isNarrow) ...[
                  _buildTipCard(isGood: true, text: resolvedGoodTip),
                  const SizedBox(height: 10),
                  _buildTipCard(isGood: false, text: resolvedPoorTip),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildTipCard(isGood: true, text: resolvedGoodTip)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTipCard(isGood: false, text: resolvedPoorTip)),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
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
                    backgroundColor: isDark ? colorScheme.primary : AppColors.primaryContainer,
                    foregroundColor: isDark ? colorScheme.onPrimary : AppColors.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    displayStep >= totalSteps ? 'Complete Lesson' : 'Got it! Continue Lesson',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? colorScheme.onPrimary : AppColors.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTipCard({required bool isGood, required String text}) {
    final isDark = _isDark;
    final colorScheme = _colorScheme;

    final borderColor = isGood
        ? (isDark ? colorScheme.secondary : AppColors.secondary)
        : (isDark ? colorScheme.error : AppColors.error);
    final badgeBg = isGood
        ? (isDark ? colorScheme.secondary : AppColors.secondary)
        : (isDark ? colorScheme.error : AppColors.error);
    final badgeTextColor = isGood
        ? (isDark ? colorScheme.onSecondary : AppColors.onSecondary)
        : (isDark ? colorScheme.onError : AppColors.onError);
    final icon = isGood ? Icons.check_circle_rounded : Icons.do_not_disturb_on_rounded;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainer : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor.withValues(alpha: isDark ? 0.35 : 0.25)),
        boxShadow: isDark
            ? const []
            : const [
                BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: isGood
                  ? (isDark
                      ? colorScheme.secondary.withValues(alpha: 0.12)
                      : AppColors.secondary.withValues(alpha: 0.08))
                  : (isDark
                      ? colorScheme.error.withValues(alpha: 0.12)
                      : AppColors.error.withValues(alpha: 0.08)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isGood
                      ? (isDark
                          ? colorScheme.secondary.withValues(alpha: 0.22)
                          : AppColors.secondary.withValues(alpha: 0.16))
                      : (isDark
                          ? colorScheme.error.withValues(alpha: 0.22)
                          : AppColors.error.withValues(alpha: 0.16)),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: borderColor, size: 18),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isGood ? 'RECOMMENDED' : 'AVOID',
              style: AppTypography.labelUi.copyWith(
                color: badgeTextColor,
                fontWeight: FontWeight.w700,
                fontSize: 9,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 12,
              height: 1.4,
              color: isDark ? colorScheme.onSurface : AppColors.onSurface,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Dynamic data delivered reactively through Riverpod providers
    final lessonsAsync = ref.watch(lessonsProvider);
    final atlasAsync = ref.watch(atlasConditionsProvider);
    final termsAsync = ref.watch(glossaryTermsProvider);
    final greetingData = ref.watch(learnContextGreetingProvider);
    final progressAsync = ref.watch(lessonProgressNotifierProvider);

    final allLessons = lessonsAsync.value ?? const <LessonDefinition>[];
    final allAtlas = atlasAsync.value ?? const <AtlasCondition>[];
    final allTerms = termsAsync.value ?? const <GlossaryTerm>[];

    final progressMap = progressAsync.value ?? const {
      'lesson_1': LessonProgress(lessonId: 'lesson_1', isCompleted: false, lastStep: 0, totalSteps: 4),
      'lesson_2': LessonProgress(lessonId: 'lesson_2', isCompleted: false, lastStep: 0, totalSteps: 4),
      'lesson_3': LessonProgress(lessonId: 'lesson_3', isCompleted: false, lastStep: 0, totalSteps: 4),
      'lesson_4': LessonProgress(lessonId: 'lesson_4', isCompleted: false, lastStep: 0, totalSteps: 4),
      'lesson_5': LessonProgress(lessonId: 'lesson_5', isCompleted: false, lastStep: 0, totalSteps: 4),
      'lesson_6': LessonProgress(lessonId: 'lesson_6', isCompleted: false, lastStep: 0, totalSteps: 4),
    };

    final activeLesson = allLessons.firstWhere(
      (l) => !(progressMap[l.id]?.isCompleted ?? false),
      orElse: () => allLessons.isNotEmpty
          ? allLessons.first
          : const LessonDefinition(
              id: 'lesson_1',
              number: 1,
              title: 'Charging & Pairing Wand',
              subtitle: 'Fast BLE auto-pair in garden yard',
              duration: '30s',
              icon: Icons.bluetooth_connected,
              steps: [],
            ),
    );

    final activeProgress = progressMap[activeLesson.id] ??
        LessonProgress(lessonId: activeLesson.id, isCompleted: false, lastStep: 0, totalSteps: activeLesson.totalSteps);
    final allDone = allLessons.isNotEmpty && allLessons.every((l) => progressMap[l.id]?.isCompleted ?? false);
    final activeStep = activeProgress.lastStep == 0 ? 1 : activeProgress.lastStep;
    final activeTotal = activeProgress.totalSteps;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const FloraScanHeader(subtitle: 'Learn'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Dynamic Context-Aware Greeting & Mascot Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? colorScheme.outlineVariant.withValues(alpha: 0.25)
                        : AppColors.outlineVariant.withValues(alpha: 0.2),
                  ),
                  boxShadow: isDark
                      ? const []
                      : const [
                          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                        ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                greetingData.greeting,
                                style: AppTypography.headlineSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                                ),
                              ),
                              if (greetingData.badge != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? colorScheme.secondaryContainer.withValues(alpha: 0.4)
                                        : AppColors.primaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                    border: isDark
                                        ? Border.all(color: colorScheme.secondary.withValues(alpha: 0.3))
                                        : null,
                                  ),
                                  child: Text(
                                    greetingData.badge!,
                                    style: AppTypography.labelUi.copyWith(
                                      color: isDark ? colorScheme.secondary : AppColors.onPrimary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            greetingData.subtitle,
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                              fontSize: 12,
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SproutlyMascot(
                      size: 48,
                      badgeColor: isDark ? colorScheme.primary : AppColors.secondary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Search Input with real interactive controller & clear affordance
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isVoiceListening
                        ? colorScheme.error
                        : (isDark
                            ? colorScheme.outlineVariant.withValues(alpha: 0.25)
                            : AppColors.outlineVariant.withValues(alpha: 0.4)),
                    width: _isVoiceListening ? 1.5 : 1.0,
                  ),
                  boxShadow: isDark
                      ? const []
                      : const [
                          BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
                        ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value.trim().toLowerCase()),
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                  ),
                  cursorColor: isDark ? colorScheme.primary : AppColors.primary,
                  decoration: InputDecoration(
                    hintText: _isVoiceListening
                        ? 'Listening... Speak now'
                        : 'Search lessons or pests',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: _isVoiceListening
                          ? colorScheme.error
                          : (isDark ? colorScheme.onSurfaceVariant : AppColors.outline),
                    ),
                    prefixIcon: Icon(
                      _isVoiceListening ? Icons.graphic_eq : Icons.search,
                      color: _isVoiceListening
                          ? colorScheme.error
                          : (isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant),
                    ),
                    suffixIcon: _isVoiceListening
                        ? IconButton(
                            icon: Icon(Icons.stop_circle, color: colorScheme.error, size: 22),
                            tooltip: 'Stop listening',
                            onPressed: _toggleVoiceSearch,
                          )
                        : (_searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : IconButton(
                                icon: Icon(Icons.mic, color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant),
                                tooltip: 'Search with voice',
                                onPressed: _toggleVoiceSearch,
                              )),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              if (_isVoiceListening) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(alpha: isDark ? 0.35 : 0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.error.withValues(alpha: isDark ? 0.4 : 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Listening... Say "blight", "chili", or "moisture"',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark ? colorScheme.onErrorContainer : AppColors.onErrorContainer,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _toggleVoiceSearch,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text(
                            'STOP',
                            style: AppTypography.labelUi.copyWith(
                              color: colorScheme.error,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // Safety-governed quick links (Replay Tour & Confirmed Reset)
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  InkWell(
                    onTap: _showGardenTourDialog,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.replay,
                            size: 16,
                            color: isDark ? colorScheme.secondary : AppColors.secondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Replay Garden App Tour',
                            style: AppTypography.labelUi.copyWith(
                              color: isDark ? colorScheme.secondary : AppColors.secondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _showResetConfirmationDialog,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh,
                            size: 16,
                            color: isDark ? colorScheme.onSurfaceVariant : AppColors.outline,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Reset Progress',
                            style: AppTypography.labelUi.copyWith(
                              color: isDark ? colorScheme.onSurfaceVariant : AppColors.outline,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 2. "Continue Where You Left Off" Hero Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.surfaceContainerLow : AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? colorScheme.outlineVariant.withValues(alpha: 0.25)
                        : Colors.transparent,
                  ),
                  boxShadow: isDark
                      ? const []
                      : const [
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? colorScheme.secondaryContainer.withValues(alpha: 0.35)
                                  : AppColors.secondaryFixed,
                              borderRadius: BorderRadius.circular(9999),
                              border: isDark
                                  ? Border.all(color: colorScheme.secondary.withValues(alpha: 0.3))
                                  : null,
                            ),
                            child: Text(
                              allDone
                                  ? 'ALL LESSONS COMPLETE • 6 OF 6'
                                  : (activeProgress.lastStep == 0
                                      ? 'START HERE • STEP 1 OF $activeTotal CARDS'
                                      : 'IN PROGRESS • $activeStep OF $activeTotal CARDS'),
                              style: AppTypography.labelUi.copyWith(
                                color: isDark ? colorScheme.secondary : AppColors.onSecondaryFixedVariant,
                                fontSize: 10,
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
                            Icon(
                              Icons.schedule,
                              size: 15,
                              color: isDark ? colorScheme.onSurfaceVariant : AppColors.onPrimaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${activeLesson.duration} guide',
                              style: AppTypography.telemetrySmall.copyWith(
                                color: isDark ? colorScheme.onSurfaceVariant : AppColors.onPrimaryContainer,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
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
                                  color: isDark ? colorScheme.onSurface : AppColors.onPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                activeLesson.subtitle,
                                style: AppTypography.bodySmall.copyWith(
                                  color: isDark ? colorScheme.onSurfaceVariant : AppColors.onPrimaryContainer,
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? colorScheme.surfaceContainerHighest
                                : Colors.white.withValues(alpha: 0.12),
                          ),
                          child: Icon(
                            activeLesson.icon,
                            color: isDark ? colorScheme.secondary : AppColors.secondaryFixed,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(9999),
                      child: LinearProgressIndicator(
                        value: allDone ? 1.0 : (activeProgress.lastStep / activeTotal).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: isDark
                            ? colorScheme.surfaceContainerHighest
                            : Colors.white.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? colorScheme.secondary : AppColors.secondaryFixed,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () => _openStoryLessonModal(
                        allLessons: allLessons,
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
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? colorScheme.onPrimary : AppColors.onSecondaryFixed,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: isDark ? colorScheme.primary : AppColors.secondaryFixed,
                        foregroundColor: isDark ? colorScheme.onPrimary : AppColors.onSecondaryFixed,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Segmented Navigation Tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                  border: isDark
                      ? Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2))
                      : null,
                ),
                child: Row(
                  children: [
                    _buildSegmentTab('Quick Lessons (${allLessons.length})', 0),
                    _buildSegmentTab('Diseases (${allAtlas.length})', 1),
                    _buildSegmentTab('A–Z Terms', 2),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // TAB CONTENT PANELS
              if (_activeTabIndex == 0) _buildLessonsTab(allLessons, progressMap),
              if (_activeTabIndex == 1) _buildProblemsTab(allAtlas),
              if (_activeTabIndex == 2) _buildGlossaryTab(allTerms),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentTab(String title, int index) {
    final isDark = _isDark;
    final colorScheme = _colorScheme;
    final isSelected = _activeTabIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTabIndex = index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? colorScheme.surfaceContainerHigh : AppColors.surfaceContainerLowest)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected && isDark
                ? Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.25))
                : null,
            boxShadow: isSelected && !isDark
                ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))]
                : null,
          ),
          child: Center(
            child: Text(
              title,
              style: AppTypography.labelUi.copyWith(
                color: isSelected
                    ? (isDark ? colorScheme.primary : AppColors.primary)
                    : (isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLessonsTab(List<LessonDefinition> allLessons, Map<String, LessonProgress> progressMap) {
    final isDark = _isDark;
    final colorScheme = _colorScheme;
    final completedCount = progressMap.values.where((p) => p.isCompleted).length;

    final filteredLessons = allLessons.where((lesson) {
      if (_searchQuery.isEmpty) return true;
      return lesson.title.toLowerCase().contains(_searchQuery) ||
          lesson.subtitle.toLowerCase().contains(_searchQuery);
    }).toList();

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
                      fontSize: 16,
                      color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                    ),
                  ),
                  Text(
                    'Tap to launch bite-sized 30-sec tutorials',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.secondaryContainer.withValues(alpha: 0.35)
                    : AppColors.secondaryFixed,
                borderRadius: BorderRadius.circular(9999),
                border: isDark
                    ? Border.all(color: colorScheme.secondary.withValues(alpha: 0.3))
                    : null,
              ),
              child: Text(
                '$completedCount of 6 Done',
                style: AppTypography.telemetrySmall.copyWith(
                  color: isDark ? colorScheme.secondary : AppColors.onSecondaryFixed,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (filteredLessons.isEmpty)
          _buildEmptySearchResult()
        else
          ...filteredLessons.map((lesson) {
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
                  allLessons: allLessons,
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
    final isDark = _isDark;
    final colorScheme = _colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? colorScheme.outlineVariant.withValues(alpha: 0.25)
                : AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
          boxShadow: isDark
              ? const []
              : const [
                  BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? colorScheme.surfaceContainer : AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDark ? colorScheme.secondary : AppColors.secondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
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
                            fontSize: 14,
                            color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCompleted) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: isDark ? colorScheme.secondary : AppColors.secondary,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                      fontSize: 12,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              duration,
              style: AppTypography.telemetrySmall.copyWith(
                color: isDark ? colorScheme.outline : AppColors.outline,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProblemsTab(List<AtlasCondition> allAtlas) {
    final isDark = _isDark;
    final colorScheme = _colorScheme;

    final filteredConditions = allAtlas.where((c) {
      final matchesCrop = _selectedProblemCrop == 'All' || c.crop == _selectedProblemCrop;
      if (!matchesCrop) return false;
      if (_searchQuery.isEmpty) return true;
      return c.title.toLowerCase().contains(_searchQuery) ||
          c.pathogen.toLowerCase().contains(_searchQuery) ||
          c.description.toLowerCase().contains(_searchQuery);
    }).toList();

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
                  fontSize: 16,
                  color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${allAtlas.length} offline conditions',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Filter chips with compliant 36dp+ touch target
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCropFilterBtn('All', 'All (${allAtlas.length})'),
              const SizedBox(width: 8),
              _buildCropFilterBtn('Tomato', '🍅 Tomato'),
              const SizedBox(width: 8),
              _buildCropFilterBtn('Chili', '🌶️ Chili'),
              const SizedBox(width: 8),
              _buildCropFilterBtn('Eggplant', '🍆 Eggplant'),
            ],
          ),
        ),

        const SizedBox(height: 14),

        if (filteredConditions.isEmpty)
          _buildEmptySearchResult()
        else
          ...filteredConditions.map((condition) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildProblemAtlasCard(condition),
              )),
      ],
    );
  }

  Widget _buildCropFilterBtn(String key, String label) {
    final isDark = _isDark;
    final colorScheme = _colorScheme;
    final isSelected = _selectedProblemCrop == key;

    return InkWell(
      onTap: () => setState(() => _selectedProblemCrop = key),
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? colorScheme.primary : AppColors.primaryContainer)
              : (isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerHigh),
          borderRadius: BorderRadius.circular(9999),
          border: isDark
              ? Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant.withValues(alpha: 0.25),
                )
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.labelUi.copyWith(
              color: isSelected
                  ? (isDark ? colorScheme.onPrimary : AppColors.onPrimary)
                  : (isDark ? colorScheme.onSurface : AppColors.onSurface),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProblemAtlasCard(AtlasCondition condition) {
    final isDark = _isDark;
    final colorScheme = _colorScheme;

    return InkWell(
      onTap: () => _openTreatmentRecipeModal(condition),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? colorScheme.outlineVariant.withValues(alpha: 0.25)
                : AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
          boxShadow: isDark
              ? const []
              : const [
                  BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _resolveTagBg(condition, colorScheme, isDark),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    condition.severityTag,
                    style: AppTypography.labelUi.copyWith(
                      color: _resolveTagColor(condition, colorScheme, isDark),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  condition.crop.toUpperCase(),
                  style: AppTypography.labelUi.copyWith(
                    color: isDark ? colorScheme.onSurfaceVariant : AppColors.outline,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              condition.title,
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: isDark ? colorScheme.onSurface : AppColors.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              condition.pathogen,
              style: AppTypography.bodySmall.copyWith(
                fontStyle: FontStyle.italic,
                fontSize: 12,
                color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Text(
              condition.description,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                fontSize: 13,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.eco,
                        size: 16,
                        color: isDark ? colorScheme.secondary : AppColors.secondary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          condition.recipeLabel,
                          style: AppTypography.labelUi.copyWith(
                            color: isDark ? colorScheme.secondary : AppColors.secondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'TREATMENT RECIPE',
                        style: AppTypography.labelUi.copyWith(
                          color: isDark ? colorScheme.primary : AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        size: 13,
                        color: isDark ? colorScheme.primary : AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlossaryTab(List<GlossaryTerm> allTerms) {
    final isDark = _isDark;
    final colorScheme = _colorScheme;

    final filteredTerms = allTerms.where((t) {
      if (_searchQuery.isEmpty) return true;
      return t.term.toLowerCase().contains(_searchQuery) ||
          t.meaning.toLowerCase().contains(_searchQuery);
    }).toList();

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
                  fontSize: 16,
                  color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${filteredTerms.length} Terms • English',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (filteredTerms.isEmpty)
          _buildEmptySearchResult()
        else
          ...filteredTerms.map(
            (t) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? colorScheme.outlineVariant.withValues(alpha: 0.25)
                      : AppColors.outlineVariant.withValues(alpha: 0.3),
                ),
                boxShadow: isDark
                    ? const []
                    : const [
                        BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.term,
                    style: AppTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isDark ? colorScheme.primary : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.meaning,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptySearchResult() {
    final isDark = _isDark;
    final colorScheme = _colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      child: Column(
        children: [
          Icon(
            Icons.search_off_outlined,
            size: 44,
            color: isDark ? colorScheme.outline : AppColors.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'No matching results found',
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: isDark ? colorScheme.onSurface : AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try searching for broader keywords like "blight", "moisture", or "neem".',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? colorScheme.primary : AppColors.primary,
              side: BorderSide(color: isDark ? colorScheme.primary : AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Clear Search Filter'),
          ),
        ],
      ),
    );
  }
}
