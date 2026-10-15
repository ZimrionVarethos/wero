import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/providers/operations_providers.dart';
import '../../models/evacuation_point.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/admin_facility_dialog.dart';
import 'widgets/evacuation_map_view.dart';
import 'widgets/facility_card.dart';
import 'widgets/facility_detail_sheet.dart';

/// Screen listing verified evacuation shelters and health facilities with search, filters, and map toggle.
class EvacuationScreen extends ConsumerStatefulWidget {
  const EvacuationScreen({super.key});

  static const routeName = '/evacuation';

  @override
  ConsumerState<EvacuationScreen> createState() => _EvacuationScreenState();
}

class _EvacuationScreenState extends ConsumerState<EvacuationScreen> {
  final _searchController = TextEditingController();
  String? _selectedKind;
  String _searchQuery = '';
  bool _isMapView = true;
  EvacuationPoint? _selectedRoutePoint;
  LatLng _userLocation = const LatLng(-7.7956, 110.3695);

  static const _kinds = [
    (null, 'Semua'),
    ('SHELTER', 'Shelter'),
    ('HEALTH', 'Kesehatan'),
    ('ASSEMBLY', 'Titik Kumpul'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToRoute(EvacuationPoint point) {
    setState(() {
      _selectedRoutePoint = point;
      _isMapView = true;
    });
  }

  void _showDetailSheet(EvacuationPoint point) {
    FacilityDetailSheet.show(
      context,
      point,
      onNavigateRoute: _navigateToRoute,
      onEditPoint: (ep) => AdminFacilityDialog.show(
        context,
        pointToEdit: ep,
        currentLocation: _userLocation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = EvacuationQuery(
      kind: _selectedKind,
      searchQuery: _searchQuery,
    );
    final pointsAsync = ref.watch(evacuationPointsProvider(query));

    return Scaffold(
      backgroundColor: AppColors.canvasBlue,
      appBar: AppBar(
        title: Text(
          'Titik & Posko Evakuasi',
          style: AppTextStyles.screenTitle.copyWith(fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Tambah Posko Baru (Admin)',
            icon: const Icon(
              Icons.add_location_alt_rounded,
              color: AppColors.chartBlue,
            ),
            onPressed: () => AdminFacilityDialog.show(
              context,
              currentLocation: _userLocation,
            ),
          ),
          TextButton.icon(
            onPressed: () => setState(() => _isMapView = !_isMapView),
            icon: Icon(
              _isMapView
                  ? Icons.format_list_bulleted_rounded
                  : Icons.map_rounded,
              size: 18,
            ),
            label: Text(_isMapView ? 'Daftar' : 'Peta'),
            style: TextButton.styleFrom(foregroundColor: AppColors.chartBlue),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: pointsAsync.when(
              data: (points) => _isMapView
                  ? EvacuationMapView(
                      points: points,
                      activeRoutePoint: _selectedRoutePoint,
                      userLocation: _userLocation,
                      onLocationSynced: (loc) =>
                          setState(() => _userLocation = loc),
                      onClearRoute: () =>
                          setState(() => _selectedRoutePoint = null),
                      onPointSelected: _showDetailSheet,
                    )
                  : _buildList(points),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.textPrimary),
              ),
              error: (e, _) => Center(
                child: Text('Gagal: $e', style: AppTextStyles.caption),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.canvasBlue,
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: TextField(
              controller: _searchController,
              style: AppTextStyles.body.copyWith(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Cari nama posko atau jalan...',
                hintStyle: AppTextStyles.caption,
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onSubmitted: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _kinds.map((k) {
                final isSelected = _selectedKind == k.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: ChoiceChip(
                    label: Text(
                      k.$2,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.textPrimary,
                    onSelected: (_) => setState(() => _selectedKind = k.$1),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<EvacuationPoint> points) {
    if (points.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_off_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Tidak ada titik evakuasi yang sesuai',
              style: AppTextStyles.sectionTitle,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      itemCount: points.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final point = points[index];
        return FacilityCard(point: point, onTap: () => _showDetailSheet(point));
      },
    );
  }
}
