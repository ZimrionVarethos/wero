import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/operations_providers.dart';
import '../../../models/sos_event.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Card showing status and actions for an ongoing emergency SOS event.
class SosActiveCard extends ConsumerWidget {
  const SosActiveCard({super.key, required this.event});

  final SosEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.softRed,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.chartRed, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.chartRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STATUS: SOS DARURAT AKTIF',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.chartRed,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Mode: ${event.mode == "PUBLIC" ? "Publik (Radius Sekitar)" : "Privat (Kontak Tepercaya)"}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (event.note != null && event.note!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.white70,
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: Text(
                'Catatan: "${event.note!}"',
                style: AppTextStyles.body.copyWith(fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => ref
                      .read(activeSosProvider.notifier)
                      .resolveSos('Tertolong'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 16,
                  ),
                  label: const Text(
                    'Sudah Aman',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton(
                onPressed: () => ref
                    .read(activeSosProvider.notifier)
                    .cancelSos('Batal oleh pengguna'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.chartRed),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                child: Text(
                  'Batalkan',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.chartRed,
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
