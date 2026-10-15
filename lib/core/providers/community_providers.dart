import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/community_category.dart';
import '../../models/community_post.dart';
import '../../models/hazard_tag.dart';
import '../../services/community_cache_service.dart';
import '../../services/community_service.dart';
import 'auth_providers.dart';
import 'supabase_providers.dart';

/// Provider for local community cache service.
final communityCacheServiceProvider = Provider<CommunityCacheService>((ref) {
  return const CommunityCacheService();
});

/// Provider for community service.
final communityServiceProvider = Provider<CommunityService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final cache = ref.watch(communityCacheServiceProvider);
  return CommunityService(client, cache);
});

/// FutureProvider for community categories.
final communityCategoriesProvider = FutureProvider<List<CommunityCategory>>((
  ref,
) async {
  return ref.watch(communityServiceProvider).fetchCategories();
});

/// FutureProvider for hazard tags.
final hazardTagsProvider = FutureProvider<List<HazardTag>>((ref) async {
  return ref.watch(communityServiceProvider).fetchHazardTags();
});

/// State for the Community Feed.
class CommunityFeedState {
  const CommunityFeedState({
    this.posts = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.hasMore = true,
    this.errorMessage,
    this.scope = 'LOCAL',
    this.selectedCategoryId,
    this.searchQuery = '',
    this.isOffline = false,
  });

  final List<CommunityPost> posts;
  final bool isLoading;
  final bool isRefreshing;
  final bool hasMore;
  final String? errorMessage;
  final String scope;
  final String? selectedCategoryId;
  final String searchQuery;
  final bool isOffline;

  CommunityFeedState copyWith({
    List<CommunityPost>? posts,
    bool? isLoading,
    bool? isRefreshing,
    bool? hasMore,
    String? errorMessage,
    String? scope,
    String? selectedCategoryId,
    bool clearCategory = false,
    String? searchQuery,
    bool? isOffline,
  }) {
    return CommunityFeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
      scope: scope ?? this.scope,
      selectedCategoryId: clearCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      searchQuery: searchQuery ?? this.searchQuery,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}

/// Notifier managing community feed loading, filtering, search, and pagination.
class CommunityFeedNotifier extends Notifier<CommunityFeedState> {
  @override
  CommunityFeedState build() {
    return const CommunityFeedState();
  }

  CommunityService get _service => ref.read(communityServiceProvider);

  /// Load initial posts.
  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await _fetchPosts(isRefresh: false);
  }

  /// Pull-to-refresh feed.
  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, errorMessage: null);
    await _fetchPosts(isRefresh: true);
  }

  /// Toggle scope between LOCAL and NATIONAL.
  void setScope(String scope) {
    if (state.scope == scope) return;
    state = state.copyWith(scope: scope);
    loadInitial();
  }

  /// Filter by category (null to reset).
  void setCategory(String? categoryId) {
    if (state.selectedCategoryId == categoryId) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategoryId: categoryId);
    }
    loadInitial();
  }

  /// Search posts by title/body.
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadInitial();
  }

  /// Remove deleted post from state.
  void removePost(String postId) {
    state = state.copyWith(
      posts: state.posts.where((p) => p.id != postId).toList(),
    );
  }

  Future<void> _fetchPosts({required bool isRefresh}) async {
    final profile = ref.read(userProfileProvider).asData?.value;
    final regionId = profile?.regionId;

    try {
      final posts = await _service.fetchPosts(
        scope: state.scope,
        regionId: regionId,
        categoryId: state.selectedCategoryId,
        searchQuery: state.searchQuery,
        limit: 20,
        offset: 0,
      );

      final hasCached = posts.any((p) => p.isCached);
      state = state.copyWith(
        posts: posts,
        isLoading: false,
        isRefreshing: false,
        hasMore: posts.length >= 20,
        isOffline: hasCached,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Load next page of posts.
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    final profile = ref.read(userProfileProvider).asData?.value;
    final regionId = profile?.regionId;

    try {
      final more = await _service.fetchPosts(
        scope: state.scope,
        regionId: regionId,
        categoryId: state.selectedCategoryId,
        searchQuery: state.searchQuery,
        limit: 20,
        offset: state.posts.length,
      );

      state = state.copyWith(
        posts: [...state.posts, ...more],
        hasMore: more.length >= 20,
      );
    } catch (_) {
      // Pagination fail can fail silently
    }
  }
}

/// Provider exposing the community feed notifier and state.
final communityFeedProvider =
    NotifierProvider<CommunityFeedNotifier, CommunityFeedState>(
      CommunityFeedNotifier.new,
    );

/// FutureProvider fetching the latest 3 local community posts for the user's selected region.
final recentLocalPostsProvider =
    FutureProvider.autoDispose<List<CommunityPost>>((ref) async {
      final service = ref.watch(communityServiceProvider);
      final profile = ref.watch(userProfileProvider).asData?.value;
      final regionId = profile?.regionId;

      return service.fetchPosts(
        scope: 'LOCAL',
        regionId: regionId,
        limit: 3,
        offset: 0,
      );
    });
