import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/community_providers.dart';
import '../../core/providers/supabase_providers.dart';
import '../../models/community_post.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_header.dart';
import 'widgets/report_post_dialog.dart';

/// Screen displaying the full community post with images and action buttons.
class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.post});

  final CommunityPost post;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  bool _isDeleting = false;

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Postingan?'),
        content: const Text(
          'Postingan yang dihapus tidak akan ditampilkan lagi di feed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.chartRed,
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      final success = await ref
          .read(communityServiceProvider)
          .softDeletePost(widget.post.id);
      if (success && mounted) {
        ref.read(communityFeedProvider.notifier).removePost(widget.post.id);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Postingan berhasil dihapus.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: AppColors.chartRed,
          ),
        );
      }
    }
  }

  void _openReportDialog() {
    showDialog(
      context: context,
      builder: (_) => ReportPostDialog(postId: widget.post.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isAuthor = currentUser?.id == widget.post.authorId;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeader(
        title: 'Detail Postingan',
        actions: [
          if (isAuthor)
            IconButton(
              icon: _isDeleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline, color: AppColors.chartRed),
              tooltip: 'Hapus Postingan',
              onPressed: _isDeleting ? null : _confirmDelete,
            )
          else
            IconButton(
              icon: const Icon(
                Icons.flag_outlined,
                color: AppColors.textSecondary,
              ),
              tooltip: 'Laporkan Konten',
              onPressed: _openReportDialog,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.post.isPendingReview)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: AppColors.accentOrange.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: AppColors.accentOrange,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Postingan ini sedang dalam peninjauan moderasi komunitas.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            _buildAuthorHeader(),
            const SizedBox(height: AppSpacing.md),
            if (widget.post.title != null && widget.post.title!.isNotEmpty) ...[
              Text(
                widget.post.title!,
                style: AppTextStyles.screenTitle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            _buildTags(),
            const SizedBox(height: AppSpacing.md),
            Text(
              widget.post.body,
              style: AppTextStyles.body.copyWith(fontSize: 15, height: 1.6),
            ),
            if (widget.post.images.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              _buildImagesGallery(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.softBlue,
          child: Text(
            widget.post.authorName.isNotEmpty
                ? widget.post.authorName[0].toUpperCase()
                : 'W',
            style: AppTextStyles.label.copyWith(
              color: AppColors.chartBlue,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.post.authorName, style: AppTextStyles.label),
              Text(
                '${widget.post.createdAt.day}/${widget.post.createdAt.month}/${widget.post.createdAt.year} • ${widget.post.regionName ?? "Indonesia"}',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        if (widget.post.categoryName != null)
          Chip(
            label: Text(
              widget.post.categoryName!,
              style: const TextStyle(fontSize: 11),
            ),
            backgroundColor: AppColors.canvasBlue,
            side: BorderSide.none,
          ),
        ...widget.post.hazardTags.map(
          (t) => Chip(
            label: Text('#${t.name}', style: const TextStyle(fontSize: 11)),
            backgroundColor: AppColors.softGreen,
            side: BorderSide.none,
          ),
        ),
      ],
    );
  }

  Widget _buildImagesGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.post.images.map((img) {
        if (img.signedUrl == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Image.network(
              img.signedUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, _, _) => Container(
                height: 180,
                color: AppColors.canvasBlue,
                child: const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
