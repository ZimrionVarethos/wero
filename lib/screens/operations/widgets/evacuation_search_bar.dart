import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Top search bar widget for filtering evacuation shelters and assembly points.
class EvacuationSearchBar extends StatelessWidget {
  const EvacuationSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: 8,
      ),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.canvasBlue,
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        child: TextField(
          controller: controller,
          style: AppTextStyles.body.copyWith(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Cari nama posko atau jalan...',
            hintStyle: AppTextStyles.caption,
            prefixIcon: const Icon(
              Icons.search,
              size: 19,
              color: AppColors.textSecondary,
            ),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 16),
                    onPressed: onClear,
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 9),
          ),
          onChanged: onChanged,
          onSubmitted: onChanged,
        ),
      ),
    );
  }
}
