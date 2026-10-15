import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Reusable horizontal image picker row for community posts.
class ImagePickerRow extends StatelessWidget {
  const ImagePickerRow({
    super.key,
    required this.images,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  final List<XFile> images;
  final VoidCallback onPickImage;
  final ValueChanged<int> onRemoveImage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Foto (${images.length}/4)', style: AppTextStyles.label),
            if (images.length < 4)
              TextButton.icon(
                onPressed: onPickImage,
                icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                label: const Text('Tambah'),
              ),
          ],
        ),
        if (images.isNotEmpty)
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final file = images[index];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.iconTile),
                      child: kIsWeb
                          ? Image.network(
                              file.path,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(file.path),
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () => onRemoveImage(index),
                        child: const CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.black54,
                          child: Icon(
                            Icons.close,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}
