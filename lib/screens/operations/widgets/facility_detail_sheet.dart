import 'package:flutter/material.dart';

import '../../../models/evacuation_point.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Modal bottom sheet displaying detailed information for an evacuation point.
class FacilityDetailSheet extends StatelessWidget {
  const FacilityDetailSheet({
    super.key,
    required this.point,
    this.onNavigateRoute,
    this.onEditPoint,
  });

  final EvacuationPoint point;
  final ValueChanged<EvacuationPoint>? onNavigateRoute;
  final ValueChanged<EvacuationPoint>? onEditPoint;

  static void show(
    BuildContext context,
    EvacuationPoint point, {
    ValueChanged<EvacuationPoint>? onNavigateRoute,
    ValueChanged<EvacuationPoint>? onEditPoint,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      builder: (ctx) => FacilityDetailSheet(
        point: point,
        onNavigateRoute: onNavigateRoute,
        onEditPoint: onEditPoint,
      ),
    );
  }

  Color get _kindColor {
    return switch (point.kind) {
      'SHELTER' => AppColors.chartBlue,
      'HEALTH' => AppColors.chartRed,
      'ASSEMBLY' => AppColors.accentOrange,
      _ => AppColors.textSecondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _kindColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text(
                  point.kindLabel,
                  style: AppTextStyles.caption.copyWith(
                    color: _kindColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              if (point.capacity != null)
                Text(
                  'Daya Tampung: ${point.capacity} Jiwa',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (onEditPoint != null) ...[
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  tooltip: 'Kelola / Edit Posko',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.edit_note_rounded,
                    color: AppColors.chartBlue,
                    size: 22,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    onEditPoint!(point);
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(point.name, style: AppTextStyles.sectionTitle),
          if (point.description != null && point.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(point.description!, style: AppTextStyles.bodySecondary),
          ],
          if (point.address != null && point.address!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(point.address!, style: AppTextStyles.caption),
                ),
              ],
            ),
          ],
          if (point.latitude != null && point.longitude != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Koordinat: ${point.latitude!.toStringAsFixed(4)}, ${point.longitude!.toStringAsFixed(4)}',
              style: AppTextStyles.caption.copyWith(fontSize: 11),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                if (onNavigateRoute != null) {
                  onNavigateRoute!(point);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Menampilkan rute evakuasi menuju ${point.name}',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(
                Icons.directions_walk_rounded,
                color: Colors.white,
              ),
              label: const Text(
                'Panduan Rute Menuju Posko',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
