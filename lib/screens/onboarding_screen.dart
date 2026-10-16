import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/image_sources.dart';
import '../routing/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Onboarding screen — first screen shown on app launch.
///
/// Layout (top to bottom):
/// 1. Full-width hero illustration (BoxFit.cover, clipped).
/// 2. White content section with headline, supporting text, page indicators.
/// 3. Primary black "Get Started" button that navigates to ActivityScreen.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasBlue,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(flex: 5, child: _HeroImage()),
            Expanded(
              flex: 4,
              child: _ContentSection(
                onGetStarted: () => context.push(AppRoutes.activity),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(AppRadius.card),
        bottomRight: Radius.circular(AppRadius.card),
      ),
      child: Image.network(
        ImageSources.onboardingHero,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            color: AppColors.canvasBlue,
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.chartBlue,
                strokeWidth: 2.5,
              ),
            ),
          );
        },
        errorBuilder: (_, _, _) => Container(
          color: AppColors.border,
          child: const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ContentSection extends StatelessWidget {
  const _ContentSection({required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          Text(
            'Track your Active Lifestyle',
            style: AppTextStyles.screenTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Find your way to the perfect body',
            style: AppTextStyles.bodySecondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          const _PageIndicators(count: 4, activeIndex: 0),
          const SizedBox(height: AppSpacing.xl),
          _GetStartedButton(onPressed: onGetStarted),
          const Spacer(),
        ],
      ),
    );
  }
}

class _PageIndicators extends StatelessWidget {
  const _PageIndicators({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24.0 : 8.0,
          height: 8.0,
          decoration: BoxDecoration(
            color: isActive ? AppColors.accentOrange : AppColors.border,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _GetStartedButton extends StatelessWidget {
  const _GetStartedButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.textPrimary,
          foregroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          elevation: 0,
        ),
        child: Text(
          'Get Started',
          style: AppTextStyles.label.copyWith(
            color: AppColors.surface,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
