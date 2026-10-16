import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../models/evacuation_point.dart';
import '../../../theme/app_colors.dart';

/// Marker helper for pins and user location on Evacuation Map.
class EvacuationMapMarkers {
  const EvacuationMapMarkers._();

  static Color pinColor(String kind) {
    return switch (kind) {
      'SHELTER' => AppColors.chartBlue,
      'HEALTH' => AppColors.chartRed,
      'ASSEMBLY' => AppColors.accentOrange,
      _ => AppColors.textSecondary,
    };
  }

  static IconData pinIcon(String kind) {
    return switch (kind) {
      'SHELTER' => Icons.night_shelter_rounded,
      'HEALTH' => Icons.local_hospital_rounded,
      'ASSEMBLY' => Icons.groups_rounded,
      _ => Icons.place_rounded,
    };
  }

  static Marker buildUserMarker(LatLng location) {
    return Marker(
      point: location,
      width: 34,
      height: 34,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.chartBlue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.my_location_rounded,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  static Marker buildFacilityMarker({
    required EvacuationPoint point,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = pinColor(point.kind);
    return Marker(
      point: LatLng(point.latitude!, point.longitude!),
      width: isSelected ? 52 : 44,
      height: isSelected ? 52 : 44,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? color.withValues(alpha: 0.6)
                    : Colors.black26,
                blurRadius: isSelected ? 10 : 6,
                spreadRadius: isSelected ? 2 : 0,
              ),
            ],
            border: Border.all(color: Colors.white, width: isSelected ? 3 : 2),
          ),
          child: Icon(
            pinIcon(point.kind),
            color: Colors.white,
            size: isSelected ? 26 : 22,
          ),
        ),
      ),
    );
  }

  static Marker buildPublicSosMarker({
    required double latitude,
    required double longitude,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Marker(
      point: LatLng(latitude, longitude),
      width: 56,
      height: 56,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.awas.withValues(alpha: 0.25),
              ),
            ),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.awas,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: isSelected ? 3.5 : 2.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
