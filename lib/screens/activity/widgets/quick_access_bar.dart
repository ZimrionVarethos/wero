import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/app_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Quick access banners for Kerabat Siaga (left) and Panduan Darurat (right).
class QuickAccessBar extends StatelessWidget {
  const QuickAccessBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Banner Kerabat (Kiri)
        Expanded(
          child: _QuickBannerCard(
            icon: Icons.family_restroom_rounded,
            title: 'Kerabat Siaga',
            onTap: () => context.push(AppRoutes.family),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // Banner Panduan Darurat (Kanan)
        Expanded(
          child: _QuickBannerCard(
            icon: Icons.menu_book_rounded,
            title: 'Panduan Darurat',
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
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
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
            vertical: AppSpacing.base,
            horizontal: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryNavy,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryNavy.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: AppColors.surfaceWhite),
              const SizedBox(height: AppSpacing.xs),
              Text(
                title,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.surfaceWhite,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
