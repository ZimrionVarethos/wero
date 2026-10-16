import 'package:flutter/material.dart';

import '../models/statistic.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// A single row tile in the statistics summary section.
///
/// Shows a colored icon on a soft background, a label, and a value string.
/// All display values come from the [StatisticItem] model.
class StatisticSummaryTile extends StatelessWidget {
  const StatisticSummaryTile({super.key, required this.item});

  final StatisticItem item;

  static const _iconSize = 22.0;
  static const _tileSize = 44.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          // Icon tile
          Container(
            width: _tileSize,
            height: _tileSize,
            decoration: BoxDecoration(
              color: item.iconBackground,
              borderRadius: BorderRadius.circular(AppRadius.iconTile),
            ),
            child: Icon(item.iconData, color: item.iconColor, size: _iconSize),
          ),
          const SizedBox(width: AppSpacing.base),
          // Labels
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label, style: AppTextStyles.label),
                const SizedBox(height: 2),
                Text(item.value, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
