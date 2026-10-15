import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/bmkg_quake.dart';
import '../../../routing/app_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import 'quake_safety_protocol_box.dart';

/// Modal bottom sheet presenting full BMKG early warning parameters, shakemap, and action guide.
class BmkgAlertDetailSheet extends StatelessWidget {
  const BmkgAlertDetailSheet({super.key, required this.quake});

  final BmkgQuake quake;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: quake.severityColor,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Text(
                      quake.formattedMagnitude,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Peringatan Dini Gempa Bumi',
                          style: AppTextStyles.sectionTitle.copyWith(
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${quake.tanggal} • ${quake.jam}',
                          style: AppTextStyles.caption.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                quake.wilayah,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: quake.isTsunamiPotential
                      ? AppColors.chartRed.withValues(alpha: 0.12)
                      : AppColors.chartGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(
                    color: quake.isTsunamiPotential
                        ? AppColors.chartRed
                        : AppColors.chartGreen,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      quake.isTsunamiPotential
                          ? Icons.warning_rounded
                          : Icons.check_circle_outline_rounded,
                      color: quake.isTsunamiPotential
                          ? AppColors.chartRed
                          : AppColors.chartGreen,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        quake.potensi,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: quake.isTsunamiPotential
                              ? AppColors.chartRed
                              : AppColors.chartGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'Kedalaman',
                      quake.kedalaman,
                      Icons.vertical_align_bottom_rounded,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildInfoItem(
                      'Koordinat',
                      quake.coordinates,
                      Icons.my_location_rounded,
                    ),
                  ),
                ],
              ),
              if (quake.dirasakan != null && quake.dirasakan!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text('Skala MMI Dirasakan:', style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(
                  quake.dirasakan!,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (quake.shakemapUrl != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Peta Guncangan (Shakemap):',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: Image.network(
                    quake.shakemapUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 80,
                      color: AppColors.canvasBlue,
                      alignment: Alignment.center,
                      child: Text(
                        'Peta Shakemap tidak tersedia untuk gempa skala lokal',
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.base),
              const QuakeSafetyProtocolBox(),
              const SizedBox(height: AppSpacing.base),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.family_restroom_rounded, size: 16),
                      label: const Text('Family Check-in'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.push(AppRoutes.family);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.near_me_rounded, size: 16),
                      label: const Text('Peta Shelter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.push(AppRoutes.evacuation);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.canvasBlue,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(fontSize: 10),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
