import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/providers/operations_providers.dart';
import '../../../services/location_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import 'location_required_dialog.dart';
import 'sos_dialog.dart';

/// Interactive Emergency SOS button requiring a 2.5s press-and-hold gesture.
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
          content: Text(
            'Tekan dan tahan selama 2.5 detik untuk mengaktifkan SOS.',
          ),
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
              backgroundColor: AppColors.chartRed,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyiarkan SOS: $e'),
              backgroundColor: AppColors.chartRed,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _onPressStart(),
      onTapUp: (_) => _onPressEnd(),
      onTapCancel: _onPressEnd,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.accentOrange,
              borderRadius: BorderRadius.circular(AppRadius.button),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentOrange.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                if (_isHolding)
                  FractionallySizedBox(
                    widthFactor: _controller.value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emergency_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      _isHolding ? 'Tahan tombol...' : 'DARURAT SOS',
                      style: AppTextStyles.label.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
