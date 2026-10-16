import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/community_post.dart';

/// Local offline cache service for community posts.
/// Enforces honest offline behavior: cached items are tagged with isCached=true.
class CommunityCacheService {
  const CommunityCacheService();

  static const String _prefix = 'wero_community_cache_';
  static const String _updatedPrefix = 'wero_community_updated_';

  String _cacheKey(String scope, String? regionId) {
    if (scope == 'LOCAL') {
      return '$_prefix${scope}_${regionId ?? "all"}';
    }
    return '$_prefix$scope';
  }

  /// Save up to 50 latest posts to local storage.
  Future<void> savePosts({
    required String scope,
    String? regionId,
    required List<CommunityPost> posts,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _cacheKey(scope, regionId);
      final list = posts.take(50).map((p) => p.toJson()).toList();
      await prefs.setString(key, jsonEncode(list));
      await prefs.setString(
        '$_updatedPrefix$key',
        DateTime.now().toIso8601String(),
      );
    } catch (_) {
      // Local storage errors should not crash the app
    }
  }

  /// Retrieve cached posts for the requested scope and region.
  Future<List<CommunityPost>> getCachedPosts({
    required String scope,
    String? regionId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _cacheKey(scope, regionId);
      final raw = prefs.getString(key);
      if (raw == null) return const [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      return decoded
          .whereType<Map<String, dynamic>>()
          .map((item) => CommunityPost.fromJson(item, isCached: true))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Timestamp of the last successful cache sync.
  Future<DateTime?> getLastUpdated({
    required String scope,
    String? regionId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _cacheKey(scope, regionId);
      final raw = prefs.getString('$_updatedPrefix$key');
      if (raw == null) return null;
      return DateTime.tryParse(raw);
    } catch (_) {
      return null;
    }
  }
}
