import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/bmkg_providers.dart';
import '../../models/bmkg_quake.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/bmkg_alert_detail_sheet.dart';

/// Screen displaying the directory of recent earthquakes across Indonesia from BMKG.
class BmkgQuakesScreen extends ConsumerStatefulWidget {
  const BmkgQuakesScreen({super.key});

  @override
  ConsumerState<BmkgQuakesScreen> createState() => _BmkgQuakesScreenState();
}

class _BmkgQuakesScreenState extends ConsumerState<BmkgQuakesScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'ALL'; // 'ALL' | 'M5' | 'FELT'
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openDetail(BmkgQuake quake) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      builder: (_) => BmkgAlertDetailSheet(quake: quake),
    );
  }

  List<BmkgQuake> _filterQuakes(List<BmkgQuake> list) {
    return list.where((q) {
      if (_selectedFilter == 'M5' && q.magnitude < 5.0) return false;
      if (_selectedFilter == 'FELT' &&
          (q.dirasakan == null || q.dirasakan!.isEmpty)) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchWilayah = q.wilayah.toLowerCase().contains(query);
        final matchDirasakan =
            q.dirasakan?.toLowerCase().contains(query) ?? false;
        return matchWilayah || matchDirasakan;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final quakesAsync = ref.watch(recentBmkgQuakesProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasBlue,
      appBar: AppBar(
        title: Text(
          'Gempa Terkini BMKG',
          style: AppTextStyles.screenTitle.copyWith(fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: quakesAsync.when(
              data: (quakes) {
                final filtered = _filterQuakes(quakes);
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'Tidak ada data gempa sesuai pencarian.',
                      style: AppTextStyles.caption,
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(recentBmkgQuakesProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.pagePadding),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => _buildQuakeTile(filtered[i]),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Gagal memuat: $e', style: AppTextStyles.caption),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.xs,
      ),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: AppColors.border),
        ),
        child: TextField(
          controller: _searchController,
          style: AppTextStyles.body.copyWith(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Cari wilayah gempa (cth: Yogyakarta, Maluku)...',
            hintStyle: AppTextStyles.caption,
            prefixIcon: const Icon(
              Icons.search,
              size: 18,
              color: AppColors.textSecondary,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
          onChanged: (val) => setState(() => _searchQuery = val.trim()),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      ('ALL', 'Semua Gempa'),
      ('M5', 'M ≥ 5.0'),
      ('FELT', 'Gempa Dirasakan'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: ChoiceChip(
              label: Text(f.$2, style: const TextStyle(fontSize: 11)),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedFilter = f.$1),
              selectedColor: AppColors.chartBlue.withValues(alpha: 0.15),
              side: BorderSide(
                color: isSelected ? AppColors.chartBlue : AppColors.border,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuakeTile(BmkgQuake quake) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: quake.severityColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          child: Text(
            quake.formattedMagnitude,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: quake.severityColor,
            ),
          ),
        ),
        title: Text(
          quake.wilayah,
          style: AppTextStyles.label.copyWith(fontSize: 13),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${quake.jam} • Kedalaman: ${quake.kedalaman}',
          style: AppTextStyles.caption.copyWith(fontSize: 11),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
        onTap: () => _openDetail(quake),
      ),
    );
  }
}
