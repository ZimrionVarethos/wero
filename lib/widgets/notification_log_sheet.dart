import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/operations_providers.dart';
import '../models/disaster_event.dart';
import '../routing/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Modal bottom sheet displaying recent emergency broadcasts and notification history.
class NotificationLogSheet extends ConsumerWidget {
  const NotificationLogSheet({super.key});

  /// Open the notification log bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      builder: (_) => const NotificationLogSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(disasterEventsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            _buildDragHandle(),
            _buildHeader(context),
            const Divider(color: AppColors.border, height: 1),
            _buildFcmBanner(),
            Expanded(
              child: eventsAsync.when(
                data: (events) => events.isEmpty
                    ? _buildEmptyState()
                    : _buildEventsList(context, events, scrollController),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.chartBlue),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Gagal memuat log notifikasi: $e',
                    style: AppTextStyles.caption,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: AppSpacing.xs,
        ),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.textSecondary.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            color: AppColors.textSecondary,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFcmBanner() {
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
              'Pipeline FCM: Siaran otomatis tersinkron ke log ini saat app dibuka.',
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

  Widget _buildEventsList(
    BuildContext context,
    List<DisasterEvent> events,
    ScrollController scrollController,
  ) {
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      itemCount: events.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final event = events[index];
        final (badgeColor, badgeText) = _resolveSeverity(event.severity);
        final targetLabel = event.targetType == 'ALL'
            ? '🌐 Nasional'
            : (event.targetRegions.isNotEmpty
                  ? '📍 ${event.targetRegions.join(", ")}'
                  : '📍 Daerah Terpilih');

        return InkWell(
          onTap: () => _showDetailDialog(
            context,
            event,
            badgeColor,
            badgeText,
            targetLabel,
          ),
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
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sumber: ${event.source} • Ketuk untuk info',
                  style: AppTextStyles.caption.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDetailDialog(
    BuildContext context,
    DisasterEvent event,
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Belum Ada Notifikasi Siaran',
              style: AppTextStyles.sectionTitle.copyWith(fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Semua sinyal darurat BMKG dan BPBD yang dikirimkan akan tercatat di log ini.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}
