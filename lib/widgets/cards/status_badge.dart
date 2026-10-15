import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

/// Semantic disaster alert level as specified in SKILL.md.
enum DisasterStatusLevel {
  awas('AWAS', Icons.warning_rounded, AppColors.awas, AppColors.awasBg),
  siaga(
    'SIAGA',
    Icons.error_outline_rounded,
    AppColors.siaga,
    AppColors.siagaBg,
  ),
  waspada(
    'WASPADA',
    Icons.info_outline_rounded,
    AppColors.waspada,
    AppColors.waspadaBg,
  ),
  aman(
    'AMAN',
    Icons.check_circle_outline_rounded,
    AppColors.aman,
    AppColors.amanBg,
  ),
  info(
    'INFO',
    Icons.notifications_none_rounded,
    AppColors.info,
    AppColors.infoBg,
  );

  const DisasterStatusLevel(this.label, this.icon, this.color, this.bgColor);

  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;

  static DisasterStatusLevel fromString(String? value) {
    if (value == null) return DisasterStatusLevel.info;
    final normalized = value.trim().toUpperCase();
    if (normalized.contains('AWAS') || normalized.contains('DANGER')) {
      return DisasterStatusLevel.awas;
    }
    if (normalized.contains('SIAGA') || normalized.contains('ALERT')) {
      return DisasterStatusLevel.siaga;
    }
    if (normalized.contains('WASPADA') || normalized.contains('WARNING')) {
      return DisasterStatusLevel.waspada;
    }
    if (normalized.contains('AMAN') || normalized.contains('SAFE')) {
      return DisasterStatusLevel.aman;
    }
    return DisasterStatusLevel.info;
  }
}

/// Status Badge adhering to SKILL.md rules:
/// - Immutable status colors
/// - Always pairs text label + icon + color (never color alone!)
/// - Corner radius 8.0 dp
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.level,
    this.customLabel,
    this.compact = false,
  });

  final DisasterStatusLevel level;
  final String? customLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = customLabel ?? level.label;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? AppSpacing.xs : 6.0,
      ),
      decoration: BoxDecoration(
        color: level.bgColor,
        borderRadius: BorderRadius.circular(AppRadius.badge),
        border: Border.all(
          color: level.color.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(level.icon, size: compact ? 14 : 16, color: level.color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            text,
            style: AppTextStyles.badge.copyWith(
              color: level.color,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
