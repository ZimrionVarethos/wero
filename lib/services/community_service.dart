import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/errors/app_exceptions.dart';
import '../models/community_category.dart';
import '../models/community_post.dart';
import '../models/hazard_tag.dart';
import 'community_cache_service.dart';
import 'community_storage_service.dart';

/// Community service managing posts, reporting, and offline cache.
class CommunityService {
  CommunityService(this._client, [CommunityCacheService? cache])
    : _cache = cache ?? const CommunityCacheService(),
      _storage = CommunityStorageService(_client);

  final SupabaseClient? _client;
  final CommunityCacheService _cache;
  final CommunityStorageService _storage;

  /// Fetch active community categories.
  Future<List<CommunityCategory>> fetchCategories() async {
    final client = _client;
    if (client == null) return const [];
    try {
      final res = await client
          .from('community_categories')
          .select('id, slug, name, description, sort_order')
          .eq('is_active', true)
          .order('sort_order', ascending: true);
      return (res as List).map((c) => CommunityCategory.fromJson(c)).toList();
    } catch (e) {
      throw ServerException('Gagal memuat kategori komunitas: $e', e);
    }
  }

  /// Fetch active hazard tags.
  Future<List<HazardTag>> fetchHazardTags() async {
    final client = _client;
    if (client == null) return const [];
    try {
      final res = await client
          .from('hazard_tags')
          .select('id, slug, name')
          .eq('is_active', true)
          .order('name', ascending: true);
      return (res as List).map((t) => HazardTag.fromJson(t)).toList();
    } catch (e) {
      throw ServerException('Gagal memuat tag bahaya: $e', e);
    }
  }

  /// Fetch published community posts for the specified scope.
  Future<List<CommunityPost>> fetchPosts({
    required String scope,
    String? regionId,
    String? categoryId,
    String? searchQuery,
    int limit = 20,
    int offset = 0,
  }) async {
    final client = _client;
    if (client == null) {
      return _cache.getCachedPosts(scope: scope, regionId: regionId);
    }

    try {
      var query = client
          .from('community_posts')
          .select(
            'id, author_id, title, body, category_id, scope, region_id, status, '
            'created_at, published_at, '
            'profiles(display_name, avatar_path), '
            'community_categories(name, slug), regions(name), '
            'community_post_images(id, post_id, storage_path, alt_text, sort_order), '
            'community_post_hazards(hazard_tags(id, slug, name))',
          )
          .eq('status', 'PUBLISHED')
          .eq('scope', scope);

      if (scope == 'LOCAL' && regionId != null) {
        query = query.eq('region_id', regionId);
      }
      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.eq('category_id', categoryId);
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim();
        query = query.or('title.ilike.%$q%,body.ilike.%$q%');
      }

      final res = await query
          .order('published_at', ascending: false)
          .range(offset, offset + limit - 1);

      final posts = <CommunityPost>[];
      for (final item in (res as List)) {
        final post = CommunityPost.fromJson(item as Map<String, dynamic>);
        posts.add(await _storage.resolveSignedImages(post));
      }

      if (offset == 0 && (searchQuery == null || searchQuery.isEmpty)) {
        await _cache.savePosts(scope: scope, regionId: regionId, posts: posts);
      }

      return posts;
    } catch (e) {
      final cached = await _cache.getCachedPosts(
        scope: scope,
        regionId: regionId,
      );
      if (cached.isNotEmpty) return cached;
      throw ServerException('Gagal memuat feed komunitas: $e', e);
    }
  }

  /// Create and publish a community post, optionally with images and hazard tags.
  Future<String> createPost({
    required String body,
    String? title,
    required String categoryId,
    required String scope,
    String? regionId,
    List<XFile> images = const [],
    List<String> hazardTagIds = const [],
  }) async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw const AppAuthException('Anda harus masuk untuk membuat postingan.');
    }

    if (scope == 'LOCAL' && regionId == null) {
      throw const ValidationException(
        'Postingan lokal memerlukan wilayah profil yang terdaftar.',
      );
    }

    try {
      final insertData = <String, dynamic>{
        'author_id': user.id,
        'body': body.trim(),
        'category_id': categoryId,
        'scope': scope,
        'status': 'PUBLISHED',
      };
      if (title != null && title.trim().isNotEmpty) {
        insertData['title'] = title.trim();
      }
      if (regionId != null) {
        insertData['region_id'] = regionId;
      }

      final inserted = await client
          .from('community_posts')
          .insert(insertData)
          .select('id')
          .single();

      final postId = inserted['id'] as String;

      for (var i = 0; i < images.length && i < 4; i++) {
        await _storage.uploadImage(
          userId: user.id,
          postId: postId,
          file: images[i],
          sortOrder: i,
        );
      }

      if (hazardTagIds.isNotEmpty) {
        final hazardRows = hazardTagIds
            .map((hId) => {'post_id': postId, 'hazard_id': hId})
            .toList();
        await client.from('community_post_hazards').insert(hazardRows);
      }

      return postId;
    } catch (e) {
      throw ServerException('Gagal menerbitkan postingan: $e', e);
    }
  }

  /// Soft delete own community post via database RPC.
  Future<bool> softDeletePost(String postId) async {
    final client = _client;
    if (client == null) return false;
    try {
      final res = await client.rpc(
        'soft_delete_own_community_post',
        params: {'p_post_id': postId},
      );
      return res == true;
    } catch (e) {
      throw ServerException('Gagal menghapus postingan: $e', e);
    }
  }

  /// Report a post for violations. Threshold of 5 distinct accounts hides it.
  Future<void> reportPost({
    required String postId,
    required String reasonCode,
    String? details,
  }) async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw const AppAuthException(
        'Anda harus masuk untuk melaporkan postingan.',
      );
    }
    try {
      await client.from('community_reports').insert({
        'post_id': postId,
        'reporter_id': user.id,
        'reason_code': reasonCode,
        'details': details?.trim(),
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const ValidationException(
          'Anda sudah pernah melaporkan postingan ini sebelumnya.',
        );
      }
      throw ServerException(e.message, e);
    } catch (e) {
      throw ServerException('Gagal mengirimkan laporan: $e', e);
    }
  }
}
