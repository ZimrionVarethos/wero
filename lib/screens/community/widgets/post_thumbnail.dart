import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Thumbnail widget for community post preview cards.
class PostThumbnail extends StatelessWidget {
  const PostThumbnail({
    super.key,
    required this.imageUrl,
    this.hasHazard = false,
  });

  final String? imageUrl;
  final bool hasHazard;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(
              color: AppColors.canvasBlue,
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.chartBlue,
                  ),
                ),
              ),
            );
          },
          errorBuilder: (_, _, _) => _buildDefaultBanner(),
        ),
      );
    }
    return _buildDefaultBanner();
  }

  Widget _buildDefaultBanner() {
    return AspectRatio(
      aspectRatio: 16 / 7,
      child: Container(
        color: AppColors.canvasBlue,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(
                    hasHazard
                        ? Icons.warning_amber_rounded
                        : Icons.newspaper_rounded,
                    color: AppColors.chartBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Warta Siaga',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
