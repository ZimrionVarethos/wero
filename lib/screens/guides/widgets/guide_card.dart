import 'package:flutter/material.dart';

import '../../../models/emergency_guide.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Card previewing an emergency survival guide.
class GuideCard extends StatelessWidget {
  const GuideCard({super.key, required this.guide, required this.onTap});

  final EmergencyGuide guide;
  final VoidCallback onTap;

  Color get _categoryColor {
    return switch (guide.category) {
      GuideCategory.earthquake => AppColors.accentOrange,
      GuideCategory.flood => AppColors.chartBlue,
      GuideCategory.fire => AppColors.chartRed,
      GuideCategory.tsunami => const Color(0xFF00838F),
      GuideCategory.landslide => const Color(0xFF6D4C41),
      GuideCategory.firstAid => const Color(0xFF2E7D32),
    };
  }

  IconData get _categoryIcon {
    return switch (guide.category) {
      GuideCategory.earthquake => Icons.broken_image_outlined,
      GuideCategory.flood => Icons.water_outlined,
      GuideCategory.fire => Icons.local_fire_department_outlined,
      GuideCategory.tsunami => Icons.waves_outlined,
      GuideCategory.landslide => Icons.terrain_outlined,
      GuideCategory.firstAid => Icons.medical_services_outlined,
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _categoryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.iconTile),
                ),
                child: Icon(_categoryIcon, color: _categoryColor, size: 24),
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.canvasBlue,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                      child: Text(
                        guide.categoryLabel,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      guide.title,
                      style: AppTextStyles.sectionTitle.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      guide.summary,
                      style: AppTextStyles.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
