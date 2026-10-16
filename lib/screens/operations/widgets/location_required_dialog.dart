import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Informative blocking dialog shown when GPS location is not enabled or denied.
class LocationRequiredDialog extends StatelessWidget {
  const LocationRequiredDialog({super.key, required this.reason});

  final String reason;

  static Future<void> show(BuildContext context, {required String reason}) {
    return showDialog(
      context: context,
      builder: (ctx) => LocationRequiredDialog(reason: reason),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      title: const Row(
        children: [
          Icon(Icons.location_off_rounded, color: AppColors.chartRed, size: 26),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Lokasi GPS Wajib Aktif',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sinyal darurat SOS membutuhkan koordinat lokasi GPS asli Anda agar tim penyelamat dan posko evakuasi dapat menemukan posisi Anda.',
            style: AppTextStyles.caption.copyWith(fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.chartRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.chip),
              border: Border.all(
                color: AppColors.chartRed.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              reason,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.chartRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await Geolocator.openLocationSettings();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentOrange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
          child: const Text(
            'Buka Pengaturan GPS',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
