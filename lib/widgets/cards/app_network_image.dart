import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Reusable network image with bounded aspect ratio, shimmer loader, and offline error fallback.
/// Strictly enforces Requirement 4 from the design system.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.aspectRatio = 16 / 9,
    this.borderRadius = AppRadius.card,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.image_not_supported_outlined,
    this.height,
    this.width,
  });

  final String? imageUrl;
  final double aspectRatio;
  final double borderRadius;
  final BoxFit fit;
  final IconData fallbackIcon;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    Widget content;
    final validUrl = imageUrl != null && imageUrl!.trim().isNotEmpty;

    if (!validUrl) {
      content = _buildFallback();
    } else {
      content = Image.network(
        imageUrl!,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _buildLoadingPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildFallback();
        },
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: AspectRatio(aspectRatio: aspectRatio, child: content),
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: AppColors.borderNeutral.withValues(alpha: 0.3),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            color: AppColors.mutedText,
          ),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      color: AppColors.backgroundCream,
      child: Center(
        child: Icon(fallbackIcon, size: 32, color: AppColors.mutedText),
      ),
    );
  }
}
