import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Card selector for choosing post scope (Local vs National) and showing region info.
class PostScopeSelector extends StatelessWidget {
  const PostScopeSelector({
    super.key,
    required this.scope,
    required this.onScopeChanged,
    this.regionName,
  });

  final String scope;
  final ValueChanged<String> onScopeChanged;
  final String? regionName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.canvasBlue,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ChoiceChip(
                label: const Text('Lokal'),
                selected: scope == 'LOCAL',
                onSelected: (_) => onScopeChanged('LOCAL'),
              ),
              const SizedBox(width: AppSpacing.sm),
              ChoiceChip(
                label: const Text('Nasional'),
                selected: scope == 'NATIONAL',
                onSelected: (_) => onScopeChanged('NATIONAL'),
              ),
            ],
          ),
          if (scope == 'LOCAL') ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Wilayah publikasi: ${regionName ?? "Belum diatur (Silakan atur di Profil)"}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
