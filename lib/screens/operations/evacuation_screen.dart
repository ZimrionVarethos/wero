import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/providers/operations_providers.dart';
import '../../core/providers/supabase_providers.dart';
import '../../core/providers/volunteer_providers.dart';
import '../../models/evacuation_point.dart';
import '../../models/public_sos_event.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../services/evacuation_cache_service.dart';
import '../../services/location_service.dart';
import 'widgets/admin_facility_dialog.dart';
import 'widgets/evacuation_filter_sheet.dart';
import 'widgets/evacuation_map_view.dart';
import 'widgets/evacuation_search_bar.dart';
import 'widgets/facility_card.dart';
import 'widgets/facility_detail_sheet.dart';
import 'widgets/offline_map_download_dialog.dart';
import 'widgets/volunteer_sos_detail_sheet.dart';
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
  void initState() {
    super.initState();
    _initLocationState();
  }

  Future<void> _initLocationState() async {
    const cacheService = EvacuationCacheService();
    final last = await cacheService.getLastLocation();
    if (last != null && mounted) {
      setState(() => _userLocation = LatLng(last.lat, last.lng));
    }
    final realTime = await const LocationService().tryGetCurrentPosition();
    if (realTime != null && mounted) {
      setState(() => _userLocation = realTime);
      await cacheService.saveLastLocation(
        realTime.latitude,
        realTime.longitude,
      );
    }
  }

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

  void _showVolunteerDetail(PublicSosEvent sos) {
    VolunteerSosDetailSheet.show(
      context,
      event: sos,
      onStartRoute: () {
        setState(() {
          _selectedRoutePoint = null;
          _isMapView = true;
        });
      },
    );
  }

  void _showOfflineDownloadDialog(List<EvacuationPoint> points) {
    OfflineMapDownloadDialog.show(
      context,
      userLocation: _userLocation,
      availablePoints: points,
      onDownloadComplete: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Peta wilayah berhasil disimpan untuk penggunaan offline.',
            ),
            backgroundColor: AppColors.siaga,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = EvacuationQuery(
      kind: _selectedKind,
      searchQuery: _searchQuery,
    );
    final pointsAsync = ref.watch(evacuationPointsProvider(query));
    final publicSosQuery = PublicSosQuery(
      latitude: _userLocation.latitude,
      longitude: _userLocation.longitude,
    );
    final publicSosAsync = ref.watch(nearbyPublicSosProvider(publicSosQuery));
    final activeMission = ref.watch(activeVolunteerMissionProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppHeader(
        title: 'Maps',
        actions: [
          IconButton(
            tooltip: 'Unduh Peta Offline',
            icon: const Icon(
              Icons.download_for_offline_rounded,
              color: AppColors.accentOrange,
            ),
            onPressed: () {
              final pts = pointsAsync.asData?.value ?? [];
              _showOfflineDownloadDialog(pts);
            },
          ),
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
          EvacuationSearchBar(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            onClear: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          ),
          Expanded(
            child: pointsAsync.when(
              data: (points) => _isMapView
                  ? EvacuationMapView(
                      points: points,
                      activeRoutePoint: _selectedRoutePoint,
                      userLocation: _userLocation,
                      publicSosList: publicSosAsync.asData?.value,
                      onSosSelected: _showVolunteerDetail,
                      activeVolunteerMission: activeMission,
                      onClearVolunteerRoute: () {
                        final id = currentUser?.id ?? 'guest-volunteer';
                        ref
                            .read(activeVolunteerMissionProvider.notifier)
                            .finishMission(id);
                      },
                      onVolunteerArrived: () {
                        final id = currentUser?.id ?? 'guest-volunteer';
                        ref
                            .read(activeVolunteerMissionProvider.notifier)
                            .markArrived(id);
                      },
                      onLocationSynced: (loc) {
                        setState(() => _userLocation = loc);
                        const EvacuationCacheService().saveLastLocation(
                          loc.latitude,
                          loc.longitude,
                        );
                      },
                      onClearRoute: () =>
                          setState(() => _selectedRoutePoint = null),
                      onPointSelected: _showDetailSheet,
                      onDownloadOfflineMap: () =>
                          _showOfflineDownloadDialog(points),
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
