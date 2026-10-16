import 'package:flutter/material.dart';

import '../../../models/region.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Card selector for choosing the region (daerah kejadian) where an event occurred.
class PostRegionSelector extends StatelessWidget {
  const PostRegionSelector({
    super.key,
    required this.selectedRegionId,
    required this.regions,
    required this.onRegionChanged,
  });

  final String? selectedRegionId;
  final List<Region> regions;
  final ValueChanged<String?> onRegionChanged;

  @override
  Widget build(BuildContext context) {
    final hasValidSelection =
        selectedRegionId != null &&
        regions.any((r) => r.id == selectedRegionId);
    final effectiveValue = hasValidSelection ? selectedRegionId : null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.canvasBlue,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 18,
                color: AppColors.chartBlue,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Daerah Kejadian (Lokasi Berita)',
                style: AppTextStyles.label.copyWith(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih daerah tempat kejadian agar warga sekitar mendapatkan informasi ini di feed lokal.',
            style: AppTextStyles.caption.copyWith(fontSize: 11),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: effectiveValue,
            hint: const Text('Pilih Kota / Kabupaten Kejadian'),
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            items: regions.map((r) {
              return DropdownMenuItem<String>(
                value: r.id,
                child: Text(
                  r.name,
                  style: AppTextStyles.body.copyWith(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: onRegionChanged,
          ),
        ],
      ),
    );
  }
}
