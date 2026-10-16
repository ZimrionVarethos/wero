import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/providers/operations_providers.dart';
import '../../../services/location_service.dart';
import '../../../theme/app_colors.dart';
import 'location_required_dialog.dart';
import 'sos_dialog.dart';

/// Circular Emergency SOS button requiring a 2.5s press-and-hold with pulsing wave animation.
class SosButton extends ConsumerStatefulWidget {
  const SosButton({super.key});

  @override
  ConsumerState<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends ConsumerState<SosButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _holdTimer;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _holdTimer?.cancel();
    super.dispose();
  }

  void _onPressStart() {
    setState(() => _isHolding = true);
    _controller.forward(from: 0.0);
    _holdTimer = Timer(const Duration(milliseconds: 2500), () {
      _controller.reset();
      setState(() => _isHolding = false);
      _handleSosActivation();
    });
  }

  void _onPressEnd() {
    if (_isHolding) {
      _holdTimer?.cancel();
      _controller.reverse();
      setState(() => _isHolding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tekan dan tahan selama 2.5 detik untuk memicu SOS.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleSosActivation() async {
    // 1. Mandatory Location Enforcement
    LatLng currentPos;
    try {
      currentPos = await const LocationService().determinePosition();
    } catch (e) {
      if (!mounted) return;
      LocationRequiredDialog.show(
        context,
        reason: e.toString().replaceAll('Exception: ', ''),
      );
      return;
    }

    if (!mounted) return;
    final result = await SosConfirmationDialog.show(
      context,
      location: currentPos,
    );
    if (result != null && mounted) {
      try {
        await ref
            .read(activeSosProvider.notifier)
            .triggerSos(
              mode: result.mode,
              latitude: currentPos.latitude,
              longitude: currentPos.longitude,
              accuracyM: 5.0,
              note: result.note,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Sinyal SOS Darurat berhasil disiarkan dengan lokasi GPS asli!',
              ),
              backgroundColor: AppColors.awas,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyiarkan SOS: $e'),
              backgroundColor: AppColors.awas,
            ),
          );
        }
      }
    }
  }

  Widget _buildWaveRing(double progress, double delay) {
    final t = (progress * 2.5 + delay) % 1.0;
    final scale = 1.0 + (t * 0.75);
    final opacity = (1.0 - t).clamp(0.0, 1.0) * 0.45;

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.awas.withValues(alpha: opacity * 0.25),
          border: Border.all(
            color: AppColors.awas.withValues(alpha: opacity),
            width: 2.0,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Tombol Darurat SOS. Tekan dan tahan 2.5 detik untuk membuka popup konfirmasi.',
      child: GestureDetector(
        onTapDown: (_) => _onPressStart(),
        onTapUp: (_) => _onPressEnd(),
        onTapCancel: _onPressEnd,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final progress = _controller.value;
            return SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Gelombang konsentris saat tombol ditekan
                  if (_isHolding) ...[
                    _buildWaveRing(progress, 0.0),
                    _buildWaveRing(progress, 0.33),
                    _buildWaveRing(progress, 0.66),
                    // Indikator progres lingkar luar
                    SizedBox(
                      width: 76,
                      height: 76,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 3.5,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.awas,
                        ),
                        backgroundColor: AppColors.awas.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                  // Pembungkus bulat warna merah dengan icon danger
                  Transform.scale(
                    scale: _isHolding ? 0.95 : 1.0,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.awas,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.awas.withValues(
                              alpha: _isHolding ? 0.6 : 0.4,
                            ),
                            blurRadius: _isHolding ? 16 : 10,
                            spreadRadius: _isHolding ? 3 : 0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.warning_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
