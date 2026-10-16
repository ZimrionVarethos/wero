import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Informational card summarizing the offline map radius, shelter count, and stored status.
class OfflineDownloadSummaryCard extends StatelessWidget {
  const OfflineDownloadSummaryCard({
    super.key,
    required this.shelterCount,
    required this.isAlreadyDownloaded,
    this.lastDownloadedDate,
  });

  final int shelterCount;
  final bool isAlreadyDownloaded;
  final String? lastDownloadedDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundCream,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderNeutral),
      ),
      child: Column(
        children: [
          _buildItemRow(
            Icons.my_location_rounded,
            'Cakupan Wilayah',
            'Radius 15 KM dari koordinat Anda',
          ),
          const SizedBox(height: 8),
          _buildItemRow(
            Icons.shield_outlined,
            'Data Posko Tersimpan',
            '$shelterCount Fasilitas & Shelter',
          ),
          const SizedBox(height: 8),
          _buildItemRow(
            Icons.sd_storage_outlined,
            'Ukuran File',
            '~14.2 MB (Hemat Penyimpanan)',
          ),
          if (isAlreadyDownloaded && lastDownloadedDate != null) ...[
            const Divider(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: AppColors.siaga,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Tersimpan pada: $lastDownloadedDate',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.siaga,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryNavy),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.mutedText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
