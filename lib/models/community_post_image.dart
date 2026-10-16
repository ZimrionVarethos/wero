/// Model for images attached to a community post.
final class CommunityPostImage {
  const CommunityPostImage({
    required this.id,
    required this.postId,
    required this.storagePath,
    this.altText,
    this.sortOrder = 0,
    this.signedUrl,
  });

  final String id;
  final String postId;
  final String storagePath;
  final String? altText;
  final int sortOrder;
  final String? signedUrl;

  CommunityPostImage copyWith({String? signedUrl}) {
    return CommunityPostImage(
      id: id,
      postId: postId,
      storagePath: storagePath,
      altText: altText,
      sortOrder: sortOrder,
      signedUrl: signedUrl ?? this.signedUrl,
    );
  }

  factory CommunityPostImage.fromJson(Map<String, dynamic> json) {
    return CommunityPostImage(
      id: json['id'] as String,
      postId: json['post_id'] as String? ?? '',
      storagePath: json['storage_path'] as String,
      altText: json['alt_text'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      signedUrl: json['signed_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'post_id': postId,
    'storage_path': storagePath,
    'alt_text': altText,
    'sort_order': sortOrder,
    'signed_url': signedUrl,
  };
}
