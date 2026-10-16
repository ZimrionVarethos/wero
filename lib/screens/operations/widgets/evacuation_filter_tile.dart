import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Representation of an evacuation filter option item.
class EvacuationFilterOption {
  const EvacuationFilterOption({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String? kind;
  final String title;
  final String subtitle;
  final IconData icon;
}

/// A selectable tile widget representing an evacuation filter option.
class EvacuationFilterTile extends StatelessWidget {
  const EvacuationFilterTile({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final EvacuationFilterOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.infoBg
                : AppColors.backgroundCream.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: isSelected ? AppColors.chartBlue : AppColors.borderNeutral,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.chartBlue
                      : AppColors.surfaceWhite,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  option.icon,
                  size: 18,
                  color: isSelected ? Colors.white : AppColors.primaryNavy,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: AppTextStyles.label.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: isSelected
                            ? AppColors.primaryNavy
                            : AppColors.primaryText,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      option.subtitle,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 11,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: AppColors.chartBlue,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
