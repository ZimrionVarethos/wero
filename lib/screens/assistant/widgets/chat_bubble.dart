import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/chat_message.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/phone_launcher.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

import 'chat_markdown.dart';

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
        right: 28,
        bottom: AppSpacing.md,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: AppColors.borderNeutral.withValues(alpha: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryNavy.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo AI dan info status menyatu di pojok kiri atas kotak chat
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/images/icon.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs + 2),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'Asisten Siaga AI',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primaryNavy,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      if (message.isOfflineFallback)
                        _buildOfflineBadge()
                      else
                        _buildGeminiBadge(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ChatMarkdown(data: message.text),
            if (message.suggestedActions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _buildActions(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGeminiBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Online',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.chartBlue,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildOfflineBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.softGreen,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'BNPB Offline',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.siaga,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
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
                PhoneLauncher.launchPhone(
                  context,
                  action.phoneNumber!,
                  label: 'Layanan Darurat',
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
