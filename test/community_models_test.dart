import 'package:flutter_test/flutter_test.dart';
import 'package:wero/models/community_category.dart';
import 'package:wero/models/community_post.dart';
import 'package:wero/models/community_post_image.dart';
import 'package:wero/models/hazard_tag.dart';

void main() {
  group('Community Models Tests', () {
    test('CommunityCategory parsing from JSON', () {
      final json = {
        'id': 'cat-123',
        'slug': 'education-mitigation',
        'name': 'Edukasi dan mitigasi',
        'description': 'Panduan umum',
        'sort_order': 10,
      };
      final cat = CommunityCategory.fromJson(json);
      expect(cat.id, 'cat-123');
      expect(cat.slug, 'education-mitigation');
      expect(cat.name, 'Edukasi dan mitigasi');
      expect(cat.sortOrder, 10);
    });

    test('HazardTag parsing from JSON', () {
      final json = {'id': 'tag-1', 'slug': 'earthquake', 'name': 'Gempa bumi'};
      final tag = HazardTag.fromJson(json);
      expect(tag.id, 'tag-1');
      expect(tag.slug, 'earthquake');
      expect(tag.name, 'Gempa bumi');
    });

    test('CommunityPostImage parsing and signedUrl copyWith', () {
      final json = {
        'id': 'img-1',
        'post_id': 'post-1',
        'storage_path': 'user1/post1/1.jpg',
        'alt_text': 'Foto kerusakan',
        'sort_order': 0,
      };
      final img = CommunityPostImage.fromJson(json);
      expect(img.id, 'img-1');
      expect(img.storagePath, 'user1/post1/1.jpg');
      expect(img.signedUrl, isNull);

      final withUrl = img.copyWith(signedUrl: 'https://storage/signed');
      expect(withUrl.signedUrl, 'https://storage/signed');
    });

    test('CommunityPost domain model serialization and honest cache flag', () {
      final json = {
        'id': 'post-abc',
        'author_id': 'user-123',
        'title': 'Tips Gempa Bumi',
        'body': 'Segera berlindung di bawah meja yang kokoh.',
        'category_id': 'cat-1',
        'scope': 'LOCAL',
        'region_id': 'reg-1',
        'status': 'PUBLISHED',
        'created_at': DateTime(2026, 10, 15).toIso8601String(),
        'profiles': {'display_name': 'Budi Santoso', 'avatar_path': null},
        'community_categories': {'name': 'Tips kesiapsiagaan', 'slug': 'tips'},
        'regions': {'name': 'Kota Bandung'},
        'community_post_images': [],
        'community_post_hazards': [],
      };

      final post = CommunityPost.fromJson(json, isCached: true);
      expect(post.id, 'post-abc');
      expect(post.authorName, 'Budi Santoso');
      expect(post.categoryName, 'Tips kesiapsiagaan');
      expect(post.regionName, 'Kota Bandung');
      expect(post.isLocal, isTrue);
      expect(post.isNational, isFalse);
      expect(post.isCached, isTrue);

      final postMap = post.toJson();
      expect(postMap['id'], 'post-abc');
      expect(postMap['scope'], 'LOCAL');
      expect(postMap['body'], 'Segera berlindung di bawah meja yang kokoh.');
    });
  });
}
