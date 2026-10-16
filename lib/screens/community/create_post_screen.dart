import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/providers/auth_providers.dart';
import '../../core/providers/community_providers.dart';
import '../../models/community_category.dart';
import '../../models/hazard_tag.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_header.dart';
import 'widgets/image_picker_row.dart';
import 'widgets/post_region_selector.dart';

/// Screen for creating and publishing a community post with specific incident region.
class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _picker = ImagePicker();

  String? _selectedRegionId;
  String? _selectedCategoryId;
  final List<String> _selectedHazardIds = [];
  final List<XFile> _images = [];
  bool _isPublishing = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_images.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maksimal 4 gambar per postingan.')),
      );
      return;
    }
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1280,
    );
    if (picked != null) {
      setState(() => _images.add(picked));
    }
  }

  Future<void> _publish() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi dan kategori wajib diisi.')),
      );
      return;
    }

    if (_selectedRegionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih daerah kejadian informasi.'),
        ),
      );
      return;
    }

    setState(() => _isPublishing = true);
    try {
      await ref
          .read(communityServiceProvider)
          .createPost(
            body: body,
            title: _titleController.text.trim().isEmpty
                ? null
                : _titleController.text.trim(),
            categoryId: _selectedCategoryId!,
            regionId: _selectedRegionId!,
            scope: 'LOCAL',
            images: _images,
            hazardTagIds: _selectedHazardIds,
          );
      await ref.read(communityFeedProvider.notifier).refresh();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Postingan berhasil diterbitkan.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPublishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: AppColors.chartRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        ref.watch(communityCategoriesProvider).asData?.value ?? [];
    final hazardTags = ref.watch(hazardTagsProvider).asData?.value ?? [];
    final profile = ref.watch(userProfileProvider).asData?.value;
    final regions = ref.watch(regionsListProvider).asData?.value ?? [];

    _selectedRegionId ??= profile?.regionId;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeader(
        title: 'Buat Postingan',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton(
              onPressed: _isPublishing ? null : _publish,
              child: _isPublishing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Terbitkan',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.chartBlue,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PostRegionSelector(
              selectedRegionId: _selectedRegionId,
              regions: regions,
              onRegionChanged: (r) => setState(() => _selectedRegionId = r),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildCategorySelector(categories),
            const SizedBox(height: AppSpacing.md),
            _buildHazardTags(hazardTags),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _titleController,
              maxLength: 120,
              decoration: const InputDecoration(
                hintText: 'Judul topik (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _bodyController,
              maxLength: 5000,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText:
                    'Tuliskan informasi, panduan, atau tips kesiapsiagaan...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ImagePickerRow(
              images: _images,
              onPickImage: _pickImage,
              onRemoveImage: (i) => setState(() => _images.removeAt(i)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(List<CommunityCategory> categories) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategoryId,
      hint: const Text('Pilih Kategori (Wajib)'),
      items: categories
          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
          .toList(),
      onChanged: (val) => setState(() => _selectedCategoryId = val),
      decoration: const InputDecoration(border: OutlineInputBorder()),
    );
  }

  Widget _buildHazardTags(List<HazardTag> tags) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: tags.map((t) {
        final isSelected = _selectedHazardIds.contains(t.id);
        return FilterChip(
          label: Text(t.name, style: const TextStyle(fontSize: 11)),
          selected: isSelected,
          onSelected: (val) {
            setState(() {
              if (val) {
                _selectedHazardIds.add(t.id);
              } else {
                _selectedHazardIds.remove(t.id);
              }
            });
          },
        );
      }).toList(),
    );
  }
}
