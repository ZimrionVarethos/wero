import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/disaster_event.dart';
import '../routing/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Full-screen high-priority alert overlay triggered when Web Admin broadcasts an emergency.
class EmergencyAlertOverlay extends StatelessWidget {
  const EmergencyAlertOverlay({
    super.key,
    required this.event,
    required this.onDismiss,
  });

  final DisasterEvent event;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final isCritical = event.isAwas || event.severity == 'CRITICAL';
    final alertColor = isCritical ? AppColors.chartRed : AppColors.accentOrange;

    return Material(
      color: Colors.black87,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: alertColor, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: alertColor.withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: alertColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: alertColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SIARAN DARURAT RESMI',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: alertColor,
                                letterSpacing: 1.1,
                              ),
                            ),
                            Text(
                              event.source,
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    event.headline,
                    style: AppTextStyles.screenTitle.copyWith(
                      fontSize: 18,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.canvasBlue,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          'Tipe: ${event.disasterType}',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Status: ${event.severity}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: alertColor,
                          ),
                        ),
                        if (event.magnitude != null)
                          Text(
                            'M ${event.magnitude}',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (event.targetRegions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: alertColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Wilayah: ${event.targetRegions.join(', ')}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: alertColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Peringatan ini disiarkan secara langsung dari Pusat Pengendalian Operasi Penanggulangan Bencana.',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: onDismiss,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: alertColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                      ),
                      icon: const Icon(
                        Icons.volume_off_rounded,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'HENTIKAN SIRINE & TETAP SIAGA',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        onDismiss();
                        context.push(AppRoutes.evacuation);
                      },
                      icon: const Icon(Icons.near_me_outlined, size: 18),
                      label: const Text('Buka Peta Jalur Evakuasi'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
