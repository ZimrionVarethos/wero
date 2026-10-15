import 'package:flutter/material.dart';

import '../../models/emergency_guide.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/phone_launcher.dart';

/// Screen displaying in-depth step-by-step survival procedures for a specific hazard.
class EmergencyGuideDetailScreen extends StatelessWidget {
  const EmergencyGuideDetailScreen({super.key, required this.guide});

  final EmergencyGuide guide;

  static const routeName = '/guides/detail';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasBlue,
      appBar: AppBar(
        title: Text(
          guide.title,
          style: AppTextStyles.screenTitle.copyWith(fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: AppSpacing.base),
            _buildHotlinesCard(context),
            const SizedBox(height: AppSpacing.base),
            ...guide.phases.map(_buildPhaseSection),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.softGreen,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.offline_pin_rounded,
                      size: 14,
                      color: AppColors.chartGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tersimpan Offline',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.chartGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(guide.categoryLabel, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(guide.title, style: AppTextStyles.sectionTitle),
          const SizedBox(height: 4),
          Text(guide.summary, style: AppTextStyles.bodySecondary),
        ],
      ),
    );
  }

  Widget _buildHotlinesCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.softRed,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.chartRed.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.phone_in_talk_rounded,
                color: AppColors.chartRed,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Kontak Darurat Terkait',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.chartRed,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: guide.emergencyNumbers.map((hotline) {
              return ActionChip(
                backgroundColor: AppColors.surface,
                avatar: const Icon(
                  Icons.call,
                  size: 14,
                  color: AppColors.chartRed,
                ),
                label: Text(
                  hotline,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () => PhoneLauncher.launchPhone(
                  context,
                  hotline,
                  label: 'Layanan Darurat',
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseSection(GuidePhase phase) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.base),
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 18,
                color: AppColors.chartBlue,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(phase.phaseName, style: AppTextStyles.sectionTitle),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          ...phase.instructions.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final instruction = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: AppColors.canvasBlue,
                    child: Text(
                      '$index',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      instruction,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
