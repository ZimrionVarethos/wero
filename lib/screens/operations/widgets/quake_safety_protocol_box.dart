import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Informational box showing official BNPB/BMKG earthquake survival protocol.
class QuakeSafetyProtocolBox extends StatelessWidget {
  const QuakeSafetyProtocolBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.canvasBlue,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.health_and_safety_rounded,
                size: 18,
                color: AppColors.chartBlue,
              ),
              const SizedBox(width: 6),
              Text(
                'Protokol Keselamatan (BNPB / BMKG):',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '1. Merunduk, Lindungi Kepala & Bertahan (Drop, Cover, Hold On).\n'
            '2. Jauhi jendela kaca, lemari tinggi, dan tiang listrik.\n'
            '3. Jika berada di pantai & gempa terasa kuat, segera evakuasi ke tempat tinggi tanpa menunggu sirene.',
            style: TextStyle(fontSize: 11.5, height: 1.4),
          ),
        ],
      ),
    );
  }
}
