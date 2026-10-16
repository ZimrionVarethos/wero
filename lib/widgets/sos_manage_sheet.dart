import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/operations_providers.dart';
import '../models/sos_event.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Modal bottom sheet for managing an active emergency SOS.
class SosManageSheet extends ConsumerStatefulWidget {
  const SosManageSheet({super.key, required this.event});

  final SosEvent event;

  static Future<void> show(BuildContext context, SosEvent event) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SosManageSheet(event: event),
    );
  }

  @override
  ConsumerState<SosManageSheet> createState() => _SosManageSheetState();
}

class _SosManageSheetState extends ConsumerState<SosManageSheet> {
  bool _isBusy = false;

  Future<void> _handleResolve() async {
    setState(() => _isBusy = true);
    try {
      await ref.read(activeSosProvider.notifier).resolveSos('Tertolong');
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status SOS diselesaikan. Semoga Anda selalu aman.'),
            backgroundColor: AppColors.aman,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBusy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyelesaikan SOS: $e'),
            backgroundColor: AppColors.awas,
          ),
        );
      }
    }
  }

  Future<void> _handleCancel() async {
    setState(() => _isBusy = true);
    try {
      await ref
          .read(activeSosProvider.notifier)
          .cancelSos('Batal oleh pengguna');
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Panggilan SOS telah dibatalkan.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBusy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membatalkan SOS: $e'),
            backgroundColor: AppColors.awas,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final modeLabel = widget.event.mode == 'PUBLIC'
        ? 'Publik (Radius Sekitar)'
        : 'Kerabat Siaga';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.md,
        AppSpacing.pagePadding,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.awas,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.priority_high_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STATUS: SOS DARURAT AKTIF',
                      style: AppTextStyles.cardTitle.copyWith(
                        color: AppColors.awas,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mode: $modeLabel',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.awas.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: AppColors.awas.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              'Sinyal darurat Anda sedang disiarkan ke relawan dan posko kendali terdekat. Jika situasi sudah aman atau panggilan tidak sengaja, pilih tindakan di bawah.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
          if (widget.event.note != null && widget.event.note!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Catatan: "${widget.event.note}"',
              style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (_isBusy)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: CircularProgressIndicator(color: AppColors.awas),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _handleResolve,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                    icon: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Sudah Aman',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _handleCancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.awas, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                    child: Text(
                      'Batalkan',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.awas,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
