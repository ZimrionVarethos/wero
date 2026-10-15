import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../models/evacuation_point.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Floating banner showing active evacuation destination and estimated walking distance.
class ActiveRouteBanner extends StatelessWidget {
  const ActiveRouteBanner({
    super.key,
    required this.point,
    required this.targetLatLng,
    required this.userLocation,
    required this.onClearRoute,
  });

  final EvacuationPoint point;
  final LatLng targetLatLng;
  final LatLng userLocation;
  final VoidCallback? onClearRoute;

  @override
  Widget build(BuildContext context) {
    const dist = Distance();
    final meters = dist.as(LengthUnit.Meter, userLocation, targetLatLng);
    final kmText = (meters / 1000).toStringAsFixed(1);
    final walkMin = (meters / 80).round().clamp(1, 180);

    return Positioned(
      top: AppSpacing.sm,
      left: AppSpacing.pagePadding,
      right: AppSpacing.pagePadding,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
          border: Border.all(color: AppColors.chartBlue.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.softBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_walk_rounded,
                color: AppColors.chartBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Rute: ${point.name}',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Jarak ~ $kmText km (± $walkMin menit jalan kaki)',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.chartBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: onClearRoute,
              tooltip: 'Tutup Rute',
            ),
          ],
        ),
      ),
    );
  }
}
