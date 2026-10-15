import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Horizontal list of quick suggested prompts for emergency disaster questions.
class SuggestedPrompts extends StatelessWidget {
  const SuggestedPrompts({
    super.key,
    required this.onSelectPrompt,
    this.disabled = false,
  });

  final ValueChanged<String> onSelectPrompt;
  final bool disabled;

  static const List<String> prompts = [
    'Apa yang harus dilakukan saat gempa?',
    'Isi tas siaga bencana (Go-Bag)?',
    'Pertolongan pertama luka bakar & darah',
    'Bagaimana evakuasi saat banjir?',
    'Nomor darurat penting (SAR, Damkar)?',
    'Tanda-tanda peringatan tsunami pesisir',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
        scrollDirection: Axis.horizontal,
        itemCount: prompts.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final prompt = prompts[index];
          return ActionChip(
            label: Text(
              prompt,
              style: AppTextStyles.caption.copyWith(
                color: disabled
                    ? AppColors.textSecondary.withValues(alpha: 0.5)
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            backgroundColor: AppColors.surface,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            onPressed: disabled ? null : () => onSelectPrompt(prompt),
          );
        },
      ),
    );
  }
}
