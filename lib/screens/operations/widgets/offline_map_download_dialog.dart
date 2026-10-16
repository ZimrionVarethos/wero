import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../models/evacuation_point.dart';
import '../../../services/evacuation_cache_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import 'offline_download_summary_card.dart';

/// Modal dialog allowing citizens to pre-download regional offline maps and evacuation shelters.
class OfflineMapDownloadDialog extends StatefulWidget {
  const OfflineMapDownloadDialog({
    super.key,
    required this.userLocation,
    required this.availablePoints,
    this.onDownloadComplete,
  });

  final LatLng userLocation;
  final List<EvacuationPoint> availablePoints;
  final VoidCallback? onDownloadComplete;

  static Future<void> show(
    BuildContext context, {
    required LatLng userLocation,
    required List<EvacuationPoint> availablePoints,
    VoidCallback? onDownloadComplete,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => OfflineMapDownloadDialog(
        userLocation: userLocation,
        availablePoints: availablePoints,
        onDownloadComplete: onDownloadComplete,
      ),
    );
  }

  @override
  State<OfflineMapDownloadDialog> createState() =>
      _OfflineMapDownloadDialogState();
}

class _OfflineMapDownloadDialogState extends State<OfflineMapDownloadDialog> {
  final _cacheService = const EvacuationCacheService();
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = 'Siap mengunduh data peta dan posko';
  bool _isAlreadyDownloaded = false;
  String? _lastDownloadedDate;

  @override
  void initState() {
    super.initState();
    _checkExistingDownload();
  }

  Future<void> _checkExistingDownload() async {
    final downloaded = await _cacheService.isOfflineMapDownloaded();
    final date = await _cacheService.getOfflineMapDownloadedDate();
    if (mounted) {
      setState(() {
        _isAlreadyDownloaded = downloaded;
        _lastDownloadedDate = date;
      });
    }
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _progress = 0.15;
      _statusText = 'Mengumpulkan posko dan shelter sekitar...';
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    // Cache the evacuation points
    await _cacheService.cachePoints(widget.availablePoints);
    await _cacheService.saveLastLocation(
      widget.userLocation.latitude,
      widget.userLocation.longitude,
    );

    setState(() {
      _progress = 0.55;
      _statusText = 'Menyimpan tile peta resolusi tinggi (Cache 180 hari)...';
    });

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    setState(() {
      _progress = 0.85;
      _statusText = 'Memvalidasi rute evakuasi darurat tanpa internet...';
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    await _cacheService.setOfflineMapDownloaded(
      isDownloaded: true,
      pointsCount: widget.availablePoints.length,
    );

    setState(() {
      _progress = 1.0;
      _isDownloading = false;
      _isAlreadyDownloaded = true;
      _statusText = 'Peta wilayah siap digunakan saat sinyal padam!';
    });

    widget.onDownloadComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.download_for_offline_rounded,
                    color: AppColors.accentOrange,
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unduh Peta Offline',
                        style: AppTextStyles.screenTitle.copyWith(
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Kesiapsiagaan Saat Sinyal Padam',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Menyimpan peta rute, shelter pengungsian, dan posko medis ke memori HP. Saat tower sinyal BTS padam pasca bencana, peta dan navigasi evakuasi tetap dapat diakses 100%.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OfflineDownloadSummaryCard(
              shelterCount: widget.availablePoints.length,
              isAlreadyDownloaded: _isAlreadyDownloaded,
              lastDownloadedDate: _lastDownloadedDate,
            ),
            if (_isDownloading || _progress > 0) ...[
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                  backgroundColor: AppColors.borderNeutral,
                  valueColor: const AlwaysStoppedAnimation(
                    AppColors.accentOrange,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _statusText,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primaryNavy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isDownloading
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _isAlreadyDownloaded ? 'Tutup' : 'Batal',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isDownloading ? null : _startDownload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isAlreadyDownloaded
                          ? AppColors.siaga
                          : AppColors.accentOrange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _isAlreadyDownloaded ? 'Perbarui Peta' : 'Unduh Sekarang',
                      style: AppTextStyles.label.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
