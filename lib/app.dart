import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/emergency_broadcast_provider.dart';
import 'routing/app_router.dart';
import 'theme/app_theme.dart';
import 'widgets/emergency_alert_overlay.dart';

/// Root application widget configured with [GoRouter] and [ProviderScope].
/// Listens to live broadcast alerts and displays EmergencyAlertOverlay when triggered.
class WeroApp extends ConsumerWidget {
  const WeroApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final activeAlert = ref.watch(activeBroadcastAlertProvider);

    return MaterialApp.router(
      title: 'Siagaku / Wero',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) {
        return Stack(
          children: [
            ?child,
            if (activeAlert != null)
              EmergencyAlertOverlay(
                event: activeAlert,
                onDismiss: () =>
                    ref.read(activeBroadcastAlertProvider.notifier).dismiss(),
              ),
          ],
        );
      },
    );
  }
}
