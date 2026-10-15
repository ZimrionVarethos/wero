import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routing/app_router.dart';
import 'theme/app_theme.dart';

/// Root application widget configured with [GoRouter] and [ProviderScope].
/// Uses centralized [AppTheme] and supports responsive Flutter mobile layout.
class WeroApp extends ConsumerWidget {
  const WeroApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Siagaku / Wero',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
