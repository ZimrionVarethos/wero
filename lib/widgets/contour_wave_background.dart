import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Style variants of the contour wave background for different screens.
enum ContourVariant { home, community, assistant, profile }

/// A background widget that paints flowing topographic/disaster-map wave
/// contours inspired by the brand ornament artwork.
class ContourWaveBackground extends StatelessWidget {
  const ContourWaveBackground({
    super.key,
    this.variant = ContourVariant.home,
    this.opacity = 1.0,
  });

  final ContourVariant variant;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _ContourWavePainter(variant: variant, opacity: opacity),
        size: Size.infinite,
      ),
    );
  }
}

class _ContourWavePainter extends CustomPainter {
  const _ContourWavePainter({required this.variant, required this.opacity});

  final ContourVariant variant;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    switch (variant) {
      case ContourVariant.home:
        _paintHomeWaves(canvas, w, h);
        break;
      case ContourVariant.community:
        _paintCommunityWaves(canvas, w, h);
        break;
      case ContourVariant.assistant:
        _paintAssistantWaves(canvas, w, h);
        break;
      case ContourVariant.profile:
        _paintProfileWaves(canvas, w, h);
        break;
    }
  }

  void _paintHomeWaves(Canvas canvas, double w, double h) {
    // 1. Top cluster: Flowing curves entering from top-right down to upper-center
    _drawContourBand(
      canvas: canvas,
      start: Offset(w * 0.40, -10),
      cp1: Offset(w * 0.65, h * 0.05),
      cp2: Offset(w * 0.85, h * 0.08),
      end: Offset(w + 20, h * 0.14),
      lineCount: 4,
      spacing: 6.0,
      primaryColor: AppColors.accentOrange,
      secondaryColor: AppColors.primaryNavy,
      baseOpacity: 0.32 * opacity,
      strokeWidth: 1.6,
    );

    // 2. Upper-middle cluster: Flowing below the hero curve across the screen
    _drawContourBand(
      canvas: canvas,
      start: Offset(-15, h * 0.28),
      cp1: Offset(w * 0.30, h * 0.36),
      cp2: Offset(w * 0.65, h * 0.26),
      end: Offset(w + 20, h * 0.33),
      lineCount: 4,
      spacing: 7.0,
      primaryColor: AppColors.accentOrange,
      secondaryColor: AppColors.primaryNavy,
      baseOpacity: 0.28 * opacity,
      strokeWidth: 1.5,
    );

    // 3. Lower-middle cluster: Topographic ribbon weaving behind post cards
    _drawContourBand(
      canvas: canvas,
      start: Offset(w + 20, h * 0.50),
      cp1: Offset(w * 0.70, h * 0.58),
      cp2: Offset(w * 0.35, h * 0.52),
      end: Offset(-20, h * 0.62),
      lineCount: 5,
      spacing: 7.5,
      primaryColor: AppColors.accentOrange,
      secondaryColor: AppColors.primaryNavy,
      baseOpacity: 0.26 * opacity,
      strokeWidth: 1.5,
    );

    // 4. Bottom cluster: Sweeping wave framing above navigation bar
    _drawContourBand(
      canvas: canvas,
      start: Offset(-20, h * 0.82),
      cp1: Offset(w * 0.35, h * 0.76),
      cp2: Offset(w * 0.72, h * 0.88),
      end: Offset(w + 20, h * 0.92),
      lineCount: 4,
      spacing: 7.0,
      primaryColor: AppColors.accentOrange,
      secondaryColor: AppColors.primaryNavy,
      baseOpacity: 0.30 * opacity,
      strokeWidth: 1.6,
    );
  }

  void _paintCommunityWaves(Canvas canvas, double w, double h) {
    // Variasi komunitas: Garis kontur yang lebih lebar dan mengalir dari kiri atas
    _drawContourBand(
      canvas: canvas,
      start: Offset(-10, h * 0.08),
      cp1: Offset(w * 0.40, h * 0.16),
      cp2: Offset(w * 0.75, h * 0.06),
      end: Offset(w + 20, h * 0.18),
      lineCount: 4,
      spacing: 6.5,
      primaryColor: AppColors.accentOrange,
      secondaryColor: AppColors.primaryNavy,
      baseOpacity: 0.28 * opacity,
      strokeWidth: 1.5,
    );
    _drawContourBand(
      canvas: canvas,
      start: Offset(w + 20, h * 0.42),
      cp1: Offset(w * 0.60, h * 0.48),
      cp2: Offset(w * 0.30, h * 0.38),
      end: Offset(-15, h * 0.46),
      lineCount: 4,
      spacing: 7.0,
      primaryColor: AppColors.accentOrange,
      secondaryColor: AppColors.primaryNavy,
      baseOpacity: 0.26 * opacity,
      strokeWidth: 1.5,
    );
    _drawContourBand(
      canvas: canvas,
      start: Offset(-20, h * 0.74),
      cp1: Offset(w * 0.45, h * 0.84),
      cp2: Offset(w * 0.80, h * 0.72),
      end: Offset(w + 20, h * 0.80),
      lineCount: 5,
      spacing: 7.0,
      primaryColor: AppColors.accentOrange,
      secondaryColor: AppColors.primaryNavy,
      baseOpacity: 0.30 * opacity,
      strokeWidth: 1.6,
    );
  }

  void _paintAssistantWaves(Canvas canvas, double w, double h) {
    // Variasi Chat AI: Gelombang lembut di latar belakang chat
    _drawContourBand(
      canvas: canvas,
      start: Offset(w * 0.3, -10),
      cp1: Offset(w * 0.7, h * 0.12),
      cp2: Offset(w * 0.5, h * 0.22),
      end: Offset(w + 20, h * 0.30),
      lineCount: 4,
      spacing: 6.0,
      primaryColor: AppColors.accentOrange,
      secondaryColor: AppColors.primaryNavy,
      baseOpacity: 0.24 * opacity,
      strokeWidth: 1.4,
    );
    _drawContourBand(
      canvas: canvas,
      start: Offset(-15, h * 0.65),
      cp1: Offset(w * 0.4, h * 0.72),
      cp2: Offset(w * 0.7, h * 0.60),
      end: Offset(w + 20, h * 0.70),
      lineCount: 4,
      spacing: 6.5,
      primaryColor: AppColors.accentOrange,
      secondaryColor: AppColors.primaryNavy,
      baseOpacity: 0.24 * opacity,
      strokeWidth: 1.4,
    );
  }

  void _paintProfileWaves(Canvas canvas, double w, double h) {
    // Variasi profil: Gelombang elegan melingkar di atas dan bawah
    _drawContourBand(
      canvas: canvas,
      start: Offset(-20, h * 0.20),
      cp1: Offset(w * 0.50, h * 0.12),
      cp2: Offset(w * 0.80, h * 0.26),
      end: Offset(w + 20, h * 0.22),
      lineCount: 4,
      spacing: 7.0,
      primaryColor: AppColors.accentOrange,
      secondaryColor: AppColors.primaryNavy,
      baseOpacity: 0.28 * opacity,
      strokeWidth: 1.5,
    );
    _drawContourBand(
      canvas: canvas,
      start: Offset(w + 20, h * 0.78),
      cp1: Offset(w * 0.65, h * 0.86),
      cp2: Offset(w * 0.25, h * 0.80),
      end: Offset(-20, h * 0.90),
      lineCount: 4,
      spacing: 7.0,
      primaryColor: AppColors.accentOrange,
      secondaryColor: AppColors.primaryNavy,
      baseOpacity: 0.28 * opacity,
      strokeWidth: 1.5,
    );
  }

  /// Draws a ribbon of parallel organic wavy contour lines.
  void _drawContourBand({
    required Canvas canvas,
    required Offset start,
    required Offset cp1,
    required Offset cp2,
    required Offset end,
    required int lineCount,
    required double spacing,
    required Color primaryColor,
    required Color secondaryColor,
    required double baseOpacity,
    required double strokeWidth,
  }) {
    for (int i = 0; i < lineCount; i++) {
      final isAccent = i % 2 == 0;
      final color = isAccent ? primaryColor : secondaryColor;
      final lineAlpha = (baseOpacity * (1.0 - (i * 0.12))).clamp(0.05, 0.45);

      final paint = Paint()
        ..color = color.withValues(alpha: lineAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      final dy = (i - (lineCount - 1) / 2) * spacing;
      final path = Path()
        ..moveTo(start.dx, start.dy + dy)
        ..cubicTo(
          cp1.dx,
          cp1.dy + dy * 1.1,
          cp2.dx,
          cp2.dy + dy * 0.9,
          end.dx,
          end.dy + dy,
        );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ContourWavePainter oldDelegate) {
    return oldDelegate.variant != variant || oldDelegate.opacity != opacity;
  }
}
