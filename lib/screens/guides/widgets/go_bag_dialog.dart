import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/guide_providers.dart';
import '../../../services/offline_guide_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Modal dialog displaying interactive Disaster Go-Bag (Tas Siaga Bencana) checklist.
class GoBagDialog extends ConsumerWidget {
  const GoBagDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      builder: (ctx) => const GoBagDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkedItemsAsync = ref.watch(goBagChecklistProvider);
    final items = OfflineGuideService.defaultGoBagItems;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
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
                  const Icon(
                    Icons.backpack_rounded,
                    color: AppColors.accentOrange,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Checklist Tas Siaga Bencana',
                      style: AppTextStyles.sectionTitle,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(goBagChecklistProvider.notifier).resetAll(),
                    child: const Text('Reset', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              Text(
                'Simpan barang kebutuhan dasar keluarga untuk bertahan hidup minimal 72 jam saat darurat.',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: AppSpacing.sm),
              checkedItemsAsync.when(
                data: (checked) {
                  final progress = checked.length / items.length;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.canvasBlue,
                        color: progress == 1.0
                            ? AppColors.chartGreen
                            : AppColors.accentOrange,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kesiapan: ${checked.length} dari ${items.length} perlengkapan siap',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: checkedItemsAsync.when(
                  data: (checked) {
                    return ListView.separated(
                      controller: scrollController,
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.xs),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isChecked = checked.contains(item);
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            item,
                            style: AppTextStyles.body.copyWith(
                              fontSize: 13,
                              decoration: isChecked
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isChecked
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          value: isChecked,
                          activeColor: AppColors.chartGreen,
                          onChanged: (_) => ref
                              .read(goBagChecklistProvider.notifier)
                              .toggleItem(item),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
