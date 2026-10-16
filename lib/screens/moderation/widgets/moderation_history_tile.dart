import 'package:flutter/material.dart';

import '../../../models/moderation_action.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Card component presenting a historical moderation decision.
class ModerationHistoryTile extends StatelessWidget {
  const ModerationHistoryTile({super.key, required this.action});

  final ModerationAction action;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(action.actionIcon, size: 16, color: action.actionColor),
              const SizedBox(width: 6),
              Text(
                action.actionLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: action.actionColor,
                ),
              ),
              const Spacer(),
              Text(
                '${action.createdAt.day}/${action.createdAt.month} ${action.createdAt.hour.toString().padLeft(2, '0')}:${action.createdAt.minute.toString().padLeft(2, '0')}',
                style: AppTextStyles.caption.copyWith(fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (action.postTitle != null && action.postTitle!.isNotEmpty)
            Text(
              'Target: ${action.postTitle}',
              style: AppTextStyles.sectionTitle.copyWith(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 2),
          Text(
            'Catatan: "${action.reason}"',
            style: AppTextStyles.caption.copyWith(
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
          ),
          if (action.moderatorName != null) ...[
            const SizedBox(height: 4),
            Text(
              'Oleh: ${action.moderatorName}',
              style: AppTextStyles.caption.copyWith(fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}
