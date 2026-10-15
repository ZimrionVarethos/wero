import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/app_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Quick navigation shortcuts for Posko, Panduan, and Kerabat Siaga.
class QuickAccessBar extends StatelessWidget {
  const QuickAccessBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.evacuation),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.chartBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            icon: const Icon(
              Icons.map_outlined,
              size: 15,
              color: AppColors.chartBlue,
            ),
            label: Text(
              'Posko',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.chartBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.guides),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.accentOrange),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            icon: const Icon(
              Icons.menu_book_outlined,
              size: 15,
              color: AppColors.accentOrange,
            ),
            label: Text(
              'Panduan',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.accentOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.family),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.chartGreen),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            icon: const Icon(
              Icons.family_restroom_rounded,
              size: 15,
              color: AppColors.chartGreen,
            ),
            label: Text(
              'Kerabat',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.chartGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
