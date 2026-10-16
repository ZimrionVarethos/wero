import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Modal dialog for confirming a moderation decision (Approve vs Takedown).
class ModerationActionDialog extends StatefulWidget {
  const ModerationActionDialog({
    super.key,
    required this.isApprove,
    required this.postTitle,
  });

  final bool isApprove;
  final String postTitle;

  @override
  State<ModerationActionDialog> createState() => _ModerationActionDialogState();
}

class _ModerationActionDialogState extends State<ModerationActionDialog> {
  final _reasonController = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _reasonController.addListener(() {
      final valid = _reasonController.text.trim().isNotEmpty;
      if (valid != _isValid) {
        setState(() => _isValid = valid);
      }
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isApprove
        ? 'Pulihkan Postingan'
        : 'Takedown / Hapus Postingan';
    final actionColor = widget.isApprove
        ? AppColors.chartGreen
        : AppColors.chartRed;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      title: Row(
        children: [
          Icon(
            widget.isApprove
                ? Icons.check_circle_outline_rounded
                : Icons.block_rounded,
            color: actionColor,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Target: "${widget.postTitle}"',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              widget.isApprove
                  ? 'Postingan akan dipulihkan ke feed publik dan laporan ditandai selesai.'
                  : 'Postingan akan dihapus dari publik dan disembunyikan permanen.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.base),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: widget.isApprove
                    ? 'Catatan keputusan (misal: "Informasi telah diverifikasi benar")...'
                    : 'Alasan penindakan (misal: "Terbukti menyebarkan hoaks meresahkan")...',
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
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(
            'Batal',
            style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _isValid
              ? () => Navigator.of(context).pop(_reasonController.text.trim())
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: actionColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
          child: Text(widget.isApprove ? 'Pulihkan' : 'Hapus Konten'),
        ),
      ],
    );
  }
}
