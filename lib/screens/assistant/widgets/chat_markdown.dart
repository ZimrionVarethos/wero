import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Renders formatted assistant response text with full Markdown support.
class ChatMarkdown extends StatelessWidget {
  const ChatMarkdown({super.key, required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: data,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: AppTextStyles.body.copyWith(
          fontSize: 13.5,
          height: 1.5,
          color: AppColors.textPrimary,
        ),
        pPadding: const EdgeInsets.only(bottom: 6),
        strong: AppTextStyles.body.copyWith(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        em: AppTextStyles.body.copyWith(
          fontSize: 13.5,
          fontStyle: FontStyle.italic,
          color: AppColors.textPrimary,
        ),
        h1: AppTextStyles.sectionTitle.copyWith(fontSize: 16, height: 1.4),
        h1Padding: const EdgeInsets.symmetric(vertical: 4),
        h2: AppTextStyles.sectionTitle.copyWith(fontSize: 15, height: 1.4),
        h2Padding: const EdgeInsets.symmetric(vertical: 4),
        h3: AppTextStyles.sectionTitle.copyWith(fontSize: 14, height: 1.4),
        h3Padding: const EdgeInsets.symmetric(vertical: 3),
        listBullet: AppTextStyles.body.copyWith(
          fontSize: 13.5,
          color: AppColors.chartBlue,
          fontWeight: FontWeight.bold,
        ),
        listBulletPadding: const EdgeInsets.only(right: 6),
        listIndent: 20,
        code: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          backgroundColor: AppColors.canvasBlue,
          color: AppColors.textPrimary,
        ),
        codeblockDecoration: BoxDecoration(
          color: AppColors.canvasBlue,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(color: AppColors.border),
        ),
        codeblockPadding: const EdgeInsets.all(8),
        blockquote: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: const BoxDecoration(
          color: AppColors.canvasBlue,
          border: Border(
            left: BorderSide(color: AppColors.chartBlue, width: 3),
          ),
        ),
        blockquotePadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 4,
        ),
      ),
    );
  }
}
