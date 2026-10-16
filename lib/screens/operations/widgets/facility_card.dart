import 'package:flutter/material.dart';

import '../../../models/evacuation_point.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Reusable card displaying summary of an evacuation facility.
class FacilityCard extends StatelessWidget {
  const FacilityCard({super.key, required this.point, required this.onTap});

  final EvacuationPoint point;
  final VoidCallback onTap;

  Color get _badgeColor {
    return switch (point.kind) {
      'SHELTER' => AppColors.chartBlue,
      'HEALTH' => AppColors.chartRed,
      'ASSEMBLY' => AppColors.accentOrange,
      _ => AppColors.textSecondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Text(
                      point.kindLabel,
                      style: AppTextStyles.caption.copyWith(
                        color: _badgeColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (point.capacity != null)
                    Text(
                      'Kapasitas: ${point.capacity} jiwa',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                point.name,
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 15),
              ),
              if (point.description != null &&
                  point.description!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(point.description!, style: AppTextStyles.caption),
              ],
              if (point.address != null && point.address!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        point.address!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
