import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_logo.dart';
import 'widgets/login_form_card.dart';

/// Screen for user login and registration framed with brand ornaments.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  static const routeName = '/login';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth > 640;

    final content = SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
            vertical: AppSpacing.lg,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Brand logo di atas form card (menggantikan header)
                AppLogo(height: 52),
                SizedBox(height: AppSpacing.lg),
                // Card form autentikasi
                LoginFormCard(),
              ],
            ),
          ),
        ),
      ),
    );

    // Mobile viewport: Fullscreen edge-to-edge ornament
    if (!isDesktop) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/ornamen.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
            content,
          ],
        ),
      );
    }

    // Desktop/Tablet viewport: Centered framed canvas matching ornament aspect ratio
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: Center(
        child: Container(
          width: 460,
          margin: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryNavy.withValues(alpha: 0.10),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/ornamen.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
              content,
            ],
          ),
        ),
      ),
    );
  }
}
