import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

/// Floating zoom in, zoom out, and re-center controls for map view.
class MapZoomControls extends StatelessWidget {
  const MapZoomControls({
    super.key,
    required this.mapController,
    required this.targetLocation,
  });

  final MapController mapController;
  final LatLng targetLocation;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: AppSpacing.lg,
      right: AppSpacing.pagePadding,
      child: Column(
        children: [
          FloatingActionButton.small(
            heroTag: 'map_recenter_user',
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.chartBlue,
            onPressed: () => mapController.move(targetLocation, 15.0),
            child: const Icon(Icons.gps_fixed_rounded, size: 20),
          ),
          const SizedBox(height: AppSpacing.xs),
          FloatingActionButton.small(
            heroTag: 'map_zoom_in',
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            onPressed: () {
              final zoom = mapController.camera.zoom;
              mapController.move(mapController.camera.center, zoom + 1);
            },
            child: const Icon(Icons.add, size: 20),
          ),
          const SizedBox(height: AppSpacing.xs),
          FloatingActionButton.small(
            heroTag: 'map_zoom_out',
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            onPressed: () {
              final zoom = mapController.camera.zoom;
              mapController.move(mapController.camera.center, zoom - 1);
            },
            child: const Icon(Icons.remove, size: 20),
          ),
        ],
      ),
    );
  }
}
