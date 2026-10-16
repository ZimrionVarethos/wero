import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/community_post.dart';
import '../models/community_post_image.dart';

/// Helper service managing community image uploads and signed URL resolution.
class CommunityStorageService {
  const CommunityStorageService(this._client);

  final SupabaseClient? _client;
  static const String bucketName = 'community-images';

  /// Upload an image to the private storage bucket and insert post image record.
  Future<void> uploadImage({
    required String userId,
    required String postId,
    required XFile file,
    required int sortOrder,
  }) async {
    final client = _client;
    if (client == null) return;
    final bytes = await file.readAsBytes();
    final ext = file.name.contains('.') ? file.name.split('.').last : 'jpg';
    final path =
        '$userId/$postId/${DateTime.now().millisecondsSinceEpoch}_$sortOrder.$ext';

    await client.storage
        .from(bucketName)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: 'image/$ext'),
        );

    await client.from('community_post_images').insert({
      'post_id': postId,
      'storage_path': path,
      'sort_order': sortOrder,
    });
  }

  /// Resolve signed URLs for private post images.
  Future<CommunityPost> resolveSignedImages(CommunityPost post) async {
    final client = _client;
    if (client == null || post.images.isEmpty) return post;

    final resolvedImages = <CommunityPostImage>[];
    for (final img in post.images) {
      if (img.storagePath.startsWith('http://') ||
          img.storagePath.startsWith('https://')) {
        resolvedImages.add(img.copyWith(signedUrl: img.storagePath));
        continue;
      }
      try {
        final signed = await client.storage
            .from(bucketName)
            .createSignedUrl(img.storagePath, 3600);
        resolvedImages.add(img.copyWith(signedUrl: signed));
      } catch (_) {
        resolvedImages.add(img);
      }
    }
    return post.copyWith(images: resolvedImages);
  }
}
