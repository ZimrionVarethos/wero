import 'package:flutter/material.dart';

import '../../../models/emergency_contact.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Card presenting a trusted emergency contact with call and action shortcuts.
class ContactCard extends StatelessWidget {
  const ContactCard({
    super.key,
    required this.contact,
    required this.onEdit,
    required this.onDelete,
    this.onCall,
    this.onWhatsApp,
  });

  final EmergencyContact contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsApp;

  Color get _statusColor {
    return switch (contact.status) {
      'SAFE' => AppColors.aman,
      'EVACUATING' => AppColors.siaga,
      'NEED_HELP' => AppColors.awas,
      _ => AppColors.mutedText,
    };
  }

  String get _statusLabel {
    return switch (contact.status) {
      'SAFE' => 'Aman',
      'EVACUATING' => 'Mengungsi',
      'NEED_HELP' => 'Butuh Bantuan',
      _ => 'Belum Ada Status',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),

      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: contact.isTrusted
              ? AppColors.chartBlue.withValues(alpha: 0.3)
              : AppColors.border,
          width: contact.isTrusted ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.canvasBlue,
                child: Text(
                  contact.name.isNotEmpty ? contact.name[0].toUpperCase() : 'K',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            contact.name,
                            style: AppTextStyles.sectionTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (contact.isTrusted) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified_user_rounded,
                            size: 14,
                            color: AppColors.chartBlue,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${contact.relationship} • ${contact.phoneNumber}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (contact.statusNote != null && contact.statusNote!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.canvasBlue,
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: Text(
                '“${contact.statusNote}”',
                style: AppTextStyles.caption.copyWith(
                  fontStyle: FontStyle.italic,
                  fontSize: 11,
                ),
              ),
            ),
          ],
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onCall,
                icon: const Icon(Icons.call_outlined, size: 16),
                label: const Text('Telepon'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.chartGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),

              const SizedBox(width: AppSpacing.xs),
              TextButton.icon(
                onPressed: onWhatsApp,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                label: const Text('WhatsApp'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.chartBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: AppColors.textSecondary,
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                tooltip: 'Hapus',
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppColors.chartRed,
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
