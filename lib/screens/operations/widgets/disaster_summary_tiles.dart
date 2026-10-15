import 'package:flutter/material.dart';

import '../../../models/bmkg_quake.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

/// Top summary metrics tile row showing disaster warning state,
/// latest magnitude, and tsunami risk.
class DisasterSummaryTiles extends StatelessWidget {
  const DisasterSummaryTiles({super.key, required this.quake});

  final BmkgQuake quake;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            label: 'Status Siaga',
            value: quake.severity,
            icon: Icons.shield_rounded,
            color: quake.severityColor,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildMetricTile(
            label: 'Gempa Terkini',
            value: quake.formattedMagnitude,
            icon: Icons.waves_rounded,
            color: AppColors.chartBlue,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildMetricTile(
            label: 'Potensi Tsunami',
            value: quake.isTsunamiPotential ? 'AWAS' : 'NIHIL',
            icon: Icons.tsunami_rounded,
            color: quake.isTsunamiPotential
                ? AppColors.chartRed
                : AppColors.chartGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
