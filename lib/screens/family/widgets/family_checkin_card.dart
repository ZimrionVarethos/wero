import 'package:flutter/material.dart';

import '../../../models/family_checkin.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Card displaying a family member's safety check-in status.
class FamilyCheckinCard extends StatelessWidget {
  const FamilyCheckinCard({super.key, required this.checkin, this.onShare});

  final FamilyCheckin checkin;
  final VoidCallback? onShare;

  Color get _statusColor {
    return switch (checkin.status) {
      'SAFE' => AppColors.chartGreen,
      'EVACUATING' => AppColors.chartBlue,
      'NEED_HELP' => AppColors.accentOrange,
      _ => AppColors.textSecondary,
    };
  }

  IconData get _statusIcon {
    return switch (checkin.status) {
      'SAFE' => Icons.check_circle_rounded,
      'EVACUATING' => Icons.directions_run_rounded,
      'NEED_HELP' => Icons.warning_rounded,
      _ => Icons.info_outline_rounded,
    };
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_statusIcon, color: _statusColor, size: 22),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  checkin.userName,
                  style: AppTextStyles.sectionTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text(
                  checkin.statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (checkin.note != null && checkin.note!.isNotEmpty)
            Text(
              checkin.note!,
              style: AppTextStyles.body.copyWith(fontSize: 13),
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (checkin.address != null && checkin.address!.isNotEmpty) ...[
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    checkin.address!,
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ] else
                const Spacer(),
              Text(
                _formatTimeAgo(checkin.createdAt),
                style: AppTextStyles.caption.copyWith(fontSize: 10),
              ),
            ],
          ),
          if (onShare != null) ...[
            const Divider(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share_outlined, size: 14),
                label: const Text(
                  'Bagikan Update',
                  style: TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.chartBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
