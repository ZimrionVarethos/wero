import 'community_post_image.dart';
import 'hazard_tag.dart';

/// Community post domain model for Wero.
final class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    this.title,
    required this.body,
    required this.categoryId,
    this.categoryName,
    required this.scope,
    this.regionId,
    this.regionName,
    required this.status,
    required this.createdAt,
    this.publishedAt,
    this.images = const [],
    this.hazardTags = const [],
    this.isCached = false,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String? title;
  final String body;
  final String categoryId;
  final String? categoryName;
  final String scope; // 'LOCAL' | 'NATIONAL'
  final String? regionId;
  final String? regionName;
  final String
  status; // 'PUBLISHED' | 'HIDDEN_PENDING_REVIEW' | 'REMOVED' | 'DELETED'
  final DateTime createdAt;
  final DateTime? publishedAt;
  final List<CommunityPostImage> images;
  final List<HazardTag> hazardTags;
  final bool isCached;

  bool get isLocal => scope == 'LOCAL';
  bool get isNational => scope == 'NATIONAL';
  bool get isPendingReview => status == 'HIDDEN_PENDING_REVIEW';
  bool get isRemoved => status == 'REMOVED';
  bool get isPublished => status == 'PUBLISHED';

  CommunityPost copyWith({
    String? title,
    String? body,
    String? status,
    List<CommunityPostImage>? images,
    bool? isCached,
  }) {
    return CommunityPost(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      title: title ?? this.title,
      body: body ?? this.body,
      categoryId: categoryId,
      categoryName: categoryName,
      scope: scope,
      regionId: regionId,
      regionName: regionName,
      status: status ?? this.status,
      createdAt: createdAt,
      publishedAt: publishedAt,
      images: images ?? this.images,
      hazardTags: hazardTags,
      isCached: isCached ?? this.isCached,
    );
  }

  factory CommunityPost.fromJson(
    Map<String, dynamic> json, {
    bool isCached = false,
  }) {
    String author = 'Warga';
    String? avatar;
    if (json['profiles'] is Map<String, dynamic>) {
      author = (json['profiles']['display_name'] as String?) ?? 'Warga';
      avatar = json['profiles']['avatar_path'] as String?;
    } else if (json['author_name'] is String) {
      author = json['author_name'] as String;
      avatar = json['author_avatar_url'] as String?;
    }

    String? catName;
    if (json['community_categories'] is Map<String, dynamic>) {
      catName = json['community_categories']['name'] as String?;
    } else if (json['category_name'] is String) {
      catName = json['category_name'] as String;
    }

    String? regName;
    if (json['regions'] is Map<String, dynamic>) {
      regName = json['regions']['name'] as String?;
    } else if (json['region_name'] is String) {
      regName = json['region_name'] as String;
    }

    final imageList = <CommunityPostImage>[];
    if (json['community_post_images'] is List) {
      for (final img in json['community_post_images']) {
        if (img is Map<String, dynamic>) {
          imageList.add(CommunityPostImage.fromJson(img));
        }
      }
      imageList.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    } else if (json['images'] is List) {
      for (final img in json['images']) {
        if (img is Map<String, dynamic>) {
          imageList.add(CommunityPostImage.fromJson(img));
        }
      }
    }

    final tagList = <HazardTag>[];
    if (json['community_post_hazards'] is List) {
      for (final h in json['community_post_hazards']) {
        if (h is Map<String, dynamic> &&
            h['hazard_tags'] is Map<String, dynamic>) {
          tagList.add(
            HazardTag.fromJson(h['hazard_tags'] as Map<String, dynamic>),
          );
        }
      }
    } else if (json['hazard_tags'] is List) {
      for (final t in json['hazard_tags']) {
        if (t is Map<String, dynamic>) {
          tagList.add(HazardTag.fromJson(t));
        }
      }
    }

    return CommunityPost(
      id: json['id'] as String,
      authorId: (json['author_id'] as String?) ?? '',
      authorName: author,
      authorAvatarUrl: avatar,
      title: json['title'] as String?,
      body: (json['body'] as String?) ?? '',
      categoryId: (json['category_id'] as String?) ?? '',
      categoryName: catName,
      scope: (json['scope'] as String?) ?? 'LOCAL',
      regionId: json['region_id'] as String?,
      regionName: regName,
      status: (json['status'] as String?) ?? 'PUBLISHED',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'] as String)
          : null,
      images: imageList,
      hazardTags: tagList,
      isCached: isCached,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'author_id': authorId,
    'author_name': authorName,
    'author_avatar_url': authorAvatarUrl,
    'title': title,
    'body': body,
    'category_id': categoryId,
    'category_name': categoryName,
    'scope': scope,
    'region_id': regionId,
    'region_name': regionName,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'published_at': publishedAt?.toIso8601String(),
    'images': images.map((i) => i.toJson()).toList(),
    'hazard_tags': hazardTags.map((t) => t.toJson()).toList(),
  };
}
