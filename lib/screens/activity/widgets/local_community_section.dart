import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/community_post.dart';
import '../../../routing/app_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../community/widgets/post_card.dart';

/// Section showing the 3 latest local community posts and a View All button.
class LocalCommunitySection extends StatelessWidget {
  const LocalCommunitySection({
    super.key,
    required this.cityName,
    required this.postsAsync,
  });

  final String cityName;
  final AsyncValue<List<CommunityPost>> postsAsync;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/images/news_icon.png',
              width: 24,
              height: 24,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.newspaper_rounded,
                size: 22,
                color: AppColors.chartBlue,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'Liat Keadaan $cityName Komunitas',
                style: AppTextStyles.sectionTitle,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Laporan situasi darurat dan kondisi terkini dari warga sekitar.',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: AppSpacing.base),
        postsAsync.when(
          data: (posts) => _buildPostList(context, posts),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              'Gagal memuat berita komunitas: $err',
              style: AppTextStyles.caption.copyWith(color: AppColors.chartRed),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.go(AppRoutes.community),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.chartBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Lihat Semua',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.chartBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppColors.chartBlue,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPostList(BuildContext context, List<CommunityPost> posts) {
    final localPosts = posts.take(3).toList();
    if (localPosts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: AppColors.canvasBlue,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.forum_outlined,
              size: 32,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Belum ada laporan komunitas di wilayah $cityName.',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Jadilah yang pertama mengabarkan situasi di lingkungan Anda.',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < localPosts.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.base),
          PostCard(
            post: localPosts[i],
            onTap: () =>
                context.push(AppRoutes.postDetail, extra: localPosts[i]),
          ),
        ],
      ],
    );
  }
}
