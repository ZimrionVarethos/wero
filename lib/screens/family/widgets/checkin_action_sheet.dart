import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_providers.dart';

import '../../../core/providers/family_providers.dart';
import '../../../core/providers/supabase_providers.dart';
import '../../../services/location_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import 'checkin_status_selector.dart';

/// Modal bottom sheet allowing users to perform a 1-tap safety check-in.
class CheckinActionSheet extends ConsumerStatefulWidget {
  const CheckinActionSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      builder: (_) => const CheckinActionSheet(),
    );
  }

  @override
  ConsumerState<CheckinActionSheet> createState() => _CheckinActionSheetState();
}

class _CheckinActionSheetState extends ConsumerState<CheckinActionSheet> {
  final _noteController = TextEditingController();
  String _selectedStatus = 'SAFE';
  bool _attachLocation = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitCheckin() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider);
      final profile = ref.read(userProfileProvider).asData?.value;
      final userId = user?.id ?? 'guest_user';
      final userName =
          profile?.displayName ??
          user?.email?.split('@').first ??
          'Warga Siaga';

      double? lat;
      double? lng;
      String? address;

      if (_attachLocation) {
        try {
          const locService = LocationService();
          final pos = await locService.determinePosition();
          lat = pos.latitude;
          lng = pos.longitude;
          address =
              'Koordinat: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
        } catch (_) {}
      }

      await ref
          .read(familyServiceProvider)
          .submitCheckin(
            userId: userId,
            userName: userName,
            status: _selectedStatus,
            note: _noteController.text.trim().isNotEmpty
                ? _noteController.text.trim()
                : null,
            latitude: lat,
            longitude: lng,
            address: address,
          );

      ref.invalidate(familyCheckinsProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status keselamatan Anda berhasil diperbarui.'),
            backgroundColor: AppColors.chartGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: AppColors.chartRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.pagePadding,
        AppSpacing.pagePadding,
        bottomInset + AppSpacing.pagePadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.family_restroom_rounded,
                color: AppColors.chartBlue,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text('Check-in Keselamatan', style: AppTextStyles.sectionTitle),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Beri tahu kondisi terkini Anda kepada keluarga dan kerabat siaga:',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          CheckinStatusSelector(
            selectedStatus: _selectedStatus,
            onChanged: (val) => setState(() => _selectedStatus = val),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Catatan kondisi / Lokasi Anda saat ini (opsional)',
              hintText:
                  'Misal: Sedang di rumah bersama keluarga, kondisi aman.',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _attachLocation,
            title: const Text(
              'Sertakan Koordinat GPS Terkini',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Membantu kerabat mengetahui lokasi Anda berada.',
              style: TextStyle(fontSize: 11),
            ),
            onChanged: (val) => setState(() => _attachLocation = val),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitCheckin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Kirim Pembaruan Status',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
