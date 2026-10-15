import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/community_providers.dart';
import '../../core/providers/moderation_providers.dart';
import '../../models/community_report.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/moderation_action_dialog.dart';
import 'widgets/moderation_history_tile.dart';
import 'widgets/reported_post_card.dart';

/// Screen presenting community moderation queue and audit history.
class ModerationScreen extends ConsumerStatefulWidget {
  const ModerationScreen({super.key});

  @override
  ConsumerState<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends ConsumerState<ModerationScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Set<String> _processingReportIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleDecision(CommunityReport report, bool isApprove) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => ModerationActionDialog(
        isApprove: isApprove,
        postTitle: report.postTitle ?? 'Postingan Tanpa Judul',
      ),
    );
    if (reason == null || reason.trim().isEmpty) return;

    setState(() => _processingReportIds.add(report.id));
    try {
      final service = ref.read(moderationServiceProvider);
      if (isApprove) {
        await service.approveAndRestorePost(
          postId: report.postId,
          reportId: report.id,
          reason: reason,
        );
      } else {
        await service.takedownPost(
          postId: report.postId,
          reportId: report.id,
          reason: reason,
        );
      }

      ref.invalidate(pendingReportsProvider);
      ref.invalidate(moderationHistoryProvider);
      ref.invalidate(communityFeedProvider);

      if (mounted) {
        final msg = isApprove
            ? 'Postingan berhasil dipulihkan.'
            : 'Postingan berhasil dihapus/takedown.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: isApprove
                ? AppColors.chartGreen
                : AppColors.chartRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses: $e'),
            backgroundColor: AppColors.chartRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingReportIds.remove(report.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(pendingReportsProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasBlue,
      appBar: AppBar(
        title: Text(
          'Moderasi Komunitas',
          style: AppTextStyles.screenTitle.copyWith(fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.textPrimary,
          indicatorColor: AppColors.chartBlue,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Antrean Laporan'),
                  const SizedBox(width: 6),
                  pendingAsync.maybeWhen(
                    data: (reports) => reports.isNotEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.chartRed,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${reports.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const Tab(text: 'Riwayat Audit'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildQueueTab(pendingAsync), _buildHistoryTab()],
      ),
    );
  }

  Widget _buildQueueTab(AsyncValue<List<CommunityReport>> pendingAsync) {
    return pendingAsync.when(
      data: (reports) {
        if (reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 56,
                  color: AppColors.chartGreen,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Semua Laporan Selesai Ditinjau',
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: 4),
                Text(
                  'Tidak ada laporan pelanggaran komunitas saat ini.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(pendingReportsProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            itemCount: reports.length,
            itemBuilder: (context, i) {
              final rep = reports[i];
              return ReportedPostCard(
                report: rep,
                isProcessing: _processingReportIds.contains(rep.id),
                onApprove: () => _handleDecision(rep, true),
                onTakedown: () => _handleDecision(rep, false),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Gagal memuat antrean laporan: $e'),
            ElevatedButton(
              onPressed: () => ref.refresh(pendingReportsProvider),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    final historyAsync = ref.watch(moderationHistoryProvider);

    return historyAsync.when(
      data: (actions) {
        if (actions.isEmpty) {
          return Center(
            child: Text(
              'Belum ada riwayat tindakan moderasi.',
              style: AppTextStyles.caption,
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(moderationHistoryProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            itemCount: actions.length,
            itemBuilder: (context, i) =>
                ModerationHistoryTile(action: actions[i]),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Gagal memuat riwayat: $e', style: AppTextStyles.caption),
      ),
    );
  }
}
