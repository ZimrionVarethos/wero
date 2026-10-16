import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/providers/operations_providers.dart';
import '../../models/evacuation_point.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/admin_facility_dialog.dart';
import 'widgets/evacuation_filter_sheet.dart';
import 'widgets/evacuation_map_view.dart';
import 'widgets/facility_card.dart';
import 'widgets/facility_detail_sheet.dart';
import '../../widgets/app_header.dart';

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

  void _showFilterSheet() {
    EvacuationFilterSheet.show(
      context,
      currentKind: _selectedKind,
      onApply: (kind) => setState(() => _selectedKind = kind),
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
      backgroundColor: AppColors.backgroundCream,
      appBar: AppHeader(
        title: 'Maps',
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
          IconButton(
            tooltip: _isMapView ? 'Tampilan Daftar' : 'Tampilan Peta',
            icon: Icon(
              _isMapView
                  ? Icons.format_list_bulleted_rounded
                  : Icons.map_rounded,
              color: AppColors.primaryNavy,
            ),
            onPressed: () => setState(() => _isMapView = !_isMapView),
          ),
          IconButton(
            tooltip: 'Filter Fasilitas',
            icon: Badge(
              isLabelVisible: _selectedKind != null,
              backgroundColor: AppColors.accentOrange,
              smallSize: 8,
              child: Icon(
                Icons.tune_rounded,
                color: _selectedKind != null
                    ? AppColors.accentOrange
                    : AppColors.primaryNavy,
              ),
            ),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
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

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: 8,
      ),
      child: Container(
        height: 40,
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
              size: 19,
              color: AppColors.textSecondary,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 16),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 9),
          ),
          onChanged: (val) {
            setState(() => _searchQuery = val.trim());
          },
          onSubmitted: (val) => setState(() => _searchQuery = val.trim()),
        ),
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
