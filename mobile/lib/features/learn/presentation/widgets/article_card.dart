import 'package:flutter/material.dart';
import '../../../../core/theme/agri_theme_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/agronomy_article_model.dart';

/// Card component presenting an educational reference guide.
class ArticleCard extends StatelessWidget {
  const ArticleCard({
    required this.article,
    required this.onTap,
    super.key,
  });

  final AgronomyArticle article;
  final VoidCallback onTap;

  String _formatCategory(AgronomyCategory category) {
    return switch (category) {
      AgronomyCategory.pathology => 'Pathology',
      AgronomyCategory.soilNutrition => 'Soil & Nutrition',
      AgronomyCategory.prevention => 'Biosecurity',
      AgronomyCategory.irrigation => 'Irrigation',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final agriColors = context.agriTheme;

    final categoryColor = switch (article.category) {
      AgronomyCategory.pathology => isDark ? colorScheme.error : agriColors.severeOutbreak,
      AgronomyCategory.soilNutrition => isDark ? colorScheme.tertiary : agriColors.richOchreSoil,
      AgronomyCategory.prevention => isDark ? colorScheme.secondary : agriColors.healthyVigor,
      AgronomyCategory.irrigation => isDark ? colorScheme.primary : agriColors.moistureCyan,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainerLow : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark
                ? colorScheme.outlineVariant.withValues(alpha: 0.25)
                : AppColors.outlineVariant,
            width: 1,
          ),
          boxShadow: isDark
              ? const []
              : const [
                  BoxShadow(
                    color: Color.fromRGBO(15, 23, 42, 0.04),
                    blurRadius: 4,
                    offset: Offset(0, 1),
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
                    color: categoryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: isDark
                        ? Border.all(color: categoryColor.withValues(alpha: 0.3))
                        : null,
                  ),
                  child: Text(
                    _formatCategory(article.category).toUpperCase(),
                    style: AppTypography.labelUi.copyWith(
                      color: categoryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${article.readTimeMinutes} min read',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              article.title,
              style: AppTypography.headlineSmall.copyWith(
                color: isDark ? colorScheme.onSurface : AppColors.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              article.summary,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? colorScheme.onSurfaceVariant : AppColors.onSurfaceVariant,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.spa_outlined,
                  size: 14,
                  color: isDark ? colorScheme.secondary : AppColors.secondary,
                ),
                const SizedBox(width: 4),
                Text(
                  article.targetCrop,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? colorScheme.secondary : AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'Read Protocol →',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? colorScheme.primary : AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
