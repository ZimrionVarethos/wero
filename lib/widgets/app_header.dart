import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/emergency_broadcast_provider.dart';
import '../core/providers/operations_providers.dart';
import '../routing/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_logo.dart';
import 'notification_log_sheet.dart';

/// Reusable top app bar used across main application screens.
///
/// Features:
/// - Optional back button on the left (or custom title)
/// - Top action buttons on the right: History -> Maps -> Notif (with alert indicator)
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.title,
    this.onMenuPressed,
    this.showBackButton = true,
    this.actions,
    this.bottom,
  });

  final String? title;
  final VoidCallback? onMenuPressed;
  final bool showBackButton;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));

  void _navigateTo(BuildContext context, String route) {
    if (GoRouterState.of(context).matchedLocation == route) return;
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surfaceWhite,
      elevation: 0,
      scrolledUnderElevation: 0,
      bottom: bottom,
      titleSpacing: showBackButton ? 0 : AppSpacing.base,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLogo(height: 26),
          if (title != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                title!,
                style: AppTextStyles.screenTitle.copyWith(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: AppColors.primaryNavy,
              tooltip: 'Kembali',
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            )
          : null,
      actions:
          actions ??
          [
            // 1. History (Riwayat Bencana & BMKG)
            IconButton(
              icon: const Icon(Icons.history_rounded, size: 22),
              color: AppColors.primaryNavy,
              tooltip: 'Riwayat & Peringatan',
              onPressed: () => _navigateTo(context, AppRoutes.statistics),
            ),
            // 2. Maps (Peta & Titik Evakuasi)
            IconButton(
              icon: const Icon(Icons.map_outlined, size: 22),
              color: AppColors.primaryNavy,
              tooltip: 'Peta & Titik Evakuasi',
              onPressed: () => _navigateTo(context, AppRoutes.evacuation),
            ),
            // 3. Notif (Log Notifikasi & Siaran Darurat)
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
                          ? AppColors.awas
                          : AppColors.primaryNavy,
                      tooltip: 'Log Notifikasi & Siaran',
                      onPressed:
                          onMenuPressed ??
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
                                ? AppColors.awas
                                : AppColors.info,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surfaceWhite,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
    );
  }
}
