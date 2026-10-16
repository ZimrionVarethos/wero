import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../models/public_sos_event.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Floating banner showing active volunteer route and distance to SOS victim.
class ActiveVolunteerBanner extends StatelessWidget {
  const ActiveVolunteerBanner({
    super.key,
    required this.event,
    required this.targetLatLng,
    required this.userLocation,
    required this.status,
    required this.onMarkArrived,
    required this.onClearRoute,
  });

  final PublicSosEvent event;
  final LatLng targetLatLng;
  final LatLng userLocation;
  final String status;
  final VoidCallback onMarkArrived;
  final VoidCallback onClearRoute;

  @override
  Widget build(BuildContext context) {
    const dist = Distance();
    final meters = dist.as(LengthUnit.Meter, userLocation, targetLatLng);
    final isArrived = status == 'ARRIVED';
    final distText = meters < 1000
        ? '${meters.round()} m'
        : '${(meters / 1000).toStringAsFixed(1)} km';
    final estMin = (meters / 400).round().clamp(1, 120); // driving/riding speed

    return Positioned(
      top: AppSpacing.sm,
      left: AppSpacing.pagePadding,
      right: AppSpacing.pagePadding,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppColors.awas, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.awas,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_run_rounded,
                    color: Colors.white,
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
                        'Rute Relawan: ${event.victimName}',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.awas,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        isArrived
                            ? 'Sudah Tiba di Lokasi Korban'
                            : 'Jarak ~ $distText (± $estMin menit)',
                        style: AppTextStyles.caption.copyWith(
                          color: isArrived ? AppColors.aman : AppColors.textPrimary,
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
            if (!isArrived) ...[
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onMarkArrived,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.aman,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                  label: const Text(
                    'Sudah Tiba di Lokasi Korban',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
