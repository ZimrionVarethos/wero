import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../services/location_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Floating interactive button that queries device GPS to synchronize current location.
class MapLocationButton extends StatefulWidget {
  const MapLocationButton({super.key, required this.onLocationSynced});

  final ValueChanged<LatLng> onLocationSynced;

  @override
  State<MapLocationButton> createState() => _MapLocationButtonState();
}

class _MapLocationButtonState extends State<MapLocationButton>
    with SingleTickerProviderStateMixin {
  bool _isSyncing = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isSyncing ? null : _sync,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.chartBlue.withValues(alpha: 0.22),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryNavy.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular GPS Icon with gradient & pulse
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                  ),
                ),
                child: Center(
                  child: _isSyncing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : ScaleTransition(
                          scale: _pulseAnimation,
                          child: const Icon(
                            Icons.gps_fixed_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Label & Status text
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sinkron Lokasi Saya',
                    style: AppTextStyles.label.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  Text(
                    _isSyncing ? 'Mencari GPS...' : 'Ketuk untuk sinkron',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 9.5,
                      color: _isSyncing
                          ? AppColors.chartBlue
                          : AppColors.mutedText,
                      fontWeight: _isSyncing
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
