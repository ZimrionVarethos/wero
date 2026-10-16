import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/chat_message.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/phone_launcher.dart';

/// Renders suggested action buttons for assistant responses.
class ChatActionPills extends StatelessWidget {
  const ChatActionPills({super.key, required this.actions});

  final List<ChatAction> actions;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: actions.map((action) {
        return InkWell(
          onTap: () => _handleAction(context, action),
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.softBlue,
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(
                color: AppColors.chartBlue.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  action.phoneNumber != null
                      ? Icons.phone_in_talk
                      : Icons.arrow_outward,
                  size: 14,
                  color: AppColors.chartBlue,
                ),
                const SizedBox(width: 4),
                Text(
                  action.label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.chartBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _handleAction(BuildContext context, ChatAction action) {
    if (action.route != null) {
      context.push(action.route!, extra: action.routeExtra);
    } else if (action.phoneNumber != null) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Panggilan Darurat'),
          content: Text('Hubungi nomor resmi ${action.phoneNumber}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                PhoneLauncher.launchPhone(
                  context,
                  action.phoneNumber!,
                  label: 'Layanan Darurat',
                );
              },
              child: const Text('Panggil'),
            ),
          ],
        ),
      );
    }
  }
}
