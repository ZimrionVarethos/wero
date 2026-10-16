import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/config/app_config.dart';
import '../../../models/evacuation_point.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import 'active_route_banner.dart';
import 'evacuation_map_markers.dart';
import 'map_layer_button.dart';
import 'map_location_button.dart';
import 'map_zoom_controls.dart';

/// Interactive high-resolution map view supporting Mapbox tiles, GPS sync, and route polylines.
class EvacuationMapView extends StatefulWidget {
  const EvacuationMapView({
    super.key,
    required this.points,
    required this.onPointSelected,
    this.activeRoutePoint,
    this.onClearRoute,
    this.initialCenter = const LatLng(-7.7956, 110.3695),
    this.userLocation = const LatLng(-7.7956, 110.3695),
    this.onLocationSynced,
  });

  final List<EvacuationPoint> points;
  final ValueChanged<EvacuationPoint> onPointSelected;
  final EvacuationPoint? activeRoutePoint;
  final VoidCallback? onClearRoute;
  final LatLng initialCenter;
  final LatLng userLocation;
  final ValueChanged<LatLng>? onLocationSynced;

  @override
  State<EvacuationMapView> createState() => _EvacuationMapViewState();
}

class _EvacuationMapViewState extends State<EvacuationMapView> {
  late final MapController _mapController;
  late LatLng _currentLocation;
  EvacuationMapStyle _currentStyle = EvacuationMapStyle.satellite;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentLocation = widget.userLocation;
    if (!AppConfig.isMapboxConfigured) {
      AppConfig.loadDynamicConfig().then((_) {
        if (mounted && AppConfig.isMapboxConfigured) {
          setState(() {});
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant EvacuationMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userLocation != oldWidget.userLocation) {
      _currentLocation = widget.userLocation;
    }
    final newRoute = widget.activeRoutePoint;
    if (newRoute != null &&
        newRoute != oldWidget.activeRoutePoint &&
        newRoute.latitude != null &&
        newRoute.longitude != null) {
      _mapController.move(
        LatLng(newRoute.latitude!, newRoute.longitude!),
        14.5,
      );
    }
  }

  List<LatLng> _buildRoutePath(LatLng start, LatLng end) {
    final midLat = (start.latitude + end.latitude) / 2;
    final midLng = (start.longitude + end.longitude) / 2;
    return [
      start,
      LatLng(
        start.latitude + (end.latitude - start.latitude) * 0.35,
        start.longitude + 0.0015,
      ),
      LatLng(midLat, midLng - 0.001),
      LatLng(
        start.latitude + (end.latitude - start.latitude) * 0.75,
        end.longitude + 0.001,
      ),
      end,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final validPoints = widget.points
        .where((p) => p.latitude != null && p.longitude != null)
        .toList();
    final targetPoint = widget.activeRoutePoint;
    final targetLatLng =
        (targetPoint?.latitude != null && targetPoint?.longitude != null)
        ? LatLng(targetPoint!.latitude!, targetPoint.longitude!)
        : null;

    final routePoints = targetLatLng != null
        ? _buildRoutePath(_currentLocation, targetLatLng)
        : <LatLng>[];

    final mapboxUrl = AppConfig.isMapboxConfigured
        ? 'https://api.mapbox.com/styles/v1/${_currentStyle.styleId}/tiles/256/{z}/{x}/{y}@2x?access_token=${AppConfig.mapboxToken}'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: targetLatLng ?? _currentLocation,
            initialZoom: targetLatLng != null ? 14.0 : 12.5,
            minZoom: 4.0,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              urlTemplate: mapboxUrl,
              userAgentPackageName: 'com.siagaku.wero',
              tileProvider: NetworkTileProvider(
                cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
                  maxCacheSize: 1024 * 1024 * 1024,
                  overrideFreshAge: const Duration(days: 180),
                ),
                silenceExceptions: true,
              ),
            ),
            if (routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    strokeWidth: 5.0,
                    color: AppColors.chartBlue,
                    borderStrokeWidth: 2.0,
                    borderColor: Colors.white,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                EvacuationMapMarkers.buildUserMarker(_currentLocation),
                ...validPoints.map(
                  (point) => EvacuationMapMarkers.buildFacilityMarker(
                    point: point,
                    isSelected: targetPoint?.id == point.id,
                    onTap: () => widget.onPointSelected(point),
                  ),
                ),
              ],
            ),
          ],
        ),
        if (targetPoint != null && targetLatLng != null)
          ActiveRouteBanner(
            point: targetPoint,
            targetLatLng: targetLatLng,
            userLocation: _currentLocation,
            onClearRoute: widget.onClearRoute,
          ),
        Positioned(
          top: AppSpacing.sm,
          right: AppSpacing.pagePadding,
          child: MapLayerButton(
            selectedStyle: _currentStyle,
            onStyleChanged: (style) => setState(() => _currentStyle = style),
          ),
        ),
        Positioned(
          bottom: AppSpacing.lg,
          left: AppSpacing.pagePadding,
          child: MapLocationButton(
            onLocationSynced: (loc) {
              setState(() => _currentLocation = loc);
              widget.onLocationSynced?.call(loc);
              _mapController.move(loc, 15.0);
            },
          ),
        ),
        MapZoomControls(
          mapController: _mapController,
          targetLocation: _currentLocation,
        ),
        if (AppConfig.isMapboxConfigured)
          Positioned(
            bottom: 4,
            left: AppSpacing.pagePadding,
            child: Text(
              '© Mapbox © OpenStreetMap',
              style: AppTextStyles.caption.copyWith(
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
      ],
    );
  }
}
