import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/app_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Modern quick access action cards for Kerabat Siaga (left) and Panduan Darurat (right).
class QuickAccessBar extends StatelessWidget {
  const QuickAccessBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Card Kerabat Siaga (Kiri) - Aksen Oranye Hangat
        Expanded(
          child: _QuickBannerCard(
            icon: Icons.family_restroom_rounded,
            iconColor: AppColors.accentOrange,
            iconBgColor: AppColors.accentOrange.withValues(alpha: 0.12),
            title: 'Kerabat Siaga',
            subtitle: 'Pantau Keluarga',
            onTap: () => context.push(AppRoutes.family),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Card Panduan Darurat (Kanan) - Aksen Biru Navy
        Expanded(
          child: _QuickBannerCard(
            icon: Icons.menu_book_rounded,
            iconColor: AppColors.chartBlue,
            iconBgColor: AppColors.chartBlue.withValues(alpha: 0.12),
            title: 'Panduan Darurat',
            subtitle: 'Protokol Siaga',
            onTap: () => context.push(AppRoutes.guides),
          ),
        ),
      ],
    );
  }
}

class _QuickBannerCard extends StatelessWidget {
  const _QuickBannerCard({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: AppColors.borderNeutral.withValues(alpha: 0.65),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryNavy.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        color: AppColors.primaryNavy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
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
    );
  }
}
