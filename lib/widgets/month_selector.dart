import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Horizontally scrollable month label row for the Statistics screen.
///
/// [selectedMonth] is the currently active month label string.
/// [months] is the ordered list of month names.
/// [onMonthSelected] updates selection in the parent widget.
class MonthSelector extends StatelessWidget {
  const MonthSelector({
    super.key,
    required this.months,
    required this.selectedMonth,
    required this.onMonthSelected,
  });

  final List<String> months;
  final String selectedMonth;
  final ValueChanged<String> onMonthSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: months.map((month) {
          final isSelected = month == selectedMonth;
          return _MonthChip(
            month: month,
            isSelected: isSelected,
            onTap: () => onMonthSelected(month),
          );
        }).toList(),
      ),
    );
  }
}

class _MonthChip extends StatelessWidget {
  const _MonthChip({
    required this.month,
    required this.isSelected,
    required this.onTap,
  });

  final String month;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: AppSpacing.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Text(
          month,
          style: AppTextStyles.label.copyWith(
            color: isSelected ? AppColors.surface : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
