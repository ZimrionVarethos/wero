import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_providers.dart';
import '../../core/providers/community_providers.dart';
import '../../routing/app_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/app_header.dart';
import '../../widgets/contour_wave_background.dart';
import 'widgets/community_filter_sheet.dart';
import 'widgets/empty_region_prompt.dart';
import 'widgets/post_card.dart';

/// Community Feed screen supporting Local & National feeds, search, and filtering via popup.
class CommunityFeedScreen extends ConsumerStatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  ConsumerState<CommunityFeedScreen> createState() =>
      _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends ConsumerState<CommunityFeedScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(communityFeedProvider.notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onBottomNavTap(int index) {
    if (index == 0) context.go(AppRoutes.activity);
    if (index == 1) context.go(AppRoutes.assistant);
    if (index == 2) return; // already here
    if (index == 3) context.go(AppRoutes.profile);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityFeedProvider);
    final profile = ref.watch(userProfileProvider).asData?.value;
    final hasActiveFilter =
        state.selectedCategoryId != null || state.scope != 'LOCAL';

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppHeader(
        showBackButton: false,
        prefixActions: [_buildFilterButton(hasActiveFilter)],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: ContourWaveBackground(variant: ContourVariant.community),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildSearchBar(),
                if (state.isOffline) _buildOfflineBanner(),
                Expanded(child: _buildBody(state, profile?.regionId)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/community/create'),
        backgroundColor: AppColors.textPrimary,
        icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
        label: const Text('Tulis Post', style: TextStyle(color: Colors.white)),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 2,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildFilterButton(bool hasActiveFilter) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.tune_rounded, size: 22),
          color: AppColors.primaryNavy,
          tooltip: 'Filter Berita & Kategori',
          onPressed: () => CommunityFilterSheet.show(context),
        ),
        if (hasActiveFilter)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.accentOrange,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceWhite, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: AppColors.borderNeutral),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryNavy.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: AppTextStyles.body.copyWith(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Cari topik kesiapsiagaan...',
            hintStyle: AppTextStyles.caption.copyWith(
              color: AppColors.mutedText,
            ),
            prefixIcon: const Icon(
              Icons.search,
              size: 20,
              color: AppColors.mutedText,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      ref
                          .read(communityFeedProvider.notifier)
                          .setSearchQuery('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
          onSubmitted: (query) =>
              ref.read(communityFeedProvider.notifier).setSearchQuery(query),
        ),
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      color: AppColors.softBlue,
      padding: const EdgeInsets.symmetric(
        vertical: 6,
        horizontal: AppSpacing.pagePadding,
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, size: 16, color: AppColors.chartBlue),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Mode Offline: Menampilkan data tersimpan di perangkat.',
              style: AppTextStyles.caption.copyWith(color: AppColors.chartBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(CommunityFeedState state, String? userRegionId) {
    if (state.scope == 'LOCAL' && userRegionId == null) {
      return EmptyRegionPrompt(
        onConfigureRegion: () => context.go(AppRoutes.profile),
      );
    }

    if (state.isLoading && state.posts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryNavy),
      );
    }

    if (state.posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(communityFeedProvider.notifier).refresh(),
        child: ListView(
          children: [
            const SizedBox(height: 80),
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Belum ada postingan',
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Jadilah yang pertama berbagi informasi!',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(communityFeedProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.sm,
        ),
        itemCount: state.posts.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final post = state.posts[index];
          return PostCard(
            post: post,
            onTap: () => context.push('/community/detail', extra: post),
          );
        },
      ),
    );
  }
}
