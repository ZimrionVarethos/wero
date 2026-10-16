import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/errors/app_exceptions.dart';
import '../models/disaster_event.dart';
import '../models/evacuation_point.dart';
import '../models/sos_event.dart';

/// Service managing emergency SOS, disaster alerts, and evacuation points.
class OperationsService {
  const OperationsService(this._client);

  final SupabaseClient? _client;

  /// Trigger emergency SOS with location, mode, and optional note.
  Future<SosEvent> triggerSos({
    required String mode,
    required double latitude,
    required double longitude,
    double accuracyM = 10.0,
    String? note,
  }) async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw const AppAuthException('Anda harus masuk untuk mengaktifkan SOS.');
    }

    try {
      final res = await client.rpc(
        'trigger_sos_event',
        params: {
          'p_mode': mode,
          'p_latitude': latitude,
          'p_longitude': longitude,
          'p_accuracy_m': accuracyM,
          'p_note': note?.trim(),
        },
      );
      return res is Map<String, dynamic>
          ? SosEvent.fromJson(res)
          : SosEvent(
              id: res['id'] as String,
              victimId: user.id,
              mode: mode,
              status: 'ACTIVE',
              note: note,
              latitude: latitude,
              longitude: longitude,
              createdAt: DateTime.now(),
            );
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const ValidationException(
          'Anda sudah memiliki permintaan bantuan SOS yang masih aktif.',
        );
      }
      throw ServerException('Gagal mengaktifkan SOS: ${e.message}', e);
    } catch (e) {
      throw ServerException('Gagal mengaktifkan SOS: $e', e);
    }
  }

  /// Cancel own active SOS.
  Future<bool> cancelSos(String sosId, [String? reason]) async {
    final client = _client;
    if (client == null) return false;
    try {
      final res = await client.rpc(
        'cancel_own_sos_event',
        params: {'p_sos_id': sosId, 'p_reason': reason},
      );
      return res == true;
    } catch (e) {
      throw ServerException('Gagal membatalkan SOS: $e', e);
    }
  }

  /// Mark SOS as resolved when safe.
  Future<bool> resolveSos(String sosId, [String? note]) async {
    final client = _client;
    if (client == null) return false;
    try {
      final res = await client.rpc(
        'resolve_own_sos_event',
        params: {'p_sos_id': sosId, 'p_resolution_note': note},
      );
      return res == true;
    } catch (e) {
      throw ServerException('Gagal menyelesaikan status SOS: $e', e);
    }
  }

  /// Check if the currently signed in user has an active SOS event.
  Future<SosEvent?> fetchActiveSos() async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return null;

    try {
      final res = await client
          .from('sos_events')
          .select(
            'id, victim_id, mode, status, stage, note, accuracy_m, created_at',
          )
          .eq('victim_id', user.id)
          .inFilter('status', ['ACTIVE', 'CLAIMED'])
          .maybeSingle();

      if (res == null) return null;
      return SosEvent.fromJson(res);
    } catch (e) {
      return null;
    }
  }

  /// Fetch published disaster event warnings (BMKG / BNPB).
  Future<List<DisasterEvent>> fetchDisasterEvents({
    String? severity,
    int limit = 10,
  }) async {
    final client = _client;
    if (client == null) return const [];

    try {
      var query = client
          .from('disaster_events')
          .select(
            'id, source, source_event_id, disaster_type, severity, magnitude, depth_km, headline, occurred_at, source_url, region_id, source_payload',
          )
          .eq('is_published', true);

      if (severity != null && severity.isNotEmpty) {
        query = query.eq('severity', severity);
      }

      final res = await query
          .order('occurred_at', ascending: false)
          .limit(limit);
      return (res as List).map((item) => DisasterEvent.fromJson(item)).toList();
    } catch (e) {
      return const [];
    }
  }

  /// Fetch active evacuation facilities with search and category filtering.
  Future<List<EvacuationPoint>> fetchEvacuationPoints({
    String? kind,
    String? searchQuery,
    int limit = 30,
  }) async {
    final client = _client;
    if (client == null) return const [];

    try {
      var query = client
          .from('evacuation_points')
          .select(
            'id, kind, name, description, address, capacity, latitude, longitude, region_id',
          )
          .eq('is_active', true);

      if (kind != null && kind.isNotEmpty) {
        query = query.eq('kind', kind);
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim();
        query = query.or('name.ilike.%$q%,address.ilike.%$q%');
      }

      final res = await query.order('name', ascending: true).limit(limit);
      return (res as List)
          .map((item) => EvacuationPoint.fromJson(item))
          .toList();
    } catch (e) {
      return const [];
    }
  }

  /// Create new evacuation point (Admin Web).
  Future<bool> createEvacuationPoint({
    required String name,
    required String kind,
    required String address,
    required double latitude,
    required double longitude,
    int? capacity,
    String? description,
  }) async {
    final client = _client;
    if (client == null) return false;
    try {
      await client.from('evacuation_points').insert({
        'name': name.trim(),
        'kind': kind,
        'address': address.trim(),
        'geom': 'POINT($longitude $latitude)',
        'capacity': capacity,
        'description': description?.trim(),
        'is_active': true,
      });
      return true;
    } catch (e) {
      throw ServerException('Gagal menambah posko: $e', e);
    }
  }

  /// Update existing evacuation point (Admin Web).
  Future<bool> updateEvacuationPoint({
    required String id,
    required String name,
    required String kind,
    required String address,
    required double latitude,
    required double longitude,
    int? capacity,
    String? description,
  }) async {
    final client = _client;
    if (client == null) return false;
    try {
      await client
          .from('evacuation_points')
          .update({
            'name': name.trim(),
            'kind': kind,
            'address': address.trim(),
            'geom': 'POINT($longitude $latitude)',
            'capacity': capacity,
            'description': description?.trim(),
          })
          .eq('id', id);
      return true;
    } catch (e) {
      throw ServerException('Gagal memperbarui posko: $e', e);
    }
  }

  /// Delete evacuation point (Admin Web).
  Future<bool> deleteEvacuationPoint(String id) async {
    final client = _client;
    if (client == null) return false;
    try {
      await client.from('evacuation_points').delete().eq('id', id);
      return true;
    } catch (e) {
      throw ServerException('Gagal menghapus posko: $e', e);
    }
  }
}
