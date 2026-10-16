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
import '../../widgets/app_logo.dart';
import 'widgets/category_filter_bar.dart';
import 'widgets/empty_region_prompt.dart';
import 'widgets/post_card.dart';
import 'widgets/scope_selector.dart';

/// Community Feed screen supporting Local & National feeds, search, and filtering.
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
    final categoriesAsync = ref.watch(communityCategoriesProvider);
    final profile = ref.watch(userProfileProvider).asData?.value;

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(state.scope),
            _buildSearchBar(),
            categoriesAsync.when(
              data: (cats) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: CategoryFilterBar(
                  categories: cats,
                  selectedCategoryId: state.selectedCategoryId,
                  onSelectCategory: (id) =>
                      ref.read(communityFeedProvider.notifier).setCategory(id),
                ),
              ),
              loading: () => const SizedBox(height: 40),
              error: (_, _) => const SizedBox.shrink(),
            ),
            if (state.isOffline) _buildOfflineBanner(),
            Expanded(child: _buildBody(state, profile?.regionId)),
          ],
        ),
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

  Widget _buildTopBar(String currentScope) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogo(height: 28),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                icon: const Icon(
                  Icons.shield_outlined,
                  size: 20,
                  color: AppColors.chartBlue,
                ),
                tooltip: 'Moderasi Komunitas',
                onPressed: () => context.push(AppRoutes.moderation),
              ),
            ],
          ),
          ScopeSelector(
            currentScope: currentScope,
            onScopeChanged: (scope) =>
                ref.read(communityFeedProvider.notifier).setScope(scope),
          ),
        ],
      ),
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: AppColors.border),
        ),
        child: TextField(
          controller: _searchController,
          style: AppTextStyles.body.copyWith(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Cari topik kesiapsiagaan...',
            hintStyle: AppTextStyles.caption,
            prefixIcon: const Icon(
              Icons.search,
              size: 20,
              color: AppColors.textSecondary,
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
        child: CircularProgressIndicator(color: AppColors.textPrimary),
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
