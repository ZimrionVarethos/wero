import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/bmkg_providers.dart';
import '../models/bmkg_quake.dart';
import '../routing/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/app_header.dart';
import 'operations/widgets/bmkg_alert_detail_sheet.dart';
import 'operations/widgets/bmkg_playtest_dialog.dart';
import 'operations/widgets/disaster_history_tile.dart';
import 'operations/widgets/disaster_summary_tiles.dart';
import 'operations/widgets/executive_alert_card.dart';

/// Screen presenting the disaster early warning alerts & earthquake history.
/// Replaces the legacy template stats with verified BMKG disaster telemetry.
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  static const routeName = '/statistics';

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  String _selectedFilter = 'Semua';
  static const _filterOptions = ['Semua', 'M ≥ 5.0', 'Dirasakan'];

  void _onNavTap(int index) {
    if (index == 0) {
      context.go(AppRoutes.activity);
      return;
    }
    if (index == 1) {
      context.go(AppRoutes.assistant);
      return;
    }
    if (index == 2) {
      context.go(AppRoutes.community);
      return;
    }
    if (index == 3) return;
    if (index == 4) {
      context.go(AppRoutes.profile);
      return;
    }
  }

  void _openDetail(BuildContext context, BmkgQuake quake) {
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

  @override
  Widget build(BuildContext context) {
    final latestQuakeAsync = ref.watch(latestBmkgQuakeProvider);
    final recentQuakesAsync = ref.watch(recentBmkgQuakesProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeader(showBackButton: Navigator.canPop(context)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(latestBmkgQuakeProvider);
          ref.invalidate(recentBmkgQuakesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
          ),
          children: [
            const SizedBox(height: AppSpacing.xs),
            _buildHeader(),
            const SizedBox(height: AppSpacing.base),

            // Top Status & Metric Summary Row
            latestQuakeAsync.maybeWhen(
              data: (quake) => DisasterSummaryTiles(quake: quake),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.base),

            // Active Warning Section
            latestQuakeAsync.maybeWhen(
              data: (quake) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Peringatan Dini Aktif',
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ExecutiveAlertCard(quake: quake),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
              orElse: () => const SizedBox.shrink(),
            ),

            // Filter Tabs Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Riwayat Gempa Terkini',
                  style: AppTextStyles.sectionTitle,
                ),
                _buildFilterChips(),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Recent Earthquake History Feed
            recentQuakesAsync.when(
              data: (quakes) {
                final filtered = quakes.where((q) {
                  if (_selectedFilter == 'M ≥ 5.0') return q.magnitude >= 5.0;
                  if (_selectedFilter == 'Dirasakan') {
                    return q.dirasakan != null && q.dirasakan!.isNotEmpty;
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xl,
                    ),
                    child: Center(
                      child: Text(
                        'Tidak ada gempa pada kategori ini',
                        style: AppTextStyles.caption,
                      ),
                    ),
                  );
                }

                return Column(
                  children: filtered.map((quake) {
                    return DisasterHistoryTile(
                      quake: quake,
                      onTap: () => _openDetail(context, quake),
                    );
                  }).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Center(
                  child: Text(
                    'Gagal memuat riwayat gempa BMKG',
                    style: AppTextStyles.caption,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 3,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Riwayat & Peringatan', style: AppTextStyles.screenTitle),
              const SizedBox(height: 2),
              Text(
                'Feed resmi BMKG TEWS & catatan aktivitas kegempaan',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          icon: const Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: AppColors.chartRed,
          ),
          tooltip: 'Uji Sirine & Simulasi BMKG',
          onPressed: () => BmkgPlaytestDialog.show(context),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Row(
      children: _filterOptions.map((f) {
        final isSelected = _selectedFilter == f;
        return Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.chip),
            onTap: () => setState(() => _selectedFilter = f),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.canvasBlue,
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: Text(
                f,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
