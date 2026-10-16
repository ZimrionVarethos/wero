import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/emergency_broadcast_provider.dart';
import '../core/providers/operations_providers.dart';
import '../models/disaster_event.dart';
import '../services/notification_dismiss_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'notification_log_header.dart';
import 'notification_log_item.dart';

/// Modal bottom sheet displaying recent emergency broadcasts and notification history.
class NotificationLogSheet extends ConsumerStatefulWidget {
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
  ConsumerState<NotificationLogSheet> createState() =>
      _NotificationLogSheetState();
}

class _NotificationLogSheetState extends ConsumerState<NotificationLogSheet> {
  final _dismissService = const NotificationDismissService();
  Set<String> _dismissedIds = {};
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadDismissed();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(disasterEventsProvider);
    });
  }

  Future<void> _loadDismissed() async {
    final ids = await _dismissService.getDismissedIds();
    if (mounted) {
      setState(() {
        _dismissedIds = ids;
        _isLoaded = true;
      });
    }
  }

  void _dismissEvent(DisasterEvent event) {
    setState(() => _dismissedIds = {..._dismissedIds, event.id});
    _dismissService.dismiss(event.id);
    // Also silence siren if this dismissed event was the active siren
    ref.read(activeBroadcastAlertProvider.notifier).dismissById(event.id);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notifikasi "${event.headline}" dihapus'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Urungkan',
          textColor: AppColors.accentOrange,
          onPressed: () {
            setState(() {
              _dismissedIds = _dismissedIds
                  .where((id) => id != event.id)
                  .toSet();
            });
            _dismissService.restore(event.id);
          },
        ),
      ),
    );
  }

  void _confirmClearAll(List<DisasterEvent> visible) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua Notifikasi?'),
        content: Text(
          'Sebanyak ${visible.length} log notifikasi akan dihapus dari daftar Anda.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final allIds = visible.map((e) => e.id);
              setState(() => _dismissedIds = {..._dismissedIds, ...allIds});
              _dismissService.dismissAll(allIds);
              ref.read(activeBroadcastAlertProvider.notifier).dismiss();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.chartRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }

  List<DisasterEvent> _filterUniqueVisible(List<DisasterEvent> events) {
    final uniqueMap = <String, DisasterEvent>{};
    for (final e in events) {
      uniqueMap.putIfAbsent(e.id, () => e);
    }
    return uniqueMap.values
        .where((e) => !_dismissedIds.contains(e.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
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
            eventsAsync.maybeWhen(
              data: (events) {
                final visible = _filterUniqueVisible(events);
                return NotificationLogHeader(
                  visibleEvents: visible,
                  onClearAll: () => _confirmClearAll(visible),
                );
              },
              orElse: () => NotificationLogHeader(
                visibleEvents: const [],
                onClearAll: () {},
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
            const NotificationFcmBanner(),
            Expanded(
              child: !_isLoaded
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.chartBlue,
                      ),
                    )
                  : eventsAsync.when(
                      data: (events) {
                        final visible = _filterUniqueVisible(events);
                        return visible.isEmpty
                            ? _buildEmptyState()
                            : _buildEventsList(visible, scrollController);
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.chartBlue,
                        ),
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

  Widget _buildEventsList(
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
        return NotificationLogItem(
          event: event,
          onDismissed: () => _dismissEvent(event),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Belum Ada Notifikasi Aktif',
              style: AppTextStyles.sectionTitle.copyWith(fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Semua riwayat notifikasi kosong atau telah dibersihkan.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}
