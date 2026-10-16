import 'package:flutter/material.dart';

import '../models/activity.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Horizontally scrollable category tab row for the Activity screen.
///
/// Renders [Popular], [Moderate], [Intensive] tabs with an underline
/// indicator on the selected tab. [selectedCategory] drives the selected
/// state; [onCategorySelected] updates it in the parent.
class CategoryTabs extends StatelessWidget {
  const CategoryTabs({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final ActivityCategory selectedCategory;
  final ValueChanged<ActivityCategory> onCategorySelected;

  static const _tabs = [
    (label: 'Popular', category: ActivityCategory.popular),
    (label: 'Moderate', category: ActivityCategory.moderate),
    (label: 'Intensive', category: ActivityCategory.intensive),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _tabs.map((tab) {
          final isSelected = tab.category == selectedCategory;
          return _TabItem(
            label: tab.label,
            isSelected: isSelected,
            onTap: () => onCategorySelected(tab.category),
          );
        }).toList(),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: isSelected ? 24 : 0,
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
