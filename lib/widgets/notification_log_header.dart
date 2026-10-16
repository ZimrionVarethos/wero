import 'package:flutter/material.dart';

import '../models/disaster_event.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Top header bar for NotificationLogSheet with icon, title, and "Hapus Semua" action.
class NotificationLogHeader extends StatelessWidget {
  const NotificationLogHeader({
    super.key,
    required this.visibleEvents,
    required this.onClearAll,
  });

  final List<DisasterEvent> visibleEvents;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.softRed,
              borderRadius: BorderRadius.circular(AppRadius.iconTile),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: AppColors.chartRed,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Log Notifikasi & Siaran',
                  style: AppTextStyles.sectionTitle,
                ),
                Text(
                  'Riwayat sinyal darurat BMKG & Web Admin',
                  style: AppTextStyles.caption.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          if (visibleEvents.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.delete_sweep_outlined, size: 16),
              label: const Text(
                'Hapus Semua',
                style: TextStyle(fontSize: 11.5),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.chartRed,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: onClearAll,
            ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            color: AppColors.textSecondary,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

/// Information hint banner indicating how to interact with notifications.
class NotificationFcmBanner extends StatelessWidget {
  const NotificationFcmBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.canvasBlue,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.chartBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_sync_rounded,
            color: AppColors.chartBlue,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Geser item ke kiri untuk menghapus atau ketuk untuk melihat detail.',
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
