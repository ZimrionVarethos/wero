import 'package:flutter/material.dart';

import '../../../models/region.dart';
import '../../../services/region_detector_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Modal dialog allowing the user to select their region manually or via live GPS.
class RegionPickerDialog extends StatefulWidget {
  const RegionPickerDialog({
    super.key,
    required this.regions,
    required this.selectedRegionId,
    this.detectorService,
  });

  final List<Region> regions;
  final String? selectedRegionId;
  final RegionDetectorService? detectorService;

  @override
  State<RegionPickerDialog> createState() => _RegionPickerDialogState();
}

class _RegionPickerDialogState extends State<RegionPickerDialog> {
  late final RegionDetectorService _detector;
  bool _isDetecting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _detector = widget.detectorService ?? RegionDetectorService();
  }

  Future<void> _detectLiveLocation() async {
    setState(() {
      _isDetecting = true;
      _errorMessage = null;
    });

    try {
      final result = await _detector.detectLiveRegion(
        availableRegions: widget.regions,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lokasi live terdeteksi: ${result.regionName}\n${result.fullAddress}',
            ),
            backgroundColor: AppColors.chartGreen,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, result.regionId);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isDetecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pilih Wilayah Siaga',
                    style: AppTextStyles.sectionTitle,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Tentukan wilayah default untuk informasi gempa dan feed darurat.',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: AppSpacing.base),
              // Live GPS Detection Button
              Material(
                color: AppColors.canvasBlue,
                borderRadius: BorderRadius.circular(AppRadius.iconTile),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.iconTile),
                  onTap: _isDetecting ? null : _detectLiveLocation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.chartBlue.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: _isDetecting
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.chartBlue,
                                  ),
                                )
                              : const Icon(
                                  Icons.my_location_rounded,
                                  color: AppColors.chartBlue,
                                  size: 20,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isDetecting
                                    ? 'Mencari lokasi live...'
                                    : 'Deteksi Lokasi GPS Live',
                                style: AppTextStyles.label.copyWith(
                                  color: AppColors.chartBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Sinkronkan kota otomatis dari GPS & Web',
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.chartBlue,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _errorMessage!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.chartRed,
                    fontSize: 11,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.base),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Atau pilih manual',
                      style: AppTextStyles.caption,
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.regions.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (ctx, index) {
                    final r = widget.regions[index];
                    final isSelected = r.id == widget.selectedRegionId;
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      title: Text(
                        r.name,
                        style: isSelected
                            ? AppTextStyles.label.copyWith(
                                color: AppColors.chartBlue,
                                fontWeight: FontWeight.bold,
                              )
                            : AppTextStyles.body,
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.chartBlue,
                              size: 18,
                            )
                          : null,
                      onTap: () => Navigator.pop(ctx, r.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
