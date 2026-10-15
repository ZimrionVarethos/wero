import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/emergency_broadcast_provider.dart';
import '../core/providers/operations_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'notification_log_sheet.dart';

/// Reusable top app bar used across main application screens.
///
/// Shows an optional back button on the left and a notification log button on the right.
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
              tooltip: 'Kembali',
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            )
          : null,
      actions: [
        Consumer(
          builder: (context, ref, _) {
            final activeAlert = ref.watch(activeBroadcastAlertProvider);
            final eventsCount =
                ref.watch(disasterEventsProvider).asData?.value.length ?? 0;
            final hasAlert = activeAlert != null || eventsCount > 0;

            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    activeAlert != null
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_rounded,
                    size: 24,
                  ),
                  color: activeAlert != null
                      ? AppColors.chartRed
                      : AppColors.textPrimary,
                  tooltip: 'Log Notifikasi & Siaran',
                  onPressed: onMenuPressed ??
                      () => NotificationLogSheet.show(context),
                ),
                if (hasAlert)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: activeAlert != null
                            ? AppColors.chartRed
                            : AppColors.chartBlue,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surface,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }
}

