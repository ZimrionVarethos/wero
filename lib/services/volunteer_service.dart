import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';
import '../models/public_sos_event.dart';

/// Service managing volunteer assistance and nearby public emergency beacons.
class VolunteerService {
  const VolunteerService({
    this.client,
    this.httpClient,
  });

  final SupabaseClient? client;
  final http.Client? httpClient;

  http.Client get _http => httpClient ?? http.Client();

  /// Fetch active public SOS alerts within given coordinate radius.
  Future<List<PublicSosEvent>> fetchNearbyPublicSos({
    double? lat,
    double? lng,
    double radiusM = 10000,
  }) async {
    try {
      final base = AppConfig.webBackendUrl.replaceAll(RegExp(r'/+$'), '');
      final uri = Uri.parse('$base/api/sos/public').replace(
        queryParameters: {
          if (lat != null) 'lat': lat.toString(),
          if (lng != null) 'lng': lng.toString(),
          'radius': radiusM.toString(),
        },
      );

      final resp = await _http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final data = body['data'] as List<dynamic>? ?? [];
        return data
            .map((e) => PublicSosEvent.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    // Fallback directly from Supabase if web endpoint is unreachable
    final sb = client;
    if (sb != null) {
      try {
        final res = await sb
            .from('sos_events')
            .select(
              'id, victim_id, mode, status, stage, note, accuracy_m, created_at, latitude, longitude',
            )
            .eq('mode', 'PUBLIC')
            .inFilter('status', ['ACTIVE', 'CLAIMED'])
            .order('created_at', ascending: false)
            .limit(20);

        return (res as List)
            .map((item) => PublicSosEvent.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    return const [];
  }

  /// Claim or update volunteer assistance status for an active SOS.
  Future<bool> claimSos({
    required String sosId,
    required String responderId,
    String? responderName,
    String status = 'EN_ROUTE',
  }) async {
    try {
      final base = AppConfig.webBackendUrl.replaceAll(RegExp(r'/+$'), '');
      final uri = Uri.parse('$base/api/sos/public');
      final resp = await _http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'sos_id': sosId,
              'responder_id': responderId,
              'responder_name': responderName ?? 'Relawan Wero',
              'status': status,
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return true;
      }
    } catch (_) {}

    // Supabase fallback update if authenticated
    final sb = client;
    if (sb != null) {
      try {
        await sb.from('responder_claims').upsert({
          'sos_id': sosId,
          'responder_id': responderId,
          'status': status,
          'claimed_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        return true;
      } catch (_) {}
    }

    return false;
  }
}
