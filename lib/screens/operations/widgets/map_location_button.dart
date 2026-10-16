import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../services/location_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// Floating action button that queries device GPS to synchronize current location.
class MapLocationButton extends StatefulWidget {
  const MapLocationButton({super.key, required this.onLocationSynced});

  final ValueChanged<LatLng> onLocationSynced;

  @override
  State<MapLocationButton> createState() => _MapLocationButtonState();
}

class _MapLocationButtonState extends State<MapLocationButton> {
  bool _isSyncing = false;

  Future<void> _sync() async {
    setState(() => _isSyncing = true);
    try {
      final loc = await const LocationService().determinePosition();
      widget.onLocationSynced(loc);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lokasi GPS Anda berhasil disinkronkan (${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)})',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.textPrimary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.chartRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'map_sync_gps_btn',
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.chartBlue,
      elevation: 4,
      icon: _isSyncing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.chartBlue,
              ),
            )
          : const Icon(Icons.gps_fixed_rounded, size: 18),
      label: Text(
        _isSyncing ? 'Mencari GPS...' : 'Sinkron Lokasi Saya',
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.chartBlue,
        ),
      ),
      onPressed: _isSyncing ? null : _sync,
    );
  }
}
