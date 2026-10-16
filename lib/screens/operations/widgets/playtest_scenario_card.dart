import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';

/// Card displaying disaster scenario details for playtest simulation.
class PlaytestScenarioCard extends StatelessWidget {
  const PlaytestScenarioCard({super.key, required this.scenario});

  final Map<String, Object> scenario;

  @override
  Widget build(BuildContext context) {
    final color = scenario['color'] as Color;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: color, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text(
                scenario['level'] as String,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            scenario['title'] as String,
            style: AppTextStyles.label.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(scenario['location'] as String, style: AppTextStyles.caption),
          const Divider(height: 16),
          Text(
            'Rekomendasi Tindakan:',
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            scenario['action'] as String,
            style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
