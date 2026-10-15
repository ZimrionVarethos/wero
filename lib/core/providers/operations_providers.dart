import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/disaster_event.dart';
import '../../models/evacuation_point.dart';
import '../../models/sos_event.dart';
import '../../services/operations_service.dart';
import 'supabase_providers.dart';

/// Provider exposing [OperationsService].
final operationsServiceProvider = Provider<OperationsService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return OperationsService(client);
});

/// Async notifier managing the user's active SOS status.
class ActiveSosNotifier extends AsyncNotifier<SosEvent?> {
  @override
  Future<SosEvent?> build() async {
    final service = ref.watch(operationsServiceProvider);
    return service.fetchActiveSos();
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
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Cancel active SOS.
  Future<void> cancelSos([String? reason]) async {
    final current = state.asData?.value;
    if (current == null) return;
    final service = ref.read(operationsServiceProvider);
    await service.cancelSos(current.id, reason);
    state = const AsyncValue.data(null);
  }

  /// Resolve active SOS.
  Future<void> resolveSos([String? note]) async {
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
  return service.fetchDisasterEvents(limit: 5);
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

/// Provider fetching evacuation facilities based on kind and search query.
final evacuationPointsProvider =
    FutureProvider.family<List<EvacuationPoint>, EvacuationQuery>((
      ref,
      query,
    ) async {
      final service = ref.watch(operationsServiceProvider);
      return service.fetchEvacuationPoints(
        kind: query.kind,
        searchQuery: query.searchQuery,
      );
    });
