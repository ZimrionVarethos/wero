import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Reusable application brand logo widget displaying `logodantulisan.png`.
/// Features:
/// - Fixed height constraint with aspect ratio preservation
/// - Semantic accessibility label
/// - Graceful fallback during tests or offline asset loading
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.height = 28.0});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logodantulisan.png',
      height: height,
      fit: BoxFit.contain,
      semanticLabel: 'Wero Logo',
      errorBuilder: (context, error, stackTrace) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shield_rounded,
              color: AppColors.primaryNavy,
              size: 22,
            ),
            const SizedBox(width: 6),
            Text(
              'Wero',
              style: AppTextStyles.sectionTitle.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primaryNavy,
              ),
            ),
          ],
        );
      },
    );
  }
}
