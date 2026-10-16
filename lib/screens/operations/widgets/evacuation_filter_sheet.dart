import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import 'evacuation_filter_tile.dart';

/// Modal bottom sheet for selecting evacuation facility filter options.
class EvacuationFilterSheet extends StatefulWidget {
  const EvacuationFilterSheet({
    super.key,
    required this.currentKind,
    required this.onApply,
  });

  final String? currentKind;
  final ValueChanged<String?> onApply;

  /// Shows the evacuation filter bottom sheet modal.
  static Future<void> show(
    BuildContext context, {
    required String? currentKind,
    required ValueChanged<String?> onApply,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          EvacuationFilterSheet(currentKind: currentKind, onApply: onApply),
    );
  }

  @override
  State<EvacuationFilterSheet> createState() => _EvacuationFilterSheetState();
}

class _EvacuationFilterSheetState extends State<EvacuationFilterSheet> {
  late String? _selectedKind;

  static const _options = [
    EvacuationFilterOption(
      kind: null,
      title: 'Semua Fasilitas',
      subtitle: 'Tampilkan seluruh posko shelter, kesehatan, & titik kumpul',
      icon: Icons.grid_view_rounded,
    ),
    EvacuationFilterOption(
      kind: 'SHELTER',
      title: 'Shelter Evakuasi',
      subtitle: 'Tempat pengungsian resmi, posko logistik, dan barak warga',
      icon: Icons.home_work_rounded,
    ),
    EvacuationFilterOption(
      kind: 'HEALTH',
      title: 'Fasilitas Kesehatan',
      subtitle: 'Rumah sakit darurat, puskesmas, dan posko medis bencana',
      icon: Icons.local_hospital_rounded,
    ),
    EvacuationFilterOption(
      kind: 'ASSEMBLY',
      title: 'Titik Kumpul Aman',
      subtitle: 'Lapangan terbuka, alun-alun, dan zona evakuasi sementara',
      icon: Icons.groups_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedKind = widget.currentKind;
  }

  void _apply() {
    widget.onApply(_selectedKind);
    Navigator.pop(context);
  }

  void _reset() {
    setState(() => _selectedKind = null);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderNeutral,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.sm,
              AppSpacing.pagePadding,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filter Fasilitas',
                        style: AppTextStyles.cardTitle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Pilih jenis posko yang ingin ditampilkan di peta',
                        style: AppTextStyles.caption.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (_selectedKind != null)
                  TextButton(
                    onPressed: _reset,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.mutedText,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Reset'),
                  ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Tutup',
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderNeutral),

          // Options list
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              children: _options.map((opt) {
                return EvacuationFilterTile(
                  option: opt,
                  isSelected: _selectedKind == opt.kind,
                  onTap: () => setState(() => _selectedKind = opt.kind),
                );
              }).toList(),
            ),
          ),

          // Apply button
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
              vertical: AppSpacing.xs,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                child: const Text(
                  'Terapkan Filter',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
