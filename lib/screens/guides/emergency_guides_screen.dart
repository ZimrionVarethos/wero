import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/guide_providers.dart';
import '../../models/emergency_guide.dart';
import '../../routing/app_router.dart';
import '../../services/offline_guide_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_header.dart';
import 'widgets/go_bag_dialog.dart';
import 'widgets/guide_card.dart';

/// Screen listing offline disaster survival and first aid guides with Go-Bag tracker.
class EmergencyGuidesScreen extends ConsumerStatefulWidget {
  const EmergencyGuidesScreen({super.key});

  static const routeName = '/guides';

  @override
  ConsumerState<EmergencyGuidesScreen> createState() =>
      _EmergencyGuidesScreenState();
}

class _EmergencyGuidesScreenState extends ConsumerState<EmergencyGuidesScreen> {
  final _searchController = TextEditingController();
  GuideCategory? _selectedCategory;
  String _searchQuery = '';

  static const _categories = [
    (null, 'Semua'),
    (GuideCategory.earthquake, 'Gempa'),
    (GuideCategory.flood, 'Banjir'),
    (GuideCategory.fire, 'Kebakaran'),
    (GuideCategory.tsunami, 'Tsunami'),
    (GuideCategory.firstAid, 'P3K'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = GuideQuery(
      category: _selectedCategory,
      searchQuery: _searchQuery,
    );
    final guides = ref.watch(emergencyGuidesProvider(query));
    final goBagState = ref.watch(goBagChecklistProvider);
    final totalGoBag = OfflineGuideService.defaultGoBagItems.length;

    return Scaffold(
      backgroundColor: AppColors.canvasBlue,
      appBar: const AppHeader(title: 'Panduan Darurat'),
      body: Column(
        children: [
          _buildGoBagBanner(context, goBagState, totalGoBag),
          _buildSearchAndFilters(),
          Expanded(child: _buildGuideList(guides)),
        ],
      ),
    );
  }

  Widget _buildGoBagBanner(
    BuildContext context,
    AsyncValue<Set<String>> goBagState,
    int totalItems,
  ) {
    final checkedCount = goBagState.value?.length ?? 0;
    final isComplete = checkedCount == totalItems;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.sm,
        AppSpacing.pagePadding,
        0,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isComplete ? AppColors.chartGreen : AppColors.accentOrange,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () => GoBagDialog.show(context),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isComplete
                        ? AppColors.softGreen
                        : AppColors.accentOrange.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.backpack_rounded,
                    color: isComplete
                        ? AppColors.chartGreen
                        : AppColors.accentOrange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tas Siaga Bencana (Go-Bag)',
                        style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '$checkedCount dari $totalItems perlengkapan darurat siap',
                        style: AppTextStyles.caption.copyWith(
                          color: isComplete
                              ? AppColors.chartGreen
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: AppColors.canvasBlue,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _searchController,
              style: AppTextStyles.body.copyWith(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Cari panduan (cth: gempa, pendarahan)...',
                hintStyle: AppTextStyles.caption,
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((c) {
                final isSelected = _selectedCategory == c.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: ChoiceChip(
                    label: Text(
                      c.$2,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.textPrimary,
                    onSelected: (_) => setState(() => _selectedCategory = c.$1),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideList(List<EmergencyGuide> guides) {
    if (guides.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada panduan darurat yang cocok.',
          style: AppTextStyles.bodySecondary,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      itemCount: guides.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final guide = guides[index];
        return GuideCard(
          guide: guide,
          onTap: () => context.push(AppRoutes.guideDetail, extra: guide),
        );
      },
    );
  }
}
