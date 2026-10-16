import 'package:flutter/material.dart';

import '../models/activity.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Card widget displaying a single activity with image, name, and calorie info.
///
/// Uses [Image.network] with a fixed aspect ratio, BoxFit.cover, and
/// rounded corners matching the design token [AppRadius.card].
/// Loading and error fallbacks are included.
class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key, required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActivityImage(imageUrl: activity.imageUrl),
          _ActivityInfo(activity: activity),
        ],
      ),
    );
  }
}

class _ActivityImage extends StatelessWidget {
  const _ActivityImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            color: AppColors.canvasBlue,
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.chartBlue,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (_, _, _) => Container(
          color: AppColors.border,
          child: const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: AppColors.textSecondary,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityInfo extends StatelessWidget {
  const _ActivityInfo({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              activity.name,
              style: AppTextStyles.label,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            Icons.local_fire_department_rounded,
            size: 16,
            color: AppColors.accentOrange,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text('${activity.calories} Kcal/hr', style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
