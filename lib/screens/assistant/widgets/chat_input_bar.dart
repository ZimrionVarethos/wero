import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Text input and send bar for the AI assistant chat screen.
class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.isGenerating,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isGenerating;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.xs,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isGenerating,
              style: AppTextStyles.body.copyWith(fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Tanyakan gempa, banjir, P3K, evakuasi...',
                hintStyle: AppTextStyles.caption,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.send_rounded,
              color: isGenerating
                  ? AppColors.textSecondary
                  : AppColors.chartBlue,
            ),
            onPressed: isGenerating ? null : onSend,
          ),
        ],
      ),
    );
  }
}
