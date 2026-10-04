import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/entities/agronomy_article_model.dart';
import 'providers/learn_providers.dart';
import 'widgets/article_card.dart';

/// Screen providing agronomic educational guides and disease reference protocols.
class LearnScreen extends ConsumerStatefulWidget {
  const LearnScreen({super.key});

  @override
  ConsumerState<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends ConsumerState<LearnScreen> {
  AgronomyCategory? _selectedCategory;
  String _searchQuery = '';

  void _showArticleDetails(AgronomyArticle article) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 20),
              Text(
                article.targetCrop.toUpperCase(),
                style: AppTypography.labelUi.copyWith(
                  color: AppColors.secondary,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                article.title,
                style: AppTypography.headlineLarge.copyWith(
                  color: AppColors.onSurface,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Text(
                  article.summary,
                  style: AppTypography.bodyMedium.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'FIELD PROTOCOL & RECOMMENDATIONS',
                style: AppTypography.labelUi.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                article.content,
                style: AppTypography.bodyMedium.copyWith(
                  height: 1.6,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(bottomSheetContext),
                child: const Text('Close Reference'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final articlesAsync = ref.watch(agronomyArticlesProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Agronomy Knowledge Base',
          style: AppTypography.headlineMedium.copyWith(color: AppColors.primary),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search disease, nutrition, irrigation...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: AppColors.surfaceContainerLowest,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.outlineVariant),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _buildCategoryChip('All Topics', null),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Pathology', AgronomyCategory.pathology),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Soil & NPK', AgronomyCategory.soilNutrition),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Irrigation', AgronomyCategory.irrigation),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Biosecurity', AgronomyCategory.prevention),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: articlesAsync.when(
                data: (articles) {
                  final filtered = articles.where((a) {
                    final matchesCategory = _selectedCategory == null ||
                        a.category == _selectedCategory;
                    final matchesSearch = _searchQuery.isEmpty ||
                        a.title.toLowerCase().contains(_searchQuery) ||
                        a.summary.toLowerCase().contains(_searchQuery) ||
                        a.targetCrop.toLowerCase().contains(_searchQuery);
                    return matchesCategory && matchesSearch;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        'No articles matching selection',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final article = filtered[index];
                      return ArticleCard(
                        article: article,
                        onTap: () => _showArticleDetails(article),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Text('Failed to load articles: $err'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, AgronomyCategory? category) {
    final isSelected = _selectedCategory == category;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedCategory = category;
        });
      },
      selectedColor: AppColors.secondaryContainer,
      labelStyle: AppTypography.bodySmall.copyWith(
        color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(9999),
        side: BorderSide(
          color: isSelected ? AppColors.secondary : AppColors.outlineVariant,
        ),
      ),
    );
  }
}
