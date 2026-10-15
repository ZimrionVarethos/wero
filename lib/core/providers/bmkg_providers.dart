import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/bmkg_quake.dart';
import '../../services/bmkg_alert_service.dart';

/// Provider for BmkgAlertService.
final bmkgAlertServiceProvider = Provider<BmkgAlertService>((ref) {
  return const BmkgAlertService();
});

/// AutoDispose FutureProvider fetching the latest significant earthquake from BMKG.
final latestBmkgQuakeProvider = FutureProvider.autoDispose<BmkgQuake>((
  ref,
) async {
  return ref.watch(bmkgAlertServiceProvider).fetchLatestQuake();
});

/// AutoDispose FutureProvider fetching list of recent earthquakes from BMKG.
final recentBmkgQuakesProvider = FutureProvider.autoDispose<List<BmkgQuake>>((
  ref,
) async {
  return ref.watch(bmkgAlertServiceProvider).fetchRecentQuakes();
});
