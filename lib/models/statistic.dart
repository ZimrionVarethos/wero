import 'package:flutter/material.dart';

/// Summary statistic tile model for the Statistics dashboard.
final class StatisticItem {
  const StatisticItem({
    required this.label,
    required this.value,
    required this.iconData,
    required this.iconColor,
    required this.iconBackground,
  });

  final String label;
  final String value;
  final IconData iconData;
  final Color iconColor;
  final Color iconBackground;
}

/// A single bar in the weekly activity chart.
final class ChartBar {
  const ChartBar({required this.day, required this.value, required this.color});

  final String day;

  /// Relative height value (0.0 – 1.0).
  final double value;
  final Color color;
}
