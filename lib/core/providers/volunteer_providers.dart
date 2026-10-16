import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/public_sos_event.dart';
import '../../services/volunteer_service.dart';
import 'supabase_providers.dart';

/// Provider exposing [VolunteerService].
final volunteerServiceProvider = Provider<VolunteerService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return VolunteerService(client: client);
});

/// Query parameter for nearby public SOS search.
class PublicSosQuery {
  const PublicSosQuery({
    this.latitude,
    this.longitude,
    this.radiusM = 10000,
  });

  final double? latitude;
  final double? longitude;
  final double radiusM;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicSosQuery &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          radiusM == other.radiusM;

  @override
  int get hashCode => Object.hash(latitude, longitude, radiusM);
}

/// Provider fetching nearby public SOS requests within radius.
final nearbyPublicSosProvider =
    FutureProvider.family<List<PublicSosEvent>, PublicSosQuery>((
      ref,
      query,
    ) async {
      final service = ref.watch(volunteerServiceProvider);
      return service.fetchNearbyPublicSos(
        lat: query.latitude,
        lng: query.longitude,
        radiusM: query.radiusM,
      );
    });

/// Active volunteer mission state.
class ActiveVolunteerMission {
  const ActiveVolunteerMission({
    required this.event,
    this.status = 'EN_ROUTE',
  });

  final PublicSosEvent event;
  final String status; // 'EN_ROUTE' | 'ARRIVED'

  ActiveVolunteerMission copyWith({String? status}) {
    return ActiveVolunteerMission(
      event: event,
      status: status ?? this.status,
    );
  }
}

/// Notifier managing volunteer response to a public SOS beacon.
class ActiveVolunteerNotifier extends Notifier<ActiveVolunteerMission?> {
  @override
  ActiveVolunteerMission? build() => null;

  /// Start volunteering and set route to victim.
  Future<bool> startMission({
    required PublicSosEvent sos,
    required String responderId,
    String? responderName,
  }) async {
    final service = ref.read(volunteerServiceProvider);
    final ok = await service.claimSos(
      sosId: sos.id,
      responderId: responderId,
      responderName: responderName,
      status: 'EN_ROUTE',
    );
    if (ok) {
      state = ActiveVolunteerMission(event: sos, status: 'EN_ROUTE');
    }
    return ok;
  }

  /// Mark arrived at victim location.
  Future<bool> markArrived(String responderId) async {
    final current = state;
    if (current == null) return false;
    final service = ref.read(volunteerServiceProvider);
    final ok = await service.claimSos(
      sosId: current.event.id,
      responderId: responderId,
      status: 'ARRIVED',
    );
    if (ok) {
      state = current.copyWith(status: 'ARRIVED');
    }
    return ok;
  }

  /// Cancel or finish volunteer mission.
  Future<bool> finishMission(String responderId) async {
    final current = state;
    if (current == null) return true;
    final service = ref.read(volunteerServiceProvider);
    await service.claimSos(
      sosId: current.event.id,
      responderId: responderId,
      status: 'RELEASED',
    );
    state = null;
    return true;
  }
}

/// Provider for current volunteer mission.
final activeVolunteerMissionProvider =
    NotifierProvider<ActiveVolunteerNotifier, ActiveVolunteerMission?>(
      ActiveVolunteerNotifier.new,
    );
