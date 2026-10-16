import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/community_providers.dart';
import '../../../models/community_category.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Modal bottom sheet for filtering community posts by scope and category.
class CommunityFilterSheet extends ConsumerStatefulWidget {
  const CommunityFilterSheet({super.key});

  /// Displays the filter bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CommunityFilterSheet(),
    );
  }

  @override
  ConsumerState<CommunityFilterSheet> createState() =>
      _CommunityFilterSheetState();
}

class _CommunityFilterSheetState extends ConsumerState<CommunityFilterSheet> {
  late String _selectedScope;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    final feedState = ref.read(communityFeedProvider);
    _selectedScope = feedState.scope;
    _selectedCategoryId = feedState.selectedCategoryId;
  }

  void _applyFilter() {
    final notifier = ref.read(communityFeedProvider.notifier);
    notifier.setScope(_selectedScope);
    notifier.setCategory(_selectedCategoryId);
    Navigator.pop(context);
  }

  void _resetFilter() {
    setState(() {
      _selectedScope = 'LOCAL';
      _selectedCategoryId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(communityCategoriesProvider);
    final profile = ref.watch(userProfileProvider).asData?.value;
    final regionName = profile?.regionName ?? 'Wilayah Anda';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.md,
        AppSpacing.pagePadding,
        AppSpacing.xl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.borderNeutral,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Berita Komunitas',
                  style: AppTextStyles.screenTitle.copyWith(
                    color: AppColors.primaryNavy,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  color: AppColors.mutedText,
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cakupan Berita',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primaryNavy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pilih sumber laporan bencana lokal atau nasional',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _buildScopeOption(
                            label: 'Lokal',
                            description: regionName,
                            icon: Icons.location_on_rounded,
                            isSelected: _selectedScope == 'LOCAL',
                            onTap: () =>
                                setState(() => _selectedScope = 'LOCAL'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildScopeOption(
                            label: 'Nasional',
                            description: 'Seluruh Indonesia',
                            icon: Icons.public_rounded,
                            isSelected: _selectedScope == 'NATIONAL',
                            onTap: () =>
                                setState(() => _selectedScope = 'NATIONAL'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Kategori Topik',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primaryNavy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Saring berdasarkan jenis mitigasi atau informasi bencana',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    categoriesAsync.when(
                      data: (cats) => _buildCategoryChips(cats),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (_, _) => const Text('Gagal memuat kategori'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _resetFilter,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryNavy,
                    side: const BorderSide(color: AppColors.borderNeutral),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  child: const Text('Reset'),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilter,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                    child: Text(
                      'Terapkan Filter',
                      style: AppTextStyles.label.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
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

  Widget _buildScopeOption({
    required String label,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final bg = isSelected ? AppColors.primaryNavy : AppColors.surfaceWhite;
    final fg = isSelected ? Colors.white : AppColors.primaryNavy;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isSelected ? AppColors.primaryNavy : AppColors.borderNeutral,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: fg),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? Colors.white70 : AppColors.mutedText,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips(List<CommunityCategory> categories) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _buildChip(
          label: 'Semua Kategori',
          isSelected: _selectedCategoryId == null,
          onTap: () => setState(() => _selectedCategoryId = null),
        ),
        for (final cat in categories)
          _buildChip(
            label: cat.name,
            isSelected: _selectedCategoryId == cat.id,
            onTap: () => setState(() => _selectedCategoryId = cat.id),
          ),
      ],
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: AppTextStyles.caption.copyWith(
        color: isSelected ? Colors.white : AppColors.primaryNavy,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      backgroundColor: AppColors.surfaceWhite,
      selectedColor: AppColors.accentOrange,
      showCheckmark: false,
      side: BorderSide(
        color: isSelected ? AppColors.accentOrange : AppColors.borderNeutral,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      onSelected: (_) => onTap(),
    );
  }
}
