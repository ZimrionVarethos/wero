import 'package:flutter/material.dart';

import '../models/statistic.dart';
import '../theme/app_colors.dart';

/// Placeholder statistics data used by StatisticsScreen.
/// Replace with API data when a backend is connected.
const List<String> monthLabels = ['April', 'May', 'June', 'July', 'August'];

/// Weekly chart bars — values are relative heights (0.0–1.0).
/// Colors rotate through chartGreen, chartRed, and chartBlue per design.md.
final List<ChartBar> weeklyChartBars = [
  const ChartBar(day: 'Mon', value: 0.55, color: AppColors.chartGreen),
  const ChartBar(day: 'Tue', value: 0.80, color: AppColors.chartRed),
  const ChartBar(day: 'Wed', value: 0.45, color: AppColors.chartBlue),
  const ChartBar(day: 'Thu', value: 0.90, color: AppColors.chartGreen),
  const ChartBar(day: 'Fri', value: 0.65, color: AppColors.chartRed),
  const ChartBar(day: 'Sat', value: 0.35, color: AppColors.chartBlue),
  const ChartBar(day: 'Sun', value: 0.70, color: AppColors.chartGreen),
];

/// Summary statistic tiles shown below the chart.
final List<StatisticItem> statisticItems = [
  StatisticItem(
    label: 'Training',
    value: '4.5 hours',
    iconData: Icons.fitness_center_rounded,
    iconColor: AppColors.chartGreen,
    iconBackground: AppColors.softGreen,
  ),
  StatisticItem(
    label: 'Steps',
    value: '24 km per week',
    iconData: Icons.directions_walk_rounded,
    iconColor: AppColors.chartRed,
    iconBackground: AppColors.softRed,
  ),
  StatisticItem(
    label: 'Calories',
    value: '6215 calories burned',
    iconData: Icons.local_fire_department_rounded,
    iconColor: AppColors.chartBlue,
    iconBackground: AppColors.softBlue,
  ),
];
