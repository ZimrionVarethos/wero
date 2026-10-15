import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Reusable top app bar used by ActivityScreen and StatisticsScreen.
///
/// Shows a back button on the left and a menu icon on the right.
/// The menu callback ([onMenuPressed]) opens a drawer or placeholder.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key, this.onMenuPressed, this.showBackButton = true});

  final VoidCallback? onMenuPressed;
  final bool showBackButton;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
              color: AppColors.textPrimary,
              tooltip: 'Back',
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            )
          : null,
      actions: [
        IconButton(
          icon: const Icon(Icons.grid_view_rounded, size: 22),
          color: AppColors.textPrimary,
          tooltip: 'Menu',
          onPressed: onMenuPressed ?? () => _showPlaceholderMenu(context),
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }

  void _showPlaceholderMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      builder: (_) => const _PlaceholderMenuSheet(),
    );
  }
}

class _PlaceholderMenuSheet extends StatelessWidget {
  const _PlaceholderMenuSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Menu',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            'Additional navigation will appear here in a future release.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
