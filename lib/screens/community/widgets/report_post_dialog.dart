import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/community_providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Modal dialog for reporting a community post.
class ReportPostDialog extends ConsumerStatefulWidget {
  const ReportPostDialog({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<ReportPostDialog> createState() => _ReportPostDialogState();
}

class _ReportPostDialogState extends ConsumerState<ReportPostDialog> {
  static const _reasons = [
    ('MISLEADING_DANGEROUS', 'Informasi berbahaya atau menyesatkan'),
    ('SPAM', 'Spam atau promosi tidak relevan'),
    ('HARASSMENT', 'Pelecehan atau ujaran kebencian'),
    ('PRIVACY', 'Pelanggaran data pribadi/privasi'),
    ('IRRELEVANT', 'Tidak relevan dengan kesiapsiagaan'),
    ('OTHER', 'Lainnya'),
  ];

  String _selectedReason = 'MISLEADING_DANGEROUS';
  final _detailsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(communityServiceProvider)
          .reportPost(
            postId: widget.postId,
            reasonCode: _selectedReason,
            details: _detailsController.text.trim().isEmpty
                ? null
                : _detailsController.text.trim(),
          );
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan Anda berhasil dikirim untuk peninjauan.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim laporan: $e'),
            backgroundColor: AppColors.chartRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      title: Text('Laporkan Postingan', style: AppTextStyles.sectionTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pilih alasan pelanggaran konten:',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.sm),
            ..._reasons.map((r) {
              final isSelected = _selectedReason == r.$1;
              return InkWell(
                borderRadius: BorderRadius.circular(AppRadius.chip),
                onTap: () => setState(() => _selectedReason = r.$1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 4,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected
                            ? AppColors.accentOrange
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          r.$2,
                          style: AppTextStyles.body.copyWith(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _detailsController,
              maxLength: 1000,
              maxLines: 3,
              style: AppTextStyles.body.copyWith(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Keterangan tambahan (opsional)...',
                hintStyle: AppTextStyles.caption,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Batal',
            style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.chartRed,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Kirim Laporan',
                  style: TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
}
