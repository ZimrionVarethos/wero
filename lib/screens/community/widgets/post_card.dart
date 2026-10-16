import 'package:flutter/material.dart';

import '../../../models/community_post.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import 'post_thumbnail.dart';

/// Community post card matching the Home ActivityCard visual style.
///
/// Features photo thumbnail, bold post title, thin separator line,
/// and metadata row (category, relative time, and region location).
class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, required this.onTap});

  final CommunityPost post;
  final VoidCallback onTap;

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m lalu';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}j lalu';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String get _displayTitle {
    if (post.title != null && post.title!.trim().isNotEmpty) {
      return post.title!.trim();
    }
    if (post.body.trim().isNotEmpty) {
      final firstLine = post.body
          .trim()
          .split('\n')
          .firstWhere(
            (line) => line.trim().isNotEmpty,
            orElse: () => post.body.trim(),
          );
      return firstLine.trim();
    }
    return 'Laporan Komunitas';
  }

  @override
  Widget build(BuildContext context) {
    final firstImage = post.images.isNotEmpty ? post.images.first : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              PostThumbnail(
                imageUrl: firstImage?.signedUrl,
                hasHazard: post.hazardTags.isNotEmpty,
              ),
              _buildCardContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Judul dengan tulisan bold
          Text(
            _displayTitle,
            style: AppTextStyles.label.copyWith(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryNavy,
              height: 1.35,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          // 2. Pemisah garis tipis antara judul dan metadata
          const Divider(
            height: 1,
            thickness: 0.8,
            color: AppColors.borderNeutral,
          ),
          const SizedBox(height: AppSpacing.sm),
          // 3. Metadata: Kategori, Waktu, Lokasi
          _buildMetadataRow(),
        ],
      ),
    );
  }

  Widget _buildMetadataRow() {
    return Row(
      children: [
        // Kiri: kategori + waktu, mengambil semua sisa ruang
        Expanded(
          child: Row(
            children: [
              if (post.categoryName != null) ...[
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.canvasBlue,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Text(
                      post.categoryName!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.chartBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(
                child: Text(
                  _formatDate(post.createdAt),
                  style: AppTextStyles.caption.copyWith(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        // Kanan: lokasi / badge tersimpan, lebar dibatasi
        if (post.isCached)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.canvasBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Tersimpan',
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                color: AppColors.chartBlue,
              ),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 13,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    post.regionName ?? 'Indonesia',
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
