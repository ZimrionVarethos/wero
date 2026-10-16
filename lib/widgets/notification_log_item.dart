import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/disaster_event.dart';
import '../routing/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Dismissible notification card supporting swipe-to-delete ("geser perbalok") and tap for detail.
class NotificationLogItem extends StatelessWidget {
  const NotificationLogItem({
    super.key,
    required this.event,
    required this.onDismissed,
  });

  final DisasterEvent event;
  final VoidCallback onDismissed;

  (Color, String) _resolveSeverity(String severity) {
    return switch (severity.toUpperCase()) {
      'AWAS' => (AppColors.awas, 'AWAS'),
      'SIAGA' => (AppColors.siaga, 'SIAGA'),
      'WASPADA' => (AppColors.waspada, 'WASPADA'),
      'AMAN' => (AppColors.aman, 'AMAN'),
      _ => (AppColors.info, 'INFO'),
    };
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m WIB';
  }

  void _showDetailDialog(
    BuildContext context,
    Color badgeColor,
    String badgeText,
    String targetLabel,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  color: badgeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                targetLabel,
                style: AppTextStyles.caption.copyWith(fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.headline, style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Jenis: ${event.disasterType}',
              style: AppTextStyles.bodySecondary,
            ),
            Text('Sumber: ${event.source}', style: AppTextStyles.bodySecondary),
            Text(
              'Waktu: ${_formatTime(event.occurredAt)}',
              style: AppTextStyles.bodySecondary,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              context.push(AppRoutes.evacuation);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.chartBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Buka Peta Evakuasi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (badgeColor, badgeText) = _resolveSeverity(event.severity);
    final targetLabel = event.targetType == 'ALL'
        ? '🌐 Nasional'
        : (event.targetRegions.isNotEmpty
              ? '📍 ${event.targetRegions.join(", ")}'
              : '📍 Daerah Terpilih');

    return Dismissible(
      key: ValueKey('notif-${event.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.chartRed,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 22),
            SizedBox(width: 6),
            Text(
              'Hapus',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      child: InkWell(
        onTap: () =>
            _showDetailDialog(context, badgeColor, badgeText, targetLabel),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.canvasBlue,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: event.isAwas
                  ? AppColors.chartRed.withValues(alpha: 0.4)
                  : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      border: Border.all(color: badgeColor, width: 0.8),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      targetLabel,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 10,
                        color: AppColors.chartBlue,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _formatTime(event.occurredAt),
                    style: AppTextStyles.caption.copyWith(fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                event.headline,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                'Sumber: ${event.source} • Geser ke kiri untuk hapus',
                style: AppTextStyles.caption.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
