import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

enum EvacuationMapStyle {
  satellite(
    'Satelit 3D (Nyata)',
    'mapbox/satellite-streets-v12',
    Icons.satellite_alt_rounded,
  ),
  streets('Jalanan (Streets)', 'mapbox/streets-v12', Icons.map_rounded),
  outdoors('Topografi', 'mapbox/outdoors-v12', Icons.terrain_rounded);

  const EvacuationMapStyle(this.label, this.styleId, this.icon);

  final String label;
  final String styleId;
  final IconData icon;
}

/// Floating action button that opens a popup menu to toggle map visual style.
class MapLayerButton extends StatelessWidget {
  const MapLayerButton({
    super.key,
    required this.selectedStyle,
    required this.onStyleChanged,
  });

  final EvacuationMapStyle selectedStyle;
  final ValueChanged<EvacuationMapStyle> onStyleChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<EvacuationMapStyle>(
      tooltip: 'Pilih Tampilan Peta',
      initialValue: selectedStyle,
      onSelected: onStyleChanged,
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      elevation: 4,
      itemBuilder: (context) => EvacuationMapStyle.values.map((style) {
        final isSelected = style == selectedStyle;
        return PopupMenuItem<EvacuationMapStyle>(
          value: style,
          child: Row(
            children: [
              Icon(
                style.icon,
                size: 20,
                color: isSelected
                    ? AppColors.chartBlue
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  style.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.chartBlue
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: AppColors.chartBlue,
                ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selectedStyle.icon, size: 16, color: AppColors.textPrimary),
            const SizedBox(width: 6),
            Text(
              selectedStyle == EvacuationMapStyle.satellite
                  ? 'Satelit 3D'
                  : 'Peta',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
