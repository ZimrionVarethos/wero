import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/supabase_providers.dart';
import '../../../core/providers/volunteer_providers.dart';
import '../../../models/public_sos_event.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Bottom sheet displaying public SOS details and action to volunteer assistance.
class VolunteerSosDetailSheet extends ConsumerStatefulWidget {
  const VolunteerSosDetailSheet({
    super.key,
    required this.event,
    this.onStartRoute,
  });

  final PublicSosEvent event;
  final VoidCallback? onStartRoute;

  static Future<void> show(
    BuildContext context, {
    required PublicSosEvent event,
    VoidCallback? onStartRoute,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          VolunteerSosDetailSheet(event: event, onStartRoute: onStartRoute),
    );
  }

  @override
  ConsumerState<VolunteerSosDetailSheet> createState() =>
      _VolunteerSosDetailSheetState();
}

class _VolunteerSosDetailSheetState
    extends ConsumerState<VolunteerSosDetailSheet> {
  bool _isBusy = false;

  Future<void> _handleStartHelp() async {
    final user = ref.read(currentUserProvider);
    final profile = ref.read(userProfileProvider).asData?.value;
    final responderId = user?.id ?? 'guest-volunteer';
    final responderName = profile?.displayName ?? 'Warga Relawan';

    setState(() => _isBusy = true);
    final ok = await ref
        .read(activeVolunteerMissionProvider.notifier)
        .startMission(
          sos: widget.event,
          responderId: responderId,
          responderName: responderName,
        );

    if (mounted) {
      setState(() => _isBusy = false);
      Navigator.of(context).pop();
      if (ok) {
        widget.onStartRoute?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Rute bantuan aktif menuju lokasi ${widget.event.victimName}.',
            ),
            backgroundColor: AppColors.primaryNavy,
          ),
        );
      }
    }
  }

  Future<void> _handleCancelHelp() async {
    final user = ref.read(currentUserProvider);
    final responderId = user?.id ?? 'guest-volunteer';

    setState(() => _isBusy = true);
    await ref
        .read(activeVolunteerMissionProvider.notifier)
        .finishMission(responderId);

    if (mounted) {
      setState(() => _isBusy = false);
      Navigator.of(context).pop();
    }
  }

  String _formatDistance() {
    final d = widget.event.distanceM;
    if (d == null) return 'Dalam radius sekitar';
    if (d < 1000) return '${d.round()} m dari Anda';
    return '${(d / 1000).toStringAsFixed(1)} km dari Anda';
  }

  @override
  Widget build(BuildContext context) {
    final activeMission = ref.watch(activeVolunteerMissionProvider);
    final isHelpingThis = activeMission?.event.id == widget.event.id;

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
                  Icons.warning_amber_rounded,
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
                      'PANGGILAN DARURAT (SOS)',
                      style: AppTextStyles.cardTitle.copyWith(
                        color: AppColors.awas,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.event.victimName,
                      style: AppTextStyles.screenTitle.copyWith(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.backgroundCream,
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.near_me_rounded,
                  size: 16,
                  color: AppColors.accentOrange,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  _formatDistance(),
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  widget.event.respondersCount > 0
                      ? '${widget.event.respondersCount} Relawan Membantu'
                      : 'Belum Ada Penolong',
                  style: AppTextStyles.caption.copyWith(
                    color: widget.event.respondersCount > 0
                        ? AppColors.aman
                        : AppColors.awas,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (widget.event.note != null && widget.event.note!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'Catatan: "${widget.event.note}"',
                style: AppTextStyles.caption.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (_isBusy)
            const Center(
              child: CircularProgressIndicator(color: AppColors.awas),
            )
          else if (isHelpingThis)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final user = ref.read(currentUserProvider);
                      final responderId = user?.id ?? 'guest-volunteer';
                      ref
                          .read(activeVolunteerMissionProvider.notifier)
                          .markArrived(responderId);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.aman,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                    icon: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Tiba di Lokasi',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton(
                  onPressed: _handleCancelHelp,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.chartRed),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  child: const Text(
                    'Batal Menolong',
                    style: TextStyle(
                      color: AppColors.chartRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleStartHelp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.awas,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                icon: const Icon(
                  Icons.health_and_safety_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text(
                  'Bantu Sekarang (Relawan)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
