import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/chat_message.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

import 'chat_markdown.dart';
import 'gemini_avatar.dart';

/// Chat bubble widget displaying either user query or assistant response.
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return _buildUserBubble();
    }
    return _buildAssistantBubble(context);
  }

  Widget _buildUserBubble() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(
          left: 48,
          right: AppSpacing.pagePadding,
          bottom: AppSpacing.sm,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppRadius.card),
            topRight: Radius.circular(AppRadius.card),
            bottomLeft: Radius.circular(AppRadius.card),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          message.text,
          style: AppTextStyles.body.copyWith(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildAssistantBubble(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.pagePadding,
        right: 48,
        bottom: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GeminiAvatar(),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(AppRadius.card),
                  bottomLeft: Radius.circular(AppRadius.card),
                  bottomRight: Radius.circular(AppRadius.card),
                ),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isOfflineFallback)
                    _buildOfflineBadge()
                  else
                    _buildGeminiBadge(),
                  ChatMarkdown(data: message.text),
                  if (message.suggestedActions.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _buildActions(context),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeminiBadge() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 13, color: AppColors.chartBlue),
          const SizedBox(width: 4),
          Text(
            'Siaga AI (Terhubung Gemini)',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.chartBlue,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBadge() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.offline_pin_outlined,
            size: 14,
            color: AppColors.chartBlue,
          ),
          const SizedBox(width: 4),
          Text(
            'Panduan Resmi BNPB (Tersimpan)',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.chartBlue,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: message.suggestedActions.map((action) {
        return InkWell(
          onTap: () => _handleAction(context, action),
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.softBlue,
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(
                color: AppColors.chartBlue.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  action.phoneNumber != null
                      ? Icons.phone_in_talk
                      : Icons.arrow_outward,
                  size: 14,
                  color: AppColors.chartBlue,
                ),
                const SizedBox(width: 4),
                Text(
                  action.label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.chartBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _handleAction(BuildContext context, ChatAction action) {
    if (action.route != null) {
      context.push(action.route!, extra: action.routeExtra);
    } else if (action.phoneNumber != null) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Panggilan Darurat'),
          content: Text('Hubungi nomor resmi ${action.phoneNumber}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Menghubungi ${action.phoneNumber}...'),
                  ),
                );
              },
              child: const Text('Panggil'),
            ),
          ],
        ),
      );
    }
  }
}
