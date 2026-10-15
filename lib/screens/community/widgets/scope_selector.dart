import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Scope selector toggle between 'LOCAL' and 'NATIONAL'.
class ScopeSelector extends StatelessWidget {
  const ScopeSelector({
    super.key,
    required this.currentScope,
    required this.onScopeChanged,
  });

  final String currentScope;
  final ValueChanged<String> onScopeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildItem(
            label: 'Lokal',
            scope: 'LOCAL',
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(width: AppSpacing.xs),
          _buildItem(
            label: 'Nasional',
            scope: 'NATIONAL',
            icon: Icons.public_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required String label,
    required String scope,
    required IconData icon,
  }) {
    final isSelected = currentScope == scope;
    return GestureDetector(
      onTap: () => onScopeChanged(scope),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
