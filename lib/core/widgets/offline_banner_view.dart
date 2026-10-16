import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

/// Reusable offline mode banner.
/// Honest about offline capability: notifies the user that cached data is being displayed.
class OfflineBannerView extends StatelessWidget {
  const OfflineBannerView({
    super.key,
    this.message = 'Mode Offline — Menampilkan data tersimpan',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.siagaBg,
        border: Border(
          bottom: BorderSide(
            color: AppColors.siaga.withValues(alpha: 0.3),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 16, color: AppColors.siaga),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              message,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.siaga,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
