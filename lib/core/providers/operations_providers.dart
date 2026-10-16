import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/disaster_event.dart';
import '../../models/evacuation_point.dart';
import '../../models/sos_event.dart';
import '../../services/evacuation_cache_service.dart';
import '../../services/operations_service.dart';
import 'supabase_providers.dart';

/// Provider exposing [OperationsService].
final operationsServiceProvider = Provider<OperationsService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return OperationsService(client);
});

/// Async notifier managing the user's active SOS status.
class ActiveSosNotifier extends AsyncNotifier<SosEvent?> {
  Timer? _pollTimer;

  @override
  Future<SosEvent?> build() async {
    ref.onDispose(() {
      _pollTimer?.cancel();
    });

    final service = ref.watch(operationsServiceProvider);
    final initial = await service.fetchActiveSos();

    if (initial != null) {
      _startAdminResolutionWatch(initial.id);
    }

    return initial;
  }

  void _startAdminResolutionWatch(String sosId) {
    _pollTimer?.cancel();
    // Poll every 4 seconds to detect when admin or helpers resolve the SOS
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      try {
        final service = ref.read(operationsServiceProvider);
        final latest = await service.fetchActiveSos();
        if (latest == null || !latest.isActive) {
          _pollTimer?.cancel();
          state = const AsyncValue.data(null);
        }
      } catch (_) {}
    });
  }

  /// Trigger emergency SOS.
  Future<SosEvent> triggerSos({
    required String mode,
    required double latitude,
    required double longitude,
    double accuracyM = 10.0,
    String? note,
  }) async {
    final service = ref.read(operationsServiceProvider);
    state = const AsyncValue.loading();
    try {
      final created = await service.triggerSos(
        mode: mode,
        latitude: latitude,
        longitude: longitude,
        accuracyM: accuracyM,
        note: note,
      );
      state = AsyncValue.data(created);
      _startAdminResolutionWatch(created.id);
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Cancel active SOS.
  Future<void> cancelSos([String? reason]) async {
    _pollTimer?.cancel();
    final current = state.asData?.value;
    if (current == null) return;
    final service = ref.read(operationsServiceProvider);
    await service.cancelSos(current.id, reason);
    state = const AsyncValue.data(null);
  }

  /// Resolve active SOS.
  Future<void> resolveSos([String? note]) async {
    _pollTimer?.cancel();
    final current = state.asData?.value;
    if (current == null) return;
    final service = ref.read(operationsServiceProvider);
    await service.resolveSos(current.id, note);
    state = const AsyncValue.data(null);
  }
}

/// Provider for user's active SOS status.
final activeSosProvider = AsyncNotifierProvider<ActiveSosNotifier, SosEvent?>(
  ActiveSosNotifier.new,
);

/// Provider fetching recent official disaster warnings.
final disasterEventsProvider = FutureProvider<List<DisasterEvent>>((ref) async {
  final service = ref.watch(operationsServiceProvider);
  return service.fetchDisasterEvents(limit: 20);
});

/// State for evacuation points filter and search.
class EvacuationQuery {
  const EvacuationQuery({this.kind, this.searchQuery = ''});
  final String? kind;
  final String searchQuery;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvacuationQuery &&
          runtimeType == other.runtimeType &&
          kind == other.kind &&
          searchQuery == other.searchQuery;

  @override
  int get hashCode => Object.hash(kind, searchQuery);
}

/// Cache service provider for offline evacuation facilities.
final evacuationCacheServiceProvider = Provider<EvacuationCacheService>((ref) {
  return const EvacuationCacheService();
});

/// Provider fetching evacuation facilities based on kind and search query.
final evacuationPointsProvider =
    FutureProvider.family<List<EvacuationPoint>, EvacuationQuery>((
      ref,
      query,
    ) async {
      final service = ref.watch(operationsServiceProvider);
      final cacheService = ref.watch(evacuationCacheServiceProvider);

      try {
        final onlinePoints = await service.fetchEvacuationPoints(
          kind: query.kind,
          searchQuery: query.searchQuery,
        );
        if (onlinePoints.isNotEmpty) {
          if (query.kind == null && query.searchQuery.isEmpty) {
            await cacheService.cachePoints(onlinePoints);
          }
          return onlinePoints;
        }
      } catch (_) {}

      return cacheService.getCachedPoints(
        kind: query.kind,
        searchQuery: query.searchQuery,
      );
    });
