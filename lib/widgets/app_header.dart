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
import 'sos_manage_sheet.dart';

/// Reusable top app bar supporting dynamic emergency SOS alert indicators.
class AppHeader extends ConsumerStatefulWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.title,
    this.titleWidget,
    this.onMenuPressed,
    this.showBackButton = true,
    this.actions,
    this.prefixActions,
    this.bottom,
  });

  final String? title;
  final Widget? titleWidget;
  final VoidCallback? onMenuPressed;
  final bool showBackButton;
  final List<Widget>? actions;
  final List<Widget>? prefixActions;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));

  @override
  ConsumerState<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends ConsumerState<AppHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _navigateTo(BuildContext context, String route) {
    if (GoRouterState.of(context).matchedLocation == route) return;
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final activeSos = ref.watch(activeSosProvider).asData?.value;
    final isSosActive = activeSos != null;

    if (isSosActive) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.reset();
      }
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) {
        final bgColor = isSosActive
            ? Color.lerp(
                AppColors.surfaceWhite,
                const Color(0xFFFFF0F0),
                _pulseAnimation.value,
              )!
            : AppColors.surfaceWhite;

        final headerDecoration = isSosActive
            ? BoxDecoration(
                color: bgColor,
                border: const Border(
                  bottom: BorderSide(color: AppColors.awas, width: 2.5),
                  top: BorderSide(color: AppColors.awas, width: 1.5),
                ),
              )
            : BoxDecoration(color: bgColor);

        return Container(
          decoration: headerDecoration,
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            bottom: widget.bottom,
            titleSpacing: widget.showBackButton ? 0 : AppSpacing.base,
            title:
                widget.titleWidget ??
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppLogo(height: 26),
                    if (widget.title != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          widget.title!,
                          style: AppTextStyles.screenTitle.copyWith(
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
            leading: widget.showBackButton
                ? IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                    ),
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
                widget.actions ??
                [
                  ...?widget.prefixActions,
                  if (isSosActive)
                    IconButton(
                      tooltip: 'Status SOS Darurat Aktif',
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.awas,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.awas.withValues(
                                alpha: 0.3 + 0.3 * _pulseAnimation.value,
                              ),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.priority_high_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      onPressed: () => SosManageSheet.show(context, activeSos),
                    ),
                  // 1. History
                  IconButton(
                    icon: const Icon(Icons.history_rounded, size: 22),
                    color: AppColors.primaryNavy,
                    tooltip: 'Riwayat & Peringatan',
                    onPressed: () => _navigateTo(context, AppRoutes.statistics),
                  ),
                  // 2. Maps
                  IconButton(
                    icon: const Icon(Icons.map_outlined, size: 22),
                    color: AppColors.primaryNavy,
                    tooltip: 'Peta & Titik Evakuasi',
                    onPressed: () => _navigateTo(context, AppRoutes.evacuation),
                  ),
                  // 3. Notif
                  Consumer(
                    builder: (context, ref, _) {
                      final activeAlert = ref.watch(
                        activeBroadcastAlertProvider,
                      );
                      final eventsCount =
                          ref
                              .watch(disasterEventsProvider)
                              .asData
                              ?.value
                              .length ??
                          0;
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
                                widget.onMenuPressed ??
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
          ),
        );
      },
    );
  }
}
