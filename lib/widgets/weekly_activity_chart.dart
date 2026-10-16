import 'package:flutter/material.dart';

import '../models/statistic.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Seven-bar weekly activity chart built entirely from Flutter widgets.
///
/// [bars] is a list of [ChartBar] with relative values (0.0–1.0).
/// Bars have rounded tops, consistent widths, and subtle gray guide lines.
/// Weekday labels are aligned below each bar.
class WeeklyActivityChart extends StatelessWidget {
  const WeeklyActivityChart({
    super.key,
    required this.bars,
    this.chartHeight = 160.0,
  });

  final List<ChartBar> bars;
  final double chartHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: chartHeight + 24, // extra space for day labels
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: bars.map((bar) {
          return Expanded(
            child: _SingleBar(bar: bar, chartHeight: chartHeight),
          );
        }).toList(),
      ),
    );
  }
}

class _SingleBar extends StatelessWidget {
  const _SingleBar({required this.bar, required this.chartHeight});

  final ChartBar bar;
  final double chartHeight;

  static const _barWidth = 18.0;
  static const _guideLines = 4;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: chartHeight,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Subtle gray guide lines
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    _guideLines,
                    (_) => Divider(
                      height: 1,
                      color: AppColors.border,
                      thickness: 1,
                    ),
                  ),
                ),
              ),
              // Actual bar
              FractionallySizedBox(
                heightFactor: bar.value.clamp(0.0, 1.0),
                child: Container(
                  width: _barWidth,
                  decoration: BoxDecoration(
                    color: bar.color,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.iconTile),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          bar.day,
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
