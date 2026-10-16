import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/bmkg_providers.dart';
import '../../../core/providers/emergency_broadcast_provider.dart';
import '../../../routing/app_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Full-width condition summary banner on the home screen.
/// Left: [icondashboard.png], Right: Live condition status.
/// Tapping the banner navigates to the History & Statistics page.
class ConditionSummaryBanner extends ConsumerWidget {
  const ConditionSummaryBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAlert = ref.watch(activeBroadcastAlertProvider);
    final latestQuakeAsync = ref.watch(latestBmkgQuakeProvider);

    // Determine status parameters
    final bool hasEmergency = activeAlert != null;
    final quake = latestQuakeAsync.asData?.value;
    final bool isQuakeWaspada =
        quake != null && (quake.magnitude >= 5.0 || quake.isTsunamiPotential);

    final Color badgeColor;
    final String badgeText;
    final String titleText;
    final String subtitleText;

    if (hasEmergency) {
      badgeColor = activeAlert.isAwas ? AppColors.awas : AppColors.siaga;
      badgeText = 'STATUS ${activeAlert.severity}';
      titleText = activeAlert.headline;
      subtitleText = 'Ketuk untuk protokol evakuasi dan riwayat darurat';
    } else if (isQuakeWaspada) {
      badgeColor = quake.isTsunamiPotential ? AppColors.awas : AppColors.siaga;
      badgeText = quake.isTsunamiPotential ? 'STATUS AWAS' : 'STATUS WASPADA';
      titleText = 'Gempa M ${quake.magnitude} Terdeteksi';
      subtitleText = '${quake.wilayah} · Ketuk untuk riwayat BMKG';
    } else {
      badgeColor = AppColors.aman;
      badgeText = 'KONDISI AMAN';
      titleText = 'Situasi Wilayah Terpantau Kondusif';
      subtitleText = quake != null
          ? 'BMKG: Gempa M ${quake.magnitude} ${quake.wilayah}'
          : 'Ketuk untuk melihat riwayat bencana & info BMKG';
    }

    return Padding(
      // Margin pinggir sangat tipis agar panjang banner mentok menutupi lebar layar
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(AppRoutes.statistics),
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Ink(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + 4,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: AppColors.borderNeutral.withValues(alpha: 0.7),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryNavy.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Kiri: Gambar icondashboard.png
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCream.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    child: Image.asset(
                      'assets/images/icondashboard.png',
                      width: 58,
                      height: 58,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.primaryNavy.withValues(alpha: 0.08),
                        child: const Icon(
                          Icons.dashboard_outlined,
                          size: 28,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                // Kanan: Status & Ringkasan Kondisi
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                AppRadius.chip,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: badgeColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  badgeText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: badgeColor,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 11,
                            color: AppColors.mutedText,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        titleText,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.primaryNavy,
                          height: 1.25,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitleText,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
