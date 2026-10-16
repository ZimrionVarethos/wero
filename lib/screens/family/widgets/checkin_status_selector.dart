import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

/// 3-button status selector for safety check-ins.
class CheckinStatusSelector extends StatelessWidget {
  const CheckinStatusSelector({
    super.key,
    required this.selectedStatus,
    required this.onChanged,
  });

  final String selectedStatus;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildOption(
          'SAFE',
          'Saya Aman',
          Icons.check_circle_rounded,
          AppColors.chartGreen,
        ),

        const SizedBox(width: AppSpacing.xs),
        _buildOption(
          'EVACUATING',
          'Mengungsi',
          Icons.directions_run_rounded,
          AppColors.chartBlue,
        ),
        const SizedBox(width: AppSpacing.xs),
        _buildOption(
          'NEED_HELP',
          'Butuh Bantuan',
          Icons.warning_rounded,
          AppColors.accentOrange,
        ),
      ],
    );
  }

  Widget _buildOption(String value, String label, IconData icon, Color color) {
    final isSelected = selectedStatus == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : AppColors.canvasBlue,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? color : AppColors.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? color : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
